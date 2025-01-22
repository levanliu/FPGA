module I2C_Master #(
    parameter CLK_DIV = 100  // 分频系数（I2C_SCL频率 = clk/(2*CLK_DIV)）
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        start,      // 启动传输
    input  wire [6:0]  slave_addr, // 从机地址
    input  wire        rw,         // 0:写, 1:读
    input  wire [7:0]  tx_data,    // 发送数据
    output reg  [7:0]  rx_data,    // 接收数据
    output reg         ack_error,  // ACK错误标志
    output reg         busy,
    // I2C物理接口（需外部上拉电阻）
    inout  wire        sda,
    output wire        scl
);

reg [3:0]  state;
reg [15:0] clk_cnt;
reg [7:0]  shift_reg;
reg [2:0]  bit_cnt;
reg        sda_out;
reg        scl_out;
reg        sda_oe;   // SDA输出使能

assign scl = (scl_out) ? 1'b0 : 1'bz;  // 开漏输出
assign sda = (sda_oe) ? sda_out : 1'bz;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state     <= 4'd0;
        scl_out   <= 1'b1;
        sda_oe    <= 1'b0;
        busy      <= 1'b0;
        ack_error <= 1'b0;
    end else begin
        case (state)
            0: begin // 空闲
                if (start) begin
                    busy    <= 1'b1;
                    clk_cnt <= 0;
                    state   <= 1;
                end
            end
            1: begin // 产生START条件（SDA在SCL高时变低）
                if (clk_cnt == CLK_DIV-1) begin
                    sda_oe  <= 1'b1;
                    sda_out <= 1'b0;
                    clk_cnt <= 0;
                    state   <= 2;
                end else begin
                    clk_cnt <= clk_cnt + 1;
                end
            end
            2: begin // 发送地址+rw位
                if (clk_cnt == CLK_DIV-1) begin
                    clk_cnt <= 0;
                    scl_out <= ~scl_out;
                    if (scl_out) begin
                        if (bit_cnt < 8) begin
                            sda_out <= (bit_cnt == 0) ? slave_addr[6] : 
                                      (bit_cnt == 7) ? rw : shift_reg[7];
                            shift_reg <= {shift_reg[6:0], 1'b0};
                            bit_cnt   <= bit_cnt + 1;
                        end else begin
                            sda_oe  <= 1'b0; // 释放SDA以检测ACK
                            bit_cnt <= 0;
                            state   <= 3;
                        end
                    end
                end else begin
                    clk_cnt <= clk_cnt + 1;
                end
            end
            3: begin // 检测ACK
                if (scl_out && sda) begin
                    ack_error <= 1'b1; // 未收到ACK
                end
                state <= 4; // 进入数据传输阶段
            end
            // ...（后续数据传输状态类似，限于篇幅省略部分代码）
            15: begin // 产生STOP条件（SDA在SCL高时变高）
                if (clk_cnt == CLK_DIV-1) begin
                    sda_oe  <= 1'b1;
                    sda_out <= 1'b1;
                    busy    <= 1'b0;
                    state   <= 0;
                end else begin
                    clk_cnt <= clk_cnt + 1;
                end
            end
        endcase
    end
end

endmodule