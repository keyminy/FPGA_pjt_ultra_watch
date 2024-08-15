`timescale 1ns / 1ps

module ultrasonic_sensor(
    input clk           ,
    input reset         ,
    input echo          ,
    // output
    output reg trigger  , //초음파 트리거 신호
    output reg [15:0] distance // 측정된 거리
    );
    // distance max : 400cm, min : 2cm

    initial begin
        trigger = 0;
        distance = 0;
    end

    // define STATE
    parameter IDLE = 3'b000;
    parameter SEND_TRIGGER = 3'b001;
    parameter WAIT_FOR_ECHO_HIGH = 3'b010;
    parameter WAIT_FOR_ECHO_LOW = 3'b011;
    parameter CALCULATE_DISTANCE = 3'b100;

    reg [2:0] state = IDLE,next_state = IDLE;
    reg [31:0] echo_time = 0; // 에코 시간을 저장하는 레지스터
    reg [31:0] count = 0; // 타이머 카운터

    // create trigger pulse
    always @(posedge clk or posedge reset) begin
        if(reset) begin
            trigger <= 0;
            count <= 0;
            state <= IDLE;
        end 
        else begin
            case (state)
                IDLE: begin
                    trigger <= 0;
                    count <= 0;
                    next_state <= SEND_TRIGGER;
                end
                SEND_TRIGGER: begin
                    if(count < 100) begin
                        // 10us트리거 펄스
                        trigger <= 1;
                        
                    end
                end
            endcase
        end
    end

endmodule
