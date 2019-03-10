`default_nettype none

module top(input wire CLK, output wire J1_8, output wire J1_9, output wire J1_10);

	wire rst = 0;

	wire [15:0] random;
	randomized_lfsr_weak
		#(.WIDTH('d16), .INIT_VALUE(16'b1010_1100_1110_0001), .FEEDBACK(16'b0000_0000_0010_1101))
		randomized_lfsr_weak(.clk(CLK), .rst(rst), .out(random));

	wire [7:0] color_now;
	wire trigger;
	wire data_request;
	ws2812_fancy_fader fader(CLK, rst, random, data_request, trigger, color_now);

	wire [7:0] color_now_postgamma;
	ws2812_gammasight gammasight(color_now, color_now_postgamma);

	ws2812_output_shifter shifter(CLK, rst, trigger, color_now_postgamma, trigger, data_request, J1_10);

	assign J1_9 = trigger;
	assign J1_8 = data_request;

endmodule

