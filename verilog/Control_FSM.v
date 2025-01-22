module Control_FSM(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        frame_valid, // 来自帧解析器的有效信号
    input  wire [7:0]  cmd_type,    // PC下发的命令类型
    output reg         spi_start,   // 触发SPI传输
    output reg         i2c_start,   // 触发I2C传输
    output reg         dut_en       // DUT使能信号
);

reg [3:0] state;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= 0;
        spi_start <= 0;
        i2c_start <= 0;
        dut_en <= 0;
    end else begin
        case (state)
            0: // 等待命令
                if (frame_valid) begin
                    case (cmd_type)
                        8'h01: state <= 1; // SPI命令
                        8'h02: state <= 2; // I2C命令
                        8'h03: dut_en <= 1; // 使能DUT
                    endcase
                end
            1: // 启动SPI
                begin
                    spi_start <= 1;
                    state <= 0;
                end
            2: // 启动I2C
                begin
                    i2c_start <= 1;
                    state <= 0;
                end
        endcase
    end
end
endmodule