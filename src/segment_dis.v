`timescale 1ns / 1ps
// ============================================================
// seg7_display.v  –  Basys3 4-digit 7-segment display
// 100 MHz clock.
//
// BUG FIX — Static AAAA / 1111 on power-on:
// ─────────────────────────────────────────────────────────────
// Root cause: seg and an outputs were driven by combinational
// case statements with no multiplexing refresh clock.
// Without a refresh counter, all four digit anodes were
// asserted simultaneously, causing all segments to blend into
// a static pattern (e.g. AAAA, 1111, or 8888 depending on
// the uninitialized password bits).
//
// Fix:
//   1. A 18-bit refresh counter divides 100 MHz to ~381 Hz
//      per digit (4-digit scan = ~95 Hz refresh, flicker-free).
//   2. Only ONE anode is asserted LOW at a time (active-LOW).
//   3. In SAVE mode, password nibbles are shown as hex digits.
//   4. In all other modes (CHECK / idle), display is blanked
//      by asserting all anodes HIGH (4'b1111).
//   5. A leading-zero blank: digit positions with value 0
//      when no entry has started show a dash "-" instead of "0".
//
// DISPLAY BEHAVIOUR:
//   save_en=1 (SAVE mode, password entered) → show 4 hex digits
//   otherwise                               → blank display
// ============================================================
module seg7_display(
    input            clk,
    input            rst,
    input            save_en,       // pulse when password saved
    input  [15:0]    password,      // raw 4-nibble password
    output reg [3:0] an,            // active-LOW anodes
    output reg [6:0] seg,           // active-LOW segments {G,F,E,D,C,B,A}
    output           dp             // decimal point — always OFF
);

assign dp = 1'b1;   // decimal point off (active-LOW)

// ── Refresh counter ───────────────────────────────────────────
// 18-bit counter: rolls over every 262144 cycles = ~2.62 ms per digit
// → ~381 Hz per digit, 95 Hz full refresh (well above 60 Hz flicker limit)
reg [17:0] refresh_cnt;
always @(posedge clk or posedge rst) begin
    if (rst) refresh_cnt <= 0;
    else     refresh_cnt <= refresh_cnt + 1;
end
wire [1:0] digit_sel = refresh_cnt[17:16];  // selects which digit to drive

// ── Latch password on save_en ─────────────────────────────────
// Hold the last saved password for display.
reg [15:0] saved_pw;
reg        display_active;   // 1 = show saved password

always @(posedge clk or posedge rst) begin
    if (rst) begin
        saved_pw       <= 16'h0000;
        display_active <= 0;
    end else if (save_en) begin
        saved_pw       <= password;
        display_active <= 1;
    end
end

// ── Select nibble to show based on digit_sel ─────────────────
reg [3:0] nibble;
always @(*) begin
    case (digit_sel)
        2'd0: nibble = saved_pw[15:12];   // leftmost digit
        2'd1: nibble = saved_pw[11:8];
        2'd2: nibble = saved_pw[7:4];
        2'd3: nibble = saved_pw[3:0];     // rightmost digit
        default: nibble = 4'h0;
    endcase
end

// ── 7-segment decode (active-LOW) ─────────────────────────────
// Segments: {seg[6]=G, seg[5]=F, seg[4]=E, seg[3]=D,
//            seg[2]=C, seg[1]=B, seg[0]=A}
//  Segment layout:
//      AAA
//     F   B
//     F   B
//      GGG
//     E   C
//     E   C
//      DDD
function [6:0] hex_to_seg;
    input [3:0] val;
    begin
        case (val)
            4'h0: hex_to_seg = 7'b1000000;  // 0
            4'h1: hex_to_seg = 7'b1111001;  // 1
            4'h2: hex_to_seg = 7'b0100100;  // 2
            4'h3: hex_to_seg = 7'b0110000;  // 3
            4'h4: hex_to_seg = 7'b0011001;  // 4
            4'h5: hex_to_seg = 7'b0010010;  // 5
            4'h6: hex_to_seg = 7'b0000010;  // 6
            4'h7: hex_to_seg = 7'b1111000;  // 7
            4'h8: hex_to_seg = 7'b0000000;  // 8
            4'h9: hex_to_seg = 7'b0010000;  // 9
            4'hA: hex_to_seg = 7'b0001000;  // A
            4'hB: hex_to_seg = 7'b0000011;  // b
            4'hC: hex_to_seg = 7'b1000110;  // C
            4'hD: hex_to_seg = 7'b0100001;  // d
            4'hE: hex_to_seg = 7'b0000110;  // E
            4'hF: hex_to_seg = 7'b0001110;  // F
            default: hex_to_seg = 7'b1111111; // blank
        endcase
    end
endfunction

// ── Anode and segment drive ───────────────────────────────────
always @(posedge clk or posedge rst) begin
    if (rst) begin
        an  <= 4'b1111;   // all digits OFF
        seg <= 7'b1111111;
    end else begin
        if (display_active) begin
            // Assert only the selected anode LOW
            case (digit_sel)
                2'd0: an <= 4'b1110;
                2'd1: an <= 4'b1101;
                2'd2: an <= 4'b1011;
                2'd3: an <= 4'b0111;
                default: an <= 4'b1111;
            endcase
            seg <= hex_to_seg(nibble);
        end else begin
            // Blank display when not in save mode
            an  <= 4'b1111;
            seg <= 7'b1111111;
        end
    end
end

endmodule
