`timescale 1ns / 1ps

module tb_ultra();
    reg clk;
    reg reset;
    reg echo;
    //
    wire trigger;
    wire [13:0] distance;


ultrasonic dut(
    .clk(clk),
    .reset(reset),
    .echo(echo),
    //
    .trigger(trigger),
    .distance(distance)
);

always #5 clk = ~clk;
initial begin
    #00 clk = 0; reset = 1'b1; echo = 1'b0;
    #10 reset = 1'b0;
    #400 echo = 1'b1;
    #800 echo = 1'b0;
    #100 $finish;
end
endmodule
