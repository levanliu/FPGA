module TestSystem_Top(
    input  wire         clk,         // 主时钟（如100MHz）
    input  wire         rst_n,       // 异步复位（低有效）
    // PC通信接口
    input  wire         pc_cmd_valid,// PC命令有效
    input  wire [7:0]   pc_cmd_data, // PC命令数据（如配置参数）
    output wire         pc_ack,      // 命令确认

    // 添加VCD波形记录
    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars(0, TestSystem_Top);
    end
    // DUT数字接口
    output wire [31:0]  dut_dio,     // 数字I/O输出
    input  wire [15:0]  dut_adc_in,  // 模拟输入（来自ADC）
    output wire [15:0]  dut_dac_out, // 模拟输出（到DAC）
    // 辅助接口
    output wire         clk_out,     // 同步时钟输出
    output wire         power_en,    // 电源使能
    // 测试控制信号
    input  wire [1:0]   test_mode,   // 测试模式选择
    input  wire [31:0]  max_cycles   // 最大测试循环次数
);

// 内部信号定义
wire [31:0] config_data;
wire        config_en;
wire [15:0] adc_data;
wire        adc_ready;
wire [15:0] dac_cmd;
wire [15:0] error_count;    // 错误计数信号
wire        test_done;      // 新增测试完成标志
wire [31:0] min_latency;    // 新增统计信号
wire [31:0] max_latency;
wire [31:0] average_latency;
wire [31:0] throughput;

// 配置解析模块
ConfigParser u_ConfigParser (
    .clk(clk),
    .rst_n(rst_n),
    .pc_cmd_valid(pc_cmd_valid),
    .pc_cmd_data(pc_cmd_data),
    .config_en(config_en),
    .config_data(config_data),
    .pc_ack(pc_ack)
);

// 数字I/O控制器
DigitalIO_Ctrl u_DigitalIO (
    .clk(clk),
    .rst_n(rst_n),
    .config_en(config_en),
    .config_data(config_data[15:0]),
    .dut_dio(dut_dio)
);

// ADC接口模块
ADC_Interface u_ADC (
    .clk(clk),
    .rst_n(rst_n),
    .adc_in(dut_adc_in),
    .adc_data(adc_data),
    .adc_ready(adc_ready)
);

// DAC接口模块
DAC_Interface u_DAC (
    .clk(clk),
    .rst_n(rst_n),
    .dac_cmd(dac_cmd),
    .dac_out(dut_dac_out)
);

// 主测试状态机
Test_FSM u_FSM (
    .clk(clk),
    .rst_n(rst_n),
    .config_en(config_en),
    .adc_data(adc_data),
    .adc_ready(adc_ready),
    .test_mode(test_mode),       // 添加测试模式输入
    .max_cycles(max_cycles),    // 连接顶层输入信号
    .dac_cmd(dac_cmd),
    .clk_out(clk_out),
    .power_en(power_en),
    .error_count(error_count),
    .test_done(test_done)
);

// 测试向量存储
reg [7:0] test_vectors [0:1023];
reg [9:0] vector_addr;

// 结果分析器
Result_Analyzer u_Analyzer(
    .clk(clk),
    .rst_n(rst_n),
    .dut_response({adc_data, dut_dio[15:0]}),
    .expected_data({24'h0, test_vectors[vector_addr]}),
    .result_valid(adc_ready),
    .error_count(error_count),
    .statistics({min_latency, max_latency, average_latency, throughput})
);

// 时钟管理模块
Clock_Manager u_ClockGen(
    .clk_in(clk),
    .rst_n(rst_n),
    .clk_out(clk_out),
    .dut_clk(dut_clk),
    .adc_clk(adc_clk),
    .dut_clk_counter(),  // 调试信号
    .adc_clk_counter()   // 调试信号
);

endmodule
