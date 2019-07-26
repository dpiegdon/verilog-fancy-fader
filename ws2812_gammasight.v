`default_nettype none

// apply some kind of gamma-correction so colors get more saturated
// returns in^2 / 2^8
module ws2812_gammasight(input wire [7:0] in, output wire [7:0] out);

	//wire [15:0] square = in*in;
	//assign out = square[15:8];
	assign out = in;

endmodule

