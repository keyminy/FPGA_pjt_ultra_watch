`timescale 1ns / 1ps

module clock_usec(
    input clk,
    input reset,
    output clk_usec
    );
    
    reg [6:0] cnt_10nsec;  // 10ns를 1usec(=1000ns)로 바꾸기 위해 100배이므로 2의7승이 필요함.
    wire cp_usec;
    
    always @(posedge clk or posedge reset) begin
        if(reset) cnt_10nsec <= 0;
        else if(cnt_10nsec >= 100-1) cnt_10nsec <= 0;
        else cnt_10nsec <= cnt_10nsec + 1;
    end
    
    assign cp_usec = cnt_10nsec < 50 ? 0 : 1;  // 100이 한 주기가 되기 위해서 1과 0이 반씩 있어야 되므로

    // ms를 만들기 위해 us의 동기를 맞춰주기 위해
    edge_detector_n ed_usec(
        .clk(clk),
        .cp_in(cp_usec), 
        .reset(reset),
        .n_edge(clk_usec)
    );
endmodule