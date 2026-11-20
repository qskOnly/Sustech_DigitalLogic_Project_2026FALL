`timescale 1ns / 1ps

// 输入计数、0~8范围检查、位图去重（seen[8:0]）
// 输出：init_we / init_idx / init_data / init_error
// init_error_idx / init_error_last / init_done

module init_validate (
    input  wire        clk,
    input  wire        rst_n,

    // 来自 game_fsm 的初始化控制
    input  wire        init_start,   // 复位后打一拍，清 seen/idx
    input  wire        init_en,      // state == INIT 时有效

    // 来自 top 的用户输入
    input  wire        confirm_pos,  // 消抖后的确认脉冲，高有效
    input  wire [3:0]  sw_num,       // 0~8

    // 给 board_reg 的写口
    output reg         init_we,      // 单周期
    output reg  [3:0]  init_idx,     // 当前待写格 0~8
    output reg  [3:0]  init_data,    // 合法输入值

    // 状态/错误
    output reg         init_error,      // 必须单周期
    output reg  [3:0]  init_error_idx,  // 出错格索引
    output reg         init_error_last, // 第 9 格非法
    output reg         init_done        // 第 9 格合法，单周期
);

    // 内部寄存器
    reg [8:0] seen_r;  // 去重位图：bit[0] 对应数字 0，bit[8] 对应数字 8

    // 组合逻辑：提前判断输入是否非法
    // 非法条件：超出 8 的范围，或者该数字已经被输入过
    wire is_illegal = (sw_num > 4'd8) || seen_r[sw_num];

    // ====================================================
    // 时序逻辑：处理初始化状态与脉冲输出
    // ====================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            init_idx        <= 4'd0;
            seen_r          <= 9'd0;
            init_we         <= 1'b0;
            init_data       <= 4'd0;
            init_error      <= 1'b0;
            init_error_idx  <= 4'd0;
            init_error_last <= 1'b0;
            init_done       <= 1'b0;
        end 
        else if (init_start) begin
            // 收到 FSM 的初始化开始脉冲，清空所有状态
            init_idx        <= 4'd0;
            seen_r          <= 9'd0;
            init_we         <= 1'b0;
            init_error      <= 1'b0;
            init_error_last <= 1'b0;
            init_done       <= 1'b0;
        end 
        else begin
            // 默认清空所有单周期脉冲（实现“单周期”特性的关键）
            init_we         <= 1'b0;
            init_error      <= 1'b0;
            init_error_last <= 1'b0;
            init_done       <= 1'b0;

            // 只有在 INIT 状态且确认键被按下时，才处理输入
            if (init_en && confirm_pos) begin
                if (is_illegal) begin
                    // 【非法输入】
                    init_error      <= 1'b1;
                    init_error_idx  <= init_idx; // 记录出错的格号
                    
                    // 如果是第 9 格（索引为 8）出错，拉高 last 标志
                    if (init_idx == 4'd8) begin
                        init_error_last <= 1'b1;
                    end
                    // 注意：init_idx 保持不变，init_we 保持 0，seen_r 不更新
                end 
                else begin
                    // 【合法输入】
                    init_we    <= 1'b1;
                    init_data  <= sw_num;
                    seen_r[sw_num] <= 1'b1; // 位图标记已使用
                    
                    // 如果已经是第 9 格（索引 8），说明初始化完成
                    if (init_idx == 4'd8) begin
                        init_done <= 1'b1;
                    end 
                    else begin
                        // 否则索引递增，准备接收下一个
                        init_idx <= init_idx + 1'b1;
                    end
                end
            end
        end
    end

endmodule