`timescale 1ns / 1ps

module FIFO #(
    parameter ADDR_WIDTH = 3,
    DATA_WIDTH = 8
    )(
        input       clk,
        input       reset,
        input       wr,
        input       rd,
        input       [DATA_WIDTH-1 : 0] wr_data,
        output      [DATA_WIDTH-1 : 0] rd_data,
        output      full,
        output      empty
    );
    wire [ADDR_WIDTH-1:0] w_rd_addr;
    wire [ADDR_WIDTH-1:0] w_wr_addr;

    RegisterFile #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH)
    ) u_registerfile (
        .clk(clk),
        .w_en(wr & ~full),//메모리 공간
        .rd_addr(w_rd_addr), // w_rd_addr : from fifo controller
        .wr_addr(w_wr_addr), // w_wr_addr : from fifo controller
        .wr_data(wr_data), 
        .rd_data(rd_data) 
    );

    // FIFO Controller
    fifo_ctrl #(
        .ADDR_WIDTH(ADDR_WIDTH)
    ) u_fifo_ctrl (
        .clk(clk),
        .reset(reset),
        // write
        .wr(wr),
        .full(full),
        .wr_addr(w_wr_addr),
        // read
        .rd(rd),
        .empty(empty),
        .rd_addr(w_rd_addr)
    );
endmodule

module RegisterFile #(
    parameter ADDR_WIDTH = 3,
    DATA_WIDTH = 8
) (
    input                    clk,
    input                    w_en,//메모리 공간
    input  [ADDR_WIDTH-1:0]  rd_addr, // Addr의 크기,rd_ptr제어가능
    input  [ADDR_WIDTH-1:0]  wr_addr, // wr_ptr제어가능
    input  [DATA_WIDTH-1:0]  wr_data, 
    output [DATA_WIDTH-1:0]  rd_data 
);
    reg [DATA_WIDTH-1:0] memory [0:2**ADDR_WIDTH-1]; // memory만듬(8bit memory) * 2^3개 exist

    // write operation(sequential circuit, clk!!!)
    // clock에따라 동작, RAM, ROM은 reset이 없음
    // write enable = 1일때 동작함
    always @(posedge clk ) begin
        if(w_en) memory[wr_addr] <= wr_data;
    end

    // read operation(combinational circuit)
    assign rd_data = memory[rd_addr];

endmodule

// FIFO Controller
module fifo_ctrl #(
    parameter ADDR_WIDTH = 3
) (
    input       clk,
    input       reset,
    // write
    input       wr,
    output      full,
    output       [ADDR_WIDTH-1 : 0] wr_addr,
    // read
    input       rd,
    output      empty,
    output      [ADDR_WIDTH-1 : 0] rd_addr
);
    reg [ADDR_WIDTH-1 : 0] wr_ptr_reg,wr_ptr_next; // make write index
    reg [ADDR_WIDTH-1 : 0] rd_ptr_reg,rd_ptr_next; // make read index
    reg full_reg, full_next;
    reg empty_reg, empty_next;

    assign wr_addr = wr_ptr_reg;
    assign rd_addr = rd_ptr_reg;
    assign full = full_reg;
    assign empty = empty_reg;

    // controller쪽이므로, reset이 들어가야함
    always @(posedge clk ,posedge reset) begin
        if(reset) begin
            rd_ptr_reg <= 0;
            wr_ptr_reg <= 0;
            empty_reg <= 1'b1; // 전원 초기값엔 아무것도 없으므로
            full_reg <= 1'b0;
        end else begin
            rd_ptr_reg <= rd_ptr_next;
            wr_ptr_reg <= wr_ptr_next;
            empty_reg <= empty_next;
            full_reg <= full_next;
        end
    end
always @(*) begin
    wr_ptr_next = wr_ptr_reg;
    rd_ptr_next = rd_ptr_reg;
    full_next = full_reg;
    empty_next = empty_reg;
    case ({wr, rd})
        2'b01: begin
            // read only 
            if (~empty_reg) begin
                // when empty is 0, begin read
                // increase read ptr
                rd_ptr_next = rd_ptr_reg + 1;
                full_next = 1'b0;
                // rd_ptr_next == wr_ptr_reg과 같아지는 순간, empty가 1
                if (rd_ptr_next == wr_ptr_reg) begin
                    empty_next = 1'b1;
                end else begin
                    empty_next = 1'b0;
                end
            end
        end
        2'b10: begin
            // write only
            if (~full_reg) begin
                // write data and increase write ptr
                wr_ptr_next = wr_ptr_reg + 1;
                empty_next = 1'b0;
                // wr_ptr_next == rd_ptr_reg과 같아지는 순간, full이 1
                if (wr_ptr_next == rd_ptr_reg) begin
                    full_next = 1'b1;
                end else begin
                    full_next = 1'b0;
                end
            end
        end
        2'b11: begin
            // write and read
            // if (~empty && ~full) begin
            //     // Simultaneous read and write
            //     rd_ptr_next = rd_ptr_reg + 1;
            //     wr_ptr_next = wr_ptr_reg + 1;
            //     // Full and empty flags do not change because pointers move together
            // end
            
            /* empty인 경우와 empty가 아닌 경우만 생각하면 된다. */
            if(empty_reg) begin
                // empty이면 그 위치 그대로(들어오는 것이 나가는 것이므로)
                wr_ptr_next = wr_ptr_reg;
                rd_ptr_next = rd_ptr_reg;
            end else begin
                // 값이 들어있으면(기존 값 존재)
                wr_ptr_next = wr_ptr_reg + 1;
                rd_ptr_next = rd_ptr_reg + 1;
            end
        end
        default: begin
            // handle default case if necessary
        end
    endcase
end

endmodule