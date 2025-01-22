# TestSystem_Top 模块说明书

## 功能概述

- FPGA 测试系统的顶层集成模块
- 协调各子模块的工作流程
- 实现 PC 指令解析、测试模式控制、结果统计

## 端口定义

| 信号名称     | 方向   | 位宽 | 描述              |
| ------------ | ------ | ---- | ----------------- |
| clk          | input  | 1    | 主时钟(100MHz)    |
| rst_n        | input  | 1    | 异步复位(低有效)  |
| pc_cmd_valid | input  | 1    | PC 指令有效信号   |
| pc_cmd_data  | input  | 8    | PC 指令数据       |
| dut_dio      | output | 32   | DUT 数字 I/O 接口 |
| dut_adc_in   | input  | 16   | ADC 输入信号      |
| dut_dac_out  | output | 16   | DAC 输出信号      |
| test_mode    | input  | 2    | 测试模式选择      |

## 子模块清单

```verilog
ConfigParser        // PC指令解析
DigitalIO_Ctrl      // 数字I/O控制
ADC_Interface       // ADC数据采集接口
DAC_Interface       // DAC控制接口
Test_FSM            // 主测试状态机
Result_Analyzer     // 结果统计分析
Clock_Manager       // 时钟管理模块
```

## 关键功能说明

1. 支持三种测试模式：

   - 模式 0：基本功能测试
   - 模式 1：性能压力测试
   - 模式 2：极限参数测试

2. 波形记录功能：

```verilog
initial begin
    $dumpfile("waveform.vcd");
    $dumpvars(0, TestSystem_Top);  // 记录顶层信号
    $dumpvars(1, TestSystem_Top.u_FSM);  // 记录状态机信号
end
```

3. 实时统计指标：

- 最小/最大/平均延迟
- 系统吞吐量
- 错误计数
