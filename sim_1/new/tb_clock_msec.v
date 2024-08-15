`timescale 1ns / 1ps

module tb_clock_msec();
    reg clk;
    reg clk_usec;
    reg reset;
    wire clk_msec;

    clock_msec dut_clk_msec(
    .clk(clk),
    .reset(reset),
    .clk_usec(clk_usec),
    .clk_msec(clk_msec)
    );

 // Clock generation : 100MHz
     always #5 clk = ~clk;

    initial  begin
        clk_usec = 0;
        forever begin
            #990; // wait for nearly 1usec
            clk_usec = 1; 
            #10;
            clk_usec = 0;
        end
    end

    initial begin
         #00 clk = 0; reset = 1;  // Apply reset
         #10; reset =0;         // Wait for 20ns (2 clock cycles)
         #2000000;     // Run simulation for 2ms (should be long enough to observe multiple clk_msec pulses)
        // End simulation
        $finish;
    end

endmodule
