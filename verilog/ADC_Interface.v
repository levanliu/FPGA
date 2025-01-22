module ADC_Interface(
    input  wire        clk,
    input  wire        rst_n,
    input  wire [15:0] adc_in,
    output reg  [15:0] adc_data,
    output reg         adc_ready
);

reg [2:0] state;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= 3'b000;
        adc_ready <= 0;
    end else begin
        case (state)
            3'b000: begin // 启动采样
                adc_ready <= 0;
                state <= 3'b001;
            end
            3'b001: state <= 3'b010; // 等待转换
            3'b010: state <= 3'b011;
            3'b011: begin
                adc_data <= adc_in;  // 捕获数据
                adc_ready <= 1;
                state <= 3'b100;
            end
            3'b100: begin
                adc_ready <= 0;
                state <= 3'b000;
            end
        endcase
    end
end

endmodule