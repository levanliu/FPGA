module Frame_Parser(
    input  wire        clk,
    input  wire        rst_n,
    input  wire [7:0]  rx_data,
    input  wire        rx_valid,
    output reg  [7:0]  cmd_type,
    output reg  [15:0] data_len,
    output reg  [7:0]  payload [0:255],
    output reg         frame_valid
);

reg [3:0] state;
reg [15:0] byte_cnt;
reg [31:0] crc_calc;
reg [7:0]  test_vectors[0:1023]; // 测试向量缓冲区
reg [9:0]  vector_addr;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= 4'b0000;
        frame_valid <= 0;
        vector_addr <= 0;
    end else begin
        case (state)
            0: begin // 等待起始符
                if (rx_valid && rx_data == 8'hAA) begin
                    crc_calc <= 32'hFFFFFFFF;
                    state <= 1;
                end
            end
            1: begin // 读取协议版本
                if (rx_valid) begin
                    case (rx_data[7:6])
                        2'b00: protocol_ver <= 1; // 基础协议
                        2'b01: protocol_ver <= 2; // 扩展协议
                        default: state <= 0; // 无效协议
                    end
                    cmd_type <= rx_data[5:0];
                    crc_calc <= crc32_update(crc_calc, rx_data);
                    state <= 2;
                end
            end
            2: // 读取数据长度高字节
                if (rx_valid) begin
                    data_len[15:8] <= rx_data;
                    state <= 3;
                end
            3: // 读取数据长度低字节
                if (rx_valid) begin
                    data_len[7:0] <= rx_data;
                    byte_cnt <= 0;
                    state <= 4;
                end
            4: // 读取数据负载
                if (rx_valid) begin
                    payload[byte_cnt] <= rx_data;
                    byte_cnt <= byte_cnt + 1;
                    if (byte_cnt == data_len-1) state <= 5;
                end
            5: begin // 校验CRC
                // CRC32校验完整实现
                function automatic [31:0] crc32_update(input [31:0] crc, input [7:0] data);
                reg [31:0] crc_temp;
                integer i;
                begin
                    crc_temp = crc ^ {24'h0, data};
                    for (i=0; i<8; i=i+1) begin
                        if (crc_temp[31]) begin
                            crc_temp = {crc_temp[30:0], 1'b0} ^ 32'hEDB88320;
                        end else begin
                            crc_temp = {crc_temp[30:0], 1'b0};
                        end
                    end
                    crc32_update = crc_temp;
                end
                endfunction

                // 添加CRC校验结果处理
                if (crc_calc == ~{payload[data_len+3], payload[data_len+2], 
                                 payload[data_len+1], payload[data_len]}) begin
                    frame_valid <= 1;
                    // 存储测试向量时增加边界检查
                    if (cmd_type == 6'h01 && (vector_addr + data_len) <= 1024) begin
                        for (integer i=0; i<data_len; i=i+1) begin
                            test_vectors[vector_addr+i] <= payload[i];
                        end
                        vector_addr <= vector_addr + data_len;
                    end
                end else begin
                    $display("CRC Error: Expected %h, Got %h", 
                            ~{payload[data_len+3], payload[data_len+2], 
                             payload[data_len+1], payload[data_len]}, 
                            crc_calc);
                end

                if (crc_calc == ~{payload[data_len+1], payload[data_len]}) begin
                    frame_valid <= 1;
                    // 存储测试向量
                    if (cmd_type == 6'h01) begin
                        test_vectors[vector_addr+:data_len] <= payload[0+:data_len];
                        vector_addr <= vector_addr + data_len;
                    end
                end
                state <= 6;
            end
            6: begin // 发送确认
                pc_ack <= 1;
                state <= 0;
            end
        endcase
    end
end
endmodule
