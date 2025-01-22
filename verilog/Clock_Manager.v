module Clock_Manager(
    input  wire clk_in,     // 100MHz main clock
    input  wire rst_n,      // Reset (active low)
    output wire clk_out,    // System sync clock
    output reg  dut_clk,    // DUT work clock
    output reg  adc_clk,    // ADC sample clock
    output reg [3:0] dut_clk_counter,  // Debug signals
    output reg [2:0] adc_clk_counter   // Debug signals
);


// System clock output (50MHz)
assign clk_out = dut_clk_counter[3]; // 100MHz / 2^1 = 50MHz

// Initialize registers
initial begin
    dut_clk = 0;
    adc_clk = 0;
    dut_clk_counter = 0;
    adc_clk_counter = 0;
end

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
