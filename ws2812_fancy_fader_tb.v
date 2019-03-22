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
	
	ws2812_fancy_fader #(.HOLDOFF_TIME(4)) dut(clk[0], rst, random, data_request, trigger, color_now);

	always #1 clk = clk+1;

	integer k;
	integer i;

	initial begin
		$dumpfile("ws2812_fancy_fader_tb.vcd");
		$dumpvars(0, ws2812_fancy_fader_tb);

		clk = 0;
		rst = 1;
		random = 16'haaaa;
		data_request = 0;

		repeat(2) @(negedge clk);

		rst = 0;

		repeat(2) @(negedge clk);

		for(i=0; i<4096; i=i+1) begin
			data_request = 1;
			repeat(1) @(negedge clk);

			data_request = 0;
			repeat(3) @(negedge clk);
		end

		repeat(8) @(negedge clk);

		$finish;
	end

endmodule

