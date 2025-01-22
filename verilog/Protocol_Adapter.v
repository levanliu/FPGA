module Protocol_Adapter(
    input  wire        clk,
    input  wire        rst_n,
    input  wire [7:0]  pc_data,  // 来自PC的数据
    input  wire        pc_valid,
    output reg  [31:0] dut_bus,  // 并行总线输出到DUT
    output reg         dut_valid
);

reg [1:0] state;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= 0;
        dut_bus <= 0;
    end else begin
        case (state)
            0: // 接收字节1
                if (pc_valid) begin
                    dut_bus[31:24] <= pc_data;
                    state <= 1;
                end
            1: // 接收字节2
                if (pc_valid) begin
                    dut_bus[23:16] <= pc_data;
                    state <= 2;
                end
            2: // 接收字节3
                if (pc_valid) begin
                    dut_bus[15:8] <= pc_data;
                    state <= 3;
                end
            3: // 接收字节4
                if (pc_valid) begin
                    dut_bus[7:0] <= pc_data;
                    dut_valid <= 1;
                    state <= 0;
                end
        endcase
    end
end
endmodule