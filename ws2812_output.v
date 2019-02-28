`default_nettype none

module ws2812_output(input wire clk, input wire rst, input wire trigger, input wire [7:0] data_in, input wire data_valid, output wire data_request, output wire out);

	// INPUT_CLOCK should not be much smaller than 12MHz
	parameter INPUT_CLOCK = 12_000_000;

	localparam TIME_T0H   = $rtoi( 350e-9 * INPUT_CLOCK) - 1;
	localparam TIME_T0L   = $rtoi(1050e-9 * INPUT_CLOCK) - 1;
	localparam TIME_T1H   = $rtoi( 800e-9 * INPUT_CLOCK) - 1;
	localparam TIME_T1L   = $rtoi( 600e-9 * INPUT_CLOCK) - 1;
	localparam TIME_RESET = $rtoi(  60e-6 * INPUT_CLOCK) - 1;

	localparam MAXTIME_HI = (TIME_T0H > TIME_T1H) ? TIME_T0H : TIME_T1H;
	localparam MAXTIME_LO = (TIME_T0L > TIME_T1L) ? TIME_T0L : TIME_T1L;

	// possible state
	localparam IDLE = 0;
	localparam RECEIVE = 1;
	localparam TRANSMIT_HI = 2;
	localparam TRANSMIT_LO = 3;
	localparam TAILGUARD = 4;

	reg [$clog2(TAILGUARD):0] state = IDLE;

	reg [6:0] tx_data;
	reg [$clog2(7)-1:0] tx_bits;
	reg [$clog2(MAXTIME_HI):0] timer_high;
	reg [$clog2(MAXTIME_LO):0] timer_low;
	reg [$clog2(TIME_RESET):0] timer_tail;

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
					timer_high <= (data_in[7]) ? TIME_T1H : TIME_T0H;
					timer_low  <= (data_in[7]) ? TIME_T1L : TIME_T0L;
					tx_data <= data_in[6:0];
					tx_bits <= 7;
					state <= TRANSMIT_HI;
				end else begin
					timer_tail <= TIME_RESET;
					state <= TAILGUARD;
				end
			end

			TRANSMIT_HI: begin
				if(timer_high) begin
					timer_high = timer_high-1;
				end else begin
					state <= TRANSMIT_LO;
				end
			end

			TRANSMIT_LO: begin
				if(timer_low) begin
					timer_low = timer_low-1;
				end else begin
					if(tx_bits) begin
						timer_high <= (tx_data[tx_bits]) ? TIME_T1H : TIME_T0H;
						timer_low  <= (tx_data[tx_bits]) ? TIME_T1L : TIME_T0L;
						tx_bits <= tx_bits-1;
						state <= TRANSMIT_HI;
					end else begin
						state <= RECEIVE;
					end
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

