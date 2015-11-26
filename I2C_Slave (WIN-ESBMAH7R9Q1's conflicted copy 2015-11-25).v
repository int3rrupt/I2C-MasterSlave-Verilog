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
	output W,
	output [4:0]addr,
	output reg [7:0]datar,	// Data Register (Received Data Only?)
	input [7:0] DOUT,
	inout scl,
	inout sda,
	input clk,
	input reset
	);

	reg myaddr;					// Slave's Address
	reg currentState;			// The ASM's current state
	reg scl_int;				// Serial Clock Interrupt
	reg sda_int;				// Serial Data Interrupt
	reg [3:0]Nb;				// Number of bits
	reg dir;						// Direction Information Register (Read or !Write)

	initial begin
		currentState = 1;
		datar = 0;
	end

	//I2C_Slave_EdgeFilter i2cSlaveEdgeFilter(
	//	);

	assign stop = dpe && fscl;
	assign start = dne && fscl;

	always@(posedge clk) begin
		if (reset) begin
			currentState <= 1;
		end
		else begin
			case(currentState)
				0:		begin : Wait_For_Stop
							sda_int <= 1;								// Interrupt Serial Clock
							scl_int <= 1;								// Interrupt Serial Data
							if (stop)									// If Stop
								currentState <= 1;					// Continue
						end
				1:		begin : Wait_For_Start
							sda_int <= 1;								// Interrupt Serial Clock
							scl_int <= 1;								// Interrupt Serial Data
							if (start) begin							// Wait for Start
								Nb <= 8;									// Set Number of bits to 8
								currentState <= 2;					// Continue
							end
						end
				2:		begin : Read_Serial_Data
							if (Nb == 0) begin						// If Number of bits is zero
								if (datar[7:0] == my_addr) begin	// And if Data Reg is Slave Address
									dir <= datar[0];					// Send Data Reg least significant to Direction Info Reg
									currentState <= 3;				// Continue
								end
								else										// Else Data Reg is not Slave Address
									currentState <= 0;				// Start over
							end
							else begin									// Else
								if (cpe) begin							// If Clock Positive Edge
									datar <= {datar[6:0], fsda};	// Append Filtered Serial Data to Data Reg
									Nb <= Nb - 1;						// Decrement Number of bits
								end
							end
						end
				3:		begin
							if (cne) begin								// If Clock Negative Edge
								sda_int <= 0;
								currentState <= 4;
							end
						end
				4:		begin
							if (cne) begin
								sda_int <= 1;
								Nb <= 8;
								currentState <= 5;
							end
						end
				5:		begin
							if (Nb == 0)
								currentState <= 6;
							else begin
								if (cpe) begin
									addr <= {addr[6:0], fsda};
									Nb <= Nb - 1;
								end
							end
						end
				6:		begin
							if (cne) begin
								sda_int <= 0;
								currentState <= 7;
							end
						end
				7:		begin
							if (cne) begin
								if (dir) begin
									sda_int <= 1;
									Nb <= 8;
									currentState <= 11;
								end
								else begin
									sda_int <= 1;
									Nb <= 8;
									currentState <= 8;
								end
							end
						end
				8:		begin
							if (stop)
								currentState <= 1;
							else begin
								if (Nb == 0) begin
									W <= 1;
									addr <= addr + 1;
									currentState <= 9;
								end
								else begin
									if (cpe) begin
										datar <= {datar[6:0], fsda};
										Nb <= Nb - 1;
									end
								end
							end
						end
				9:		begin
							if (cne) begin
								sda_int <= 0;
								currentState <= 10;
							end
						end
				10:	begin
							if (cne) begin
								sda_int <= 1;
								Nb <= 8;
								currentState <= 8;
							end
						end
				11:	begin
							sda_int <= 1;
							scl_int <= 1;
							if (stop)
								currentState <= 1;
							else begin
								if (start) begin
									Nb <= 8;
									currentState <= 12;
								end
							end
						end
				12:	begin
							if (Nb == 0) begin
								if (datar[7:1] == my_addr) begin
									if (datar[0]) begin
										TXr <= DOUT;
										Nb <= 8;
										addr <= addr + 1;
										currentState <= 13;
									end
									else
										currentState <= 0;
								end
								else
									currentState <= 0;
							end
							else begin
								if (cpe) begin
									datar <= {datar[6:0], fsda};
									Nb <= Nb - 1;
								end
							end
						end
				13:	begin
							if (cne)
								currentState <= 14;
						end
				14:	begin
							sda_int <= TXr[7];
							currentState <= 15;
						end
				15:	begin
							if (stop)
								currentState <= 1;
							else begin
								if (Nb == 0) begin
									sda_int <= 1;
									currentState <= 16;
								end
								else begin
									if (cne) begin
										TXr <= {TXr[6:0], 1'b1};
										Nb <= Nb - 1;
										currentState <= 14;
									end
								end
							end
						end
				16:	begin
							if (cpe) begin
								if (sda)
									currentState <= 0;
								else begin
									TXr <= RAM[addr];
									Nb <= 8;
									addr <= addr + 1;
									currentState <= 13;
								end
							end
						end
			endcase
		end
	end
endmodule
