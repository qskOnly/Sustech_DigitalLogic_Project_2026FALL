`timescale 1ns/1ps

module tb_init_validate();
    reg         clk;
    reg         rst_n;
    reg         init_start;
    reg         init_en;
    reg         confirm_pos;
    reg  [3:0]  sw_num;

    wire        init_we;
    wire [3:0]  init_idx;
    wire [3:0]  init_data;
    wire        init_error;
    wire [3:0]  init_error_idx;
    wire        init_error_last;
    wire        init_done;

    // 例化 UUT
    init_validate uut (
        .clk(clk),
        .rst_n(rst_n),
        .init_start(init_start),
        .init_en(init_en),
        .confirm_pos(confirm_pos),
        .sw_num(sw_num),
        .init_we(init_we),
        .init_idx(init_idx),
        .init_data(init_data),
        .init_error(init_error),
        .init_error_idx(init_error_idx),
        .init_error_last(init_error_last),
        .init_done(init_done)
    );

    // 100MHz 时钟
    initial clk = 0;
    always #5 clk = ~clk;

    // 模拟按键 Task
    task press_key(input [3:0] val);
        begin
            @(negedge clk);
            sw_num = val;
            confirm_pos = 1'b1;
            @(negedge clk);
            confirm_pos = 1'b0;
            sw_num = 4'd0; // 按键后清零，防止干扰
            #10; // 等待逻辑响应
        end
    endtask

    initial begin
        // 1. 初始化与启动
        rst_n = 0; init_start = 0; init_en = 0; confirm_pos = 0; sw_num = 0;
        #25;
        rst_n = 1;
        @(negedge clk); init_start = 1;
        @(negedge clk); init_start = 0;
        init_en = 1; // 模拟进入 INIT 状态
        #10;

        // 2. 场景1：合法连续输入 (1 2 3)
        $display("--- Test 1: Valid Inputs (1,2,3) ---");
        press_key(4'd1);
        press_key(4'd2);
        press_key(4'd3);
        $display("init_idx: %d, init_done: %b, init_error: %b", init_idx, init_done, init_error);
        if (init_idx !== 4'd3) $display("ERROR: idx didn't advance to 3!");

        // 3. 场景2：中途超范围输入 (10)
        $display("--- Test 2: Invalid Range (10) ---");
        press_key(4'd10);
        $display("init_idx: %d (should stay 3), init_error: %b", init_idx, init_error);
        if (init_idx !== 4'd3) $display("ERROR: idx advanced during error!");
        
        // 验证非法后的恢复 (输入 4)
        $display("--- Test 2: Recovery with (4) ---");
        press_key(4'd4);
        if (init_idx !== 4'd4) $display("ERROR: idx failed to recover to 4!");

        // 4. 场景3：中途重复输入 (2)
        $display("--- Test 3: Invalid Duplicate (2) ---");
        press_key(4'd2);
        $display("init_idx: %d (should stay 4), init_error: %b", init_idx, init_error);
        if (init_idx !== 4'd4) $display("ERROR: idx advanced during duplicate!");

        // 5. 场景4：填满前8格
        $display("--- Filling 5,6,7,8 ---");
        press_key(4'd5);
        press_key(4'd6);
        press_key(4'd7);
        press_key(4'd8);
        if (init_idx !== 4'd8) $display("ERROR: idx failed to reach 8!");

        // 6. 场景5：第9格非法
        $display("--- Test 4: 9th Cell Invalid ---");
        press_key(4'd1); // 重复的 1
        $display("init_error_last: %b, init_done: %b", init_error_last, init_done);
        if (init_error_last !== 1'b1) $display("ERROR: init_error_last not asserted!");
        if (init_done !== 1'b0) $display("ERROR: init_done asserted on error!");

        // 7. 场景6：第9格合法，触发 init_done
        $display("--- Test 5: 9th Cell Valid ---");
        press_key(4'd0);
        $display("init_error_last: %b, init_done: %b", init_error_last, init_done);
        if (init_done !== 1'b1) $display("ERROR: init_done not asserted!");

        #100;
        $finish;
    end
endmodule