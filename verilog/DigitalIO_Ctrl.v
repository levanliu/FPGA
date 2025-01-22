module DigitalIO_Ctrl(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        config_en,
    input  wire [15:0] config_data,
    output reg  [31:0] dut_dio
);

reg [31:0] dio_reg;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        dio_reg <= 32'h0;
    end else if (config_en) begin
        // 根据配置设置I/O方向及电平
        case (config_data[15:14])
            2'b00: begin
                dio_reg <= 32'hZZZZ_ZZZZ; // 高阻态（使用Z字符需用十六进制格式）
            end
            2'b01: begin
                dio_reg <= 32'h0000_0000; // 输出低
            end
            2'b10: begin
                dio_reg <= 32'hFFFF_FFFF; // 输出高
            end
            2'b11: begin
                dio_reg <= {16'h0, config_data[13:0], 2'b00}; // 自定义模式
            end
        endcase
    end
end

// 直接输出寄存器值，实际设计中需要根据工艺库添加三态控制
assign dut_dio = dio_reg;

endmodule
