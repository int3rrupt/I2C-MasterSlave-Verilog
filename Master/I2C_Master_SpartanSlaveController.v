`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer:        Adrian Reyes
// Module Name:     Controller
// Project Name:    I2C
// Target Devices:  SPARTAN 3E
// Description:     LCDI Controller
// Dependencies:    EightBitBinaryToBCD
//////////////////////////////////////////////////////////////////////////////////
module I2C_Master_SpartanSlaveController(
	output reg [4:0]RAM_ADD,
	output reg [7:0]RAM_DIN,
	output RAM_W,
	output Master_Go,
	output reg Master_RW,
	output reg [5:0]Master_NumOfBytes,
	output reg [6:0]Master_SlaveAddr,
	output reg [7:0]Master_DataWriteReg,
	output [7:0]Master_SlaveRegAddr,
	output reg Master_Stop,
	output reg Controller_Done,
	input Controller_Enable,
	input [6:0]Menu_SlaveAddr,
	input Menu_RWControl,
	input Master_Done,
	input Master_Ready,
	input Master_ACK,
	input [7:0]Master_ReadData,
	input [7:0]RAM_RDOUT,
	input clk,
	input reset
	);

	/////////////////////////////// PARAMETERS //////////////////////////////////
	/////////////////////////////////////////////////////////////////////////////
	// Mode Parameters
	parameter MODE_SLAVE_WRITE = 0, MODE_SLAVE_READ = 1;
	// Write State Parameters
	parameter STATE_WRITE_SETUP_INITIAL = 0, STATE_WRITE_ASSERT_GO = 1,
		STATE_WRITE_SEND_NEXT_BYTE = 2, STATE_WRITE_SETUP_NEXT_BYTE = 3,
		STATE_STOP = 4;
	// Read State Parameters
	parameter STATE_READ_SETUP_INITIAL = 0, STATE_READ_ASSERT_GO = 1,
		STATE_READ_GET_NEXT_BYTE = 2, STATE_READ_SETUP_NEXT_BYTE = 3;

	reg mode;
	reg [2:0]state;
	reg [6:0] device_address;
	reg [15:0] data;
	reg menuRWControlPrev;
	reg menuRWControlEvent;

	integer i;

	initial begin
		// Reset values
		state = 0;
		Master_RW = 1;
		Master_DataWriteReg = 0;
		device_address = 7'b1100111;
	end

	assign Master_SlaveRegAddr = RAM_ADD;
	// Put outside the always
	assign Master_Go = (state == STATE_WRITE_ASSERT_GO ||
						state == STATE_READ_ASSERT_GO);

	assign RAM_W = mode == MODE_SLAVE_READ && state == STATE_READ_SETUP_NEXT_BYTE;

	// Menu RW Control event watcher
	always@(posedge clk) begin
		menuRWControlPrev <= Menu_RWControl;
		if ((Menu_RWControl == 1 && menuRWControlPrev == 0) ||
				(Menu_RWControl == 0 && menuRWControlPrev == 1))
			menuRWControlEvent <= 1;
		else menuRWControlEvent <= 0;
	end

	always@(posedge clk) begin
		if (reset) begin
			// If resetting back to state zero
			state <= 0;
		end
		else if (Controller_Enable) begin
			// If change to rw from menu controller
			if (menuRWControlEvent) begin
				// Change modes
				//mode <= Menu_RWControl;
				// Reset state
				state <= 0;
				// Send Stop signal to master
				Master_Stop <= 1;
			end
			else begin
				Master_Stop <= 0;
				case (Menu_RWControl)
					MODE_SLAVE_WRITE:
							begin
								case (state)
									STATE_WRITE_SETUP_INITIAL:
											begin
												if (Master_Done) begin
													// Set to write
													Master_RW <= 0;
													// Reset byte counter
													Master_NumOfBytes <= 32;
													// Set register begin address
													RAM_ADD <= 0;
													// Set device address
													Master_SlaveAddr <= Menu_SlaveAddr;
													// Clear Done flag
													Controller_Done <= 0;
													state <= STATE_WRITE_ASSERT_GO;
												end
											end
									STATE_WRITE_ASSERT_GO:
											begin
												// Move on to the next state
												state <= STATE_WRITE_SEND_NEXT_BYTE;
											end
									STATE_WRITE_SEND_NEXT_BYTE:
											begin
												// Wait for master to become Master_Ready
												if (Master_Ready) begin
													// Set next byte
													Master_DataWriteReg <= RAM_RDOUT;
													// Move on to the next state.
													state <= STATE_WRITE_SETUP_NEXT_BYTE;
												end
											end
									STATE_WRITE_SETUP_NEXT_BYTE:
											begin // Need to wait for Master_Done or something
												// If Master_Done writing to slave
												if (RAM_ADD == 31)
													// Start over
													//state <= STATE_WRITE_SETUP_INITIAL;
													state <= STATE_STOP;
												else if (!Master_Ready) begin
													RAM_ADD <= RAM_ADD + 1;
													state <= STATE_WRITE_SEND_NEXT_BYTE;
												end
											end
									STATE_STOP:
											begin
												Controller_Done <= 1;
											end
								endcase
							end
					MODE_SLAVE_READ:
							begin
								case (state)
									STATE_READ_SETUP_INITIAL:
											begin
												// Wait for the I2C Master to assert Master_Done flag
												if (Master_Done) begin
													// Set to read
													Master_RW <= 1;
													// Reset byte counter
													Master_NumOfBytes <= 32;
													// Set register begin address
													RAM_ADD <= 0;
													// Set device address
													Master_SlaveAddr <= Menu_SlaveAddr;
													// Clear Done flag
													Controller_Done <= 0;
													state <= STATE_READ_ASSERT_GO;
												end
											end
									STATE_READ_ASSERT_GO:
											begin
												// Move on to the next state
												state <= STATE_READ_GET_NEXT_BYTE;
											end
									STATE_READ_GET_NEXT_BYTE:
											begin
												// Wait for master to become Master_Ready
												if (Master_Ready) begin
													// Get data read from slave
													RAM_DIN <= Master_ReadData;
													// Move on to the next state.
													state <= STATE_READ_SETUP_NEXT_BYTE;
												end
											end
									STATE_READ_SETUP_NEXT_BYTE:
											begin
												// If Master_Done reading from slave
												if (RAM_ADD == 31)
													// Start over
													//state <= STATE_READ_SETUP_INITIAL;
													state <= STATE_STOP;
												else if (!Master_Ready) begin
													RAM_ADD <= RAM_ADD + 1;
													state <= STATE_READ_GET_NEXT_BYTE;
												end
											end
									STATE_STOP:
											begin
												Controller_Done <= 1;
											end
								endcase
							end
				endcase
			end
		end
	end

endmodule
