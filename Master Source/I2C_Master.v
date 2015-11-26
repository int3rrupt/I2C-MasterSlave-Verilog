`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer:			Adrian Reyes
// Module Name:		I2C_MASTER
// Project Name:		I2C_Master-LCD_TempSensor
// Target Devices:	SPARTAN 3E
// Description:		I2C Master
// Dependencies:		Counter
//							Stretch
//////////////////////////////////////////////////////////////////////////////////
module I2C_Master(
	input go,
	output reg done,
	output ready,
	input rw,
	input [5:0] N_Byte,				// Number of Bytes to transmit
	input [6:0] dev_add,				// Device Address (Slave Address)
	input [7:0] dwr_DataWriteReg,	// Data to be written to a slave
	input [7:0] R_Pointer,			// Register Pointer (Address)
	output reg [7:0] drd_lcdData,	// Data to be written to LCD
	output reg ack_e,
	inout scl,
	inout sda,
	input clk,
	input reset
	);

	wire [9:0] count;
	wire stretch;
	wire waiting;					// Flag indicating whether the Master is in the
										// WAITING state
	wire k;
	wire ne;
	wire wbit;
	wire pe;
	wire rbit;

	reg scl_int;					// Flag indicating whether Serial Clock Output
										// should be interrupted
	reg sda_int;					// Flag indicating whether Serial Data Output
										// should be interrupted

	wire idle;						// Flag indicating whether the serial bus is Idle
	reg [3:0] currentState;		// Holds the current state of the state machine
	reg [7:0] RTX_DataWrite;	// Register used to hold the data to be written
										// to slave
	reg [7:0] R_DevAddr;			// Register used to hold the device address to
										// connect to
	reg [5:0] NB;					// Holds the Number of Bytes from N_Byte input
	reg R_W;							// Holds the Read/Write bit from rw input
	reg [3:0] bc;					// Counter used to keep track of bits transmitted
	reg [7:0] RRX_DataRead;		// Register used to hold the sda data that was read

	// State declarations
	parameter WAITING = 4'b0001, START = 4'b0010, D_ADD = 4'b0011, SACK1 = 4'b0100,
		WR_RP = 4'b0101, SACK2 = 4'b0110, SR = 4'b0111, D_ADD1 = 4'b1000,
		SACK3 = 4'b1001, WR = 4'b1010, SACK = 4'b1011, STOP = 4'b1100,
		RD = 4'b1101, MACK = 4'b1110;

	// Initialize
	initial begin
		scl_int = 1;
		sda_int = 1;
		drd_lcdData = 0;
		done = 0;
		ack_e = 0;
		currentState = WAITING;
	end

	I2C_Master_Counter counterModule (count, stretch, waiting, clk, reset);
	I2C_Master_Stretch stretchModule (stretch, pe, rbit, scl, clk, reset);

	// Segments
	assign k = (count[7:0] == 0);
	assign ne = k && (count[9:8] == 0);
	assign wbit = k && (count[9:8] == 1);
	assign pe = k && (count[9:8] == 2);
	assign rbit = k && (count[9:8] == 3);

	assign scl = (scl_int == 1) ? 1'bz : 0;
	assign sda = (sda_int == 1) ? 1'bz : 0;
	assign waiting = currentState == WAITING;
	assign ready = (currentState == SACK2 && R_W == 0) ||
						(currentState == SACK && NB > 0) ||
						(currentState == MACK && wbit);

	// Continuously assign idle value
	assign idle = scl && sda;

	always@(posedge clk) begin
		if (reset) begin
			// Interrupt the serial clock
			scl_int <= 1;
			// Interrupt the serial data
			sda_int <= 1;
			drd_lcdData <= 0;
			done <= 1;
			ack_e <= 0;
			// Reset state
			currentState <= WAITING;
		end
		else begin
			case (currentState)
				WAITING:	begin
								// If go is asserted by Controller AND communication lines
								// are idle
								if (go && idle) begin
									// Store Register Address given by Controller to
									// RTX_DataWrite internal register
									RTX_DataWrite <= R_Pointer;
									// Store Slave address with padded zero (read) to
									// R_DevAddr internal register
									R_DevAddr <= {dev_add, 1'b0};
									// Assign Byte Count to NB internal register
									NB <= N_Byte;
									// Store rw flag in R_W internal register
									R_W <= rw;
									// Clear acknowledge flag
									ack_e <= 0;
									// Clear done flag
									done <= 0;
									// Move on to Start state
									currentState <= START;
								end
								else begin
									// Don't pull Serial Clock down
									scl_int <= 1;
									// Don't pull Serial Data down
									sda_int <= 1;
								end
							end //End WAITING
				START:	begin : Initiate_Start_Sequence
								// If we are in read bit segment pull Serial Data down to
								// initiate START signal
								if (rbit)
									sda_int <= 0;
								// Else if we are at Negative Edge and Serial Data was
								// pulled down
								else begin
									if (ne && sda == 0) begin
										// Pull Serial Clock down
										scl_int <= 0;
										// Reset the bit count to 8
										bc <= 8;
										// Move on to Data Address state
										currentState <= D_ADD;
									end
								end
							end // End START
				D_ADD:	begin : Send_Device_Address
								if (wbit) begin
									if (bc > 0) begin
										sda_int <= R_DevAddr[bc - 1];
										bc <= bc - 1;
									end
								end
								else begin
									if (pe)
										scl_int <= 1;
									else begin
										if (ne) begin
											if (bc == 0) begin
												scl_int <= 0;
												sda_int <= 1;
												currentState <= SACK1;
											end
											else
												scl_int <= 0;
										end
									end
								end // End Else
							end // End D_ADD
				SACK1:	begin : Receive_Acknowledgement_1
								if (pe)
									scl_int <= 1;
								else begin
									// If at read bit segment
									if (rbit) begin
										// If Serial Data is high set acknowledged flag
										if (sda != 1'b0)
											ack_e <= 1;
										// Else clear acknowledge flag
										else
											ack_e <= 0;
									end
									else begin
										if (ne) begin
											scl_int <= 0;
											sda_int <= 1;
											bc <= 8;
											currentState <= WR_RP;
										end
									end
								end // End else
							end // End SACK1
				WR_RP:	begin : Send_Register_Address
								if (wbit) begin
									if (bc > 0) begin
										sda_int <= RTX_DataWrite[bc - 1];
										bc <= bc - 1;
									end
								end
								else begin
									if (pe)
										scl_int <= 1;
									else begin
										if (ne) begin
											if (bc == 0) begin
												scl_int <= 0;
												sda_int <= 1;
												currentState <= SACK2;
											end
											else
												scl_int <= 0;
										end
									end
								end // End Else
							end // End WR_RP
				SACK2:	begin : Receive_Acknowledgement_2
								if (pe)
									scl_int <= 1;
								else begin
									if (rbit) begin
										if (sda != 1'b0)
											ack_e <= 1;
										else
											ack_e <= 0;
									end
									else begin
										if (ne) begin
											if (R_W) begin
												scl_int <= 0;
												sda_int <= 1;
												bc <= 8;
												currentState <= SR;
											end
											else begin
												scl_int <= 0;
												sda_int <= 1;
												bc <= 8;
												RTX_DataWrite <= dwr_DataWriteReg;
												currentState <= WR;
											end
										end
									end
								end // End Else
							end // End SACK2
				SR:		begin : Initiate_Start_Sequence2_For_Read
								if (wbit)
									scl_int <= 1;
								else begin
									if (rbit)
										sda_int <= 0;
									else begin
										if (ne && sda == 1'b0) begin
											scl_int <= 0;
											bc <= 8;
											R_DevAddr <= {dev_add, 1'b1};
											currentState <= D_ADD1;
										end
									end
								end // End Else
							end // End SR
				D_ADD1:	begin : Send_Device_Address_Again_For_Read
								if (wbit) begin
									if (bc > 0) begin
										sda_int <= R_DevAddr[bc - 1];
										bc <= bc - 1;
									end
								end
								else begin
									if (pe)
										scl_int <= 1;
									else begin
										if (ne) begin
											if (bc == 0) begin
												scl_int <= 0;
												sda_int <= 1;
												currentState <= SACK3;
											end
											else
												scl_int <= 0;
										end
									end
								end //End Else
							end // End D_ADD1
				SACK3:	begin : Receive_Acknowledgement_3
								if (pe)
									scl_int <= 1;
								else begin
									if (rbit) begin
										if (sda != 1'b0)
											ack_e <= 1;
										else
											ack_e <= 0;
									end
									else begin
										if (ne) begin
											scl_int <= 0;
											sda_int <= 1;
											bc <= 8;
											currentState <= RD;
										end
									end
								end // End Else
							end // End SACK3
				WR:		begin : Send_Data
								if (wbit) begin
									if (bc > 0) begin
										sda_int <= RTX_DataWrite[bc - 1];
										bc <= bc - 1;
									end
								end
								else begin
									if (pe)
										scl_int <= 1;
									else begin
										if (ne) begin
											if (bc == 0) begin
												scl_int <= 0;
												sda_int <= 1;
												NB <= NB - 1;
												currentState <= SACK;
											end
											else
												scl_int <= 0;
										end
									end
								end // End Else
							end // End WR
				SACK:		begin : Receive_Acknowledgement_For_Data_Sent
								if (pe)
									scl_int <= 1;
								else begin
									if (rbit) begin
										if (sda != 1'b0)
											ack_e <= 1;
										else
											ack_e <= 0;
									end
									else begin
										if (ne) begin
											if (NB > 0) begin
												scl_int <= 0;
												sda_int <= 1;
												bc <= 8;
												RTX_DataWrite <= dwr_DataWriteReg;
												currentState <= WR;
											end
											else begin
												scl_int <= 0;
												sda_int <= 0;
												currentState <= STOP;
											end
										end
									end
								end // End Else
							end // End SACK
				STOP:		begin : Stop_And_Return_To_Waiting
								if (pe)
									scl_int <= 1;
								else begin
									if (rbit)
										sda_int <= 1'b1;
									else begin
										if (ne) begin
											scl_int <= 1;
											sda_int <= 1;
											drd_lcdData <= 0;
											ack_e <= 0;
											done <= 1;
											currentState <= WAITING;
										end
									end
								end // End Else
							end // End STOP
				RD:		begin : Read_Data_From_Slave
								if (pe)
									scl_int <= 1;
								else begin
									if (rbit) begin
										if (bc > 0) begin
											RRX_DataRead[bc - 1] <= sda;
											bc <= bc - 1;
										end
									end
									else begin
										if (ne) begin
											if (bc == 0) begin
												scl_int <= 0;
												drd_lcdData <= RRX_DataRead;
												NB <= NB - 1;
												RRX_DataRead <= 0;
												currentState <= MACK;
											end
											else
												scl_int <= 0;
										end
									end
								end // End Else
							end // End RD
				MACK:		begin
								if (wbit) begin
									if (NB > 0)
										sda_int <= 0;
									else
										sda_int <= 1;
								end
								else begin
									if (pe)
										scl_int <= 1;
									else begin
										if (ne) begin
											if (NB > 0) begin
												scl_int <= 0;
												bc <= 8;
												sda_int <= 1;
												currentState <= RD;
											end
											else begin
												scl_int <= 0;
												bc <= 8;
												sda_int <= 0;
												currentState <= STOP;
											end
										end
									end
								end // End Else
							end // End MACK
			endcase
		end // End else
	end // End always

endmodule
