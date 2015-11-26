`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer:			Adrian Reyes
// Module Name:		EightBitBinaryToBCD
// Project Name:		I2C_Master-LCD_TempSensor
// Target Devices:	SPARTAN 3E
// Description:		Eight bit binary to BCD converter
// Dependencies:
//////////////////////////////////////////////////////////////////////////////////
module EightBitBinaryToBCD(
	output reg [3:0] BCDDigitHundreds,
	output reg [3:0] BCDDigitTens,
	output reg [3:0] BCDDigitOnes,
	output reg Done,
	input [7:0] BinaryInput,
	input Enable,
	input clk
	);

	reg Enabled;
	reg [7:0] Binary;

	initial Enabled = 0;

	always@(posedge clk) begin
		if (Enable) begin
			Binary <= BinaryInput;
			BCDDigitHundreds <= 0;
			BCDDigitTens <= 0;
			BCDDigitOnes <= 0;
			Enabled <= 1;
			Done <= 0;
		end
		else begin
			if (Enabled) begin
				if (Binary > 100) begin
					BCDDigitHundreds <= BCDDigitHundreds + 1;
					Binary <= Binary - 100;
				end
				else begin
					if (Binary > 10) begin
						BCDDigitTens <= BCDDigitTens + 1;
						Binary <= Binary - 10;
					end
					else begin
						BCDDigitOnes <= Binary[3:0];
						Enabled <= 0;
						Done <= 1;
					end
				end
			end
		end
	end

endmodule
