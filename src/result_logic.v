`timescale 1ns / 1ps
module result_logic(
    input      clk,
    input      rst,
    input      check_en,  
    input      match,

    output reg unlock,
    output reg error
);

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
