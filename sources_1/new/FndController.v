`timescale 1ns / 1ps

module FndController(
    input clk,
    input reset,
    input [6:0] digit_h,
    input [6:0] digit_l,
    input dot,
    output [3:0] fndCom,
    output [7:0] fndFont
    );

    wire w_clk_1khz;
    wire [1:0] w_select;
    wire [3:0] w_digit;
    wire [3:0] w_dig_l_1,w_dig_l_10;
    wire [3:0] w_dig_h_1,w_dig_h_10;

    wire [6:0] w_fndFont;
    
    assign fndFont = (fndCom == 4'b1011)? {dot,w_fndFont}:{1'b1,w_fndFont};


    BCD2SEG U_Bcd2Seg(
        .bcd(w_digit),
        .seg(w_fndFont)
    );

    clkDiv_1kHz u_clkDiv_1kHz(
        .clk(clk),
        .reset(reset),
        .o_clk(w_clk_1khz)
    );

    decoder_2x4 U_Decoder_2x4(
        .x(w_select),
        .y(fndCom)
    );
    sel_counter u_sel_counter(
        .clk(w_clk_1khz),
        .reset(reset),
        .count(w_select)
    );
    digitSplitter u_digit_L(
    .i_digit     (digit_l),
    .o_digit_1   (w_dig_l_1),
    .o_digit_10  (w_dig_l_10)
    );
    digitSplitter u_digit_H(
    .i_digit     (digit_h),
    .o_digit_1   (w_dig_h_1),
    .o_digit_10  (w_dig_h_10)
    );
    mux_4x1 U_Mux_4x1(
        .sel(w_select),
        .x0(w_dig_l_1),
        .x1(w_dig_l_10),
        .x2(w_dig_h_1),
        .x3(w_dig_h_10),
        .y(w_digit)
    );

endmodule


module sel_counter(
    input           clk,
    input           reset,
    output [1:0]    count
);
    reg [1:0] r_counter;
    assign count = r_counter;

    always @(posedge clk or posedge reset) begin
        if(reset) begin
            r_counter <= 0;
        end else begin
            if(r_counter == 3) begin
                r_counter <= 0;
            end else begin
                r_counter <= r_counter + 1;
            end
        end
    end

endmodule

module BCD2SEG(
    input [3:0] bcd,
    output reg [7:0] seg
);

always @(bcd) begin
//When typing within an always statement, you must use the reg data type.
// you should use reg type when type in always
    case (bcd)
    4'h0: seg = 8'hc0;
    4'h1: seg = 8'hf9;
    4'h2: seg = 8'ha4;
    4'h3: seg = 8'hb0;
    4'h4: seg = 8'h99;
    4'h5: seg = 8'h92;
    4'h6: seg = 8'h82;
    4'h7: seg = 8'hf8;
    4'h8: seg = 8'h80;
    4'h9: seg = 8'h90;
    4'ha: seg = 8'h88;
    4'hb: seg = 8'h83;
    4'hc: seg = 8'hc6;
    4'hd: seg = 8'ha1;
    4'he: seg = 8'h86;
    4'hf: seg = 8'h8e;
    endcase
end
 
endmodule

module decoder_2x4(
    input [1:0] x,
    output reg [3:0] y
);
    always @(x) begin
        // watch x
        case(x)
            2'b00: y = 4'b1110;
            2'b01: y = 4'b1101;
            2'b10: y = 4'b1011;
            2'b11: y = 4'b0111;
        endcase
    end
endmodule

module digitSplitter(
    input [6:0] i_digit,
    output [3:0] o_digit_1,
    output [3:0] o_digit_10,
    output [3:0] o_digit_100,
    output [3:0] o_digit_1000
    );
    assign o_digit_1 = i_digit % 10; // 1의 자리 추출
    assign o_digit_10 = i_digit /10 % 10; // 10의 자리 추출
    assign o_digit_100 = i_digit / 100 % 10; // 100의 자리 추출
    assign o_digit_1000 = i_digit / 1000 % 10; // 1000의 자리 추출
endmodule

module mux_4x1(
    input [1:0] sel,
    input [3:0] x0,
    input [3:0] x1,
    input [3:0] x2,
    input [3:0] x3,
    output reg [3:0] y
);
    // always @(sel,x0,x1,x2,x3) begin
    always @(*) begin
        case(sel)
            2'b00: y=x0;
            2'b01: y=x1;
            2'b10: y=x2;
            2'b11: y=x3;
        endcase
    end
endmodule



module clkDiv_1kHz(
    input clk,
    input reset,
    output o_clk
);
reg [16:0] r_counter;
reg r_clk;
assign o_clk = r_clk;

// 100MHz to 1KHz
always @(posedge clk,posedge reset) begin
    if(reset) begin
        r_counter <= 0;
        r_clk <= 1'b0;
    end else begin
        if(r_counter == 100_000 -1) begin
            r_counter <= 0;
            r_clk <= 1'b1;
        end else begin
            r_counter <= r_counter + 1;
            r_clk <= 1'b0;
        end
    end
end

endmodule