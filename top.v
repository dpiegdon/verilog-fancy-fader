`default_nettype none

module top(input wire CLK, output wire J1_8, output wire J1_9, output wire J1_10);

	localparam LEDS=40;
	// NOTE: INTERPOLATIONS better be a power-of-two.
	localparam INTERPOLATIONS=8;
	// NOTE the +1 at the end of MILESTONES: avoids index-error for milestone_color_next.
	localparam MILESTONES=$rtoi($ceil((LEDS*1.0)/INTERPOLATIONS)) + 1;
	localparam COLORBITS=8*3*MILESTONES;

	localparam HOLDOFF_MAX=1200000;

	wire rst = 0;

	reg [$clog2(HOLDOFF_MAX) : 0] holdoff = 0;

	// store for colors, addressed via [COLOR][rgb][bit].
	reg [COLORBITS-1:0] colors = 0;

	reg [$clog2(INTERPOLATIONS-1):0] start_interpolation = 0;

	reg [$clog2(LEDS-1):0] current_led = 0;
	reg [$clog2(MILESTONES-1):0] current_milestone = 0;
	reg [$clog2(INTERPOLATIONS-1):0] current_interpolation = 0;
	reg [$clog2(3-1):0] current_rgb = 0;

	wire trigger = (0 == holdoff);
	wire data_request;
	wire [7:0] color_now_postgamma;
	ws2812_output ws2812(CLK, rst, trigger, color_now_postgamma, trigger, data_request, J1_10);

	wire [$clog2(COLORBITS-1):0] index_prev = current_milestone * 8*3 + current_rgb * 8;
	wire [$clog2(COLORBITS-1):0] index_next = index_prev + 8*3;
	wire [7:0] milestone_color_prev = colors[ index_prev+7 : index_prev ];
	wire [7:0] milestone_color_next = colors[ index_next+7 : index_next ];
	wire [7:0] color_now = (milestone_color_next*current_interpolation + milestone_color_prev*(INTERPOLATIONS-current_interpolation)) / INTERPOLATIONS;
	gammasight gammasight(color_now, color_now_postgamma);

	wire [15:0] random;
	randomized_lfsr_weak
		#(.WIDTH('d16), .INIT_VALUE(16'b1010_1100_1110_0001), .FEEDBACK(16'b0000_0000_0010_1101))
		randomized_lfsr_weak(.clk(CLK), .rst(rst), .out(random));

	assign J1_9 = trigger;
	assign J1_8 = data_request;

	always @(posedge CLK) begin
		if(rst) begin
			holdoff <= 0;
			colors <= 0;
			start_interpolation <= 0;
			current_led <= 0;
			current_milestone <= 0;
			current_interpolation <= 0;
			current_rgb <= 0;
		end else if(data_request) begin
			if(holdoff) begin
				holdoff <= holdoff-1;
			end else if(2 > current_rgb) begin
				current_rgb <= current_rgb+1;
			end else begin
				current_rgb <= 0;
				if(LEDS-1 > current_led) begin
					current_led <= current_led + 1;
					if(INTERPOLATIONS-1 > current_interpolation) begin
						current_interpolation <= current_interpolation+1;
					end else begin
						current_interpolation <= 0;
						current_milestone <= current_milestone+1;
					end
				end else begin
					holdoff <= HOLDOFF_MAX;
					current_led <= 0;
					current_milestone <= 0;
					if(INTERPOLATIONS-1 > start_interpolation) begin
						start_interpolation <= start_interpolation+1;
						current_interpolation <= start_interpolation+1;
					end else begin
						start_interpolation <= 0;
						current_interpolation <= 0;
						colors <= { {random[14:10], 3'b0, random[9:5], 3'b0, random[4:0], 3'b0},
								colors[COLORBITS-1 : 8*3]};
					end
				end
			end
		end else begin
			if(holdoff) begin
				holdoff <= holdoff-1;
			end
		end
	end

endmodule

// multiplier ahead. needs a LOT of logic.
module gammasight(input wire [7:0] in, output wire [7:0] out);
	wire [15:0] square = in*in;
	assign out = square[15:8];
endmodule

