`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer:			Adrian Reyes
// Module Name:		I2C_Slave_Controller
// Project Name:		I2C_Slave-LCD_Buttons_Switches
// Target Devices:	SPARTAN 3E
// Description:		I2C Slave Controller
// Dependencies:
//////////////////////////////////////////////////////////////////////////////////
module I2C_Slave_Controller(
	output reg [4:0]WADD,
	output reg [7:0]DIN,
	output W,
	input AddrIncr,
	input AddrDecr,
	input NibbleIndicate,
	input E,
	input [3:0]data,
	input clk,
	input reset
	);

	reg currentState;
	reg currentNibble;
	reg IncrAddrPressed;
	reg DecrAddrPressed;
	
	initial currentState = 0;
	
	assign W = currentState == 3;
	
	always@(posedge AddrIncr) begin
		IncrAddrPressed <= 1;
	end
	always@(posedge AddrDecr) begin
		IncrAddrPressed <= 1;
	end

	always@(posedge clk) begin
		if (reset)
			currentState <= 0;
		else begin
			if (IncrAddrPressed) begin
				currentState <= 3;
			end
			else begin
				if (IncrAddrPressed)
					currentState <= 4;
				else begin
					case (currentState)
						0:	begin : Initialize
								WADD <= 0;
								currentNibble <= 0;
								currentState <= 1;
							end
						1:	begin : Write_First_Nibble
								if (E) begin
									DIN[7:4] <= data;
									currentNibble <= 1;
									currentState <= 2;
								end
							end
						2:	begin : Write_Second_Nibble
								if (E) begin
									DIN[3:0] <= data;
									currentState <= 3;
								end
							end
						3:	begin : Increment_Address
								WADD <= WADD + 1;
								currentState <= 5;
							end
						4: begin : Decrement_Address
								WADD <= WADD - 1;
								currentState <= 5;
							end
						5: begin : Validate_Address
								currentNibble <= 0;
								if (WADD == 32)
									currentState <= 0;
								else
									currentState <= 1;
							end
					endcase
				end
			end
			
		end
	end

endmodule
