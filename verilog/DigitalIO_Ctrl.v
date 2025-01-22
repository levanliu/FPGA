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
            2'b00: dio_reg <= {32{1'bz}}; // 高阻态
            2'b01: dio_reg <= {32{1'b0}}; // 输出低
            2'b10: dio_reg <= {32{1'b1}}; // 输出高
            2'b11: dio_reg <= config_data[13:0]; // 自定义模式
        endcase
    end
end

assign dut_dio = dio_reg;

endmodule