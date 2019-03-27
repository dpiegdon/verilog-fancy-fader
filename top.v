`default_nettype none

module top(input wire CLK, output wire J1_7, output wire J1_8, output wire J1_9, output wire J1_10,
	output wire LED0, output wire LED1, output wire LED2, output wire LED3, output wire LED4);

	wire rst;
	synchronous_reset_timer reset_generator(CLK, rst, 1'b0);

	wire [15:0] random;
	wire metastable;
	randomized_lfsr_weak
		#(.WIDTH('d16), .INIT_VALUE(16'b1010_1100_1110_0001), .FEEDBACK(16'b0000_0000_0010_1101))
		randomized_lfsr_weak(.clk(CLK), .rst(rst), .out(random), .metastable(metastable));

	wire [7:0] color_now;
	wire trigger;
	wire data_request;
	ws2812_fancy_fader fader(CLK, rst, random, data_request, trigger, color_now);

	wire [7:0] color_now_postgamma;
	ws2812_gammasight gammasight(color_now, color_now_postgamma);

	ws2812_output_shifter shifter(CLK, rst, trigger, color_now_postgamma, trigger, data_request, J1_10);

	assign J1_9 = trigger;
	assign J1_8 = data_request;
	assign J1_7 = 0;

	reg [3:0] led_ring = 4'b1;
	assign LED0 = led_ring[3];
	assign LED1 = led_ring[2];
	assign LED2 = led_ring[1];
	assign LED3 = led_ring[0];
	assign LED4 = metastable;

	always @ (posedge trigger, posedge rst) begin
		if(rst) begin
			led_ring <= 4'b1;
		end else begin
			led_ring <= {led_ring[0], led_ring[3:1]};
		end
	end

endmodule

