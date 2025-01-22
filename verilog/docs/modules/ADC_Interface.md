# ADC_Interface 模块说明书

## 功能概述

- 实现 ADC 数据采集接口
- 控制 ADC 采样时序
- 生成数据有效标志信号

## 状态机流程

```verilog
always @(posedge clk) begin
    case(state)
        3'b000: // 空闲状态
            if (采样触发条件) state <= 3'b001;
        3'b001: // 启动转换
            state <= 3'b010;
        3'b010: // 等待转换完成
            state <= 3'b011;
        3'b011: // 数据锁存
            state <= 3'b100;
        3'b100: // 数据有效
            state <= 3'b000;
    endcase
end
```

## 端口定义

| 信号名称  | 方向   | 位宽 | 描述              |
| --------- | ------ | ---- | ----------------- |
| clk       | input  | 1    | 系统时钟(100MHz)  |
| rst_n     | input  | 1    | 异步复位(低有效)  |
| adc_in    | input  | 16   | ADC 原始输入信号  |
| adc_data  | output | 16   | 同步后的 ADC 数据 |
| adc_ready | output | 1    | 数据有效标志      |

## 时序参数

| 参数名称     | 值   | 说明         |
| ------------ | ---- | ------------ |
| T_sample     | 10ns | 最小采样周期 |
| T_conversion | 50ns | ADC 转换时间 |
| T_hold       | 5ns  | 数据保持时间 |

## 使用注意事项

1. 需配合 Clock_Manager 模块提供 ADC 时钟
2. 数据有效信号应保持至少 2 个时钟周期
3. 输入信号需满足 ADC 器件的建立保持时间要求
