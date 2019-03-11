`default_nettype none

// implements fader logic getween random milestones
module ws2812_fancy_fader(input wire clk, input wire rst, input wire [15:0] random, input wire data_request,
		output wire trigger, output reg [7:0] color_now);

	// number of LEDs to be controlled.
	parameter LEDS = 32;
	// number of interpolation steps between uniq random color milestones
	// NOTE: this must be a power of two.
	parameter INTERPOLATIONS = 8;
	// scroll speed. time to wait after all LEDs have been addressed.
	parameter HOLDOFF_TIME = 800000;

	// NOTE the +1 at the end of MILESTONES: avoids index-error for milestone_color_prev.
	localparam MILESTONES = $rtoi($ceil((LEDS*1.0)/INTERPOLATIONS)) + 1;
	localparam COLORBITS = MILESTONES*8*3;

	// possible state
	localparam GET_INDEX_NEXT = 0;
	localparam GET_INDEX_PREV = 1;
	localparam GET_MILESTONES = 2;
	localparam GET_COLOR = 3;
	localparam DELIVER_COLOR = 4;
	localparam HOLDOFF = 5;

	reg [$clog2(HOLDOFF):0] state = GET_INDEX_NEXT;

	// trigger for the WS2812 output block
	assign trigger = (state == DELIVER_COLOR);

	// timeout in between full transmissions to WS2812 strip
	reg [$clog2(HOLDOFF_TIME) : 0] holdoff = 0;

	// store for color milestones
	reg [COLORBITS-1:0] milestones = 0;

	// interpolation step we started at when starting this iteration of
	// the full color strip
	reg [$clog2(INTERPOLATIONS-1):0] start_interpolation = 0;

	// index variables for single run over the full color strip
	reg [$clog2(LEDS-1):0] current_led = 0;
	reg [$clog2(MILESTONES-1):0] forward_milestone = 0;
	reg [$clog2(INTERPOLATIONS-1):0] current_interpolation = 0;
	reg [$clog2(3-1):0] current_rgb = 0;

	// actual output color for the current LED
	reg [$clog2(COLORBITS-1):0] index_next;
	reg [$clog2(COLORBITS-1):0] index_prev;
	reg [7:0] milestone_color_next;
	reg [7:0] milestone_color_prev;

	always @(posedge clk) begin
		if(rst) begin
			state = GET_INDEX_NEXT;
			holdoff = 0;
			milestones = 0;
			start_interpolation = 0;
			current_led = 0;
			forward_milestone = 0;
			current_interpolation = 0;
			current_rgb = 0;
		end

		case(state)
			GET_INDEX_NEXT: begin
				index_next <= forward_milestone * 8*3 + current_rgb * 8;
				state <= GET_INDEX_PREV;
			end

			GET_INDEX_PREV: begin
				index_prev <= 8*3 + index_next;
				state <= GET_MILESTONES;
			end

			GET_MILESTONES: begin
				milestone_color_next <= milestones[ index_next+7 : index_next ];
				milestone_color_prev <= milestones[ index_prev+7 : index_prev ];
				state <= GET_COLOR;
			end

			GET_COLOR: begin
				color_now <= (    milestone_color_next*(INTERPOLATIONS-current_interpolation)
						+ milestone_color_prev*current_interpolation
					) / INTERPOLATIONS;
				state <= DELIVER_COLOR;
			end

			DELIVER_COLOR: begin
				if(data_request) begin
					// WS2812 block gets an 8 bit segment for transmission
					// this clock. so prepare index variables for the next
					// transmission.
					if(2 > current_rgb) begin
						state <= GET_INDEX_NEXT;
						// next 8bit R/G/B block within a single LED?
						current_rgb <= current_rgb+1;
					end else begin
						current_rgb <= 0;
						if(LEDS-1 > current_led) begin
							state <= GET_INDEX_NEXT;
							// next led is ...
							current_led <= current_led + 1;
							if(INTERPOLATIONS-1 > current_interpolation) begin
								// ... next interpolation between milestones
								current_interpolation <= current_interpolation+1;
							end else begin
								// ... next milestone color
								current_interpolation <= 0;
								forward_milestone <= forward_milestone+1;
							end
						end else begin
							// transmission of full strip completed.
							// start a holdoff and prepare the next transmission:
							// move the interpolations of milestones one slot along.
							state <= HOLDOFF;
							holdoff <= HOLDOFF_TIME;
							current_led <= 0;
							forward_milestone <= 0;
							if(0 != start_interpolation) begin
								// only add a new interpolation
								start_interpolation <= start_interpolation-1;
								current_interpolation <= start_interpolation-1;
							end else begin
								// insert a new random milestone color
								// and start interpolating towards it.
								start_interpolation <= INTERPOLATIONS-1;
								current_interpolation <= INTERPOLATIONS-1;
								milestones <= { 
										milestones[COLORBITS-1-8*3 : 0],
										random[14:10], 3'b0,
										random[9:5], 3'b0,
										random[4:0], 3'b0
									};
							end
						end
					end
				end
			end

			HOLDOFF: begin
				if(holdoff) begin
					holdoff <= holdoff-1;
				end else begin
					state <= GET_INDEX_NEXT;
				end
			end
		endcase
	end

endmodule

