module ConfigParser(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        pc_cmd_valid,
    input  wire [7:0]  pc_cmd_data,
    output reg         config_en,
    output reg  [31:0] config_data,
    output reg         pc_ack
);

reg [1:0] state;
reg [7:0] config_buffer[3:0];

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= 2'b00;
        pc_ack <= 0;
        config_en <= 0;
    end else begin
        case (state)
            2'b00: // 等待命令
                if (pc_cmd_valid) begin
                    config_buffer[0] <= pc_cmd_data;
                    state <= 2'b01;
                    pc_ack <= 1;
                end
            2'b01: // 接收数据字节1
                config_buffer[1] <= pc_cmd_data;
                state <= 2'b10;
            2'b10: // 接收数据字节2
                config_buffer[2] <= pc_cmd_data;
                state <= 2'b11;
            2'b11: // 接收数据字节3
                config_buffer[3] <= pc_cmd_data;
                config_data <= {config_buffer[3], config_buffer[2], 
                               config_buffer[1], config_buffer[0]};
                config_en <= 1;
                state <= 2'b00;
                pc_ack <= 0;
        endcase
    end
end

endmodule