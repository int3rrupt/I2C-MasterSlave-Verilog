`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer:			Adrian Reyes
// Module Name:		RAM32x8
// Project Name:		I2C_Slave-LCD_Buttons_Switches
// Target Devices:	SPARTAN 3E
// Description:		32x8 RAM
// Dependencies:
//////////////////////////////////////////////////////////////////////////////////
module RAM32x8(
	output [7:0]DOUT,
	input [4:0]RADD,
	input W,
	input [7:0]DIN,
	input [4:0]WADD,
	input clk
	);
	
	reg [7:0]RAM[0:31];

	integer i;
	// Initialize RAM with spaces
	initial begin
		for (i = 0; i < 16; i = i + 1) begin
			RAM[i] = 8'hFE;
		end
	end

	// Assign DOUT continuously
	assign DOUT = RAM[RADD];

	// Load DIN into RAM when W is asserted
	always@(posedge clk)
		if(W) RAM[WADD] <= DIN;

endmodule
