`timescale 1ns / 1ps
// ============================================================
// result_logic.v
//
// FIX: match_reg in top.v is registered in the SAME cycle as
// check_en. So when result_logic sees check_en=1, match_reg
// still has the OLD value (from the previous check).
//
// Solution: delay check_en by 1 clock internally so that by
// the time we sample match, it has already been updated.
// This gives clean 1-cycle unlock/error pulses with correct data.
// ============================================================
module result_logic(
    input      clk,
    input      rst,
    input      check_en,   // 1-cycle pulse from top (already locked-masked)
    input      match,      // registered: valid 1 cycle AFTER check_en

    output reg unlock,
    output reg error
);

// Delay check_en by 1 cycle
reg check_en_d;
always @(posedge clk or posedge rst) begin
    if(rst) check_en_d <= 0;
    else    check_en_d <= check_en;
end

always @(posedge clk or posedge rst) begin
    if(rst) begin
        unlock <= 0;
        error  <= 0;
    end else begin
        unlock <= 0;
        error  <= 0;
        if(check_en_d) begin        // now match is valid
            if(match) unlock <= 1;
            else      error  <= 1;
        end
    end
end

endmodule
