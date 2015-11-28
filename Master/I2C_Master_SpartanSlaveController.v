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
	output reg [4:0]RADD,
	output reg [4:0]WADD,
	output reg [7:0]DIN,
	output reg W,
	output go,
	output reg rw,
	output reg [5:0] N_Byte,
	output reg [6:0] dev_add,
	output reg [7:0] dwr_DataWriteReg,
	output [7:0] R_Pointer,
	output reg stop,
	input menuRWControl,
	input [7:0]RDOUT,
	input [7:0] drd_lcdData,
	input done,
	input ready,
	input ack_e,
	input clk,
	input reset
	);

	/////////////////////////////// PARAMETERS //////////////////////////////////
	/////////////////////////////////////////////////////////////////////////////
	// Mode Parameters
	parameter MODE_SLAVE_WRITE = 0, MODE_SLAVE_READ = 1;
	// Write State Parameters
	parameter STATE_WRITE_SETUP_INITIAL = 0, STATE_WRITE_ASSERT_GO = 1,
		STATE_WRITE_SEND_NEXT_BYTE = 2, STATE_WRITE_SETUP_NEXT_BYTE = 3;
	// Read State Parameters
	parameter STATE_READ_SETUP_INITIAL = 0, STATE_READ_ASSERT_GO = 1,
		STATE_READ_GET_NEXT_BYTE = 2, STATE_READ_SETUP_NEXT_BYTE = 3;

	reg mode;
	reg [4:0] state;
	reg [7:0] lcdData[0:31];
	reg [7:0] Confg_R_add;
	reg [6:0] device_address;
	reg [15:0] data;
	reg menuRWControlPrev;
	reg menuRWControlEvent;

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
		state = STATE_WRITE_INITIAL_SETUP;
		Confg_R_add = 8'b00000001;
		device_address = 7'b1100111;
		config_first_byte = 8'b11100011;
		config_second_byte = 8'b00011100;
		Temp_R_add = 8'b00000101;
		for (i = 0; i < 32; i = i+1) begin
			lcdData[i] = 8'hFE; // FE = Empty Space
		end
	end

	assign R_Pointer = menuRWControl ? RADD : WADD;
	// Put outside the always
	assign go = (currentState == STATE_WRITE_INITIAL_SETUP ||
						currentState == STATE_READ_ASSERT_GO);

	assign W = mode == MODE_SLAVE_READ && state == STATE_READ_SETUP_NEXT_BYTE;

	// Menu RW Control event watcher
	always@(posedge clk) begin
		menuRWControlPrev <= menuRWControl;
		if ((menuRWControl == 1 && menuRWControlPrev == 0) ||
				(menuRWControl == 0 && menuRWControlPrev == 1)
			menuRWControlEvent <= 1;
		else menuRWControlEvent <= 0;
	end

	always@(posedge clk) begin
		if (reset) begin
			// If resetting go back to state zero
			state <= 0;
		end
		else begin
			// If change to rw from menu controller
			if (menuRWControlEvent) begin
				// Change modes
				mode <= menuRWControl;
				// Reset state
				state <= 0;
				// Send stop signal to master
				stop <= 1;
			end
			else begin
				case (mode)
					MODE_SLAVE_WRITE:
							begin
								case (state)
									STATE_WRITE_SETUP_INITIAL:
											begin
												if (done) begin
													// Set to write
													rw <= 0;
													// Reset byte counter
													N_Byte <= 32;
													// Set register begin address
													RADD <= 0;
													// Set device address
													dev_add <= device_address;
													currentState <= STATE_WRITE_ASSERT_GO;
												end
											end
									STATE_WRITE_ASSERT_GO:
											begin
												// Move on to the next state
												currentState <= STATE_WRITE_SEND_NEXT_BYTE;
											end
									STATE_WRITE_SEND_NEXT_BYTE:
											begin
												// Wait for master to become ready
												if (ready) begin
													// Set next byte
													dwr_DataWriteReg <= RDOUT;
													// Move on to the next state.
													currentState <= STATE_WRITE_SETUP_NEXT_BYTE;
												end
											end
									STATE_WRITE_SETUP_NEXT_BYTE:
											begin // Need to wait for done or something
												// If done writing to slave
												if (RADD == 31)
													// Start over
													state <= STATE_WRITE_SETUP_INITIAL;
												else if (!ready) begin
													RADD <= RADD + 1;
													currentState <= STATE_WRITE_SEND_NEXT_BYTE;
												end
											end
								endcase
							end
					MODE_SLAVE_READ:
							begin
								case (state)
									STATE_READ_SETUP_INITIAL:
											begin
												// Wait for the I2C Master to assert done flag
												if (done) begin
													// Set to read
													rw <= 1;
													// Reset byte counter
													N_Byte <= 32;
													// Set register begin address
													WADD <= 0;
													// Set device address
													dev_add <= device_address;
													currentState <= STATE_READ_ASSERT_GO;
												end
											end
									STATE_READ_ASSERT_GO:
											begin
												// Move on to the next state
												currentState <= STATE_READ_GET_NEXT_BYTE;
											end
									STATE_READ_GET_NEXT_BYTE:
											begin
												// Wait for master to become ready
												if (ready) begin
													// Get data read from slave
													DIN <= drd_lcdData
													// Move on to the next state.
													currentState <= STATE_READ_SETUP_NEXT_BYTE;
												end
											end
									STATE_READ_SETUP_NEXT_BYTE:
											begin
												// If done reading from slave
												if (WADD == 31)
													// Start over
													state <= STATE_READ_SETUP_INITIAL;
												else if (!ready) begin
													WADD <= WADD + 1;
													currentState <= STATE_READ_GET_NEXT_BYTE;
												end
											end
								endcase
							end
				endcase
			end
		end
	end

endmodule
