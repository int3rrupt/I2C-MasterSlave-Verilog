`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer:			Adrian Reyes
// Module Name:		I2C_Master_Counter
// Project Name:		I2C_Master-LCD_TempSensor
// Target Devices:	SPARTAN 3E
// Description:		I2C Master Counter
// Dependencies:
//////////////////////////////////////////////////////////////////////////////////
module I2C_Master_Counter(
	output reg [9:0] count,
	input stretch,
	input waiting,
	input clk,
	input reset
	);

	// NOTES:
	//		1000 = 1111101000

	always@(posedge clk) begin
		// If reset, clear count
		if (reset)
			count <= 0;
		// Otherwise run counter
		else begin
			// If state = WAITING. Reset count
			if (waiting)
				count <= 0;
			else begin
				// If NOT stretching increment count
				if (!stretch)
					count <= count + 1;
			end
		end
	end

endmodule
