`timescale 1ns/1ps

module tb_board_reg();
    reg         clk;
    reg         rst_n;
    reg         init_we;
    reg  [3:0]  init_idx;
    reg  [3:0]  init_data;
    
    wire [35:0] board;
    wire [8:0]  cell_valid;
    wire [3:0]  zero_pos;

    // 例化 UUT
    board_reg uut (
        .clk(clk),
        .rst_n(rst_n),
        .init_we(init_we),
        .init_idx(init_idx),
        .init_data(init_data),
        .board(board),
        .cell_valid(cell_valid),
        .zero_pos(zero_pos)
    );

    // 100MHz 时钟
    initial clk = 0;
    always #5 clk = ~clk;

    // 模拟写入一格的 Task
    task write_cell(input [3:0] idx, input [3:0] data);
        begin
            @(negedge clk);
            init_we = 1'b1;
            init_idx = idx;
            init_data = data;
            @(negedge clk);
            init_we = 1'b0;
            #10; // 等待内部逻辑更新
        end
    endtask

    initial begin
        // 1. 初始化与复位
        rst_n = 0; init_we = 0; init_idx = 0; init_data = 0;
        #25;
        rst_n = 1;
        #10;
        $display("--- Reset Test ---");
        $display("board: %h, cell_valid: %b, zero_pos: %d", board, cell_valid, zero_pos);
        if (board !== 36'd0 || cell_valid !== 9'd0 || zero_pos !== 4'd0)
            $display("ERROR: Reset failed!");

        // 2. 逐格写入测试 (1~8, 0)
        $display("--- Sequential Write Test ---");
        write_cell(4'd0, 4'd1); // 第0格写1
        write_cell(4'd1, 4'd2);
        write_cell(4'd2, 4'd3);
        
        $display("After 3 writes -> board: %h, cell_valid: %b, zero_pos: %d", board, cell_valid, zero_pos);
        if (cell_valid !== 9'b000000111) $display("ERROR: cell_valid mismatch!");
        if (board[3:0] !== 4'd1) $display("ERROR: board[0] mismatch!");

        // 写 0 号棋，验证 zero_pos 更新
        write_cell(4'd3, 4'd0); 
        write_cell(4'd4, 4'd4);
        write_cell(4'd5, 4'd5);
        write_cell(4'd6, 4'd6);
        write_cell(4'd7, 4'd7);
        write_cell(4'd8, 4'd8); // 写第9格 8
        
        $display("After 9 writes -> board: %h, cell_valid: %b, zero_pos: %d", board, cell_valid, zero_pos);
        // 期望：board[3:0] = 3 (zero_pos=3), cell_valid=1_1111_1111
        if (board !== 36'h8_76540123) $display("ERROR: Final board mismatch!"); // 只是演示，实际值按写入的顺序
        if (cell_valid !== 9'h1FF) $display("ERROR: cell_valid not fully set!");
        if (zero_pos !== 4'd3) $display("ERROR: zero_pos mismatch!");

        // 3. 中途复位测试
        $display("--- Mid-way Reset Test ---");
        @(negedge clk); rst_n = 0;
        @(negedge clk); rst_n = 1;
        @(negedge clk);
        if (board !== 36'd0 || cell_valid !== 9'd0 || zero_pos !== 4'd0)
            $display("ERROR: Mid-way reset failed!");
        else
            $display("Mid-way reset passed.");

        #100;
        $finish;
    end
endmodule