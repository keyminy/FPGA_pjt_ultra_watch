`timescale 1ns / 1ps

module top (
    input clk,
    input rst,
    input a,
    input b
);

clk_div #(.HZ(1)) U_CLK_DIV_1
(
    .clk(clk),
    .rst(rst),
    .o_clk(w_clk_1)
);

clk_div #(.HZ(100)) U_CLK_DIV_100
(
    .clk(clk),
    .rst(rst),
    .o_clk(w_clk_100)
);

clk_div #(.HZ(1000)) U_CLK_DIV_1000
(
    .clk(clk),
    .rst(rst),
    .o_clk(w_clk_1000)
);
    
clk_counter #(CNT(100)) U_CNT_1
(
    .clk(w_clk_1),
    .rst(rst),
    //
    .count(w_cnt_100)
);

clk_counter #(CNT(1000)) U_CNT_2
(
    .clk(w_clk_100),
    .rst(rst),
    //
    .count(w_cnt_100)
);



endmodule

module clk_div #(parameter HZ = 1000)
(
    input clk,
    input rst,
    output o_clk
);

    reg[$clog2(100_000_000/HZ)-1:0] r_cnt;
    reg r_clk;
    assign o_clk = r_clk;

    always @(posedge clk, posedge rst) begin
        if(rst) begin
            r_cnt <= 0;
            r_clk <= 1'b0;
        end
        else begin
            if(r_cnt == 100_000_000/HZ - 1) begin
                r_cnt <= 0;
                r_clk <= 1'b1;
            end
            else begin
                r_cnt <= r_cnt + 1;
                r_clk <= 1'b0;
            end
        end
    end
endmodule


module clk_counter #(
    parameter CNT = 16
) (
    input clk,
    input rst,
    //
    output [$clog2(CNT)-1:0] count
);
    reg [$clog2(CNT)-1:0] r_cnt;

    assign count = r_cnt;

    always @(posedge clk, posedge rst) begin
        if(rst) begin
            r_cnt <= 0;
        end
        else begin
            if(r_cnt == CNT - 1) begin
                r_cnt <= 0;
            end
            else begin
                r_cnt <= r_cnt + 1;
            end
        end
    end
endmodule


