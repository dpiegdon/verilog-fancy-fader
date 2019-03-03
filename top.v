`default_nettype none

module top(input wire CLK, output wire J1_7, output wire J1_8, output wire J1_9, output wire J1_10);

	localparam LEDS=40;
	// NOTE: INTERPOLATIONS better be a power-of-two.
	localparam INTERPOLATIONS=8;
	// NOTE the +1 at the end of MILESTONES: avoids index-error for milestone_color_next.
	localparam MILESTONES=$rtoi($ceil((LEDS*1.0)/INTERPOLATIONS)) + 1;
	localparam COLORBITS=8*3*MILESTONES;

	localparam HOLDOFF_MAX=1200000;

	wire rst;
	assign rst = 0;

	reg [$clog2(HOLDOFF_MAX) : 0] holdoff = 0;

	// store for colors, addressed via [COLOR][rgb][bit].
	reg [COLORBITS-1:0] colors;

	reg [$clog2(INTERPOLATIONS):0] start_interpolation;

	reg [$clog2(LEDS):0] current_led;
	reg [$clog2(MILESTONES):0] current_milestone;
	reg [$clog2(INTERPOLATIONS):0] current_interpolation;
	reg [2:0] current_rgb;

	wire trigger;
	assign trigger = (0 == holdoff);
	assign J1_9 = trigger;
	wire data_request;
	assign J1_8 = data_request;
	wire [7:0] color_now_postgamma;
	ws2812_output ws2812(CLK, rst, trigger, color_now_postgamma, trigger, data_request, J1_10);

	wire [7:0] milestone_color_prev;
	assign milestone_color_prev = colors[ (current_milestone+0) * 8*3 + current_rgb * 8 + 7 : (current_milestone+0) * 8*3 + current_rgb * 8];
	wire [7:0] milestone_color_next;
	assign milestone_color_next = colors[ (current_milestone+1) * 8*3 + current_rgb * 8 + 7 : (current_milestone+1) * 8*3 + current_rgb * 8];
	wire [7:0] color_now;
	assign color_now = (milestone_color_prev*current_interpolation + milestone_color_prev*(INTERPOLATIONS-current_interpolation)) / INTERPOLATIONS;
	gammasight gammasight(color_now, color_now_postgamma);

	wire [15:0] random;
	randomized_lfsr randomized_lfsr_weak(.clk(CLK), .rst(rst), .out(random));

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

