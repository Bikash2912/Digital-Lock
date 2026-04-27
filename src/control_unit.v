`timescale 1ns / 1ps
module control_unit(
    input      clk, rst,
    input      valid_pulse,
    input      mode_sw, save_btn, check_btn,
    output reg entry_done, save_en, check_en
);
reg md1,md2;
always @(posedge clk or posedge rst) begin
    if(rst) begin md1<=0;md2<=0; end
    else    begin md1<=mode_sw;md2<=md1; end
end
wire mode_sync=md2;
reg sb1,sb2,sb3,cb1,cb2,cb3;
always @(posedge clk or posedge rst) begin
    if(rst) begin sb1<=0;sb2<=0;sb3<=0;cb1<=0;cb2<=0;cb3<=0; end
    else    begin sb1<=save_btn;sb2<=sb1;sb3<=sb2;
                  cb1<=check_btn;cb2<=cb1;cb3<=cb2; end
end
wire save_pulse=sb2&~sb3;
wire check_pulse=cb2&~cb3;
reg [1:0] count;
reg ready_to_save,ready_to_check,mode_prev;
always @(posedge clk or posedge rst) begin
    if(rst) begin
        count<=0;entry_done<=0;save_en<=0;check_en<=0;
        ready_to_save<=0;ready_to_check<=0;mode_prev<=0;
    end else begin
        entry_done<=0;save_en<=0;check_en<=0;
        mode_prev<=mode_sync;
        if(mode_sync!=mode_prev)
            begin count<=0;ready_to_save<=0;ready_to_check<=0; end
        if(valid_pulse) begin
            if(count==2'd3) begin
                count<=0;entry_done<=1;
                if(mode_sync) begin ready_to_save<=1;ready_to_check<=0; end
                else          begin ready_to_check<=1;ready_to_save<=0; end
            end else count<=count+1;
        end
        if(mode_sync&&save_pulse&&ready_to_save)
            begin save_en<=1;ready_to_save<=0; end
        if(!mode_sync&&check_pulse&&ready_to_check)
            begin check_en<=1;ready_to_check<=0; end
    end
end
endmodule
