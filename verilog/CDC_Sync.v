// 异步信号同步化（双触发器法）
module CDC_Sync(
    input  wire clk_dest,
    input  wire async_signal,
    output reg  sync_signal
);
reg sync_reg;
always @(posedge clk_dest) begin
    sync_reg   <= async_signal;
    sync_signal <= sync_reg;
end
endmodule