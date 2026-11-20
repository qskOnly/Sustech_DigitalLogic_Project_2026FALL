`timescale 1ns / 1ps

// 1.存储棋盘board[35:0]，其中board[4*k +: 4]；
// 2.输出cell_valid[8:0]（每格是否已写入）；
// 3.输出zero_pos：0号空位所在格索引；

module board_reg (
    input  wire        clk,
    input  wire        rst_n,

    // 初始化写入（来自 init_validate）
    input  wire        init_we,
    input  wire [3:0]  init_idx,     // 0~8
    input  wire [3:0]  init_data,    // 0~8

    // input wire         swap_en,
    // input wire  [3:0]  piece_pos;

    // 棋盘只读输出（给 display_top / core_top 内部）
    output wire [35:0] board,        // board[4*k +: 4] = 第 k 格
    output wire [8:0]  cell_valid,   // 每格是否已写入
    output wire [3:0]  zero_pos      // 0 号空位所在格索引
);

    // 内部寄存器
    reg [35:0] board_r;
    reg [8:0]  cell_valid_r;
    reg [3:0]  zero_pos_r;

    // 时序逻辑：处理初始化写入
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 复位：清空棋盘、清空有效位、空位索引归 0
            board_r      <= 36'd0;
            cell_valid_r <= 9'd0;
            zero_pos_r   <= 4'd0;
        end else if (init_we) begin
            // 1. 写入数据到对应的棋盘格
            board_r[init_idx * 4 +: 4] <= init_data;
            
            // 2. 将该格的有效标志置 1（用于数码管渐进显示）
            cell_valid_r[init_idx]     <= 1'b1;
            
            // 3. 如果输入的是 0 号棋，更新空位索引
            if (init_data == 4'd0) begin
                zero_pos_r <= init_idx;
            end
        end
    end

    // 组合逻辑：输出连线
    assign board      = board_r;
    assign cell_valid = cell_valid_r;
    assign zero_pos   = zero_pos_r;


endmodule