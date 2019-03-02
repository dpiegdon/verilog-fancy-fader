`default_nettype none

module top(input wire CLK, output wire J1_7, output wire J1_8, output wire J1_9, output wire J1_10);

	wire ws2812_dataline;
	assign ws2812_dataline = J1_10;

	wire data_request;
	assign data_request = J1_9;

	reg [5:0] led_count = 0;
	reg wait_for_tailguard = 0;

	wire more_leds;
	assign more_leds = (0 != led_count);
	assign more_leds = J1_8;

	wire trigger;
	assign trigger = !wait_for_tailguard;
	assign trigger = J1_7;

	wire [15:0] random;
	wire _oc, _owc;
	randomized_lfsr randomized_lfsr(CLK, 0, _oc, _owc, random);

	ws2812_output ws2812(CLK, 0, trigger, random[7:0], more_leds, data_request, ws2812_dataline);

	always @(posedge CLK) begin
		if(more_leds) begin
			if(data_request) begin
				led_count <= led_count-1;
				wait_for_tailguard <= 1;
			end
		end else if(wait_for_tailguard) begin
			if(data_request) begin
				wait_for_tailguard <= 0;
			end
		end else begin
			led_count <= 3 * 11;
		end
	end

endmodule

