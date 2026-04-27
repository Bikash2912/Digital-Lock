`timescale 1ns / 1ps
// ============================================================
// lcd_parallel.v  –  HD44780 16×2 LCD, 4-bit parallel mode
//
// PHYSICAL WIRING — Basys3 Pmod JB:
//   JB pin 1  → lcd_rs   (LCD pin 4,  RS)
//   JB pin 2  → lcd_en   (LCD pin 6,  EN)
//   JB pin 3  → lcd_d[0] (LCD pin 11, D4)
//   JB pin 4  → lcd_d[1] (LCD pin 12, D5)
//   JB pin 7  → lcd_d[2] (LCD pin 13, D6)
//   JB pin 8  → lcd_d[3] (LCD pin 14, D7)
//   JB pin 5  → GND      (LCD pins 1, 5  VSS, R/W)
//   JB pin 6  → 3.3 V    (LCD pin 2,  VDD)
//   Contrast pot wiper   → LCD pin 3   (V0)
//   Backlight + via 33Ω → LCD pin 15
//   Backlight −          → LCD pin 16 → GND
//
// BUG FIXES:
// ─────────────────────────────────────────────────────────────
// 1. MULTIPLE-DRIVER BUG (LCD stays blank):
//    `clearing` was driven from TWO always blocks. A reg with
//    two drivers = X in simulation, undefined in hardware.
//    FIX: ONE always block owns clearing and clear_cnt.
//
// 2. WRONG LCD MESSAGE (digit masking logic for ENTER state):
//    msg[11] had a broken ternary condition that never produced
//    an asterisk for the 4th slot during partial entry.
//    msg[8..11] now use digit_count correctly:
//      digit_count 0 → "----"
//      digit_count 1 → "*---"
//      digit_count 2 → "**--"
//      digit_count 3 → "***-"
//      entry_done    → "****" (digit_count resets to 0 after
//                              entry_done but LCD loops, so
//                              we use a latch `all_four`)
//
// 3. TIMING: EN pulse = 50 cycles = 500 ns (spec min 230 ns).
//    Power-on delay: 8 000 000 cycles = 80 ms.
//    Post-clear delay: 2 000 000 cycles = 20 ms.
//
// Init sequence (HD44780, 4-bit):
//   0x33 → 0x32 → 0x28 → 0x0C → 0x06 → 0x01 → display loop
// ============================================================
module lcd_parallel(
    input            clk,
    input            rst,
    input  [2:0]     sys_state,
    input  [15:0]    password,      // kept for potential future use
    input  [1:0]     digit_count,   // 0–3: digits entered so far (resets after entry_done)
    input            entry_done,    // 1-cycle pulse when 4th digit entered
    output reg       lcd_rs,
    output reg       lcd_en,
    output reg [3:0] lcd_d
);

// ── Power-on delay: 80 ms ─────────────────────────────────────
reg [23:0] delay_cnt;
reg        init_done;
always @(posedge clk or posedge rst) begin
    if (rst) begin delay_cnt <= 0; init_done <= 0; end
    else if (!init_done) begin
        if (delay_cnt == 24'd8_000_000) init_done <= 1;
        else delay_cnt <= delay_cnt + 1;
    end
end

// ── Track whether all 4 digits have been entered ─────────────
// digit_count resets to 0 AFTER entry_done (same cycle).
// We latch a flag so msg[8..11] can show "****" correctly.
reg all_four;
always @(posedge clk or posedge rst) begin
    if (rst) all_four <= 0;
    else if (entry_done) all_four <= 1;
    else if (sys_state != 3'd1) all_four <= 0;  // clear when leaving ENTER
end

// ── Registered message array ──────────────────────────────────
// Single always block — no combinational fan-out.
reg [7:0] msg [0:15];

always @(posedge clk or posedge rst) begin
    if (rst) begin
        msg[0]<=8'h20; msg[1]<=8'h20; msg[2]<=8'h20; msg[3]<=8'h20;
        msg[4]<=8'h20; msg[5]<=8'h20; msg[6]<=8'h20; msg[7]<=8'h20;
        msg[8]<=8'h20; msg[9]<=8'h20; msg[10]<=8'h20;msg[11]<=8'h20;
        msg[12]<=8'h20;msg[13]<=8'h20;msg[14]<=8'h20;msg[15]<=8'h20;
    end else begin
        case (sys_state)

        3'd0: begin  // READY
            msg[0]<="S"; msg[1]<="Y"; msg[2]<="S"; msg[3]<="T";
            msg[4]<="E"; msg[5]<="M"; msg[6]<=" "; msg[7]<="R";
            msg[8]<="E"; msg[9]<="A"; msg[10]<="D"; msg[11]<="Y";
            msg[12]<=" "; msg[13]<=" "; msg[14]<=" "; msg[15]<=" ";
        end

        3'd1: begin  // ENTER — accurate *-masking from digit_count
            msg[0]<="E"; msg[1]<="N"; msg[2]<="T"; msg[3]<="E";
            msg[4]<="R"; msg[5]<=" "; msg[6]<="P"; msg[7]<="W";
            // slot 1: * if at least 1 digit entered
            msg[8]  <= (all_four || digit_count >= 2'd1) ? 8'h2A : 8'h2D;
            // slot 2: * if at least 2 digits entered
            msg[9]  <= (all_four || digit_count >= 2'd2) ? 8'h2A : 8'h2D;
            // slot 3: * if at least 3 digits entered
            msg[10] <= (all_four || digit_count >= 2'd3) ? 8'h2A : 8'h2D;
            // slot 4: * only after all 4 entered (entry_done latch)
            msg[11] <= all_four ? 8'h2A : 8'h2D;
            msg[12]<=" "; msg[13]<=" "; msg[14]<=" "; msg[15]<=" ";
        end

        3'd2: begin  // SAVED
            msg[0]<="P"; msg[1]<="A"; msg[2]<="S"; msg[3]<="S";
            msg[4]<="W"; msg[5]<="D"; msg[6]<=" "; msg[7]<=" ";
            msg[8]<="S"; msg[9]<="A"; msg[10]<="V"; msg[11]<="E";
            msg[12]<="D"; msg[13]<="!"; msg[14]<=" "; msg[15]<=" ";
        end

        3'd3: begin  // UNLOCKED
            msg[0]<="A"; msg[1]<="C"; msg[2]<="C"; msg[3]<="E";
            msg[4]<="S"; msg[5]<="S"; msg[6]<=" "; msg[7]<=" ";
            msg[8]<="G"; msg[9]<="R"; msg[10]<="A"; msg[11]<="N";
            msg[12]<="T"; msg[13]<="E"; msg[14]<="D"; msg[15]<="!";
        end

        3'd4: begin  // WRONG
            msg[0]<="A"; msg[1]<="C"; msg[2]<="C"; msg[3]<="E";
            msg[4]<="S"; msg[5]<="S"; msg[6]<=" "; msg[7]<=" ";
            msg[8]<="D"; msg[9]<="E"; msg[10]<="N"; msg[11]<="I";
            msg[12]<="E"; msg[13]<="D"; msg[14]<="!"; msg[15]<=" ";
        end

        3'd5: begin  // LOCKED
            msg[0]<="S"; msg[1]<="Y"; msg[2]<="S"; msg[3]<="T";
            msg[4]<="E"; msg[5]<="M"; msg[6]<=" "; msg[7]<=" ";
            msg[8]<="L"; msg[9]<="O"; msg[10]<="C"; msg[11]<="K";
            msg[12]<="E"; msg[13]<="D"; msg[14]<="!"; msg[15]<=" ";
        end

        default: begin
            msg[0]<=" "; msg[1]<=" "; msg[2]<=" "; msg[3]<=" ";
            msg[4]<=" "; msg[5]<=" "; msg[6]<=" "; msg[7]<=" ";
            msg[8]<=" "; msg[9]<=" "; msg[10]<=" ";msg[11]<=" ";
            msg[12]<=" ";msg[13]<=" ";msg[14]<=" ";msg[15]<=" ";
        end

        endcase
    end
end

// ── LCD 4-bit FSM — SINGLE always block (single driver for clearing)
// state_fsm: 0-5=init, 6=set addr line1, 7=line1 chars,
//            8=set addr line2, 9=line2 chars, loops 6→9→6
// sub: 0=load  1=hi_nibble  2=EN_hi  3=EN_lo
//      4=lo_nibble  5=EN_hi  6=EN_lo+advance
reg [4:0]  state_fsm;
reg [3:0]  idx;
reg [7:0]  data_buf;
reg [2:0]  sub;
reg [5:0]  en_cnt;
reg [21:0] clear_cnt;   // post-clear 20 ms wait counter
reg        clearing;    // SINGLE DRIVER: only driven from FSM block below

always @(posedge clk or posedge rst) begin
    if (rst) begin
        state_fsm <= 0; idx <= 0; lcd_en <= 0; lcd_rs <= 0;
        lcd_d <= 0; sub <= 0; data_buf <= 0; en_cnt <= 0;
        clear_cnt <= 0; clearing <= 0;
    end
    else if (init_done) begin

        // ── Post-clear 20 ms wait ─────────────────────────────
        if (clearing) begin
            if (clear_cnt == 22'd2_000_000)
                clearing <= 0;
            else
                clear_cnt <= clear_cnt + 1;
        end
        else begin
        // ── Main FSM ──────────────────────────────────────────
        lcd_en <= 0;

        case (sub)

        3'd0: begin  // Load byte for current state
            case (state_fsm)
                5'd0: begin data_buf <= 8'h33; lcd_rs <= 0; end
                5'd1: begin data_buf <= 8'h32; lcd_rs <= 0; end
                5'd2: begin data_buf <= 8'h28; lcd_rs <= 0; end  // 4-bit, 2-line, 5×8
                5'd3: begin data_buf <= 8'h0C; lcd_rs <= 0; end  // display ON, cursor OFF
                5'd4: begin data_buf <= 8'h06; lcd_rs <= 0; end  // entry mode: increment
                5'd5: begin data_buf <= 8'h01; lcd_rs <= 0; end  // clear display
                5'd6: begin data_buf <= 8'h80; lcd_rs <= 0; idx <= 0; end  // DDRAM addr line1
                5'd7: begin data_buf <= msg[idx]; lcd_rs <= 1; end
                5'd8: begin data_buf <= 8'hC0; lcd_rs <= 0; idx <= 8; end  // DDRAM addr line2
                5'd9: begin data_buf <= msg[idx]; lcd_rs <= 1; end
                default: begin data_buf <= 8'h20; lcd_rs <= 1; end
            endcase
            en_cnt <= 0; sub <= 3'd1;
        end

        3'd1: begin  // Drive high nibble onto lcd_d
            lcd_d <= data_buf[7:4]; en_cnt <= 0; sub <= 3'd2;
        end

        3'd2: begin  // EN HIGH — 500 ns (50 cycles at 100 MHz)
            lcd_en <= 1;
            if (en_cnt == 6'd49) begin en_cnt <= 0; sub <= 3'd3; end
            else en_cnt <= en_cnt + 1;
        end

        3'd3: begin  // EN LOW hold — 500 ns
            lcd_en <= 0;
            if (en_cnt == 6'd49) begin en_cnt <= 0; sub <= 3'd4; end
            else en_cnt <= en_cnt + 1;
        end

        3'd4: begin  // Drive low nibble
            lcd_d <= data_buf[3:0]; en_cnt <= 0; sub <= 3'd5;
        end

        3'd5: begin  // EN HIGH — 500 ns
            lcd_en <= 1;
            if (en_cnt == 6'd49) begin en_cnt <= 0; sub <= 3'd6; end
            else en_cnt <= en_cnt + 1;
        end

        3'd6: begin  // EN LOW + advance state_fsm
            lcd_en <= 0;
            if (en_cnt == 6'd49) begin
                en_cnt <= 0; sub <= 3'd0;

                // After clear command: start 20 ms wait (single driver)
                if (state_fsm == 5'd5) begin
                    clearing  <= 1;
                    clear_cnt <= 0;
                end

                case (state_fsm)
                    5'd0: state_fsm <= 5'd1;
                    5'd1: state_fsm <= 5'd2;
                    5'd2: state_fsm <= 5'd3;
                    5'd3: state_fsm <= 5'd4;
                    5'd4: state_fsm <= 5'd5;
                    5'd5: state_fsm <= 5'd6;
                    5'd6: state_fsm <= 5'd7;
                    5'd7: begin
                        if (idx == 4'd7) state_fsm <= 5'd8;
                        else             idx <= idx + 1;
                    end
                    5'd8: state_fsm <= 5'd9;
                    5'd9: begin
                        if (idx == 4'd15) state_fsm <= 5'd6;  // loop back to line1 addr
                        else              idx <= idx + 1;
                    end
                    default: state_fsm <= 5'd6;
                endcase
            end else en_cnt <= en_cnt + 1;
        end

        default: sub <= 3'd0;
        endcase

        end  // end else !clearing
    end
end

endmodule
