`timescale 1ns / 1ps
// system_state.v — 6-state priority FSM for LCD
// Priority: LOCKED > OK > FAIL > SAVED > ENTER > READY
// user_started prevents ENTER showing before first keypress.
module system_state(
    input        clk, rst,
    input        valid_pulse,
    input        save_en, unlock, error, locked,
    output reg [2:0] state
);
localparam READY=3'd0,ENTER=3'd1,SAVED=3'd2,OK=3'd3,FAIL=3'd4,LOCKED=3'd5;
reg user_started;
always @(posedge clk or posedge rst) begin
    if(rst) begin state<=READY; user_started<=0; end
    else begin
        if(valid_pulse||save_en||unlock||error) user_started<=1;
        if(locked)            state<=LOCKED;
        else if(unlock)       state<=OK;
        else if(error)        state<=FAIL;
        else if(save_en)      state<=SAVED;
        else if(user_started) state<=ENTER;
        else                  state<=READY;
    end
end
endmodule
