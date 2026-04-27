`timescale 1ns / 1ps
module seg7_display(
    input            clk,
    input            rst,
    input            save_en,     
    input  [15:0]    password,     
    output reg [3:0] an,            
    output reg [6:0] seg,           
    output           dp            
);

assign dp = 1'b1;   

reg [17:0] refresh_cnt;
always @(posedge clk or posedge rst) begin
    if (rst) refresh_cnt <= 0;
    else     refresh_cnt <= refresh_cnt + 1;
end
wire [1:0] digit_sel = refresh_cnt[17:16];  

reg [15:0] saved_pw;
reg        display_active;  

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

always @(posedge clk or posedge rst) begin
    if (rst) begin
        an  <= 4'b1111;   // all digits OFF
        seg <= 7'b1111111;
    end else begin
        if (display_active) begin
            case (digit_sel)
                2'd0: an <= 4'b1110;
                2'd1: an <= 4'b1101;
                2'd2: an <= 4'b1011;
                2'd3: an <= 4'b0111;
                default: an <= 4'b1111;
            endcase
            seg <= hex_to_seg(nibble);
        end else begin
            an  <= 4'b1111;
            seg <= 7'b1111111;
        end
    end
end
endmodule
