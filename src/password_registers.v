`timescale 1ns / 1ps
module password_register(
    input        clk,
    input        rst,
    input        valid,      
    input  [3:0] key,
    output reg [15:0] password
);
always @(posedge clk or posedge rst) begin
    if(rst)        password <= 16'b0;
    else if(valid) password <= {password[11:0], key};
end
endmodule
