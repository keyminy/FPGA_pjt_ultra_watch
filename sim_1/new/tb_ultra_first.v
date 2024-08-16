`timescale 1ns / 1ps

module tb_ultra_first();
    reg clk;
    reg reset;
    reg echo;
    wire trigger;
    wire [8:0] distance;

    ultra_first U_S_test(
        .clk(clk),
        .reset(reset),
        .echo(echo),
        .trigger(trigger),
        .distance(distance)
    );
	
    initial begin
        clk = 0;
        reset = 1;
        echo = 0;
    end

    always #5 clk = ~clk;

    initial begin
        #10 reset = 0;
        #10 wait(trigger); // wait 1
            wait(!trigger); // wiat 0
        #20000; // wait 20us
        echo = 1; #800000; // wait 800us
        echo = 0;
        #10000; $stop;
    end

endmodule
