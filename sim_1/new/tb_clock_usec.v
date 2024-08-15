`timescale 1ns / 1ps

module tb_clock_usec();
    // input
    reg clk;
    reg reset;
    //outputs
    wire clk_usec;

    // Instantiate the DUT
    clock_usec dut_clk_usec(
    .clk(clk),
    .reset(reset),
    .clk_usec(clk_usec)
    );

    // Clock generation : 100MHz
     always #5 clk = ~clk;

    initial begin
        // Initialize Inputs
        #00 clk = 0; reset = 1;  // Apply reset
         #10; reset = 0;  // Release reset
        #100000;      // Run simulation for 100μs (should be long enough to observe multiple clk_usec pulses)
        // End simulation
        $finish;
    end

endmodule
