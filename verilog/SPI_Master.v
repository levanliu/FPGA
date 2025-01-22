module SPI_Master #(
    parameter CLK_DIV = 8,    // 主时钟分频系数（SPI_SCK频率 = clk/(2*CLK_DIV)）
    parameter CPOL = 0,       // 时钟极性（0: SCK空闲低电平）
    parameter CPHA = 0        // 时钟相位（0: 数据在第一个边沿采样）
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        start,     // 传输启动信号
    input  wire [7:0]  tx_data,   // 发送数据
    output reg  [7:0]  rx_data,   // 接收数据
    output reg         busy,      // 传输状态指示
    // SPI物理接口
    output reg         spi_sck,
    output reg         spi_mosi,
    input  wire        spi_miso,
    output reg         spi_cs_n
);

reg [2:0]  state;
reg [7:0]  tx_reg;
reg [7:0]  rx_reg;
reg [3:0]  bit_cnt;
reg [15:0] clk_cnt;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state    <= 3'd0;
        spi_cs_n <= 1'b1;
        spi_sck  <= CPOL;
        busy     <= 1'b0;
    end else begin
        case (state)
            0: begin // 空闲状态
                if (start) begin
                    spi_cs_n <= 1'b0;
                    tx_reg   <= tx_data;
                    busy     <= 1'b1;
                    clk_cnt  <= 0;
                    bit_cnt  <= 0;
                    state    <= 1;
                end
            end
            1: begin // 生成SCK时钟
                if (clk_cnt == CLK_DIV-1) begin
                    clk_cnt <= 0;
                    spi_sck <= ~spi_sck;
                    if (spi_sck != CPOL) begin // 在有效边沿采样/发送
                        if (CPHA == 0) begin
                            spi_mosi <= tx_reg[7];
                            tx_reg   <= {tx_reg[6:0], 1'b0};
                        end else begin
                            rx_reg   <= {rx_reg[6:0], spi_miso};
                        end
                    end else begin
                        if (CPHA == 1) begin
                            spi_mosi <= tx_reg[7];
                            tx_reg   <= {tx_reg[6:0], 1'b0};
                        end else begin
                            rx_reg   <= {rx_reg[6:0], spi_miso};
                        end
                    end
                    if (bit_cnt == 7) begin
                        state <= 2;
                    end else begin
                        bit_cnt <= bit_cnt + 1;
                    end
                end else begin
                    clk_cnt <= clk_cnt + 1;
                end
            end
            2: begin // 传输结束
                spi_cs_n <= 1'b1;
                spi_sck  <= CPOL;
                rx_data  <= rx_reg;
                busy     <= 1'b0;
                state    <= 0;
            end
        endcase
    end
end

endmodule