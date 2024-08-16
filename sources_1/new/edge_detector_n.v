`timescale 1ns / 1ps

module edge_detector_n (
    input clk,
    input cp_in, // 감지할 입력 신호
    input reset,
    output p_edge,
    output n_edge
);
    reg ff_cur, ff_old;

    always @(posedge reset or negedge clk) begin
        if(reset) begin
            ff_cur <= 0;
            ff_old <= 0;
        end else begin
            ff_old <= ff_cur; // 현재 상태를 이전 상태에 저장
            ff_cur <= cp_in; // 입력 신호 cp_in을 현재 상태로 저장
        end
    end

    //양의 엣지 검출 : ff_cur이 1이고, ff_old가 0인 경우는 p_edge가 1
    assign p_edge = ({ff_cur,ff_old} == 2'b10) ? 1 : 0;
    //음의 엣지 검출 : ff_cur이 0이고, ff_old가 1인 경우는 n_edge가 1
    assign n_edge = ({ff_cur,ff_old} == 2'b01) ? 1 : 0;

endmodule