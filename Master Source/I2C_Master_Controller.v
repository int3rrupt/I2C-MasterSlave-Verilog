`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer:        Adrian Reyes
// Module Name:     Controller
// Project Name:    I2C
// Target Devices:  SPARTAN 3E
// Description:     LCDI Controller
// Dependencies:    EightBitBinaryToBCD
//////////////////////////////////////////////////////////////////////////////////
module I2C_Master_Controller(
	input clk,
	input reset,
	output reg W,
	output reg [4:0] WADD,
	output reg [7:0] DIN,
	output go,
	input done,
	input ready,
	output reg rw,
	output reg [5:0] N_Byte,
	output reg [6:0] dev_add,
	output reg [7:0] dwr_DataWriteReg,
	output reg [7:0] R_Pointer,
	input [7:0] drd_lcdData,
	input ack_e
	);

	reg [4:0] currentState;
	reg [7:0] lcdData[0:31];
	reg [7:0] Confg_R_add;
	reg [6:0] device_address;
	reg [7:0] config_first_byte;
	reg [7:0] config_second_byte;
	reg [7:0] Temp_R_add;
	reg [15:0] data;
	reg [7:0] T;							// The temperature in binary

	// BCD Conversion Variables
	wire [3:0] BCDDigitHundreds;		// BCD Hundredth's place digit
	wire [3:0] BCDDigitTens;			// BCD Tenth's place digit
	wire [3:0] BCDDigitOnes;			// BDC One's place digit
	wire BCDConversionDone;
	reg [7:0] BinaryInput;
	reg EnableBCDConversion;

	integer i;

	initial begin
		// Reset values
		W = 0;
		WADD = 0;
		DIN = 0;
		rw = 0;
		N_Byte = 1;
		dev_add = 0;
		dwr_DataWriteReg = 0;
		R_Pointer = 0;
		currentState = 0;
		Confg_R_add = 8'b00000001;
		device_address = 7'b1100111;
		config_first_byte = 8'b11100011;
		config_second_byte = 8'b00011100;
		Temp_R_add = 8'b00000101;
		BinaryInput = 0;
		EnableBCDConversion = 0;
		for (i = 0; i < 32; i = i+1) begin
			lcdData[i] = 8'hFE; // FE = Empty Space
		end
		lcdData[0] = 8'h54;		// T
		lcdData[1] = 8'h65;		// e
		lcdData[2] = 8'h6D;		// m
		lcdData[3] = 8'h70;		// p
		lcdData[4] = 8'h3A;		// :
		lcdData[9] = 8'hDF;		// Degrees symbol
		lcdData[10] = 8'h43;		// Character 'C'
	end

	EightBitBinaryToBCD bcdConversion (
		.BCDDigitHundreds(BCDDigitHundreds),
		.BCDDigitTens(BCDDigitTens),
		.BCDDigitOnes(BCDDigitOnes),
		.Done(BCDConversionDone),
		.BinaryInput(BinaryInput),
		.Enable(EnableBCDConversion),
		.clk(clk));

	// Put outside the always
	assign go = (currentState == 1 || currentState == 7);

	always@(posedge clk) begin
		if (reset) begin
			// If resetting go back to state zero
			currentState <= 0;
			BinaryInput <= 0;
			EnableBCDConversion <= 0;
		end
		else begin
			case (currentState)
				0:		begin : Set_Config_Values
							if (done) begin
								rw <= 0;
								N_Byte <= 2;
								R_Pointer <= Confg_R_add;
								dev_add <= device_address;
								currentState <= 1;
							end
						end
				1:		begin : Assert_Go_For_Configuration
							// Move on to the next state
							currentState <= 2;
						end
				2:		begin : Write_Sensor_Config_Byte1
							if (ready) begin
								dwr_DataWriteReg <= config_first_byte;
								// Move on to the next state. Skiped three to match value
								// in the PDF
								currentState <= 3;
							end
						end
				3:		begin // Need to wait for done or something
							if (!ready)
								currentState <= 4;
						end
				4:		begin : Write_Sensor_Config_Byte2
							if (ready) begin
								dwr_DataWriteReg <= config_second_byte;
								currentState <= 5;
							end
						end
				5:		begin : Wait_For_Master_Done
							// Wait for the I2C Master to assert done flag
							if (done)
								currentState <= 6;
						end
				6:		begin : Read_Temperature
							// Wait for the I2C Master to assert done flag
							if (done) begin
								rw <= 1;
								N_Byte <=2;
								R_Pointer <= Temp_R_add;
								dev_add <= device_address;
								currentState <= 7;
							end
						end
				7:		begin : Assert_Go_For_Slave_Read
							currentState <= 8;
						end
				8:		begin : Store_Temperature_Byte2
							if (ready) begin
								data[15:8] <= drd_lcdData;
								currentState <= 9;
							end
						end
				9:		begin : Store_Temperature_Byte1
							if (ready) begin
								data[7:0] <= drd_lcdData;
								currentState <= 10;
							end
						end
				10:	begin : Convert_From_Negative
							if (data[12])
								T <= 256 - data[11:4];
							else
								T <= data[11:4];
							currentState <= 11;
						end
				11:	begin : Start_Binary_To_BCD_Conversion
							if (done) begin
								// Start LCD address from begining of text
								WADD <= 0;
								BinaryInput <= T;
								EnableBCDConversion <= 1;
								currentState <= 12;
							end
						end
				12:	begin : Wait_For_Binary_Conversion_To_Complete
							EnableBCDConversion <= 0;
							// Wait for binary temperature T to be converted to BCD so
							// that we can display it
							if (BCDConversionDone) begin
								case(BCDDigitHundreds)
									// Empty Space if not 100 degrees or more
									0: lcdData[6] <= 8'hFE;
									1: lcdData[6] <= 8'h31;
									2: lcdData[6] <= 8'h32;
									3: lcdData[6] <= 8'h33;
									4: lcdData[6] <= 8'h34;
									5: lcdData[6] <= 8'h35;
									6: lcdData[6] <= 8'h36;
									7: lcdData[6] <= 8'h37;
									8: lcdData[6] <= 8'h38;
									9: lcdData[6] <= 8'h39;
								endcase
								case(BCDDigitTens)
									// Empty Space if not 10 degrees or more
									0: lcdData[7] <= 8'hFE;
									1: lcdData[7] <= 8'h31;
									2: lcdData[7] <= 8'h32;
									3: lcdData[7] <= 8'h33;
									4: lcdData[7] <= 8'h34;
									5: lcdData[7] <= 8'h35;
									6: lcdData[7] <= 8'h36;
									7: lcdData[7] <= 8'h37;
									8: lcdData[7] <= 8'h38;
									9: lcdData[7] <= 8'h39;
								endcase
								case(BCDDigitOnes)
									0: lcdData[8] <= 8'h30;
									1: lcdData[8] <= 8'h31;
									2: lcdData[8] <= 8'h32;
									3: lcdData[8] <= 8'h33;
									4: lcdData[8] <= 8'h34;
									5: lcdData[8] <= 8'h35;
									6: lcdData[8] <= 8'h36;
									7: lcdData[8] <= 8'h37;
									8: lcdData[8] <= 8'h38;
									9: lcdData[8] <= 8'h39;
								endcase
								W<=1;
								currentState <= 13;
							end
						end
				13:	begin : Send_Data_To_LCDI
							if (W) begin
								// Disable Write
								W <= 0;
								// Send current character to LCDI
								DIN <= lcdData[WADD];
							end
							else begin
								// If end of text
								if (WADD == 31)
									// Read new temperature
									currentState <= 6;
								else begin
									// Increment LCD RAM address to write next character
									WADD <= WADD + 1;
									// Enable Write
									W <= 1;
								end
							end
						end
			endcase
		end
	end

endmodule
