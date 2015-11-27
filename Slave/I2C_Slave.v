`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer:			Adrian Reyes
// Module Name:		I2C_Slave
// Project Name:		I2C_Slave-LCD_Buttons_Switches
// Target Devices:	SPARTAN 3E
// Description:		I2C Slave
// Dependencies:
//////////////////////////////////////////////////////////////////////////////////
module I2C_Slave(
	output reg W,
	output reg [7:0]addr,
	output reg [7:0]datar,	// Data Register (Received Data Only?)
	input [7:0] DOUT,
	inout scl,
	inout sda,
	input clk,
	input reset
	);

	wire fsda;					// Filtered Serial Data siganl
	wire dne;					// Negative Edge of Serial Data bus
	wire dpe;					// Positive Edge of Serial Data bus
	wire fscl;					// Filtered Serial Clock signal
	wire cne;					// Negative Edge of Serial Clock bus
	wire cpe;					// Positive Edge of Serial Clock bus

	reg [6:0]my_addr;			// Slave's Address
	reg [4:0]currentState;		// The ASM's current state
	reg scl_int;				// Serial Clock Interrupt
	reg sda_int;				// Serial Data Interrupt
	reg [3:0]Nb;				// Number of bits to Read or Transmit
	reg dir;						// Direction Information Register (Read or !Write)
	reg [7:0]TXr;				// Transmit Register

	initial begin
		my_addr = 7'b1100111;
		currentState = 1;
		datar = 0;
	end

	I2C_Slave_EdgeFilter sclEdgeFilter(
		.fsig(fscl),
		.ne(cne),
		.pe(cpe),
		.sig(scl),
		.clk(clk),
		.reset(reset)
		);

	I2C_Slave_EdgeFilter sdaEdgeFilter(
		.fsig(fsda),
		.ne(dne),
		.pe(dpe),
		.sig(sda),
		.clk(clk),
		.reset(reset)
		);


	assign scl = scl_int ? 1'bz : 0;
	assign sda = sda_int ? 1'bz : 0;
	assign stop = dpe && fscl;
	assign start = dne && fscl;

	always@(posedge clk) begin
		if (reset) begin
			currentState <= 1;
		end
		else begin
			case(currentState)
				0:		begin : Wait_For_Stop
							// Interrupt Serial Clock
							sda_int <= 1;
							// Interrupt Serial Data
							scl_int <= 1;
							// Wait for Stop sequence
							if (stop)
								// Continue
								currentState <= 1;
						end
				1:		begin : Wait_For_Start
							// Interrupt Serial Clock
							sda_int <= 1;
							// Interrupt Serial Data
							scl_int <= 1;
							// Wait for Start sequence
							if (start) begin
								// Set Number of bits to 8
								Nb <= 8;
								// Continue
								currentState <= 2;
							end
						end
				2:		begin : Read_Slave_Address
							// If Number of bits remaining is zero
							if (Nb == 0) begin
								// If read data is this slave's address
								if (datar[7:1] == my_addr) begin
									// Send least significant bit of read data to
									// Direction Info Reg
									dir <= datar[0];
									// Continue
									currentState <= 3;
								end
								// Else read data is not this slave's address
								else
									// Start over and wait for Stop sequence
									currentState <= 0;
							end
							// Keep reading bits
							else begin
								// Wait for Serial Clock positive edge
								if (cpe) begin
									// Append Filtered Serial Data value to Data Reg
									datar <= {datar[6:0], fsda};
									// Decrement Number of bits left to read
									Nb <= Nb - 1;
								end
							end
						end
				3:		begin : Send_Address_Ack
							// Wait for Serial Clock negative edge
							if (cne) begin
								// Send Acknowledgement by pulling sda down
								sda_int <= 0;
								// Continue
								currentState <= 4;
							end
						end
				4:		begin : Release_Address_Ack
							// Wait for Serial Clock negative edge
							if (cne) begin
								// Release sda bus
								sda_int <= 1;
								// Set the number of bits to be read to 8
								Nb <= 8;
								// Continue
								currentState <= 5;
							end
						end
				5:		begin : Read_Register_Address
							// If Number of bits remaining is zero
							if (Nb == 0)
								// Continue
								currentState <= 6;
							// Keep reading bits
							else begin
								// Wait for Serial Clock positive edge
								if (cpe) begin
									// Append Filtered Serial Data value to Address Reg
									addr <= {addr[6:0], fsda};
									// Decrement Number of bits left to read
									Nb <= Nb - 1;
								end
							end
						end
				6:		begin : Send_Reg_Address_Ack
							// Wait for Serial Clock negative edge
							if (cne) begin
								// Send Acknowledgement by pulling sda down
								sda_int <= 0;
								// Continue
								currentState <= 7;
							end
						end
				7:		begin : Determine_Read_or_Write
							// Wait for Serial Clock negative edge
							if (cne) begin
								// Release sda bus
								sda_int <= 1;
								// Set the number of bits to be read to 8
								Nb <= 8;
								// If Master requests Read operation
								if (dir) begin
									// Continue to grab requested register data
									currentState <= 11;
								end
								// Else Master requests Write operation
								else begin
									// Continue to read data from Master
									currentState <= 8;
								end
							end
						end
				8:		begin : Write_Operation
							// If Stop sequence encountered
							if (stop)
								// Start over and wait for Start sequence
								currentState <= 1;
							// Else Stop sequence not encountered
							else begin
								// If Number of bits remaining is zero
								if (Nb == 0) begin
									// Assert write
									W <= 1;
									// Increment Register Address reg
									addr <= addr + 1;
									// Continue
									currentState <= 9;
								end
								// Keep reading bits
								else begin
									// Wait for Serial Clock positive edge
									if (cpe) begin
										// Append Filtered Serial Data value to Data Reg
										datar <= {datar[6:0], fsda};
										// Decrement Number of bits left to read
										Nb <= Nb - 1;
									end
								end
							end
						end
				9:		begin : Send_Data_Writen_Ack
							if (cne) begin
								// Send Acknowledgement by pulling sda down
								sda_int <= 0;
								// Clear write
								W <= 0;
								// Continue
								currentState <= 10;
							end
						end
				10:	begin : Release_Data_Written_Ack
							if (cne) begin
								// Release sda bus
								sda_int <= 1;
								// Set the number of bits to be read to 8
								Nb <= 8;
								// Continue to read or wait for Stop sequence
								currentState <= 8;
							end
						end
				11:	begin : Wait_For_Second_Start_Sequence_For_Read
							// Release sda bus
							sda_int <= 1;
							// Release scl bus
							scl_int <= 1;
							// If Stop sequence encountered
							if (stop)
								// Start over and wait for Start sequence
								currentState <= 1;
							// Otherwise continue
							else begin
								// Wait for Start sequence
								if (start) begin
									// Set the number of bits to be read to 8
									Nb <= 8;
									// Continue
									currentState <= 12;
								end
							end
						end
				12:	begin : Read_Slave_Address_Again
							// If Number of bits remaining is zero
							if (Nb == 0) begin
								// If read data is this slave's address
								if (datar[7:1] == my_addr) begin
									// If Master requests Read operation
									if (datar[0]) begin
										// Store Register Data from RAM into
										// Transmit Register
										TXr <= DOUT;
										// Set the number of bits to be transmitted to 8
										Nb <= 8;
										// Increment Register Address
										addr <= addr + 1;
										// Continue
										currentState <= 13;
									end
									else
										// If Master requests write, something went wrong
										// Start over and wait for Stop Sequence
										currentState <= 0;
								end
								else
									// If read data is not this slave's address something
									// went wrong start over and wait for Stop Sequence
									currentState <= 0;
							end
							// Keep reading bits
							else begin
								// Wait for Serial Clock positive edge
								if (cpe) begin
									// Append Filtered Serial Data value to Data Reg
									datar <= {datar[6:0], fsda};
									// Decrement Number of bits left to read
									Nb <= Nb - 1;
								end
							end
						end
				13:	begin : Wait_For_Negative_Edge_To_Transmit
							// Wait for Serial Clock negative edge
							if (cne)
								// Continue
								currentState <= 14;
						end
				14:	begin : Transmit_Most_Significant_Bit
							// Transmit most significant bit
							sda_int <= TXr[7];
							// Continue
							currentState <= 15;
						end
				15:	begin : Left_Shift_Transmit_Reg
							// If Stop sequence encountered
							if (stop)
								// Start over and wait for Start sequence
								currentState <= 1;
							// Otherwise continue
							else begin
								// If Number of bits remaining is zero
								if (Nb == 0) begin
									// Release sda bus
									sda_int <= 1;
									// Continue
									currentState <= 16;
								end
								// Keep transmitting bits
								else begin
									// Wait for Serial Clock negative edge
									if (cne) begin
										// Left shift Transmit Reg with 1
										TXr <= {TXr[6:0], 1'b1};
										// Decrement Number of bits left to transmit
										Nb <= Nb - 1;
										// Go back and transmit most significant bit now
										// that we've left shifted
										currentState <= 14;
									end
								end
							end
						end
				16:	begin : Determine_Continue_Reading
							// Wait for Serial Clock positive edge
							if (cpe) begin
								// If Master is done reading
								if (sda)
									// Go to beginning and wait for Stop sequence
									currentState <= 0;
								// Else, Master wishes to continue reading
								else begin
									// Store Register Data from RAM into
									// Transmit Register
									TXr <= DOUT;
									// Set the number of bits to be transmitted to 8
									Nb <= 8;
									// Increment Register Address
									addr <= addr + 1;
									// Go back and wait for negative edge of Serial Clock
									// to begin transmitting
									currentState <= 13;
								end
							end
						end
			endcase
		end
	end
endmodule
