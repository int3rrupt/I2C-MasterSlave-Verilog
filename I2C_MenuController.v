`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer:			Adrian Reyes
// Module Name:		I2C_MenuController
// Project Name:		I2C_Slave-LCD_Menu
// Target Devices:	SPARTAN 3E
// Description:		I2C Menu Controller
//							Module that takes input from user and performs desired
//							operation
// Dependencies:
//////////////////////////////////////////////////////////////////////////////////
module I2C_MenuController(
	// LCDI Outputs
	output [4:0]LCD_WADD,			// LCD Word Address
	output [7:0]LCD_DIN,				// LCD Data In
	output LCD_W,						// LCD Write
	output reg RemoteRWControl,	// RW Control for remote
	output enableCursor,
	output reg cursorLeft,
	output reg cursorRight,
	output [7:0]editAddress,
	output reg [1:0]enableControllers,// Enable controller bits
	output reg [4:0]MenuRAM_Select,
	output reg [1:0]MultiRAM_SEL,
	output reg [4:0]MultiRAM_ADD,
	output reg [7:0]MultiRAM_DIN,
	output MultiRAM_W,
	output MultiRAM_Clear,
	output reg [6:0]SlaveAddr,
	output reg I2C_Mode,
	input [7:0]MultiRAM_DOUT,
	input Controller_Done,
	input rotary_event,				// Flag indicating Rotary Button rotation
	input rotary_left,				// Rotary rotation direction
	input rotaryBtn,					// Rotary Button used for Selecting
	input charColumnLeftBtn,		// Button used to change character index
	input charColumnRightBtn,		// Button used to change character index
	input menuBtn,						// Menu Button
	input clk,
	input reset
	);

	/////////////////////////////// PARAMETERS //////////////////////////////////
	/////////////////////////////////////////////////////////////////////////////
	// Register widths
	//parameter BITS_2 = 2, BITS_5 = 5;
	// I2C Mode
	parameter I2C_MODE_MASTER = 0, I2C_MODE_SLAVE = 1;
	// Parent Mode Parameters
	parameter
		MODE_MENU = 0, MODE_DISPLAY_REMOTE = 1, MODE_DISPLAY_LOCAL = 2,
		MODE_MODIFY_LOCAL_RAM = 3, MODE_CLEAR_RAM = 4, MODE_WRITE_TO_REMOTE = 5,
		MODE_READ_FROM_REMOTE = 6;
	// Sub Mode parameters
	parameter SUBMODE_REFRESH_MENU_TITLE = 0, SUBMODE_REFRESH_MENU_OPTION = 1,
		SUBMODE_DISPLAY_REMOTE = 2, SUBMODE_DISPLAY_LOCAL = 3,
		SUBMODE_MODIFY_LOCAL_RAM_DISPLAY = 4, SUBMODE_MODIFY_LOCAL_RAM_POSITION_SEL = 5,
		SUBMODE_MODIFY_LOCAL_RAM_CHAR_SEL = 6, SUBMODE_CLEAR_LOCAL_RAM_CONFIRM = 7,
		SUBMODE_CLEAR_LOCAL_RAM = 8, SUBMODE_WAIT_FOR_SELECTION = 9,
		SUBMODE_WRITE_TO_REMOTE_WRITING = 10, SUBMODE_WRITE_TO_REMOTE_WAITING = 11;
	// State parameters
	parameter
		STATE_REFRESH_LCD_MENU_TITLE =			0,
		STATE_REFRESH_LCD_MENU_OPTION =			1,
		STATE_SETUP_LCD_DATA =						2,
		STATE_WRITE_TO_LCD =							3,
		STATE_WAIT_FOR_SELECTION =					4,
		STATE_DISPLAY_REMOTE =						5,
		STATE_DISPLAY_LOCAL =						6,
		STATE_MODIFY_LOCAL_RAM =					7,
		STATE_WAIT_FOR_ROTARY_OR_MENU_PRESS =	8,
		STATE_MODIFY_LOCAL_RAM_CHAR_POS_SEL =	9,
		STATE_MODIFY_LOCAL_RAM_CHAR_SEL =		10,
		STATE_CLEAR_LOCAL_RAM_CONFIRM =			11,
		STATE_CLEAR_LOCAL_RAM =						12,
		STATE_MODE_REDIRECT =						13,
		STATE_WRITE_TO_REMOTE =						14,
		STATE_WRITE_TO_REMOTE_WAIT =				15,
		STATE_READ_FROM_REMOTE =					16,
		STATE_SWITCH_I2C_MODE =						17;
	// RAM select parameters
	parameter RAM_SEL_MENU = 2'd0, RAM_SEL_REMOTE = 2'd1, RAM_SEL_LOCAL = 2'd2;
	// Menu parameters
	parameter
		MENU_TITLE_MAIN_MASTER =			0,
		MENU_TITLE_MAIN_SLAVE =				1,
		MENU_OPTION_DISPLAY_REMOTE =		2,
		MENU_OPTION_DISPLAY_LOCAL =		3,
		MENU_OPTION_MODIFY_LOCAL_RAM =	4,
		MENU_OPTION_CLEAR_LOCAL_RAM =		5,
		MENU_OPTION_I2C_ACTIONS =			6,
		MENU_TITLE_I2C_ACTIONS =			7,
		MENU_TITLE_ARE_YOU_SURE =			8,
		MENU_OPTION_YES =						9,
		MENU_OPTION_NO =						10,
		MENU_OPTION_WRITE_TO_REMOTE =		11,
		MENU_OPTION_READ_FROM_REMOTE =	12,
		MENU_OPTION_SET_LOCAL_ADDR = 		13,
		MENU_TITLE_STATUS =					14,
		MENU_STATUS_WRITING =				15,
		MENU_STATUS_ACTION_COMPLETE =		16,
		MENU_OPTION_SWITCH_I2C_MODE = 	17;
	parameter ENABLE_CONTROLLER_SPARTAN_SLAVE = 1, ENABLE_CONTROLLER_TEMP = 2;

	//////////////////////////////// REGISTERS //////////////////////////////////
	/////////////////////////////////////////////////////////////////////////////
	reg [4:0]state;							// Current state of the controller
	reg [3:0]mode;								// Current mode of the controller
	reg [3:0]subMode;							// Current sub mode of the controller
	// Display Selection Registers
	reg [4:0]displayOption;					// The menu option to display
	// LCD registers
	reg [4:0]lcdAddress;						// The LCD address to write to
	reg [7:0]lcdData;							// The LCD data to be written
	reg [4:0]lcdStopAddress;				// The last LCD address to write to
	// Character Select Registers
	reg [4:0]currentCharPos;				// The current position of the character
													// being edited
	reg [3:0]currentCharColumn;			// The current character column index
	reg [3:0]currentCharRow;				// The current character row index
	wire [7:0]currentChar;					// The current character based on current
													// character column and row
	reg [7:0]currentDisplayedChar;		// The currently displayed character
	reg ramWriteReady;						// Flag used to indicate when data is ready
													// to be written to the selected RAM

	initial begin
		I2C_Mode = I2C_MODE_MASTER;
		mode= MODE_MENU;
		SlaveAddr = 7'b1100111;
		state = STATE_REFRESH_LCD_MENU_TITLE;
		displayOption = MENU_OPTION_DISPLAY_REMOTE;
		currentCharPos = 0;
		currentCharColumn = 4'b0100;
		currentCharRow = 4'b0001;
		enableControllers = 2'b00;
	end

	////////////////////////////////// ASSIGN ///////////////////////////////////
	/////////////////////////////////////////////////////////////////////////////
	// Continuously assign values to LCD ports
	assign LCD_WADD = lcdAddress;
	assign LCD_DIN = subMode == SUBMODE_MODIFY_LOCAL_RAM_CHAR_SEL ? lcdData : MultiRAM_DOUT;
	assign LCD_W = state == STATE_WRITE_TO_LCD;
	// Continuously concatenate the current character column and row
	assign currentChar = {currentCharColumn, currentCharRow};
	// Continuously assign MultiRAM_W
	assign MultiRAM_W = (subMode == SUBMODE_MODIFY_LOCAL_RAM_CHAR_SEL) && ramWriteReady;
	assign MultiRAM_Clear = subMode == SUBMODE_CLEAR_LOCAL_RAM;
	// Continuously assign cursor enable
	assign enableCursor = subMode == SUBMODE_MODIFY_LOCAL_RAM_POSITION_SEL;

	////////////////////////////////// ALWAYS ///////////////////////////////////
	/////////////////////////////////////////////////////////////////////////////
	always@(posedge clk) begin
		// Check for rotary and button events
		if (reset || menuBtn) begin
			// Set mode
			mode <= MODE_MENU;
			// Reset to home position
			currentCharPos <= 0;
			// Reset character column and row index to letter A
			currentCharColumn <= 4;
			currentCharRow <= 1;
			// Return to first menu item on reset only
			//if (reset)
				displayOption <= MENU_OPTION_DISPLAY_REMOTE;
			// Refresh menu
			state <= STATE_REFRESH_LCD_MENU_TITLE;
		end
		else begin
			case(state)
				STATE_REFRESH_LCD_MENU_TITLE:
						begin
							// Set the subMode to Menu
							subMode <= SUBMODE_REFRESH_MENU_TITLE;
							// Select Menu RAM
							MultiRAM_SEL <= RAM_SEL_MENU;
							// Reset address to first character
							MultiRAM_ADD <= 0;
							// Reset LCD address to first character of first line
							lcdAddress <= 0;
							// Set the LCD stop address
							lcdStopAddress <= 15;
							// Select the Menu Title to display for current menu option
							case(displayOption)
								MENU_OPTION_DISPLAY_REMOTE:
										case (I2C_Mode)
											I2C_MODE_MASTER:
													MenuRAM_Select <= MENU_TITLE_MAIN_MASTER;
											I2C_MODE_SLAVE:
													MenuRAM_Select <= MENU_TITLE_MAIN_SLAVE;
										endcase
								MENU_OPTION_DISPLAY_LOCAL:
										case (I2C_Mode)
											I2C_MODE_MASTER:
													MenuRAM_Select <= MENU_TITLE_MAIN_MASTER;
											I2C_MODE_SLAVE:
													MenuRAM_Select <= MENU_TITLE_MAIN_SLAVE;
										endcase
								MENU_OPTION_MODIFY_LOCAL_RAM:
										case (I2C_Mode)
											I2C_MODE_MASTER:
													MenuRAM_Select <= MENU_TITLE_MAIN_MASTER;
											I2C_MODE_SLAVE:
													MenuRAM_Select <= MENU_TITLE_MAIN_SLAVE;
										endcase
								MENU_OPTION_CLEAR_LOCAL_RAM:
										case (I2C_Mode)
											I2C_MODE_MASTER:
													MenuRAM_Select <= MENU_TITLE_MAIN_MASTER;
											I2C_MODE_SLAVE:
													MenuRAM_Select <= MENU_TITLE_MAIN_SLAVE;
										endcase
								MENU_OPTION_I2C_ACTIONS:
										case (I2C_Mode)
											I2C_MODE_MASTER:
													MenuRAM_Select <= MENU_TITLE_MAIN_MASTER;
											I2C_MODE_SLAVE:
													MenuRAM_Select <= MENU_TITLE_MAIN_SLAVE;
										endcase
								MENU_OPTION_YES:
										MenuRAM_Select <= MENU_TITLE_ARE_YOU_SURE;
								MENU_OPTION_NO:
										MenuRAM_Select <= MENU_TITLE_ARE_YOU_SURE;
								MENU_OPTION_WRITE_TO_REMOTE:
										MenuRAM_Select <= MENU_TITLE_I2C_ACTIONS;
								MENU_OPTION_READ_FROM_REMOTE:
										MenuRAM_Select <= MENU_TITLE_I2C_ACTIONS;
								MENU_OPTION_SET_LOCAL_ADDR:
										MenuRAM_Select <= MENU_TITLE_I2C_ACTIONS;
								MENU_STATUS_WRITING:
										MenuRAM_Select <= MENU_TITLE_STATUS;
								MENU_STATUS_ACTION_COMPLETE:
										MenuRAM_Select <= MENU_TITLE_STATUS;
								MENU_OPTION_SWITCH_I2C_MODE:
										MenuRAM_Select <= MENU_TITLE_I2C_ACTIONS;
							endcase
							// Setup LCD data
							state <= STATE_SETUP_LCD_DATA;
						end
				STATE_REFRESH_LCD_MENU_OPTION:
						begin
							// Set the subMode to Menu
							subMode <= SUBMODE_REFRESH_MENU_OPTION;
							// Select Menu RAM
							MultiRAM_SEL <= RAM_SEL_MENU;
							// Reset address to first character
							MultiRAM_ADD <= 0;
							// Set LCD address to first character of second line
							lcdAddress <= 16;
							// Set the LCD stop address
							lcdStopAddress <= 31;
							// Select the Menu to display
							MenuRAM_Select <= displayOption;
							// Setup LCD data
							state <= STATE_SETUP_LCD_DATA;
						end
				STATE_SETUP_LCD_DATA:
						begin
							// Perform additional actions based on subMode
							case(subMode)
								SUBMODE_MODIFY_LOCAL_RAM_CHAR_SEL:
										currentDisplayedChar <= currentChar;
							endcase
							// Continue writing to LCD
							state <= STATE_WRITE_TO_LCD;
						end
				STATE_WRITE_TO_LCD:
						begin
							// If done writing to the display
							if (lcdAddress == lcdStopAddress) begin
								state <= STATE_MODE_REDIRECT;
							end
							else begin
								// Increment RAM data pointer
								MultiRAM_ADD <= MultiRAM_ADD + 1;
								// Increment lcd data pointer
								lcdAddress <= lcdAddress + 1;
								// W is asserted in this state, return to setup LCD
								// for next write
								state <= STATE_SETUP_LCD_DATA;
							end
						end
				STATE_WAIT_FOR_SELECTION:
						begin
							subMode <= SUBMODE_WAIT_FOR_SELECTION;
							// If the rotary button was pressed
							if (rotaryBtn) begin
								// Check which option was selected
								case(displayOption)
									MENU_OPTION_DISPLAY_REMOTE:
											// Display what the Master has sent
											state <= STATE_DISPLAY_REMOTE;
									MENU_OPTION_DISPLAY_LOCAL:
											// Display local RAM
											state <= STATE_DISPLAY_LOCAL;
									MENU_OPTION_MODIFY_LOCAL_RAM:
											// Modify local RAM
											state <= STATE_MODIFY_LOCAL_RAM;
									MENU_OPTION_CLEAR_LOCAL_RAM:
											// Clear Slave RAM
											state <= STATE_CLEAR_LOCAL_RAM_CONFIRM;
									MENU_OPTION_YES:
											// Confirm RAM Clear
											state <= STATE_MODE_REDIRECT;
									MENU_OPTION_NO:
											begin
												// Return to Main Menu
												displayOption <= MENU_OPTION_DISPLAY_REMOTE;
												state <= STATE_REFRESH_LCD_MENU_TITLE;
											end
									MENU_OPTION_I2C_ACTIONS:
											begin
												if (I2C_Mode == I2C_MODE_MASTER)
													displayOption <= MENU_OPTION_WRITE_TO_REMOTE;
												else
													displayOption <= MENU_OPTION_SET_LOCAL_ADDR;
												state <= STATE_REFRESH_LCD_MENU_TITLE;
											end
									MENU_OPTION_WRITE_TO_REMOTE:
											state <= STATE_WRITE_TO_REMOTE;
									MENU_OPTION_READ_FROM_REMOTE:
											state <= STATE_READ_FROM_REMOTE;
									MENU_OPTION_SWITCH_I2C_MODE:
											state <= STATE_SWITCH_I2C_MODE;
									MENU_STATUS_ACTION_COMPLETE:
											begin
												// Return to Main Menu
												displayOption <= MENU_OPTION_DISPLAY_REMOTE;
												state <= STATE_REFRESH_LCD_MENU_TITLE;
											end
								endcase
							end
							else if (rotary_event) begin
								case(displayOption)
									MENU_OPTION_DISPLAY_REMOTE:
											begin
												// If rotate right
												if (rotary_left)
													// Show next option
													displayOption <= MENU_OPTION_DISPLAY_LOCAL;
												// Else rotate left
												else
													// Show previous option
													displayOption <= MENU_OPTION_I2C_ACTIONS;
											end
									MENU_OPTION_DISPLAY_LOCAL:
											begin
												// If rotate right
												if (rotary_left)
													// Show next option
													displayOption <= MENU_OPTION_MODIFY_LOCAL_RAM;
													// Else rotate left
												else
													// Show previous option
													displayOption <= MENU_OPTION_DISPLAY_REMOTE;
											end
									MENU_OPTION_MODIFY_LOCAL_RAM:
											begin
												// If rotate right
												if (rotary_left)
													// Show next option
													displayOption <= MENU_OPTION_CLEAR_LOCAL_RAM;
												// Else rotate left
												else
													// Show previous option
													displayOption <= MENU_OPTION_DISPLAY_LOCAL;
											end
									MENU_OPTION_CLEAR_LOCAL_RAM:
											begin
												// If rotate right
												if (rotary_left)
													// Show next option
													displayOption <= MENU_OPTION_I2C_ACTIONS;
												// Else rotate left
												else
													// Show previous option
													displayOption <= MENU_OPTION_MODIFY_LOCAL_RAM;
											end
									MENU_OPTION_I2C_ACTIONS:
											begin
												// If rotate right
												if (rotary_left)
													// Show next option
													displayOption <= MENU_OPTION_DISPLAY_REMOTE;
												// Else rotate left
												else
													// Show previous option
													displayOption <= MENU_OPTION_CLEAR_LOCAL_RAM;
											end
									MENU_OPTION_YES:
											begin
												// Show next option
												displayOption <= MENU_OPTION_NO; end
									MENU_OPTION_NO:
											begin
												// Show next option
												displayOption <= MENU_OPTION_YES;
											end
									MENU_OPTION_WRITE_TO_REMOTE:
											begin
												// If rotate right
												if (rotary_left)
													// Show next option
													displayOption <= MENU_OPTION_READ_FROM_REMOTE;
												// Else rotate left
												else
													// Show previous option
													displayOption <= MENU_OPTION_SWITCH_I2C_MODE;
											end
									MENU_OPTION_READ_FROM_REMOTE:
											begin
												// If rotate right
												if (rotary_left)
													// Show next option
													displayOption <= MENU_OPTION_SET_LOCAL_ADDR;
												// Else rotate left
												else
													// Show previous option
													displayOption <= MENU_OPTION_WRITE_TO_REMOTE;
											end
									MENU_OPTION_SET_LOCAL_ADDR:
											begin
												// If rotate right
												if (rotary_left)
													// Show next option
													displayOption <= MENU_OPTION_SWITCH_I2C_MODE;
												// Else rotate left
												else begin
													if (I2C_Mode == I2C_MODE_MASTER)
														// Show previous option
														displayOption <= MENU_OPTION_READ_FROM_REMOTE;
													else
														// Show previous option
														displayOption <= MENU_OPTION_SWITCH_I2C_MODE;
												end
											end
									MENU_OPTION_SWITCH_I2C_MODE:
											begin
												// If rotate right
												if (rotary_left) begin
													if (I2C_Mode == I2C_MODE_MASTER)
														// Show next option
														displayOption <= MENU_OPTION_WRITE_TO_REMOTE;
													else
														// Show next option
														displayOption <= MENU_OPTION_SET_LOCAL_ADDR;
												end
												else
													// Show previous option
													displayOption <= MENU_OPTION_SET_LOCAL_ADDR;
											end
									MENU_STATUS_ACTION_COMPLETE:
											// Return to main menu
											displayOption <= MENU_OPTION_DISPLAY_REMOTE;
								endcase
								state <= STATE_REFRESH_LCD_MENU_TITLE;
							end // End else if rotary_event
						end
				STATE_WAIT_FOR_ROTARY_OR_MENU_PRESS:
						begin
							// Wait for rotary button press. RAM was displayed now
							// waiting to return to menu
							if (rotaryBtn) begin
								case (mode)
									MODE_DISPLAY_LOCAL:
											// Return to option
											displayOption <= MENU_OPTION_DISPLAY_LOCAL;
									MODE_WRITE_TO_REMOTE:
											// Return to option
											displayOption <= MENU_OPTION_WRITE_TO_REMOTE;
								endcase
								mode <= MODE_MENU;
								state <= STATE_REFRESH_LCD_MENU_TITLE;
							end
						end
				STATE_DISPLAY_REMOTE:
						begin
							// Wait for menu button press. RAM was displayed now
							// waiting to return to menu
							if (rotaryBtn) state <= STATE_REFRESH_LCD_MENU_TITLE;
							else begin
								// Select Master RAM
								MultiRAM_SEL <= RAM_SEL_REMOTE;
								// Reset address to first character
								MultiRAM_ADD <= 0;
								// Set LCD address to first character of second line
								lcdAddress <= 0;
								// Set the LCD stop address
								lcdStopAddress <= 31;
								// Set mode
								mode <= MODE_DISPLAY_REMOTE;
								// Set subMode to Display Master RAM
								subMode <= SUBMODE_DISPLAY_REMOTE;
								// Setup up LCD data to display Master RAM
								state <= STATE_SETUP_LCD_DATA;
							end
						end
				STATE_DISPLAY_LOCAL:
						begin
							// Select Slave RAM
							MultiRAM_SEL <= RAM_SEL_LOCAL;
							// Reset address to first character
							MultiRAM_ADD <= 0;
							// Set LCD address to first character of second line
							lcdAddress <= 0;
							// Set the LCD stop address
							lcdStopAddress <= 31;
							// Set mode
							mode <= MODE_DISPLAY_LOCAL;
							// Set subMode to Display Slave RAM
							subMode <= SUBMODE_DISPLAY_LOCAL;
							// Setup up LCD data to display Master RAM
							state <= STATE_SETUP_LCD_DATA;
						end
				STATE_MODIFY_LOCAL_RAM:
						begin
							// Select Slave RAM
							MultiRAM_SEL <= RAM_SEL_LOCAL;
							// Reset address to first character
							MultiRAM_ADD <= 0;
							// Set LCD address to first character of second line
							lcdAddress <= 0;
							// Set the LCD stop address
							lcdStopAddress <= 31;
							// Set mode
							mode <= MODE_MODIFY_LOCAL_RAM;
							// Set subMode to Display Slave RAM
							subMode <= SUBMODE_MODIFY_LOCAL_RAM_DISPLAY;
							// Setup up LCD data to display Master RAM
							state <= STATE_SETUP_LCD_DATA;
						end
				STATE_MODIFY_LOCAL_RAM_CHAR_POS_SEL:
						begin
							// Set the subMode
							subMode <= SUBMODE_MODIFY_LOCAL_RAM_POSITION_SEL;
							// Clear write ready flag
							ramWriteReady <= 0;
							// Wait for the rotary button to be pressed indicating
							// that the user has selected an LCD character position
							// to edit
							if (rotaryBtn) state <= STATE_MODIFY_LOCAL_RAM_CHAR_SEL;
							// Check for rotary event
							if (rotary_event) begin
								// Rotated left
								if (rotary_left) begin
									// Increment current character position
									currentCharPos <= currentCharPos + 1;
									cursorRight <= 1;
								end
								// Else rotated right
								else begin
									currentCharPos <= currentCharPos - 1;
									cursorLeft <= 1;
								end
							end
							else begin
								cursorRight <= 0;
								cursorLeft <= 0;
							end
						end
				STATE_MODIFY_LOCAL_RAM_CHAR_SEL:
						begin
							// Set the subMode
							subMode <= SUBMODE_MODIFY_LOCAL_RAM_CHAR_SEL;
							// Wait for the rotary button to be pressed indicating
							// that the user has selected an LCD character for the
							// current position
							if (rotaryBtn) begin
								MultiRAM_SEL <= RAM_SEL_LOCAL;
								MultiRAM_ADD <= currentCharPos;
								MultiRAM_DIN <= currentDisplayedChar;
								ramWriteReady <= 1;
								state <= STATE_MODIFY_LOCAL_RAM_CHAR_POS_SEL;
							end
							else begin
								if (rotary_event) begin
									// If rotary rotated left
									if (rotary_left)
										// Decrement current character row
										currentCharRow <= currentCharRow + 1;
									// Otherwise rotary rotated right
									else
										currentCharRow <= currentCharRow - 1;
								end
								else begin
									if (charColumnLeftBtn) begin
										case(currentCharColumn)
											4'b0010:	currentCharColumn <= 4'b1111;
											4'b1010:	currentCharColumn <= 4'b0111;
											// Decrement current character column
											default:	currentCharColumn <= currentCharColumn - 1;
										endcase
									end
									else if (charColumnRightBtn) begin
										case(currentCharColumn)
											4'b0111:	currentCharColumn <= 4'b1010;
											4'b1111:	currentCharColumn <= 4'b0010;
											// Decrement current character column
											default:	currentCharColumn <= currentCharColumn + 1;
										endcase
									end
								end
								if (currentDisplayedChar != currentChar) begin
									// Set the LCD data to first the current character
									lcdData <= currentChar;
									// Set LCD address to first character of second line
									lcdAddress <= currentCharPos;
									// Set the LCD stop address
									lcdStopAddress <= currentCharPos;
									// Setup LCD data
									state <= STATE_SETUP_LCD_DATA;
								end
							end // End else not rotary button
						end
				STATE_CLEAR_LOCAL_RAM_CONFIRM:
						begin
							// Set the parent mode
							mode <= MODE_CLEAR_RAM;
							// Set the sub mode
							subMode <= SUBMODE_CLEAR_LOCAL_RAM_CONFIRM;
							// Set display option to YES
							displayOption <= MENU_OPTION_YES;
							// Refresh menu
							state <= STATE_REFRESH_LCD_MENU_TITLE;
						end
				STATE_CLEAR_LOCAL_RAM:
						begin
							// Set mode back to menu since operation complete
							mode <= MODE_MENU;
							// Set sub mode
							subMode <= SUBMODE_CLEAR_LOCAL_RAM;
							// Select RAM to be cleared
							MultiRAM_SEL <= RAM_SEL_LOCAL;
							// Set display option back to main menu
							displayOption <= MENU_OPTION_DISPLAY_REMOTE;
							// Refresh display
							state <= STATE_REFRESH_LCD_MENU_TITLE;
						end
				STATE_MODE_REDIRECT:
						begin
							case (mode)
								MODE_MENU:
										case (subMode)
											SUBMODE_REFRESH_MENU_TITLE:
													// Refresh the menu option
													state <= STATE_REFRESH_LCD_MENU_OPTION;
											SUBMODE_REFRESH_MENU_OPTION:
													// Wait for user selection
													state <= STATE_WAIT_FOR_SELECTION;
										endcase
								MODE_DISPLAY_REMOTE:
										// Keep refreshing display with remote RAM display
										// contents while waiting for menu button press
										state <= STATE_DISPLAY_REMOTE;
								MODE_DISPLAY_LOCAL:
										case (subMode)
											SUBMODE_REFRESH_MENU_TITLE:
													// Refresh the menu option
													state <= STATE_REFRESH_LCD_MENU_OPTION;
											SUBMODE_REFRESH_MENU_OPTION:
													// Wait for user selection
													state <= STATE_WAIT_FOR_SELECTION;
											SUBMODE_DISPLAY_LOCAL:
													// Wait for menu button press
													state <= STATE_WAIT_FOR_ROTARY_OR_MENU_PRESS;
										endcase
								MODE_MODIFY_LOCAL_RAM:
										case (subMode)
											SUBMODE_MODIFY_LOCAL_RAM_DISPLAY:
													// Wait for user to choose a character
													// position to edit
													state <= STATE_MODIFY_LOCAL_RAM_CHAR_POS_SEL;
											SUBMODE_MODIFY_LOCAL_RAM_POSITION_SEL:
													// Continue Waiting for user to choose a
													// character position to edit
													state <= STATE_MODIFY_LOCAL_RAM_CHAR_POS_SEL;
											SUBMODE_MODIFY_LOCAL_RAM_CHAR_SEL:
													// Continue waiting for user to choose a
													// character
													state <= STATE_MODIFY_LOCAL_RAM_CHAR_SEL;
										endcase
								MODE_CLEAR_RAM:
										case (subMode)
											SUBMODE_REFRESH_MENU_TITLE:
													// Refresh the menu option
													state <= STATE_REFRESH_LCD_MENU_OPTION;
											SUBMODE_REFRESH_MENU_OPTION:
													// Wait for user selection
													state <= STATE_WAIT_FOR_SELECTION;
											SUBMODE_WAIT_FOR_SELECTION:
													// User confirmed selection, clear local RAM
													state <= STATE_CLEAR_LOCAL_RAM;
										endcase
								MODE_WRITE_TO_REMOTE:
										case (subMode)
											SUBMODE_REFRESH_MENU_TITLE:
													// Refresh the menu option
													state <= STATE_REFRESH_LCD_MENU_OPTION;
											SUBMODE_REFRESH_MENU_OPTION:
													// Wait for remote write to complete
													state <= STATE_WRITE_TO_REMOTE_WAIT;
										endcase
							endcase
						end
				STATE_WRITE_TO_REMOTE:
						begin
							// Set the mode
							mode <= MODE_WRITE_TO_REMOTE;
							// Set the sub mode
							subMode <= SUBMODE_WRITE_TO_REMOTE_WRITING;
							// Set remote RW control to write
							RemoteRWControl <= 0;
							// Enable the Spartan 3E Slave controller
							enableControllers <= ENABLE_CONTROLLER_SPARTAN_SLAVE;
							// Update display value
							displayOption <= MENU_STATUS_WRITING;
							// Refresh display
							state <= STATE_REFRESH_LCD_MENU_TITLE;
						end
				STATE_WRITE_TO_REMOTE_WAIT:
						begin
							// Set sub mode
							subMode <= SUBMODE_WRITE_TO_REMOTE_WAITING;
							if (Controller_Done) begin
								mode <= MODE_MENU;
								displayOption <= MENU_STATUS_ACTION_COMPLETE;
								state <= STATE_REFRESH_LCD_MENU_TITLE;
							end
						end
				STATE_READ_FROM_REMOTE:
						begin
							// Set the mode
							mode <= MODE_READ_FROM_REMOTE;
							// Set the sub mode
							subMode <= SUBMODE_WRITE_TO_REMOTE_WRITING;
							// Set remote RW control to write
							RemoteRWControl <= 1;
							// Enable the Spartan 3E Slave controller
							enableControllers <= ENABLE_CONTROLLER_SPARTAN_SLAVE;
							// Update display value
							displayOption <= MENU_STATUS_WRITING;
							// Refresh display
							state <= STATE_REFRESH_LCD_MENU_TITLE;
						end
				STATE_SWITCH_I2C_MODE:
						begin
							I2C_Mode <= !I2C_Mode;
							// Set mode
							mode <= MODE_MENU;
							// Reset to home position
							currentCharPos <= 0;
							// Reset character column and row index to letter A
							currentCharColumn <= 4;
							currentCharRow <= 1;
							// Return to first menu item on reset only
							displayOption <= MENU_OPTION_DISPLAY_REMOTE;
							// Refresh menu
							state <= STATE_REFRESH_LCD_MENU_TITLE;
						end
			endcase
		end // End else
	end

endmodule
