module FFT_8point (
    input  wire         clk,
    input  wire         rst_n,
    input  wire         start,
    input  wire [15:0]  in_real [0:7], // 输入实部
    output reg  [15:0]  out_real[0:7], // 输出实部
    output reg  [15:0]  out_imag[0:7], // 输出虚部
    output reg          done
);

// 旋转因子预存（Q15格式）
localparam [15:0] W0_real = 16'h7FFF; // 1.0
localparam [15:0] W0_imag = 16'h0000;
localparam [15:0] W1_real = 16'h5A82; // cos(π/4) ≈ 0.7071
localparam [15:0] W1_imag = 16'hA57E; // -sin(π/4) ≈ -0.7071

reg [2:0] stage;
reg [2:0] step;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        done <= 0;
        stage <= 0;
        step <= 0;
    end else begin
        case (stage)
            0: begin // 初始化
                if (start) begin
                    stage <= 1;
                    step <= 0;
                end
            end
            1: begin // 第一级蝶形运算
                // 示例：计算第0和第4点的蝶形
                out_real[0] <= in_real[0] + in_real[4];
                out_imag[0] <= 0;
                out_real[4] <= in_real[0] - in_real[4];
                out_imag[4] <= 0;
                // ...（其他蝶形计算）
                step <= step + 1;
                if (step == 3) stage <= 2;
            end
            2: begin // 第二级蝶形运算（含旋转因子）
                // 示例：计算第0和第2点
                out_real[0] <= out_real[0] + (out_real[2] * W0_real - out_imag[2] * W0_imag)>>>15;
                out_imag[0] <= out_imag[0] + (out_real[2] * W0_imag + out_imag[2] * W0_real)>>>15;
                // ...（其他蝶形计算）
                step <= step + 1;
                if (step == 3) stage <= 3;
            end
            3: begin // 第三级蝶形运算
                // ...（类似步骤）
                done <= 1;
                stage <= 0;
            end
        endcase
    end
end

endmodule