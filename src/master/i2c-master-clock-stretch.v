`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer:			Adrian Reyes
// Module Name:		I2C_Master_Stretch
// Project Name:		I2C_Master-LCD_TempSensor
// Target Devices:	SPARTAN 3E
// Description:		I2C Master Stretch
// Dependencies:
//////////////////////////////////////////////////////////////////////////////////
module I2C_Master_Stretch(stretch, pe, rbit, scl, clk, reset);
	output stretch;
	input pe;			// scl segment 3: Positive Edge of scl
	input rbit;			// scl segment 4: Read Bit
	input scl;			// Serial Clock
	input clk;			// Main clock
	input reset;

	reg stretch;
	reg Q3;

	initial begin
		stretch = 0;
		Q3 = 0;
	end

	always@(posedge clk) begin
		// If reset, clear stretch and Q3
		if (reset) begin stretch <= 0; Q3 <= 0; end
		else begin
			// If we are at pos edge of scl
			if (pe)
				Q3 <= 1;
			else begin
				// If we are at read bit
				if (rbit) Q3 <= 0;
				else begin
					if (Q3) begin
						if (scl) stretch <= 0;
						else stretch <=1;
					end
				end
			end
		end
	end

endmodule
