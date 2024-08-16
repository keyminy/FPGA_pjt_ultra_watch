module Top_fsm (
    input clk,
    input reset,
    input btn_run_stop,
    input btn_clear,
    input btn_change,
//    input rx,
    // output
    output [3:0] fndCom,
    output [7:0] fndFont
//    output tx
);
    wire w_btn_run_stop;
    wire w_btn_clear;
    wire w_btn_change;
    wire [6:0] w_digit_h;
    wire [6:0] w_digit_l;
    wire w_dot;
    wire w_enable;
    wire w_clear;
    wire w_change;

    button U_button_enable(
        .clk(clk),
        .reset(reset),
        .i_btn(btn_run_stop),
        .o_btn(w_btn_run_stop)
    );
    button U_button_clear(
        .clk(clk),
        .reset(reset),
        .i_btn(btn_clear),
        .o_btn(w_btn_clear)
    );
    button U_button_change(
        .clk(clk),
        .reset(reset),
        .i_btn(btn_change),
        .o_btn(w_btn_change)
    );

    FSM U_FSM(
    .clk(clk),
    .reset(reset),
    .btn_run_stop(w_btn_run_stop),
    .btn_clear(w_btn_clear),
    .btn_change(w_btn_change),
    // uart
    //input
    .rx_data(),
    .rx_done(),
    // output
    .rd_en(), 
    // output
    .enable(w_enable),
    .clear(w_clear),
    .change(w_change)
    );
    
    time_sel U_time_select(
        // input
        .clk(clk),
        .reset(reset),
        .clear(w_clear),
        .enable(w_enable),
        .change(w_change),
        // output
        .digit_h(w_digit_h),
        .digit_l(w_digit_l),
        .dot(w_dot)
    );

    FndController U_FndController(
        .clk(clk),
        .reset(reset),
        .digit_h(w_digit_h),
        .digit_l(w_digit_l),
        .dot(w_dot),
        .fndCom(fndCom),
        .fndFont(fndFont)
    );

    
endmodule