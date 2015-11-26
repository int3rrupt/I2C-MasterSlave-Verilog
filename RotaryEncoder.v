`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////////
module RotaryEncoder(
	output reg rotary_event,
	output reg rotary_left,
   input rotary_a,
   input rotary_b,
	input clk
	);

	reg [1:0]rotary_in;
	reg rotary_q1;
	reg rotary_q2;
	reg delay_rotary_q1;

	initial begin
		rotary_in = 0;
		rotary_q1 = 0;
		rotary_q2 = 0;
		delay_rotary_q1 = 0;
	end

	// Filter out switch chatter
	always@(posedge clk) begin
		rotary_in <= {rotary_b, rotary_a};
		case(rotary_in)
			2'b00:	begin
							rotary_q1 <= 0;
							rotary_q2 <= rotary_q2;
						end
			2'b01:	begin
							rotary_q1 <= rotary_q1;
							rotary_q2 <= 0;
						end
			2'b10:	begin
							rotary_q1 <= rotary_q1;
							rotary_q2 <= 1;
						end
			2'b11:	begin
							rotary_q1 <= 1;
							rotary_q2 <= rotary_q2;
						end
			default:	begin
							rotary_q1 <= rotary_q1;
							rotary_q2 <= rotary_q2;
						end
		endcase
	end

	// Wait for rotation event and determine direction
	// rotary_q1 functions as rotary event and rotary_q2 functions as direction
	always@(posedge clk) begin
		// Store current rotary_q1 value
		delay_rotary_q1 <= rotary_q1;
		// If rotary_q1 was previously 0 but is now 1, then rotary event has occurred
		if (rotary_q1 == 1 && delay_rotary_q1 == 0) begin
			// Set rotary_event
			rotary_event <= 1;
			// Assign rotary_q2 value to rotary_left
			rotary_left <= rotary_q2;
		end
		// Otherwise, rotary event did not occur or already occurred
		else begin
			// Clear rotary_event
			rotary_event <= 0;
			// Retain rotary_left value
			rotary_left <= rotary_left;
		end
	end

endmodule
