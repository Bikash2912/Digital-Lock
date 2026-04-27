`timescale 1ns / 1ps
// ============================================================
// password_storage.v
// Stores the hashed password.  Only updates on save_en pulse.
// Default stored value = 0 (no password set after reset).
// ============================================================
module password_storage(
    input             clk,
    input             rst,
    input             save_en,
    input      [15:0] hash_in,
    output reg [15:0] stored_hash
);

always @(posedge clk or posedge rst) begin
    if(rst)
        stored_hash <= 16'd0;
    else if(save_en)
        stored_hash <= hash_in;
end

endmodule
