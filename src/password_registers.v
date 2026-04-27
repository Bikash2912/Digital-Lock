`timescale 1ns / 1ps
// ============================================================
// password_register.v
// 4-nibble shift register. valid = 1-cycle pulse from keypad.
// Keys 1,2,3,4 pressed in order → password = 16'h1234
// ============================================================
module password_register(
    input        clk,
    input        rst,
    input        valid,        // 1-cycle pulse directly from keypad_controller
    input  [3:0] key,
    output reg [15:0] password
);
always @(posedge clk or posedge rst) begin
    if(rst)        password <= 16'b0;
    else if(valid) password <= {password[11:0], key};
end
endmodule
