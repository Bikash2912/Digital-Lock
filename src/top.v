`timescale 1ns / 1ps
module top(
    input        clk,

    input        rst_btn,       // BTNC  U18
    input        mode_sw,       // SW0   V17 — 1=SAVE, 0=CHECK
    input        save_btn,      // BTNU  T18
    input        check_btn,     // BTNL  U17

    input  [3:0] col,
    output [3:0] row,

    output       unlock_led,   // LD0  U16
    output       error_led,    // LD1  E19
    output       save_led,     // LD2  U19
    output       press_led,    // LD3  V19
    output       mode_led14,   // LD14 P1  — SAVE mode indicator
    output       mode_led15,   // LD15 L1  — SAVE mode indicator

    output       led_green,    // M18 — unlock
    output       led_red,      // N17 — error/locked
    output       led_yellow,   // P18 — keypress

    input        ext_save_btn,   // JC7  L17
    input        ext_check_btn,  // JC8  M19
    input        ext_rst_btn,    // JC9  P17
    input        ext_mode_btn,   // JC10 L16 — unused (tied in XDC)

    output       buzzer,
    output       lcd_rs,
    output       lcd_en,
    output [3:0] lcd_d,

    output [3:0] an,
    output [6:0] seg,
    output       dp
);

reg [19:0] init_cnt;
reg        init_stable;
always @(posedge clk or posedge rst_btn) begin
    if (rst_btn) begin init_cnt <= 0; init_stable <= 0; end
    else if (!init_stable) begin
        if (init_cnt == 20'd1_000_000) init_stable <= 1;   // 10 ms
        else init_cnt <= init_cnt + 1;
    end
end

reg ext_sv1, ext_sv2;
reg ext_ck1, ext_ck2;
reg ext_rs1, ext_rs2;
always @(posedge clk) begin
    ext_sv1 <= ext_save_btn;  ext_sv2 <= ext_sv1;
    ext_ck1 <= ext_check_btn; ext_ck2 <= ext_ck1;
    ext_rs1 <= ext_rst_btn;   ext_rs2 <= ext_rs1;
end

wire ext_save_act  = init_stable & (~ext_sv2);
wire ext_check_act = init_stable & (~ext_ck2);
wire ext_rst_act   = init_stable & (~ext_rs2);

reg sw_d1, sw_d2;
always @(posedge clk or posedge rst_btn) begin
    if (rst_btn) begin sw_d1 <= 0; sw_d2 <= 0; end
    else         begin sw_d1 <= mode_sw; sw_d2 <= sw_d1; end
end
wire mode_final = sw_d2;   // 1=SAVE, 0=CHECK
wire rst = rst_btn | ext_rst_act;
wire save_combined  = save_btn  | ext_save_act;
wire check_combined = check_btn | ext_check_act;
wire [3:0] key;
wire       valid;

keypad_controller KC(
    .clk(clk), .rst(rst),
    .col(col), .row(row),
    .key(key), .valid(valid)
);
reg valid_d;
always @(posedge clk or posedge rst) begin
    if (rst) valid_d <= 0; else valid_d <= valid;
end
wire valid_pulse = valid_d;

wire [15:0] password;

password_register PR(
    .clk(clk), .rst(rst),
    .valid(valid),
    .key(key),
    .password(password)
);
wire       entry_done;   // from control_unit
reg [1:0]  digit_count;  // 0..3 (4th digit triggers entry_done simultaneously)

always @(posedge clk or posedge rst) begin
    if (rst) begin
        digit_count <= 0;
    end else if (entry_done) begin
        digit_count <= 0;
    end else if (valid_pulse) begin
        if (digit_count != 2'd3)
            digit_count <= digit_count + 1;
    end
end

wire [15:0] hash;
strong_hash HASH(.data(password), .hash(hash));
wire [15:0] stored_hash;
wire        save_en;

password_storage STORE(
    .clk(clk),
    .rst(rst),
    .save_en(save_en),
    .hash_in(hash),
    .stored_hash(stored_hash)
);
wire check_en_raw;

control_unit CTRL(
    .clk(clk), .rst(rst),
    .valid_pulse(valid_pulse),
    .mode_sw(mode_final),
    .save_btn(save_combined),
    .check_btn(check_combined),
    .entry_done(entry_done),
    .save_en(save_en),
    .check_en(check_en_raw)
);
reg        match_reg;
reg [1:0]  attempt_cnt;
reg        locked;
wire       check_en = check_en_raw & ~locked;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        match_reg <= 0; attempt_cnt <= 0; locked <= 0;
    end else if (check_en) begin
        if (hash == stored_hash) begin
            match_reg   <= 1;
            attempt_cnt <= 0;
        end else begin
            match_reg <= 0;
            if (attempt_cnt == 2'd2) locked <= 1;
            else                     attempt_cnt <= attempt_cnt + 1;
        end
    end
end

wire unlock, error;

result_logic RES(
    .clk(clk), .rst(rst),
    .check_en(check_en),
    .match(match_reg),
    .unlock(unlock),
    .error(error)
);

wire [2:0] sys_state;

system_state SYS(
    .clk(clk), .rst(rst),
    .valid_pulse(valid_pulse),
    .save_en(save_en),
    .unlock(unlock),
    .error(error),
    .locked(locked),
    .state(sys_state)
);

reg unlock_latched, error_latched, save_latched;
always @(posedge clk or posedge rst) begin
    if (rst) begin
        unlock_latched <= 0; error_latched <= 0; save_latched <= 0;
    end else begin
        if (save_en)
            save_latched <= 1;
        else if (sys_state == 3'd1 && valid_pulse)
            save_latched <= 0;

        if (unlock) begin
            unlock_latched <= 1; error_latched <= 0;
        end else if (error) begin
            error_latched <= 1; unlock_latched <= 0;
        end
    end
end

assign unlock_led = unlock_latched;
assign error_led  = error_latched | locked;
assign save_led   = save_latched;

assign mode_led14 = mode_final;   // ON when SW0=1 (SAVE)
assign mode_led15 = mode_final;   // ON when SW0=1 (SAVE)

reg [19:0] press_timer;
always @(posedge clk or posedge rst) begin
    if (rst)               press_timer <= 0;
    else if (valid_pulse)  press_timer <= 20'd200_000;
    else if (press_timer > 0) press_timer <= press_timer - 1;
end
wire press_active = (press_timer > 0);
assign press_led  = press_active;

assign led_green  = unlock_latched;
assign led_red    = error_latched | locked;
assign led_yellow = press_active;

localparam BZ_IDLE=4'd0,  BZ_SUCC=4'd1,  BZ_EB1=4'd2,   BZ_EGAP=4'd3,
           BZ_EB2=4'd4,   BZ_ALM1=4'd5,  BZ_AGAP1=4'd6, BZ_ALM2=4'd7,
           BZ_AGAP2=4'd8, BZ_ALM3=4'd9,  BZ_CLICK=4'd10;

reg [25:0] bz_cnt;
reg [3:0]  bz_st;
reg        bz_out;
reg        locked_d;
wire       locked_rise = locked & ~locked_d;

always @(posedge clk or posedge rst) begin
    if (rst) locked_d <= 0; else locked_d <= locked;
end

always @(posedge clk or posedge rst) begin
    if (rst) begin bz_st <= BZ_IDLE; bz_cnt <= 0; bz_out <= 0; end
    else begin
        case (bz_st)
        BZ_IDLE: begin
            bz_out <= 0; bz_cnt <= 0;
            if      (unlock)      bz_st <= BZ_SUCC;
            else if (error)       bz_st <= BZ_EB1;
            else if (locked_rise) bz_st <= BZ_ALM1;
            else if (valid_pulse) bz_st <= BZ_CLICK;
        end
        BZ_SUCC: begin   // 500 ms
            bz_out <= 1;
            if (bz_cnt == 26'd50_000_000) begin bz_out <= 0; bz_st <= BZ_IDLE; bz_cnt <= 0; end
            else bz_cnt <= bz_cnt + 1;
        end
        BZ_EB1: begin    // 200 ms
            bz_out <= 1;
            if (bz_cnt == 26'd20_000_000) begin bz_st <= BZ_EGAP; bz_cnt <= 0; end
            else bz_cnt <= bz_cnt + 1;
        end
        BZ_EGAP: begin   // 100 ms gap
            bz_out <= 0;
            if (bz_cnt == 26'd10_000_000) begin bz_st <= BZ_EB2; bz_cnt <= 0; end
            else bz_cnt <= bz_cnt + 1;
        end
        BZ_EB2: begin    // 200 ms
            bz_out <= 1;
            if (bz_cnt == 26'd20_000_000) begin bz_out <= 0; bz_st <= BZ_IDLE; bz_cnt <= 0; end
            else bz_cnt <= bz_cnt + 1;
        end
        BZ_ALM1: begin   // alarm 100 ms
            bz_out <= 1;
            if (bz_cnt == 26'd10_000_000) begin bz_st <= BZ_AGAP1; bz_cnt <= 0; end
            else bz_cnt <= bz_cnt + 1;
        end
        BZ_AGAP1: begin  // 80 ms gap
            bz_out <= 0;
            if (bz_cnt == 26'd8_000_000) begin bz_st <= BZ_ALM2; bz_cnt <= 0; end
            else bz_cnt <= bz_cnt + 1;
        end
        BZ_ALM2: begin
            bz_out <= 1;
            if (bz_cnt == 26'd10_000_000) begin bz_st <= BZ_AGAP2; bz_cnt <= 0; end
            else bz_cnt <= bz_cnt + 1;
        end
        BZ_AGAP2: begin
            bz_out <= 0;
            if (bz_cnt == 26'd8_000_000) begin bz_st <= BZ_ALM3; bz_cnt <= 0; end
            else bz_cnt <= bz_cnt + 1;
        end
        BZ_ALM3: begin
            bz_out <= 1;
            if (bz_cnt == 26'd10_000_000) begin bz_out <= 0; bz_st <= BZ_IDLE; bz_cnt <= 0; end
            else bz_cnt <= bz_cnt + 1;
        end
        BZ_CLICK: begin  // 1 ms click
            bz_out <= 1;
            if (bz_cnt == 26'd100_000) begin bz_out <= 0; bz_st <= BZ_IDLE; bz_cnt <= 0; end
            else bz_cnt <= bz_cnt + 1;
        end
        default: bz_st <= BZ_IDLE;
        endcase
    end
end
assign buzzer = bz_out;

lcd_parallel LCD(
    .clk(clk), .rst(rst),
    .sys_state(sys_state),
    .password(password),
    .digit_count(digit_count),
    .entry_done(entry_done),      
    .lcd_rs(lcd_rs),
    .lcd_en(lcd_en),
    .lcd_d(lcd_d)
);

// 7-SEGMENT DISPLAY 
seg7_display SEG(
    .clk(clk), .rst(rst),
    .save_en(save_en),
    .password(password),
    .an(an), .seg(seg), .dp(dp)
);

endmodule
