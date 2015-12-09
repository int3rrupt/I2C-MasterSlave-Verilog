`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer:			Adrian Reyes
// Module Name:		I2C_RAMController
// Project Name:		I2C_Slave-LCD_Menu
// Target Devices:	SPARTAN 3E
// Description:		I2C RAM Controller
//							This controller contains within it two separate RAMs.
//							*	Local RAM is used for storing local data.
//								When in master mode, local RAM is data that can be written
//								to the slave by the master.
//								When in slave mode, local RAM is data that can be read by
//								the master from the slave.
//							*	Remote RAM is used for storing remote data.
//								When in master mode, remote RAM is where data that has been
//								read from the slave by the master is stored.
//								When in slave mode, remote RAM is where data that has been
//								written to the slave by the master is stored.
// Dependencies:
//////////////////////////////////////////////////////////////////////////////////
module I2C_RAMController(
	output reg [7:0]LocalRAM_DOUT,	// Local RAM data out
	output reg [7:0]RemoteRAM_DOUT,	// Remote RAM data out
	input [4:0]LocalRAM_RADD,			// Local RAM read address
	input [4:0]LocalRAM_WADD,			// Local RAM write address
	input [7:0]LocalRAM_DIN,			// Local RAM data in
	input LocalRAM_W,						// Local RAM write port
	input LocalRAM_Clear,				// Local RAM clear port
	input [4:0]RemoteRAM_RADD,			// Remote RAM read address
	input [4:0]RemoteRAM_WADD,			// Remote RAM write address
	input [7:0]RemoteRAM_DIN,			// Remote RAM data in
	input RemoteRAM_W,					// Remote RAM write port
	input RemoteRAM_Clear,				// Remote RAM clear port
	input clk
	);

	reg [7:0]localRAM[0:31];			// 8x32 Local LCD character RAM
	reg [7:0]remoteRAM[0:31];			// 8x32 Remote LCD character RAM


	reg [7:0]clearRAMChar = CHAR_SPACE;

	integer i, j;
	initial begin
		for (i = 0; i < 32; i = i + 1) begin
			localRAM[i] = i;
		end
	end

	// RAM read
	always@(posedge clk) begin
		case(MultiRAM_SEL)
			RAM_SEL_MENU:		MultiRAM_DOUT <= menuROM[MenuRAM_Select][MultiRAM_ADD];
			RAM_SEL_REMOTE:	MultiRAM_DOUT <= remoteRAM[MultiRAM_ADD];
			RAM_SEL_LOCAL:		MultiRAM_DOUT <= localRAM[MultiRAM_ADD];
		endcase
	end
	// RAM write
	always@(posedge clk) begin
		if (MultiRAM_W) begin
			localRAM[MultiRAM_ADD] <= MultiRAM_DIN;
		end
		else begin
			if (MultiRAM_Clear && MultiRAM_SEL == RAM_SEL_LOCAL) begin
				localRAM[0] <= clearRAMChar; localRAM[16] <= clearRAMChar;
				localRAM[1] <= clearRAMChar; localRAM[17] <= clearRAMChar;
				localRAM[2] <= clearRAMChar; localRAM[18] <= clearRAMChar;
				localRAM[3] <= clearRAMChar; localRAM[19] <= clearRAMChar;
				localRAM[4] <= clearRAMChar; localRAM[20] <= clearRAMChar;
				localRAM[5] <= clearRAMChar; localRAM[21] <= clearRAMChar;
				localRAM[6] <= clearRAMChar; localRAM[22] <= clearRAMChar;
				localRAM[7] <= clearRAMChar; localRAM[23] <= clearRAMChar;
				localRAM[8] <= clearRAMChar; localRAM[24] <= clearRAMChar;
				localRAM[9] <= clearRAMChar; localRAM[25] <= clearRAMChar;
				localRAM[10] <= clearRAMChar; localRAM[26] <= clearRAMChar;
				localRAM[11] <= clearRAMChar; localRAM[27] <= clearRAMChar;
				localRAM[12] <= clearRAMChar; localRAM[28] <= clearRAMChar;
				localRAM[13] <= clearRAMChar; localRAM[29] <= clearRAMChar;
				localRAM[14] <= clearRAMChar; localRAM[30] <= clearRAMChar;
				localRAM[15] <= clearRAMChar; localRAM[31] <= clearRAMChar;
			end
		end
	end
	// Remote write
	always@(posedge clk) begin
		if (RemoteRAM_W) begin
			remoteRAM[RemoteRAM_WADD] = RemoteRAM_DIN;
		end
	end
	// Local read
	always@(posedge clk) begin
		LocalRAM_DOUT <= localRAM[LocalRAM_RADD];
	end

endmodule
