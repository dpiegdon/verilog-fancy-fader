`default_nettype none

module top(input wire CLK, output wire J1_10);

reg half_clk;
assign J1_10 = half_clk;

always @ (posedge CLK) begin
	half_clk = !half_clk;
end

endmodule

