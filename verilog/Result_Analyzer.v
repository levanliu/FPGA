module Result_Analyzer(
    input  wire        clk,
    input  wire        rst_n,
    input  wire [31:0] dut_response,
    input  wire [31:0] expected_data,
    input  wire        result_valid,
    output reg  [15:0] error_count,
    output wire [127:0] statistics
);

reg [31:0] total_latency;
reg [31:0] total_samples;
reg [31:0] min_latency;
reg [31:0] max_latency;
reg [31:0] latency_buffer[0:31];
reg [5:0]  write_ptr;
reg [31:0] sample_counter;
wire [31:0] average_latency;
wire [31:0] throughput;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        error_count <= 0;
        total_latency <= 0;
        total_samples <= 0;
        min_latency <= 32'hFFFFFFFF;
        max_latency <= 0;
        write_ptr <= 0;
        sample_counter <= 0;
    end else if (result_valid) begin
        // 错误计数
        if (dut_response !== expected_data) 
            error_count <= error_count + 1;
            
        // 延迟统计
        if (latency_buffer[write_ptr] < min_latency)
            min_latency <= latency_buffer[write_ptr];
        if (latency_buffer[write_ptr] > max_latency)
            max_latency <= latency_buffer[write_ptr];
            
        total_latency <= total_latency + latency_buffer[write_ptr];
        total_samples <= total_samples + 1;
        write_ptr <= write_ptr + 1;
        sample_counter <= sample_counter + 1;
    end
end

assign average_latency = (total_samples != 0) ? total_latency / total_samples : 0;
assign throughput = sample_counter * 1000 / (total_latency + 1); // 单位：操作/秒

assign statistics = {
    min_latency[31:16],  // 127:112
    max_latency[31:16],  // 111:96
    average_latency[31:16], // 95:80
    throughput[31:16],   // 79:64
    min_latency[15:0],   // 63:48
    max_latency[15:0],   // 47:32
    average_latency[15:0], // 31:16
    throughput[15:0]     // 15:0
};

endmodule
