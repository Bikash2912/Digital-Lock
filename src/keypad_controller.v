`timescale 1ns / 1ps
// ============================================================
// keypad_controller.v  –  Basys3 4×4 matrix keypad
// 100 MHz clock.  Scan period per row: 2^17 cycles (~1.31 ms)
//
// BUG FIX (row-0 silence — keys 1,2,3,A not registering):
// ─────────────────────────────────────────────────────────────
// Root cause: on scan_tick, the previous design latched
// row_stable = row_idx (the row just STARTING to drive),
// then advanced row_idx. This meant cols were sampled one
// period early — the col reading belonged to row N but
// row_stable reported row N+1.
//
// Fix: introduce row_drive (currently driving) and
// row_sampled (row that was stable during the period
// whose col result we are reading right now).
// On scan_tick:
//   1. row_sampled <= row_drive   (save settled row)
//   2. row_drive   <= row_drive+1 (advance)
//   3. row output  <= new pattern
// Key decode uses row_sampled — always correct.
// ============================================================
module keypad_controller(
    input            clk,
    input            rst,
    input  [3:0]     col,        // active-LOW, XDC PULLUP
    output reg [3:0] key,
    output reg       valid,      // 1-cycle pulse per new keypress
    output reg [3:0] row         // active-LOW row drive
);

// ── 17-bit clock divider → scan_tick every 131072 cycles ─────
reg [16:0] div;
always @(posedge clk or posedge rst) begin
    if (rst) div <= 0;
    else     div <= div + 1;
end
wire scan_tick = (div == 17'd0);

// ── 2-FF synchroniser on col inputs ──────────────────────────
reg [3:0] col1, col2;
always @(posedge clk or posedge rst) begin
    if (rst) begin col1 <= 4'hF; col2 <= 4'hF; end
    else     begin col1 <= col;  col2 <= col1;  end
end
wire [3:0] col_active = ~col2;   // 1 = column pressed

// ── Row drive and row-sampled tracking ───────────────────────
reg [1:0] row_drive;    // row currently being driven LOW
reg [1:0] row_sampled;  // row that was stable just before this tick

always @(posedge clk or posedge rst) begin
    if (rst) begin
        row_drive   <= 2'd0;
        row_sampled <= 2'd0;
        row         <= 4'b1110;   // drive row 0 LOW on startup
    end else if (scan_tick) begin
        // 1. capture which row was stable (col reading belongs to this row)
        row_sampled <= row_drive;
        // 2. advance drive counter
        row_drive   <= row_drive + 1;
        // 3. assert new row LOW
        case (row_drive + 1)
            2'd0: row <= 4'b1110;
            2'd1: row <= 4'b1101;
            2'd2: row <= 4'b1011;
            2'd3: row <= 4'b0111;
        endcase
    end
end

// ── Key detection ─────────────────────────────────────────────
// Fire on scan_tick when a column is pressed and no key is held.
// row_sampled holds the correct settled row for the col reading.
reg key_held;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        valid    <= 0;
        key      <= 0;
        key_held <= 0;
    end else begin
        valid <= 0;

        if (col_active != 4'b0000) begin
            if (!key_held && scan_tick) begin
                key_held <= 1;
                valid    <= 1;
                // Decode {row_sampled[1:0], col_active[3:0]}
                // row_sampled: 0=row0(1,2,3,A)  1=row1(4,5,6,B)
                //              2=row2(7,8,9,C)   3=row3(*,0,#,D)
                // col_active : bit0=col0  bit1=col1  bit2=col2  bit3=col3
                case ({row_sampled, col_active})
                    6'b00_0001: key <= 4'd1;
                    6'b00_0010: key <= 4'd2;
                    6'b00_0100: key <= 4'd3;
                    6'b00_1000: key <= 4'd10;  // A
                    6'b01_0001: key <= 4'd4;
                    6'b01_0010: key <= 4'd5;
                    6'b01_0100: key <= 4'd6;
                    6'b01_1000: key <= 4'd11;  // B
                    6'b10_0001: key <= 4'd7;
                    6'b10_0010: key <= 4'd8;
                    6'b10_0100: key <= 4'd9;
                    6'b10_1000: key <= 4'd12;  // C
                    6'b11_0001: key <= 4'd14;  // *
                    6'b11_0010: key <= 4'd0;
                    6'b11_0100: key <= 4'd15;  // #
                    6'b11_1000: key <= 4'd13;  // D
                    default:    key <= 4'd0;
                endcase
            end
        end else begin
            key_held <= 0;   
        end
    end
end

endmodule
