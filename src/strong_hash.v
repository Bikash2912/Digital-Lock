`timescale 1ns / 1ps
// ============================================================
// strong_hash.v
// Combinational 16-bit hash (two-round rotate-XOR-add).
// Purely combinational — no clock needed.
// Prevents plain-text password comparison.
// ============================================================
module strong_hash(
    input  [15:0] data,
    output [15:0] hash
);

// Round 1: XOR with left-rotate-3, then add constant
wire [15:0] rot3 = {data[12:0], data[15:13]};    // left rotate by 3
wire [15:0] r1   = (data ^ rot3) + 16'h9E37;

// Round 2: XOR with left-rotate-5, then add constant
wire [15:0] rot5 = {r1[10:0], r1[15:11]};         // left rotate by 5
wire [15:0] r2   = (r1 ^ rot5) + 16'h7F4A;

assign hash = r2;

endmodule
