`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer:			Adrian Reyes
// Module Name:		I2C_Slave_EdgeFilter
// Project Name:		I2C_Slave-LCD_Buttons_Switches
// Target Devices:	SPARTAN 3E
// Description:		I2C Slave Edge Filter
// Dependencies:
//////////////////////////////////////////////////////////////////////////////////
module I2C_Slave_EdgeFilter(
	output reg fsig,	// Filtered Signal
	output ne,			// Negative Edge
	output pe,			// Positive Edge
	input sig,			// Original Signal
	input clk,
	input reset
	);

	wire A0s;
	wire A1s;
	reg [7:0]fR;
	
	//assign A0s = ~(~(~(~(~(~(~(fR[7] | fR[6]) | fR[5]) | fR[4]) | fR[3]) | fR[2]) | fR[1]) | fR[0]);
	assign A0s = fR == 0;
	assign A1s = fR == 8'b11111111;
	//assign A1s = (((((((fR[7] & fR[6]) & fR[5]) & fR[4]) & fR[3]) & fR[2]) & fR[1]) & fR[0]);
	assign ne = A0s & fsig;
	assign pe = A1s & ~fsig;

	always@(posedge clk) begin
		if (reset) begin
			fR <= 0;
			fsig <= 0;
		end
		else begin
			fR <= {sig, fR[7:1]};
			if (A0s)
				// Set Filtered Signal Low
				fsig <= 0;
			else begin
				if (A1s)
					// Set Filtered Signal High
					fsig <= 1;
			end
		end
	end
endmodule
