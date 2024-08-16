`timescale 1ns / 1ps

module ultra_first(
    input clk,
    input reset,
    input echo,
    output reg trigger,
    output reg [8:0] distance
    );

    // Define parameters
    parameter IDLE = 2'b00;
    parameter SEND_TRIGGER = 2'b01;
    parameter ECHO_READ  = 2'b10;
    parameter READ_DATA = 2'b11;

    parameter WAIT_PEDGE = 2'b00;
    parameter WAIT_NEDGE = 2'b01;

    wire clk_usec;
    wire hc_nedge, hc_pedge;

    reg count_usec_en;
    reg [15:0] count_usec;
    reg [1:0] state,next_state,read_state;
    reg [15:0] count_start,count_end;

    clock_usec clk_us(
        .clk(clk),
        .reset(reset),
        .clk_usec(clk_usec)
    );

    always @(negedge clk or posedge reset) begin
        if(reset) count_usec <= 0;
        else if(count_usec_en && clk_usec) count_usec <= count_usec + 1;
        else if(!count_usec_en) count_usec <= 0;
    end

    // status register
    always @(negedge clk or posedge reset)begin
    	if(reset) state = IDLE;
    	else state = next_state;
    end
    
    edge_detector_n ed_dec (
        .clk(clk), 
        .cp_in(echo), 
        .reset(reset), 
        .n_edge(hc_nedge), 
        .p_edge(hc_pedge)
    );

    always @(posedge clk or posedge reset) begin
        if(reset) begin
            count_usec_en <= 0;
            next_state <= IDLE;
            read_state <= WAIT_PEDGE;
            trigger <= 0;
            count_start <= 0;
            count_end <= 0;
            distance <= 0;
        end else begin
            case (state)
                IDLE:begin
                    if(count_usec < 16'd65_535) begin
                        count_usec_en <= 1;
                        trigger <= 0;
                    end else begin
                        next_state <= SEND_TRIGGER;
                        count_usec_en <= 0;
                    end
                end 
                SEND_TRIGGER:begin
                    if(count_usec < 16'd16) begin
                        count_usec_en <= 1;
                        trigger <= 1;
                    end else begin
                        count_usec_en <= 0;
                        next_state <= ECHO_READ;
                        trigger <= 0;
                        read_state <= WAIT_PEDGE;
                    end
                end
                ECHO_READ: begin
                    case(read_state)
                        WAIT_PEDGE : begin
                            if(hc_pedge) begin
                                // when echo pedged is detected
                                read_state <= WAIT_NEDGE;
                                count_usec_en <= 1; // begin count
                            end else begin
                                count_usec_en <= 0; // no count
                            end
                        end
                        WAIT_NEDGE: begin
                            if(count_usec < 16'd23_201) begin
                                if(hc_nedge) begin
                                    next_state <= READ_DATA; // go to next state
                                    count_end <= count_usec;
                                end else begin
                                    count_usec_en <= 1;
                                    read_state <= WAIT_NEDGE; // continue to count
                                end
                            end
                        end 
                        default: begin
                            // prevent error
                            read_state <= WAIT_PEDGE;
                            next_state <= IDLE;
                        end 
                    endcase // endcase read_state
                end
                READ_DATA: begin
                    distance <= count_end / 58;
                    count_start <= 0;
                    count_end <= 0;
                    next_state <= IDLE; // reset state
                    read_state <= WAIT_PEDGE; // reset read_state
                end
                default: 
                    next_state <= IDLE;
            endcase // end case state
        end
    end
endmodule
