`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer:			Adrian Reyes
// Module Name:		I2C_Master_SpartanSlaveController
// Project Name:		I2C_Slave-LCD_Menu
// Target Devices:	SPARTAN 3E
// Description:		Controller for Spartan 3E slave
// Dependencies:
//////////////////////////////////////////////////////////////////////////////////
module I2C_Master_SpartanSlaveController(
	output reg [4:0]RAM_ADD,
	output reg [7:0]RemoteRAM_DIN,
	output RemoteRAM_W,
	output Master_Go,
	output reg Master_Stop,
	output reg Master_RW,
	output reg [5:0]Master_NumOfBytes,
	output reg [6:0]Master_SlaveAddr,
	output [7:0]Master_SlaveRegAddr,
	output reg [7:0]Master_DataWriteReg,
	output reg Controller_Done,
	input Controller_Enable,
	input [6:0]Menu_SlaveAddr,
	input Menu_RWControl,
	input [7:0]RAM_RDOUT,
	input Master_Done,
	input Master_Ready,
	input Master_ACK,
	input [7:0]Master_ReadData,
	input clk,
	input reset
	);

	/////////////////////////////// PARAMETERS //////////////////////////////////
	/////////////////////////////////////////////////////////////////////////////
	// Mode Parameters
	parameter MODE_SLAVE_WRITE = 0, MODE_SLAVE_READ = 1;
	// State Parameters
	parameter STATE_SETUP_INITIAL = 0, STATE_ASSERT_GO = 1, STATE_NEXT_BYTE = 2,
		STATE_SETUP_NEXT_BYTE = 3, STATE_STOP = 4;

	reg mode;
	reg [2:0]state;
	reg menuRWControlPrev;
	reg menuRWControlEvent;

	integer i;

	initial begin
		// Reset values
		Controller_Done = 0;
		state = STATE_SETUP_INITIAL;
		Master_RW = MODE_SLAVE_WRITE;
		Master_DataWriteReg = 0;
	end

	assign Master_SlaveRegAddr = RAM_ADD;
	// Put outside the always
	assign Master_Go = (state == STATE_WRITE_ASSERT_GO ||
						state == STATE_READ_ASSERT_GO);

	assign RemoteRAM_W = mode == MODE_SLAVE_READ && state == STATE_READ_SETUP_NEXT_BYTE;

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
		else begin
			if (Controller_Enable) begin
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
					case (state)
						STATE_SETUP_INITIAL:
								begin
									if (Master_Done) begin
										// Set whether we are reading or writing
										Master_RW <= Menu_RWControl;
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
						STATE_ASSERT_GO:
								begin
									// Move on to the next state
									state <= STATE_NEXT_BYTE;
								end
						STATE_NEXT_BYTE:
								begin
									// Wait for master to become Master_Ready
									if (Master_Ready) begin
										if (Menu_RWControl == MODE_SLAVE_WRITE)
											// Set next byte to send to slave
											Master_DataWriteReg <= RAM_RDOUT;
										else
											// Get data read from slave
											RemoteRAM_DIN <= Master_ReadData;
										// Move on to the next state.
										state <= STATE_SETUP_NEXT_BYTE;
									end
								end
						STATE_SETUP_NEXT_BYTE:
								begin // Need to wait for Master_Done or something
									// If Controller done writing to slave
									if (RAM_ADD == 31)
										// Start over
										//state <= STATE_WRITE_SETUP_INITIAL;
										// Stop
										state <= STATE_STOP;
									else if (!Master_Ready) begin
										RAM_ADD <= RAM_ADD + 1;
										state <= STATE_NEXT_BYTE;
									end
								end
						STATE_STOP:
								begin
									Controller_Done <= 1;
								end
					endcase
				end
			end // End If Enabled
		end // End Else NOT reset
	end

endmodule
