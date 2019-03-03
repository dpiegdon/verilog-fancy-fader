`default_nettype none

module top(input wire CLK, output wire J1_7, output wire J1_8, output wire J1_9, output wire J1_10);

	localparam LEDS=11;
	localparam INTERPOLATIONS=4;
	// NOTE: INTERPOLATIONS better be a power-of-two.
	localparam MILESTONES=$rtoi($ceil((LEDS*1.0)/INTERPOLATIONS)) + 1;
	// NOTE the +1 at the end of MILESTONES: avoids index-error for milestone_color_next.
	localparam COLORBITS=8*3*MILESTONES;

	reg holdoff = 0;

	// store for colors, addressed via [COLOR][rgb][bit].
	reg [COLORBITS-1:0] colors;

	reg [$clog2(INTERPOLATIONS):0] start_interpolation;

	reg [$clog2(LEDS):0] current_led;
	reg [$clog2(MILESTONES):0] current_milestone;
	reg [$clog2(INTERPOLATIONS):0] current_interpolation;
	reg [2:0] current_rgb;

	wire trigger;
	assign trigger = (0 != holdoff);
	wire data_request;
	wire [7:0] color_now_postgamma;
	ws2812_output ws2812(CLK, 0, trigger, color_now_postgamma, !holdoff, data_request, J1_10);

	wire [7:0] milestone_color_prev;
	assign milestone_color_prev = colors[ (current_milestone+0)*current_rgb+7 : (current_milestone+0)*current_rgb ];
	wire [7:0] milestone_color_next;
	assign milestone_color_next = colors[ (current_milestone+1)*current_rgb+7 : (current_milestone+1)*current_rgb ];
	wire [7:0] color_now;
	assign color_now = (milestone_color_prev*current_interpolation + milestone_color_prev*(INTERPOLATIONS-current_interpolation)) / INTERPOLATIONS;
	gammasight gammasight(color_now, color_now_postgamma);

	wire [7:0] random;
	randomized_lfsr_weak randomized_lfsr_weak(CLK, 0, random);

	always @(posedge CLK) begin
		if(data_request) begin
			if(holdoff) begin
				holdoff <= holdoff-1;
			end else begin
				if(2 > current_rgb) begin
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
						holdoff <= 1;
						current_led <= 0;
						current_milestone <= 0;
						if(INTERPOLATIONS-1 > start_interpolation) begin
							start_interpolation <= start_interpolation+1;
							current_interpolation <= start_interpolation+1;
						end else begin
							start_interpolation <= 0;
							current_interpolation <= 0;
							colors[COLORBITS-1:24] <= { colors[COLORBITS-1-24:0], random, random, random };
							// FIXME random is 8' but we need 24'
						end
					end
				end
			end
		end
	end

endmodule

// multiplier ahead. needs a LOT of logic.
module gammasight(input wire [7:0] in, output wire [7:0] out);
	wire [15:0] square = in*in;
	assign out = square[15:8];
endmodule

