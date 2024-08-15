module button(
    input clk,
    input reset,
    input i_btn,
    //
    output o_btn
    );

reg [3:0] shiftReg;
reg [1:0] edgeReg;
wire w_shift;
reg [$clog2(100_000)-1:0]r_counter;
reg r_clk_1kHz;

always @(posedge clk, posedge reset) begin
    if(reset)
    begin
        r_counter <= 0;
    end
    else
    begin
        //if(r_counter == 100_000 -1)
        if(r_counter == 2 -1)   // for simul
        begin
            r_counter <= 0;
            r_clk_1kHz <= 1'b1;
        end
        else
        begin
            r_counter <= r_counter +1;
            r_clk_1kHz <= 1'b0;
        end
    end
end

always @(posedge r_clk_1kHz, posedge reset) begin
    if(reset)
    begin
        shiftReg <= 0;
    end
    else
    begin
        shiftReg <= {i_btn, shiftReg[3:1]};
    end
end

assign w_shift = &shiftReg;  // &shiftReg = shiftReg[0] & shiftReg[1] & shiftReg[2] & shiftReg[3]

always @(posedge clk, posedge reset) begin
    if(reset)
    begin
        edgeReg <= 0;
    end
    else
    begin
        edgeReg[0] <= w_shift;
        edgeReg[1] <= edgeReg[0];
    end
end

assign o_btn = edgeReg[0] & ~edgeReg[1];
endmodule