module Test_FSM(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        config_en,
    input  wire [15:0] adc_data,
    input  wire        adc_ready,
    input  wire [1:0]  test_mode,    // 测试模式输入
    input  wire [31:0] max_cycles,   // 最大循环次数
    output reg  [15:0] dac_cmd,
    output reg         clk_out,
    output reg         power_en,
    output reg [15:0]  error_count,  // 错误计数
    output reg         test_done,    // Test complete flag
    input  wire        dump_en       // VCD dump enable
);

reg [3:0] state;
reg [31:0] cycle_counter;
reg [15:0] test_pattern;

// Add VCD dumping control
initial begin
    if (dump_en) begin
        $dumpfile("waveform.vcd");
        $dumpvars(0, Test_FSM);
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= 4'h0;
        clk_out <= 0;
        power_en <= 0;
        dac_cmd <= 16'h0000;
    end else begin
        case (state)
            4'h0: begin // 初始化
                power_en <= 1;
                state <= 4'h1;
            end
            4'h1: begin // 发送测试模式
                dac_cmd <= 16'hAAAA; // 示例DAC输出
                state <= 4'h2;
            end
            4'h2: begin // 等待ADC数据
                if (adc_ready) begin
                    test_pattern <= adc_data;
                    state <= 4'h3;
                end
            end
            4'h3: begin // 执行测试模式
                case(test_mode)
                    2'b00: begin // 单次测试
                        dac_cmd <= 16'hAAAA;
                        state <= 4'h4;
                    end
                    2'b01: begin // 连续测试
                        if (cycle_counter < max_cycles) begin
                            dac_cmd <= 16'hAAAA;
                            cycle_counter <= cycle_counter + 1;
                            state <= 4'h4;
                        end else begin
                            test_done <= 1;
                            state <= 4'h5;
                        end
                    end
                    default: state <= 4'h0;
                endcase
            end
            4'h4: begin // 等待响应
                if (adc_ready) begin
                    if (adc_data !== 16'h5555) // 示例校验
                        error_count <= error_count + 1;
                    state <= 4'h3;
                end
            end
            4'h5: begin // 测试完成
                test_done <= 1;
                if (test_mode == 2'b01) begin // 连续模式自动重启
                    cycle_counter <= 0;
                    state <= 4'h1;
                end
            end
        endcase
    end
end

endmodule
