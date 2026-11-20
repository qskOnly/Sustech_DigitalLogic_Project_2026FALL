`timescale 1ns / 1ps 

module core_top (
    input  wire        clk,
    input  wire        rst_n,

    // 来自 huarongdao_top
    input  wire [3:0]  sw_num,
    input  wire        confirm_pos,

    // 给 display_top / huarongdao_top
    output wire [35:0] board,
    output wire [8:0]  cell_valid,
    output wire [3:0]  zero_pos,
    output wire [2:0]  state,
    output wire        win,
    output wire        error_pulse
);

    // ====================================================
    // 内部连线声明
    // ====================================================
    // init_validate -> board_reg
    wire        init_we;
    wire [3:0]  init_idx;
    wire [3:0]  init_data;

    // init_validate -> game_fsm
    wire        init_done;

    // game_fsm -> init_validate
    wire        init_en;
    wire        init_start;
    
    // 内部悬空信号（本期不需要输出到 top，但 init_validate 会输出）
    wire        init_error_idx;
    wire        init_error_last;

    // ====================================================
    // 模块例化
    // ====================================================

    // 1. 初始化校验模块
    init_validate u_init_validate (
        .clk            (clk),
        .rst_n          (rst_n),
        
        // 来自 FSM 的控制
        .init_start     (init_start),
        .init_en        (init_en),
        
        // 来自用户
        .confirm_pos    (confirm_pos),
        .sw_num         (sw_num),
        
        // 给 board_reg 的写口
        .init_we        (init_we),
        .init_idx       (init_idx),
        .init_data      (init_data),
        
        // 状态/错误
        .init_error     (error_pulse),      // 汇总给显示域的 error_pulse
        .init_error_idx (init_error_idx),   // 本期 core_top 不输出，留空即可
        .init_error_last(init_error_last),  // 同上
        .init_done      (init_done)
    );

    // 2. 棋盘寄存器模块
    board_reg u_board_reg (
        .clk            (clk),
        .rst_n          (rst_n),
        
        .init_we        (init_we),
        .init_idx       (init_idx),
        .init_data      (init_data),
        
        // 输出到子顶层
        .board          (board),
        .cell_valid     (cell_valid),
        .zero_pos       (zero_pos)
    );

    // 3. 游戏主控状态机模块
    game_fsm u_game_fsm (
        .clk            (clk),
        .rst_n          (rst_n),
        
        .init_done      (init_done),
        
        // 输出到子顶层
        .state          (state),
        .init_en        (init_en),
        .init_start     (init_start),
        .win            (win)
    );

endmodule
