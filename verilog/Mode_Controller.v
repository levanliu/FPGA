module Mode_Controller(
    input  wire        clk,
    input  wire        rst_n,
    input  wire [1:0]  mode, // 00: Hold, 01:右移, 10:左移, 11:并行加载
    output reg         s0,
    output reg         s1,
    output reg         mr,
    output reg         g1,
    output reg         g2
);

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        {s0, s1, mr, g1, g2} <= 5'b00011; // 默认：复位无效，输出使能
    end else begin
        case (mode)
            2'b00: {s0, s1} <= 2'b00;  // Hold模式
            2'b01: {s0, s1} <= 2'b01;  // 右移
            2'b10: {s0, s1} <= 2'b10;  // 左移
            2'b11: {s0, s1} <= 2'b11;  // 并行加载
        endcase
        mr <= 1'b1;  // 正常操作时保持高电平
        {g1, g2} <= 2'b00; // 输出使能
    end
end
endmodule