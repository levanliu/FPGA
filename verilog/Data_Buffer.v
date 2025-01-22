module Data_Buffer(
    input  wire        clk,
    input  wire        rst_n,
    input  wire [7:0]  data_in,
    input  wire        wr_en,
    input  wire        rd_en,
    output reg [7:0]  data_out,
    output wire        empty,
    output wire        full
);

reg [7:0] mem [0:1023];
reg [10:0] wr_ptr, rd_ptr;

assign empty = (wr_ptr == rd_ptr);
assign full  = (wr_ptr - rd_ptr == 1024);

always @(posedge clk) begin
    if (wr_en && !full)
        mem[wr_ptr] <= data_in;
    if (rd_en && !empty)
        data_out <= mem[rd_ptr];
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        wr_ptr <= 0;
        rd_ptr <= 0;
    end else begin
        if (wr_en && !full) wr_ptr <= wr_ptr + 1;
        if (rd_en && !empty) rd_ptr <= rd_ptr + 1;
    end
end
endmodule
