`timescale 1ns / 1ps
// 100 MHz clock.  Scan period per row: 2^17 cycles (~1.31 ms)
module keypad_controller(
    input            clk,
    input            rst,
    input  [3:0]     col,      
    output reg [3:0] key,
    output reg       valid,      
    output reg [3:0] row
);

reg [16:0] div;
always @(posedge clk or posedge rst) begin
    if (rst) div <= 0;
    else     div <= div + 1;
end
wire scan_tick = (div == 17'd0);

reg [3:0] col1, col2;
always @(posedge clk or posedge rst) begin
    if (rst) begin col1 <= 4'hF; col2 <= 4'hF; end
    else     begin col1 <= col;  col2 <= col1;  end
end
wire [3:0] col_active = ~col2;

reg [1:0] row_drive;    
reg [1:0] row_sampled;  

always @(posedge clk or posedge rst) begin
    if (rst) begin
        row_drive   <= 2'd0;
        row_sampled <= 2'd0;
        row         <= 4'b1110;   
    end else if (scan_tick) begin
        row_sampled <= row_drive;
        row_drive   <= row_drive + 1;
        case (row_drive + 1)
            2'd0: row <= 4'b1110;
            2'd1: row <= 4'b1101;
            2'd2: row <= 4'b1011;
            2'd3: row <= 4'b0111;
        endcase
    end
end
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
