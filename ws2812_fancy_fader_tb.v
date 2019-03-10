`default_nettype none
`timescale 1ns / 1ps

// testbench for ws2812_fancy_fader
module ws2812_fancy_fader_tb();

	reg [20:0] clk;
	reg rst;
	reg [15:0] random;
	reg data_request;

	wire trigger;
	wire [7:0] color_now;
	
	ws2812_fancy_fader dut(clk[0], rst, random, data_request, trigger, color_now);

	always #1 clk = clk+1;

	initial begin
		clk = 0;
		rst = 0;
		random = 0;
		data_request = 0;
	end

endmodule

