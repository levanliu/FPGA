module DAC_Interface(
    input  wire        clk,
    input  wire        rst_n,
    input  wire [15:0] dac_cmd,
    output reg  [15:0] dac_out
);

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        dac_out <= 16'h0000;
    end else begin
        dac_out <= dac_cmd;  // 直接输出DAC命令
    end
end

endmodule