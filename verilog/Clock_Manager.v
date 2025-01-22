module Clock_Manager(
    input  wire clk_in,     // 100MHz主时钟
    input  wire rst_n,
    output wire clk_out,    // 系统同步时钟
    output reg  dut_clk,    // DUT工作时钟
    output reg  adc_clk     // ADC采样时钟
);

reg [3:0] dut_clk_counter;
reg [2:0] adc_clk_counter;

// 系统时钟输出（50MHz）
assign clk_out = dut_clk_counter[3]; // 100MHz / 2^1 = 50MHz

always @(posedge clk_in or negedge rst_n) begin
    if (!rst_n) begin
        dut_clk_counter <= 0;
        dut_clk <= 0;
    end else begin
        // DUT时钟生成（25MHz）
        if (dut_clk_counter == 4'd3) begin
            dut_clk <= ~dut_clk;
            dut_clk_counter <= 0;
        end else begin
            dut_clk_counter <= dut_clk_counter + 1;
        end

        // ADC时钟生成（10MHz）
        if (adc_clk_counter == 3'd4) begin
            adc_clk <= ~adc_clk;
            adc_clk_counter <= 0;
        end else begin
            adc_clk_counter <= adc_clk_counter + 1;
        end
    end
end

endmodule
