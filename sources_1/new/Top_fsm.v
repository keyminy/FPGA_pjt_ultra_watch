module Top_fsm (
    input clk,
    input reset,
    input btn_run_stop,
    input btn_clear,
    input btn_change,
   input rx,
    // output
    output [3:0] fndCom,
    output [7:0] fndFont,
   output tx
);
    wire w_btn_run_stop, w_btn_clear,w_btn_change;
    wire [6:0] w_digit_h, w_digit_l;
    wire w_dot,w_enable, w_clear,w_change;

    wire w_rx_done; 
    wire [7:0] w_rx_data;

    uart U_uart_my(
        // global signal
        .clk(clk),
        .reset(reset),
        // transmitter signal
        .start(w_rx_done),
        .tx_data(w_rx_data),
        .o_tx_done(), // no connect
        .o_txd(tx),
        // receiver signal
        .rx(rx),
        .o_rx_data(w_rx_data),
        .o_rx_done(w_rx_done)
    );

    FSM U_FSM(
        .clk(clk),
        .reset(reset),
        .btn_run_stop(w_btn_run_stop),
        .btn_clear(w_btn_clear),
        .btn_change(w_btn_change),
        // uart
        //input
        .rx_data(w_rx_data),
        .rx_done(w_rx_done),
        // output
        .rd_en(), 
        // output
        .enable(w_enable),
        .clear(w_clear),
        .change(w_change)
    );

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