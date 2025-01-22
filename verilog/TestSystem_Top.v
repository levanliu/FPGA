module TestSystem_Top(
    input  wire         clk,         // Main clock (e.g. 100MHz)
    input  wire         rst_n,       // Async reset (active low)
    // PC interface
    input  wire         pc_cmd_valid,// PC command valid
    input  wire [7:0]   pc_cmd_data, // PC command data
    output wire         pc_ack,      // Command acknowledge
    // DUT digital interface
    output wire [31:0]  dut_dio,     // Digital I/O
    input  wire [15:0]  dut_adc_in,  // ADC input
    output wire [15:0]  dut_dac_out, // DAC output
    // Auxiliary interface
    output wire         clk_out,     // Clock output
    output wire         power_en,    // Power enable
    // Test control
    input  wire [1:0]   test_mode,   // Test mode select
    input  wire [31:0]  max_cycles   // Max test cycles
);

// Add VCD waveform dumping
initial begin
    $dumpfile("waveform.vcd");
    $dumpvars(0, TestSystem_Top);
end

// VCD Dumping control
initial begin
    if ($test$plusargs("DUMP_VCD")) begin
        $dumpfile("waveform.vcd");
        $dumpvars(0, TestSystem_Top);
    end
end

// Internal signals
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
    .test_done(test_done),
    .dump_en(test_mode[0])  // 使用test_mode[0]作为VCD dump使能信号
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
