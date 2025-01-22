module Result_Checker(
    input  wire        clk,
    input  wire        rst_n,
    input  wire [7:0]  dut_output, // 来自74299的并行输出
    output reg         test_pass
);

reg [7:0] expected;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        expected <= 8'h00;
        test_pass <= 0;
    end else begin
        case (expected)
            8'hAA: expected <= 8'hD5; // 右移后的预期值
            8'hD5: expected <= 8'h6A;
            // ... 更新预期值
        endcase
        test_pass <= (dut_output == expected);
    end
end
endmodule