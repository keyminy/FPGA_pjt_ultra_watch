`timescale 1ns / 1ps

module tb_top_fsm();
    reg clk;
    reg reset;
    reg sw;
    reg echo;
    //
    wire [3:0] fndCom;
    wire [7:0] fndFont;
    wire trigger;

Top_fsm dut(
    .clk(clk),
    .reset(reset),
    .sw(sw),
    .echo(echo),
    .btn_run_stop(),
    .btn_clear(),
    .btn_change(),
    .rx(),
    //
    .fndCom(fndCom),
    .fndFont(fndFont),
    .tx(),
    .trigger(trigger)
    );

always #3 clk = ~clk;

initial begin
    #00 clk = 0; reset = 1'b1; echo = 1'b0; sw = 1'b1;
    #10 reset = 1'b0;
    #400 echo = 1'b1;
    #300 echo = 1'b0;
    #300 echo = 1'b1;
    #300 echo = 1'b0;
    #300 echo = 1'b1;
    #300 echo = 1'b0;
    #100 $finish;
end
endmodule
