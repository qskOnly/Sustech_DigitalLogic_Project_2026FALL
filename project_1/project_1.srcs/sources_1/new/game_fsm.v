`timescale 1ns / 1ps

module game_fsm (
    input  wire        clk,
    input  wire        rst_n,

    input  wire        init_done,    // 来自 init_validate

    output reg  [2:0]  state,        // IDLE / INIT / PLAY ...
    output wire        init_en,      // state == INIT
    output reg         init_start,   // 复位后打一拍给 init_validate
    output wire        win           // 本期可 assign 0；后续接 win_check
);

    // 状态常量定义（按文档规范）
    localparam IDLE     = 3'd0;
    localparam INIT     = 3'd1;
    localparam PLAY     = 3'd2;
    localparam WIN      = 3'd3;
    localparam WIN_STAT = 3'd4;
    localparam DEMO     = 3'd5;

    reg [2:0] next_state;

    // ====================================================
    // 第一段：状态寄存器（时序逻辑）
    // ====================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 为了避开与 init_validate 的复位同拍，这里先复位到 IDLE
            // 下一拍自动进 INIT，此时再发出 init_start
            state <= IDLE; 
        end else begin
            state <= next_state;
        end
    end

    // ====================================================
    // 第二段：次态逻辑（组合逻辑）
    // ====================================================
    always @(*) begin
        next_state = state; // 默认保持当前状态，防止生成锁存器
        case (state)
            IDLE: begin
                next_state = INIT; // 自动进入初始化状态
            end
            INIT: begin
                if (init_done) begin
                    next_state = PLAY; // 收到初始化完成脉冲，进入游戏
                end
            end
            PLAY: begin
                // 本期保持停留在 PLAY 状态
                // Sprint 3 再补充：if (win) next_state = WIN;
            end
            WIN: begin
                // Sprint 3 再补充：按确认键进入 WIN_STAT
            end
            WIN_STAT: begin
                // 待实现
            end
            DEMO: begin
                // 待实现
            end
            default: next_state = IDLE;
        endcase
    end

    // ====================================================
    // init_start 脉冲生成（关键时序）
    // 在离开 IDLE 进入 INIT 的那一拍拉高，第二拍拉低
    // ====================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            init_start <= 1'b0;
        end else if (state == IDLE && next_state == INIT) begin
            init_start <= 1'b1; // 进入 INIT 的瞬间给出 1 周期脉冲
        end else begin
            init_start <= 1'b0; // 仅在那一拍有效
        end
    end

    // ====================================================
    // 第三段：输出逻辑（Moore型，仅与当前状态有关）
    // ====================================================
    assign init_en = (state == INIT);
    
    // 本期暂不实现通关判定，直接赋 0
    assign win     = 1'b0; 


endmodule