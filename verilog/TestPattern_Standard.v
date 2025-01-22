`timescale 1ns / 1ps

module TestPattern_Standard(
    input  wire        clk,
    input  wire        rst_n,
    input  wire [1:0]  pattern_sel, // 00:全0 01:全1 10:交替 11:递增
    output reg  [31:0] test_pattern
);

// 测试模式参数
localparam PATTERN_ALL_ZERO  = 2'b00;
localparam PATTERN_ALL_ONE   = 2'b01;
localparam PATTERN_ALTERNATE = 2'b10;
localparam PATTERN_INCREMENT = 2'b11;

reg [31:0] counter;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        test_pattern <= 32'h0;
        counter <= 32'h0;
    end else begin
        case (pattern_sel)
            PATTERN_ALL_ZERO:  test_pattern <= 32'h0000_0000;
            PATTERN_ALL_ONE:   test_pattern <= 32'hFFFF_FFFF;
            PATTERN_ALTERNATE: test_pattern <= ~test_pattern;
            PATTERN_INCREMENT: begin
                test_pattern <= counter;
                counter <= counter + 1;
            end
        endcase
    end
end

// 自动验证逻辑
reg [31:0] expected;
always @(*) begin
    case (pattern_sel)
        PATTERN_ALL_ZERO:  expected = 32'h0;
        PATTERN_ALL_ONE:   expected = 32'hFFFF_FFFF;
        PATTERN_ALTERNATE: expected = ~test_pattern;
        PATTERN_INCREMENT: expected = counter;
    endcase
end

wire error_flag = (test_pattern != expected);

endmodule
