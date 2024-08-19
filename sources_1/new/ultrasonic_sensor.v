`timescale 1ns / 1ps

module ultrasonic_sensor(
    input clk,
    input reset,
    input echo,
    output reg trigger,
    output reg [8:0] distance
    );

    // Define parameters
    parameter IDLE          = 2'b00;    // wait for next correct action
    parameter SEND_TRIGGER  = 2'b01;    // output trigger to HCSR04
    parameter ECHO_READ     = 2'b10;    // input echo read pedge and nedge
    parameter READ_DATA     = 2'b11;    // calculate distance

    parameter WAIT_PEDGE = 2'b00; // when detect pedge
    parameter WAIT_NEDGE = 2'b01; // when detect nedge

    wire clk_usec;
    wire hc_nedge, hc_pedge;

    reg count_usec_en;
    // reg [15:0] count_usec;
    reg [$clog2(500_000)-1 : 0] count_usec;
    reg [1:0] state,next_state,read_state;
    // count_start <= pedge, count_end <= nedge
    // reg [15:0] count_start; // start : pedge, end : nedge
    reg [15:0] count_end; // start : pedge, end : nedge

    clock_usec clk_us(
        .clk(clk),
        .reset(reset),
        .clk_usec(clk_usec)
    );

    // usec count
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
    // Communication Part
    always @(posedge clk or posedge reset) begin
        if(reset) begin
            count_usec_en <= 0;
            next_state <= IDLE;
            read_state <= WAIT_PEDGE;
            trigger <= 0;
            // count_start <= 0;
            count_end <= 0;
            distance <= 0;
        end else begin
            case (state)
                IDLE:begin
                    // if(count_usec < 16'd65_535) begin
                        //다음 거리 측정을 정학하게 하기 위해선 60ms의 여유시간이 필요하다고 권장된다.
                        // 65.535ms(datasheet = 60ms)
                    if(count_usec < 500_000) begin
                        // 0.5초 세리고..
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
                                // count_start <= count_usec;
                                count_usec_en <= 1; // begin count
                            end 
                            else if(count_usec > 16'd23_201) begin
                                // 4m넘으면 reset
                                read_state <= WAIT_PEDGE; // reset read_state
                                next_state <= IDLE; // reset state
                            end 
                            else begin
                                count_usec_en <= 0; // no count
                            end
                        end
                        WAIT_NEDGE: begin
                            if(count_usec < 16'd23_201) begin
                                // 4m거리내 여야함.
                                if(hc_nedge) begin
                                    next_state <= READ_DATA; // go to next state
                                    count_end <= count_usec;
                                end else begin
                                    count_usec_en <= 1;
                                    read_state <= WAIT_NEDGE; // continue to wait nedge
                                end
                            end else begin
                                read_state <= WAIT_PEDGE; // reset read_state
                                next_state <= IDLE; // reset state
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
                    // distance <= (count_end - count_start) / 58;
                    distance <= (count_end) / 58;
                    // count_start <= 0;
                    count_end <= 0;
                    next_state <= IDLE; // reset state
                    read_state <= WAIT_PEDGE; // reset read_state
                    count_usec_en <= 0; // added my
                end
                default: 
                    next_state <= IDLE;
            endcase // end case state
        end
    end
endmodule


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