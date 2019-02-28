`default_nettype none

module top(input wire CLK,
	input wire J1_3, input wire J1_4,
	input wire J1_5, input wire J1_6,
	input wire J1_7, input wire J1_8,
	output wire J1_9, output wire J1_10,
	input wire J3_10, input wire J3_9,
	input wire J3_8, input wire J3_7,
	input wire J3_6, input wire J3_5,
	input wire J3_4, input wire J3_3
);

	wire [7:0] data_in;
	assign data_in = {J3_10, J3_9, J3_8, J3_7, J3_6, J3_5, J3_4, J3_3};

	ws2812_output ws2812(
		// to:
		.clk(CLK), .rst(0), .trigger(!J1_4), .data_in(data_in), .data_valid(1),
		// from:
		.data_request(J1_9), .out(J1_10)
	);

endmodule

