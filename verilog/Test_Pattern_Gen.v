module Test_Pattern_Gen(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        start,
    output reg  [7:0]  parallel_data, // 并行加载数据
    output reg         serial_data    // 串行输入数据（右移/左移）
);

reg [3:0] state;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= 0;
        parallel_data <= 8'h00;
        serial_data <= 0;
    end else if (start) begin
        case (state)
            0: begin // 并行加载测试数据
                parallel_data <= 8'hAA; // 10101010
                state <= 1;
            end
            1: begin // 右移模式，输入序列1
                serial_data <= 1'b1;
                state <= 2;
            end
            2: begin // 右移模式，输入序列0
                serial_data <= 1'b0;
                if (parallel_data == 8'h55) state <= 3;
            end
            3: begin // 左移模式测试
                parallel_data <= 8'h55; // 01010101
                state <= 4;
            end
            4: begin // 左移输入序列
                serial_data <= 1'b1;
                if (parallel_data == 8'hAA) begin
                    state <= 5;
                end
            end
            5: begin // 混合模式测试
                parallel_data <= 8'hFF;
                serial_data <= 1'b0;
                if (parallel_data == 8'h7F) begin
                    state <= 0;
                end
            end
        endcase
    end
end
endmodule
