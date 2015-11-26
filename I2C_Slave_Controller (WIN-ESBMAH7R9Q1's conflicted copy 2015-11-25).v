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
	output [4:0]WADD,
	output [7:0]DIN,
	output W,
	input EA,
	input EDM,
	input EDL,
	input [3:0]data,
	input reset,
	input clk
	);

	reg currentState;

	assign W = currentState == 3;

	always@(posedge) begin
		if (reset)
			currentState <= 0;
		else begin
			case (currentState)
				0:	begin : Initialize
						WADD <= 0;
						currentState <= 1;
					end
				1:	begin :
						if (E) begin
							DIN[7:4] <= data;
							currentState <= 2;
						end
					end
				2:	begin
						if (E) begin
							DIN[3:0] <= data;
							currentState <= 3;
						end
					end
				3:	begin
						WADD <= WADD + 1;
						if (WADD == 32)
							currentState <= 0;
						else
							currentState <= 1;
					end
			endcase
		end
	end

endmodule
