`default_nettype none

module Ws2812Sender(input wire clk, input wire rst, input wire trigger, input wire [7:0] data_in, input wire data_valid, output wire data_request, output wire out);

	// INPUT_CLOCK should not be much smaller than 12MHz
	parameter INPUT_CLOCK = 12_000_000;

	localparam TIME_T0H   = $rtoi(350e-9 * INPUT_CLOCK);
	localparam TIME_T0L   = $rtoi(700e-9 * INPUT_CLOCK);
	localparam TIME_T1H   = $rtoi(800e-9 * INPUT_CLOCK);
	localparam TIME_T1L   = $rtoi(600e-9 * INPUT_CLOCK);
	localparam TIME_RESET = $rtoi( 60e-6 * INPUT_CLOCK);

	// possible state
	localparam IDLE = 0;
	localparam RECEIVE = 1;
	localparam TRANSMIT_HI = 2;
	localparam TRANSMIT_LO = 3;
	localparam TAILGUARD = 4;
	localparam STATEMAX = 5;

	reg [$clog2(STATEMAX)-1:0] state = IDLE;

	reg [6:0] tx_data;
	reg [2:0] tx_bits;
	reg [$clog2(TIME_T0H+TIME_T1H)-1:0] timer_high;
	reg [$clog2(TIME_T0L+TIME_T1L)-1:0] timer_low;
	reg [$clog2(TIME_RESET)-1:0] timer_tail;

	assign data_request = (RECEIVE == state);
	assign out = (TRANSMIT_HI == state);

	always @ (posedge clk) begin
		if(rst) begin
			state <= IDLE;
		end

		case(state)
			IDLE: begin
				if(trigger) begin
					state <= RECEIVE;
				end
			end

			RECEIVE: begin
				if(data_valid) begin
					tx_data <= data_in[6:0];
					tx_bits <= 6;
					timer_high <= (data_in[7]) ? TIME_T1H : TIME_T0H;
					timer_low  <= (data_in[7]) ? TIME_T1L : TIME_T0L;
					state <= TRANSMIT_HI;
				end else begin
					timer_tail <= TIME_RESET;
					state <= TAILGUARD;
				end
			end

			TRANSMIT_HI: begin
				if(timer_high)
					timer_high = timer_high-1;
				else
					state <= TRANSMIT_LO;
			end

			TRANSMIT_LO: begin
				if(timer_low)
					timer_low = timer_low-1;
				else
					if(tx_bits) begin
						timer_high <= (tx_data[6]) ? TIME_T1H : TIME_T0H;
						timer_low  <= (tx_data[6]) ? TIME_T1L : TIME_T0L;
						tx_data <= {tx_data[5:0], 0};
						tx_bits <= tx_bits-1;
					end else begin
						state <= RECEIVE;
					end
			end

			TAILGUARD: begin
				if(timer_tail)
					timer_tail = timer_tail-1;
				else
					state <= IDLE;
			end

			default: begin
				state <= IDLE;
			end
		endcase
	end

endmodule

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

	Ws2812Sender ws2812(
		// to:
		.clk(CLK), .rst(J1_3), .trigger(J1_4), .data_in(data_in), .data_valid(J1_5),
		// from:
		.data_request(J1_9), .out(J1_10)
	);

endmodule

