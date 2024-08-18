`timescale 1ns / 1ps

module time_sel(
        input clk,
        input reset,
        input clear,
        input enable,
        input change,
        output [6:0] digit_h,
        output [6:0] digit_l,
        output dot
    );
    wire w_clk_100hz;
    wire [6:0] w_ms10,w_sec,w_min,w_hour;
    wire w_ms10_tick,w_sec_tick,w_min_tick;

    // wire w_dot;
    // wire w_onlyHM_dot;
    
    // assign dot = w_onlyHM_dot;

    // clk_100hz u_clk_100Hz(
    // .clk(clk),
    // .reset(reset),
    // .o_clk(w_clk_100Hz)
    // );

    clk_hz #(
        .HZ(100)
    ) U_clk_100hz (
        .clk  (clk),
        .reset(reset),
        //
        .o_clk(w_clk_100hz)
    );

    t_count #(
    .CNT(100)
    ) U_ms10(
    .clk(clk),
    .reset(reset),
    .in_tick(w_clk_100hz),
    .enable(enable),
    .clear(clear),
    // 
    .count(w_ms10),
    .out_tick(w_ms10_tick)
    // w_ms10_tick : 100Hz신호를 100번 세린 1sec out_tick
    );

    t_count #(
    .CNT(60)
    ) U_sec(
    .clk(clk),
    .reset(reset),
    .in_tick(w_ms10_tick),
    .enable(enable),
    .clear(clear),
    // 
    .count(w_sec),
    .out_tick(w_sec_tick)
    // w_sec_tick : 1초 신호를 60번 세린, 1min out_tick
    );

    t_count #(
    .CNT(60)
    ) U_min(
    .clk(clk),
    .reset(reset),
    .in_tick(w_sec_tick),
    .enable(enable),
    .clear(clear),
    // 
    .count(w_min),
    .out_tick(w_min_tick)
    // w_min_tick : 1분 신호를 60번 세린, 1hour out_tick
    );

    t_count #(
    .CNT(24)
    ) U_hour(
    .clk(clk),
    .reset(reset),
    .in_tick(w_min_tick),
    .enable(enable),
    .clear(clear),
    // 
    .count(w_hour),
    .out_tick()
    );

    dot_prod U_dot(
    .clk(clk),
    .reset(reset),
    .in_tick(w_ms10_tick),
    //
    .dot(dot)
    );

    time_h_l U_time_h_l (
    .clk(clk),
    .reset(reset),
    .change(change),
    .ms10(w_ms10),
    .sec(w_sec),
    .min(w_min),
    .hour(w_hour),
    //
    .digit_h(digit_h),
    .digit_l(digit_l)
    );

//     ms_sec_min_hour u_ms_sec_min_hour(
//     .clk(clk),
//     .reset(reset),
//     .tick_100Hz(w_clk_100Hz),
//     .clear(clear),
//     .enable(enable),
//     // output
//     .ms10(w_ms10),
//     .sec(w_sec),
//     .min(w_min),
//     .hour(w_hour),
//     .dot(w_dot)
//     );

//     time_h_l u_time_h_l (
//     // input
//     .clk(clk),
//     .reset(reset),
//     .change(change),
//     .ms10(w_ms10),
//     .sec(w_sec),
//     .min(w_min),
//     .hour(w_hour),
//     .i_dot(w_dot), // ms_sec_min_hour에서 생성된 dot을 입력으로 받음
//     // output
//     .digit_h(digit_h),
//     .digit_l(digit_l),
//     .o_dot(w_onlyHM_dot)  // time_h_l 모듈에서 수정된 dot을 출력
// );


endmodule

module time_h_l (
    input clk,
    input reset,
    input change,
    input [6:0] ms10,
    input [6:0] sec,
    input [6:0] min,
    input [6:0] hour,
    // input i_dot,  // 입력 dot
    // output
    output reg [6:0] digit_h,
    output reg [6:0] digit_l
    // output reg o_dot  // 출력 dot
);
    reg mode;
    localparam SEC_MSEC = 1'b0;
    localparam HOUR_MIN = 1'b1;

    always @(posedge clk or posedge reset) begin
        if(reset) begin
            mode <= SEC_MSEC;
        end
        else begin
            if(change) mode <= !mode;
            case (mode)
                SEC_MSEC: begin
                    digit_h <= sec;
                    digit_l <= ms10;
                    // o_dot <= 1'b1;
                end
                HOUR_MIN: begin
                    digit_h <= hour;
                    digit_l <= min;
                    // o_dot <= i_dot;
                end
            endcase
        end
    end
endmodule

module clk_hz #(
    parameter HZ = 100
)(
    input clk,
    input reset,
    output o_clk
);
    reg [$clog2(100_000_000/100)-1:0] r_counter;
    reg r_clk;

    assign o_clk = r_clk;

    // 100MHz to 100Hz
    always @(posedge clk or posedge reset) begin
        if(reset) begin
            r_counter <= 0;
            r_clk <= 1'b0;
        end else begin
            if(r_counter == 100_000_000/HZ -1) begin
                r_counter <= 0;
                r_clk <= 1'b1;
            end else begin
                r_counter <= r_counter + 1;
                r_clk <= 1'b0;
            end
        end
    end    
endmodule

module dot_prod (
    input clk,
    input reset,
    input in_tick,
    //
    output dot
);
    reg r_dot;
    assign dot = r_dot;

    always @(posedge clk or posedge reset) begin
        if(reset) begin
            r_dot <= 0;
        end else begin
            if(in_tick) begin
                r_dot <= ~r_dot;
            end
        end
    end
endmodule

module t_count #(
    parameter CNT = 100
)(
    input clk,
    input reset,
    input in_tick,
    input enable,
    input clear,
    //
    output [6:0] count,
    output out_tick
);
    reg r_out_tick;
    reg [6:0] r_count;

    assign count = r_count;
    assign out_tick = r_out_tick;

    always @(posedge clk or posedge reset) begin
        if(reset) begin
            r_count <= 0;
            r_out_tick <= 0;
        end else begin
            r_out_tick <= 0; // forgot this, this was essential!!
            if(enable) begin
                if(in_tick) begin
                    if(r_count >= CNT -1) begin
                        r_count <= 0;
                        r_out_tick <= 1'b1;
                    end else begin
                        r_count <= r_count + 1;
                        r_out_tick <= 1'b0;
                    end
                end else begin
                    r_count <= r_count;
                end
            end else begin
                // not enable signal
                r_count <= r_count;
                if(clear) begin
                    r_count <= 0;
                end
            end
        end
    end
endmodule


// module clk_100hz (
//     input clk,
//     input reset,
//     output o_clk
// );
//     reg [$clog2(100_000_000/100)-1:0] r_counter;
//     reg r_clk;

//     assign o_clk = r_clk;

//     // 100MHz to 100Hz
//     always @(posedge clk or posedge reset) begin
//         if(reset) begin
//             r_counter <= 0;
//             r_clk <= 1'b0;
//         end else begin
//             if(r_counter == 100_000_000/100 -1) begin
//                 r_counter <= 0;
//                 r_clk <= 1'b1;
//             end else begin
//                 r_counter <= r_counter + 1;
//                 r_clk <= 1'b0;
//             end
//         end
//     end    
// endmodule

// module ms_sec_min_hour (
//     input clk,
//     input reset,
//     input tick_100Hz,
//     input clear,
//     input enable,
//     // output
//     output [6:0] ms10,
//     output [6:0] sec,
//     output [6:0] min,
//     output [6:0] hour,
//     output dot
// );
//     reg r_dot;
//     reg [6:0] r_ms10,r_sec,r_min,r_hour;

//     assign ms10 = r_ms10;
//     assign sec = r_sec;
//     assign min = r_min;
//     assign hour = r_hour;
//     assign dot = r_dot;

//     always @(posedge clk ,posedge reset) begin
//         if(reset) begin
//             r_ms10 <= 0; r_sec <= 0; r_min <= 0; r_hour <= 0;
//             r_dot <=1;
//         end else begin
//             if(enable) begin
//                 if(tick_100Hz) begin
//                     if(r_ms10 >= 99) begin
//                         r_ms10 <= 0;
//                         r_sec <= r_sec + 1;
//                         r_dot <= !r_dot;
//                     end else begin
//                         r_ms10 <= r_ms10 + 1;
//                     end
//                     if(r_sec >= 60) begin
//                         r_sec <= 0;
//                         r_min <= r_min + 1;
//                     end
//                     if(r_min >= 60) begin
//                         r_min <= 0;
//                         r_hour <= r_hour + 1;
//                     end
//                 end else begin // if not tick
//                 // prevent latch
//                     r_ms10 <= r_ms10; r_sec <= r_sec; r_min <= r_min; r_hour <= r_hour;
//                 end
//             end else begin
//                 //not enable signal
//                 r_ms10 <= r_ms10; r_sec <= r_sec; r_min <= r_min; r_hour <= r_hour;
//                 if(clear) begin
//                     r_ms10 <= 0; r_sec <= 0; r_min <= 0; r_hour <= 0;
//                 end 
//                 // else begin
//                 //     r_ms10 <= r_ms10; r_sec <= r_sec; r_min <= r_min; r_hour <= r_hour;
//                 // end
//             end
//         end
//     end
    
// endmodule