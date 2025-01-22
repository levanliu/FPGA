module UART_Receiver #(
    parameter BAUD_RATE = 115200,
    parameter CLK_FREQ  = 100_000_000
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        uart_rx,      // 来自PC的串口接收线
    output reg  [7:0]  rx_data,
    output reg         rx_valid
);

// 计算分频系数
localparam CLK_DIV = CLK_FREQ / BAUD_RATE;

reg [15:0]  clk_cnt;
reg [3:0]   bit_cnt;
reg         rx_reg;
reg [7:0]   data_reg;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        clk_cnt  <= 0;
        bit_cnt  <= 0;
        rx_valid <= 0;
    end else begin
        // 检测起始位（下降沿）
        if (!bit_cnt && !rx_reg && uart_rx) begin
            clk_cnt <= CLK_DIV/2; // 对齐到数据位中心
            bit_cnt <= 1;
        end

        if (bit_cnt) begin
            if (clk_cnt == CLK_DIV-1) begin
                clk_cnt <= 0;
                if (bit_cnt < 9) begin
                    data_reg[bit_cnt-1] <= uart_rx; // 采集数据位
                end
                bit_cnt <= bit_cnt + 1;
            end else begin
                clk_cnt <= clk_cnt + 1;
            end

            if (bit_cnt == 9) begin // 停止位
                rx_data  <= data_reg;
                rx_valid <= 1;
                bit_cnt  <= 0;
            end
        end
    end
end
endmodule