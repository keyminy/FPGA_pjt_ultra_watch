`timescale 1ns / 1ps

module FSM(
    input           clk,
    input           reset,
    input           btn_run_stop,
    input           btn_clear,
    input           btn_change,
    // uart
    input   [7:0]   rx_data,
    input           rx_done,
    output          rd_en,
    // output
    output reg      enable,
    output reg      clear,
    output reg      change
    );

    // for fifo uart
    reg rd_en_reg,rd_en_next;
    reg [7:0] rx_data_reg,rx_data_next;

    assign rd_en = rd_en_reg;

    // existed
    parameter STOP = 2'b00;
    parameter RUN = 2'b01;
    parameter CLEAR = 2'b10;

    // state change
    parameter MS10_SEC =1'b0;
    parameter MIN_HOUR = 1'b1;

    // for watch
    reg [1:0] state,next_state;
    reg state_ch,state_ch_next;

    // ===========for changing mode
    // 1.state register
    always @(posedge clk or posedge reset) begin
        if(reset) begin
            state_ch <= MS10_SEC;
        end else begin
            state_ch <= state_ch_next;
        end
    end
    //2.next state combinational logic
    always @(*) begin
        state_ch_next = state_ch;
        case (state_ch)
            MS10_SEC: begin
                if((btn_change==1'b1) || rx_data_reg =="h") begin
                    state_ch_next = MIN_HOUR;
                end
            end
            MIN_HOUR: begin
                if((btn_change==1'b1) || rx_data_reg =="m") begin
                    state_ch_next = MS10_SEC;
                end
            end
        endcase
    end
    // 3. output combinational logic
    always @(*) begin
        change = 1'b0; // Becareful!!... prevent error
        case (state_ch)
            MS10_SEC: begin
                change = 1'b0;
            end
            MIN_HOUR: begin
                change = 1'b1;
            end
        endcase
    end
    // =========== end for changing mode

    // ===========for basic stopwatch mode
    // 1.state register
    always @(posedge clk or posedge reset) begin
        if(reset) begin
            state <= STOP;
            rd_en_reg <= 1'b0;
            rx_data_reg <= 0;
        end else begin
            state <= next_state;
            rx_data_reg <= rx_data_next;
            rd_en_reg <= rd_en_next;
        end
    end

    // 2.next state combinational logic
    always @(*) begin
        rx_data_next = 0; // clear rx buffer!!!
        rd_en_next = 1'b0;
        if(rx_done==1'b1) begin
            rx_data_next = rx_data;
            rd_en_next = 1'b1;
        end
        case (state)
            STOP: begin
                if(btn_run_stop || rx_data_reg == "r") begin
                    next_state = RUN;
                end
                else if(btn_clear || rx_data_reg == "c") begin
                    next_state = CLEAR;
                end
                else
                    // 자기자신의 상태를 쭉 유지하게 해주어야함
                    next_state = STOP;
            end 
            RUN: begin
                 if(btn_run_stop == 1'b1 || rx_data_reg == "s") // 's' 혹은 'r'
                begin
                    next_state = STOP;
                    // rx_data_next = 0;
                end
                else
                    // 자기자신의 상태를 쭉 유지하게 해주어야함
                    next_state = RUN;
            end 
            CLEAR: begin
                if(btn_clear == 1'b0)
                    next_state = STOP;
                else 
                    // 자기자신의 상태를 쭉 유지하게 해주어야함
                    next_state = CLEAR;
            end 
            default: begin
                next_state = state;
            end
        endcase
    end

    // 3.Output Combinational logic
    always @(*) begin
        case(state)
        STOP: begin
            enable = 1'b0;
            clear = 1'b0;
        end
        RUN: begin
            enable = 1'b1;
            clear = 1'b0;
        end
        CLEAR: begin
            clear = 1'b1;
            enable = 1'b0;
        end
        // default이거 안하면 어떻게 될까요?? -> latch
        default: begin
            enable = 1'b0;
            clear = 1'b0;
        end
        endcase
    end
endmodule
