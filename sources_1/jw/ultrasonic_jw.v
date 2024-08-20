`timescale 1ns / 1ps

module ultrasonic (
    input clk,
    input reset,
    input echo,
    //
    output trigger,
    output [13:0] distance
);

    wire w_trigger_enable;
    wire w_echo_count;

    ultra_fsm U_ULT_FSM (
        .clk(clk),
        .reset(reset),
        .echo(echo),
        .trigger(trigger),
        //
        .trigger_enable(w_trigger_enable),
        .echo_count(w_echo_count)
    );

    make_trigger U_MAK_TRI (
        .clk(clk),
        .reset(reset),
        .trigger_enable(w_trigger_enable),
        //
        .trigger(trigger)
    );

    cal_dis U_CAL_DIS (
        .clk(clk),
        .reset(reset),
        .echo_count(w_echo_count),
        //
        .distance(distance)
    );

endmodule

module ultra_fsm (
    input clk,
    input reset,
    input echo,
    input trigger,
    //
    output reg trigger_enable,
    output reg echo_count
);

    parameter IDLE = 2'b00, TRIGGER = 2'b01, WAIT = 2'b10, ECHO = 2'b11;
    reg [1:0] state, next_state;
    reg tr_0, tr_1;
    reg ec_0, ec_1;

    // state register
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            state <= IDLE;
            tr_0  <= 1'b0;
            tr_1  <= 1'b0;
            ec_0  <= 1'b0;
            ec_1  <= 1'b0;
        end else begin
            state <= next_state;
            tr_0  <= trigger;
            tr_1  <= tr_0;
            ec_0  <= echo;
            ec_1  <= ec_0;
        end
    end

    // next state combinational logic
    always @(*) begin
        next_state = state;
        case (state)
            IDLE: begin
                next_state = TRIGGER;
            end
            TRIGGER: begin
                if (~tr_0 & tr_1) next_state = WAIT;
            end
            WAIT: begin
                if (ec_0 & ~ec_1) next_state = ECHO;
            end
            ECHO: begin
                if (~ec_0 & ec_1) next_state = IDLE;
            end
        endcase
    end

    // output combinational logic
    always @(*) begin
        case (state)
            IDLE: begin
                trigger_enable = 1'b0;
                echo_count = 1'b0;
            end
            TRIGGER: begin
                trigger_enable = 1'b1;
                echo_count = 1'b0;
            end
            WAIT: begin
                trigger_enable = 1'b0;
                echo_count = 1'b0;
            end
            ECHO: begin
                trigger_enable = 1'b0;
                echo_count = 1'b1;
            end
        endcase
    end

endmodule

module make_trigger (
    input  clk,
    input  reset,
    input  trigger_enable,
    //
    output trigger
);

    reg [$clog2(100_000_000/2)-1 : 0] r_ms500_cnt;
    reg [$clog2(100_000_000/62_500)-1 : 0] r_16us_cnt;
    reg r_trigger;
    reg tr_0, tr_1;
    reg tri_start;

    assign trigger = r_trigger;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            r_trigger <= 0;
            tr_0 <= 0; tr_1 <= 0;
            r_ms500_cnt <= 0;
            tri_start <= 0;
            r_16us_cnt <= 0;
        end else begin
            tr_0 <= trigger_enable; tr_1 <= tr_0;

            if (trigger_enable) begin 
                if (r_ms500_cnt >= 100_000_000/2 - 1) begin
                    //if (r_sec_cnt >= 30 - 1) begin  // simul
                    r_ms500_cnt <= 0;
                    tri_start <= 1'b1;
                    r_16us_cnt <= 0;
                end else begin
                    if(~tr_1) r_ms500_cnt <= 0;
                    else r_ms500_cnt <= r_ms500_cnt + 1;
                end
                if (tri_start) begin
                    if (r_16us_cnt <= 100_000_000 / 62_500 - 1) begin
                        //if (r_16us_cnt <= 2 - 1) begin    // simul
                        r_16us_cnt  <= r_16us_cnt + 1;
                        r_trigger <= 1'b1;
                    end else begin
                        r_16us_cnt <= r_16us_cnt;
                        r_trigger <= 1'b0;
                        tri_start <= 1'b0;
                    end
                end
            end
        end
    end

endmodule

module cal_dis (
    input clk,
    input reset,
    input echo_count,
    //
    output [13:0] distance
);

    reg [13:0] r_cnt;
    reg ec_0, ec_1;
    reg [$clog2(100_000_000 / 1_000_000)-1:0] r_us_cnt;
    reg r_us_tick;
    reg [13:0] r_distance;

    assign distance = r_distance;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            ec_0 <= 1'b0;
            ec_1 <= 1'b1;
        end
        begin
            ec_0 <= echo_count;
            ec_1 <= ec_0;
        end
    end

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            r_cnt <= 0;
            r_distance <= 0;
        end else begin
            if (echo_count) begin
                if (r_us_tick) begin
                    r_cnt <= r_cnt + 1;
                end else begin
                    r_cnt <= r_cnt;
                    if (~ec_1) r_cnt <= 0;
                end
            end

            if (~ec_0 & ec_1) r_distance <= r_cnt / 58;
            //if (~ec_0 & ec_1) r_distance <= r_cnt / 2;    // simul
        end
    end

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            r_us_cnt <= 0;
        end else begin
            if (ec_0 & ~ec_1) r_us_cnt <= 0;
            if (r_us_cnt >= 100_000_000 / 1_000_000 - 1) begin
                //if (r_us_cnt >= 3 - 1) begin    // simul
                r_us_cnt  <= 0;
                r_us_tick <= 1'b1;
            end else begin
                r_us_cnt  <= r_us_cnt + 1;
                r_us_tick <= 1'b0;
            end
        end
    end

endmodule




