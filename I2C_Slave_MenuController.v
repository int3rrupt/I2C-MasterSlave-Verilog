`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer:			Adrian Reyes
// Module Name:		I2C_Slave_MenuController
// Project Name:		I2C_Slave-LCD_Buttons_Switches
// Target Devices:	SPARTAN 3E
// Description:		I2C Slave Menu Controller
//							Module that takes input from user and performs desired
//							operation
// Dependencies:
//////////////////////////////////////////////////////////////////////////////////
module I2C_Slave_MenuController(
	output [4:0]lcd_WADD,			// LCD Word Address
	output [7:0]lcd_DIN,				// LCD Data In
	output lcd_W,						// LCD Write
	output enableCursor,
	output reg cursorLeft,
	output reg cursorRight,
	output [7:0]slaveRAM_DOUT,		// Slave RAM Data Out
	output [7:0]editAddress,
	input [4:0]slaveRAM_RADD,		// Slave RAM Read Address
	input [4:0]masterRAM_WADD,		// Master RAM Write Address
	input [7:0]masterRAM_DIN,		// Master RAM Data In
	input masterRAM_W,				// Write for Master RAM
	input rotary_event,				// Flag indicating Rotary Button rotation
	input rotary_left,				// Rotary rotation direction
	input rotaryBtn,					// Rotary Button
	input charColumnLeftBtn,
	input charColumnRightBtn,
	input menuBtn,						// Menu Button
	input clk,
	input reset
	);

	////////////////////////////// PARAMETERS //////////////////////////////////
	////////////////////////////////////////////////////////////////////////////
	// Parent Mode Parameters
	parameter MODE_CLEAR_RAM = 0;
	// Sub Mode parameters
	parameter SUBMODE_REFRESH_MENU_TITLE = 0, SUBMODE_REFRESH_MENU_OPTION = 1,
		SUBMODE_DISPLAY_MASTER_RAM = 2, SUBMODE_DISPLAY_SLAVE_RAM = 3,
		SUBMODE_MODIFY_RAM_DISPLAY = 4, SUBMODE_MODIFY_RAM_POSITION_SEL = 5,
		SUBMODE_MODIFY_RAM_CHAR_SEL = 6, SUBMODE_CLEAR_RAM = 7;
	// State parameters
	parameter STATE_REFRESH_LCD_MENU_TITLE = 0,
		STATE_REFRESH_LCD_MENU_OPTION = 1, STATE_SETUP_LCD_DATA = 2,
		STATE_WRITE_TO_LCD = 3, STATE_WAIT_FOR_SELECTION = 4,
		STATE_DISPLAY_MASTER = 5, STATE_DISPLAY_RAM = 6,
		STATE_MODIFY_RAM = 7, STATE_WAIT_FOR_MENU_PRESS = 8,
		STATE_MODIFY_RAM_CHAR_POS_SEL = 9,
		STATE_MODIFY_RAM_CHAR_SEL = 10, STATE_CLEAR_RAM_CONFIRM = 11,
		STATE_CLEAR_RAM = 12, STATE_SUBMENU_REDIRECT = 13;
	// RAM select parameters
	parameter RAM_SEL_MENU = 2'b00, RAM_SEL_MASTER = 2'b01, RAM_SEL_SLAVE = 2'b10;
	// Menu parameters
	parameter MENU_MAIN = 4'b0000, MENU_DISPLAY_MASTER = 4'b0001,
		MENU_DISPLAY_RAM = 4'b0010, MENU_MODIFY_RAM = 4'b0011,
		MENU_CLEAR_RAM = 4'b0100, MENU_SLAVE_ACTIONS = 4'b0101,
		MENU_ARE_YOU_SURE = 4'b0110, MENU_SET_SLAVE_ADDR = 4'b0111,
		MENU_YES = 4'b1000, MENU_NO = 4'b1001;


	/////////////////////////////// REGISTERS //////////////////////////////////
	////////////////////////////////////////////////////////////////////////////
	reg [3:0]state;							// Current state of the controller
	reg [2:0]mode;								// Current mode of the controller
	reg [2:0]subMode;							// Current sub mode of the controller
	// Rotary Event Reg
	reg rotary_event_prev;					// The previous rotary event value.
	// Button Events
	reg charColumnLeftBtn_prev;			// The previous character column left
													// button value
	reg charColumnRightBtn_prev;			// The previous character column right
													// button value
	// Display Selection Registers
	reg [3:0]displayTitle;					// The menu title to display
	reg [3:0]displayOption;					// The menu option to display
	reg [3:0]currentDisplayedOption;		// Current option being displayed
	// LCD registers
	reg [4:0]lcdAddress;						// The LCD address to write to
	reg [7:0]lcdData;							// The LCD data to be written
	reg [4:0]lcdStopAddress;				// The last LCD address to write to
	// Character Select Registers
	reg [4:0]currentCharPos;				// The current position of the character
													// being edited
	reg [3:0]currentCharColumn;			// The current character column index
	reg [3:0]currentCharRow;				// The current character row index
	reg [4:0]currentDisplayedCharPos;	// The currently displayed position of the
													// character being edited
	reg [7:0]currentRAMChar;				// TODO
	wire [7:0]currentChar;					// The current character based on current
													// character column and row
	reg [7:0]currentDisplayedChar;		// The currently displayed character
	// Master RAM Registers
	reg [7:0]masterRAM_DOUT;				// Master RAM data out
	// RAM Read (Menu Controller Use Only)
	reg [3:0]menuSelect;						// Menu select. Choose menu ROM to read
	wire [7:0]RAM_DOUT;						// RAM data out
	reg [1:0]RAM_RSEL;						// RAM read select. Select RAM to read from
	reg [4:0]RAM_RADD;						// RAM read address (Menu Controller)
	// RAM Write (Menu Controller Use Only)
	reg [1:0]RAM_WSEL;						// RAM write select. Select RAM to write to
	reg [4:0]RAM_WADD;						// RAM write address
	reg [7:0]RAM_DIN;							// RAM data in
	wire RAM_W;									// RAM write port
	wire RAM_Clear;
	reg ramWriteReady;						// Flag used to indicate when data is ready
													// to be written to the selected RAM

	integer i;
	initial begin
		state = STATE_REFRESH_LCD_MENU_TITLE;
		displayOption = MENU_DISPLAY_MASTER;
		currentDisplayedOption = MENU_DISPLAY_MASTER;
		currentCharPos = 0;
		currentCharColumn = 4'b0100;
		currentCharRow = 4'b0001;
	end

	I2C_Slave_RAMController ramController(
		.RAM_DOUT(RAM_DOUT),
		.slaveRAM_DOUT(slaveRAM_DOUT),
		.menuSelect(menuSelect),
		.RAM_RSEL(RAM_RSEL),
		.RAM_WSEL(RAM_WSEL),
		.RAM_RADD(RAM_RADD),
		.RAM_WADD(RAM_WADD),
		.RAM_DIN(RAM_DIN),
		.RAM_W(RAM_W),
		.RAM_Clear(RAM_Clear),
		.masterRAM_WADD(masterRAM_WADD),
		.masterRAM_DIN(masterRAM_DIN),
		.masterRAM_W(masterRAM_W),
		.slaveRAM_RADD(slaveRAM_RADD),
		.clk(clk)
		);
	///////////////////////////////// ASSIGN ///////////////////////////////////
	////////////////////////////////////////////////////////////////////////////
	// Continuously assign values to LCD ports
	assign lcd_WADD = lcdAddress;
	assign lcd_DIN = subMode == SUBMODE_MODIFY_RAM_CHAR_SEL ? lcdData : RAM_DOUT;
	assign lcd_W = state == STATE_WRITE_TO_LCD;
	// Continuously concatenate the current character column and row
	assign currentChar = {currentCharColumn, currentCharRow};
	// Continuously assign RAM_W
	assign RAM_W = (subMode == SUBMODE_MODIFY_RAM_CHAR_SEL) && ramWriteReady;
	assign RAM_Clear = mode == MODE_CLEAR_RAM && subMode == SUBMODE_CLEAR_RAM;
	// Continuously assign cursor enable
	assign enableCursor = subMode == SUBMODE_MODIFY_RAM_POSITION_SEL;

	///////////////////////////////// ALWAYS ///////////////////////////////////
	////////////////////////////////////////////////////////////////////////////
	always@(posedge clk) begin
		// Check for rotary and button events
		if (reset || menuBtn || rotary_event) begin
			if (reset || menuBtn) begin
				currentCharRow <= 0;
				displayOption <= MENU_DISPLAY_MASTER;
				// Reset state to menu refresh
				state <= STATE_REFRESH_LCD_MENU_TITLE;
			end
			else begin
				if (rotary_event) begin
					// Check current state and determine what action to take
					case(state)
						STATE_WAIT_FOR_SELECTION: begin
								case(displayOption)
									MENU_DISPLAY_MASTER: begin
												// If rotate right
												if (rotary_left)
													// Show next option
													displayOption <= MENU_DISPLAY_RAM;
												// Else rotate left
												else
													// Show previous option
													displayOption <= MENU_SLAVE_ACTIONS;
											end
									MENU_DISPLAY_RAM: begin
												// If rotate right
												if (rotary_left)
													// Show next option
													displayOption <= MENU_MODIFY_RAM;
												// Else rotate left
												else
													// Show previous option
													displayOption <= MENU_DISPLAY_MASTER;
											end
									MENU_MODIFY_RAM: begin
												// If rotate right
												if (rotary_left)
													// Show next option
													displayOption <= MENU_CLEAR_RAM;
												// Else rotate left
												else
													// Show previous option
													displayOption <= MENU_DISPLAY_RAM;
											end
									MENU_CLEAR_RAM: begin
												// If rotate right
												if (rotary_left)
													// Show next option
													displayOption <= MENU_SLAVE_ACTIONS;
												// Else rotate left
												else
													// Show previous option
													displayOption <= MENU_MODIFY_RAM;
											end
									MENU_SLAVE_ACTIONS: begin
												// If rotate right
												if (rotary_left)
													// Show next option
													displayOption <= MENU_DISPLAY_MASTER;
												// Else rotate left
												else
													// Show previous option
													displayOption <= MENU_CLEAR_RAM;
											end
									MENU_YES: begin
											// Show next option
											displayOption <= MENU_NO; end
									MENU_NO: begin
											// Show next option
											displayOption <= MENU_YES; end
								endcase
								state <= STATE_REFRESH_LCD_MENU_TITLE; end
						STATE_MODIFY_RAM_CHAR_POS_SEL: begin
								// If rotary rotated left
								if (rotary_left) begin
									// Increment current character position
									currentCharPos <= currentCharPos + 1;
									cursorRight <= 1; end
								// Otherwise rotary rotated right
								else begin
									currentCharPos <= currentCharPos - 1;
									cursorLeft <= 1; end end
						STATE_MODIFY_RAM_CHAR_SEL: begin
								// If rotary rotated left
								if (rotary_left)
									// Decrement current character row
									currentCharRow <= currentCharRow + 1;
								// Otherwise rotary rotated right
								else currentCharRow <= currentCharRow - 1; end
					endcase
				end
			end
		end
		else begin
			cursorLeft <= 0;
			cursorRight <= 0;
				case(state)
					STATE_REFRESH_LCD_MENU_TITLE: begin
							// Select Menu RAM
							RAM_RSEL <= RAM_SEL_MENU;
							// Reset address to first character
							RAM_RADD <= 0;
							// Reset LCD address to first character of first line
							lcdAddress <= 0;
							// Set the LCD stop address
							lcdStopAddress <= 15;
							// Select the Menu Title to display
							case(displayOption)
								MENU_DISPLAY_MASTER: menuSelect <= MENU_MAIN;
								MENU_DISPLAY_RAM: menuSelect <= MENU_MAIN;
								MENU_MODIFY_RAM: menuSelect <= MENU_MAIN;
								MENU_CLEAR_RAM: menuSelect <= MENU_MAIN;
								MENU_SLAVE_ACTIONS: menuSelect <= MENU_MAIN;
								MENU_YES: menuSelect <= MENU_ARE_YOU_SURE;
								MENU_NO: menuSelect <= MENU_ARE_YOU_SURE;
							endcase
							// Set the subMode to Menu
							subMode <= SUBMODE_REFRESH_MENU_TITLE;
							// Setup LCD data
							state <= STATE_SETUP_LCD_DATA; end
					STATE_REFRESH_LCD_MENU_OPTION: begin
							// Select Menu RAM
							RAM_RSEL <= RAM_SEL_MENU;
							// Reset address to first character
							RAM_RADD <= 0;
							// Set LCD address to first character of second line
							lcdAddress <= 16;
							// Set the LCD stop address
							lcdStopAddress <= 31;
							// Select the Menu to display
							menuSelect <= displayOption;
							// Set the subMode to Menu
							subMode <= SUBMODE_REFRESH_MENU_OPTION;
							// Setup LCD data
							state <= STATE_SETUP_LCD_DATA; end
					STATE_SETUP_LCD_DATA: begin
							// Perform additional actions based on subMode
							case(subMode)
								SUBMODE_MODIFY_RAM_POSITION_SEL:
										currentDisplayedCharPos <= currentCharPos;
								SUBMODE_MODIFY_RAM_CHAR_SEL:
										currentDisplayedChar <= currentChar;
							endcase
							// Continue writing to LCD
							state <= STATE_WRITE_TO_LCD; end
					STATE_WRITE_TO_LCD: begin
							// If done writing to the display
							if (lcdAddress == lcdStopAddress) begin
								case(subMode)
									// Refresh the menu option
									SUBMODE_REFRESH_MENU_TITLE:
											state <= STATE_REFRESH_LCD_MENU_OPTION;
									// Wait for user selection
									SUBMODE_REFRESH_MENU_OPTION:
											state <= STATE_WAIT_FOR_SELECTION;
									// Wait for menu button press
									SUBMODE_DISPLAY_MASTER_RAM:
											state <= STATE_WAIT_FOR_MENU_PRESS;
									// Wait for menu button press
									SUBMODE_DISPLAY_SLAVE_RAM:
											state <= STATE_WAIT_FOR_MENU_PRESS;
									// Wait for user to move cursor and
									// choose a character position to edit
									SUBMODE_MODIFY_RAM_DISPLAY:
											state <= STATE_MODIFY_RAM_CHAR_POS_SEL;
									SUBMODE_MODIFY_RAM_POSITION_SEL:
											state <= STATE_MODIFY_RAM_CHAR_POS_SEL;
									SUBMODE_MODIFY_RAM_CHAR_SEL:
											state <= STATE_MODIFY_RAM_CHAR_SEL;
								endcase
							end
							else begin
								// Increment RAM data pointer
								RAM_RADD <= RAM_RADD + 1;
								// Increment lcd data pointer
								lcdAddress <= lcdAddress + 1;
								// W is asserted in this state, return to setup LCD
								// for next write
								state <= STATE_SETUP_LCD_DATA;
							end end
					STATE_WAIT_FOR_SELECTION: begin
							// If the rotary button was pressed
							if (rotaryBtn) begin
								// Check which option was selected
								case(displayOption)
									// Display what the Master has sent
									MENU_DISPLAY_MASTER: state <= STATE_DISPLAY_MASTER;
									// Display local RAM
									MENU_DISPLAY_RAM: state <= STATE_DISPLAY_RAM;
									// Modify local RAM
									MENU_MODIFY_RAM: state <= STATE_MODIFY_RAM;
									// Clear Slave RAM
									MENU_CLEAR_RAM: state <= STATE_CLEAR_RAM_CONFIRM;
									// Confirm RAM Clear
									MENU_YES: state <= STATE_SUBMENU_REDIRECT;
								endcase
							end end
					STATE_WAIT_FOR_MENU_PRESS: begin
							// Wait for menu button press. RAM was displayed now
							// waiting to return to menu
							if (rotaryBtn) state <= STATE_REFRESH_LCD_MENU_TITLE; end
					STATE_DISPLAY_MASTER: begin
							// Select Master RAM
							RAM_RSEL <= RAM_SEL_MASTER;
							// Reset address to first character
							RAM_RADD <= 0;
							// Set LCD address to first character of second line
							lcdAddress <= 0;
							// Set the LCD stop address
							lcdStopAddress <= 31;
							// Set subMode to Display Master RAM
							subMode <= SUBMODE_DISPLAY_MASTER_RAM;
							// Setup up LCD data to display Master RAM
							state <= STATE_SETUP_LCD_DATA; end
					STATE_DISPLAY_RAM: begin
							// Select Slave RAM
							RAM_RSEL <= RAM_SEL_SLAVE;
							// Reset address to first character
							RAM_RADD <= 0;
							// Set LCD address to first character of second line
							lcdAddress <= 0;
							// Set the LCD stop address
							lcdStopAddress <= 31;
							// Set subMode to Display Slave RAM
							subMode <= SUBMODE_DISPLAY_SLAVE_RAM;
							// Setup up LCD data to display Master RAM
							state <= STATE_SETUP_LCD_DATA; end
					STATE_MODIFY_RAM: begin
							// Select Slave RAM
							RAM_RSEL <= RAM_SEL_SLAVE;
							// Reset address to first character
							RAM_RADD <= 0;
							// Set LCD address to first character of second line
							lcdAddress <= 0;
							// Set the LCD stop address
							lcdStopAddress <= 31;
							// Set subMode to Display Slave RAM
							subMode <= SUBMODE_MODIFY_RAM_DISPLAY;
							// Setup up LCD data to display Master RAM
							state <= STATE_SETUP_LCD_DATA; end
					STATE_MODIFY_RAM_CHAR_POS_SEL: begin
							// Set the subMode
							subMode <= SUBMODE_MODIFY_RAM_POSITION_SEL;
							// Clear write ready flag
							ramWriteReady <= 0;
							// Wait for the rotary button to be pressed indicating
							// that the user has selected an LCD character position
							// to edit
							if (rotaryBtn) state <= STATE_MODIFY_RAM_CHAR_SEL; end
					STATE_MODIFY_RAM_CHAR_SEL: begin
							// Set the subMode
							subMode <= SUBMODE_MODIFY_RAM_CHAR_SEL;
							// Wait for the rotary button to be pressed indicating
							// that the user has selected an LCD character for the
							// current position
							if (rotaryBtn) begin
								RAM_WSEL <= RAM_SEL_SLAVE;
								RAM_WADD <= currentCharPos;
								RAM_DIN <= currentDisplayedChar;
								ramWriteReady <= 1;
								state <= STATE_MODIFY_RAM_CHAR_POS_SEL; end
							else begin
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
							end end
					STATE_CLEAR_RAM_CONFIRM: begin
							// Set the parent mode
							mode <= MODE_CLEAR_RAM;
							// Set display option to YES
							displayOption <= MENU_YES;
							// Refresh menu
							state <= STATE_REFRESH_LCD_MENU_TITLE; end
					STATE_CLEAR_RAM: begin
							// Set sub mode
							subMode <= SUBMODE_CLEAR_RAM;
							// Select RAM to be cleared
							RAM_WSEL <= RAM_SEL_SLAVE;
							// Set display option back to main menu
							displayOption <= MENU_DISPLAY_MASTER;
							// Refresh display
							state <= STATE_REFRESH_LCD_MENU_TITLE; end
					STATE_SUBMENU_REDIRECT: begin
							case(mode)
								MODE_CLEAR_RAM: state <= STATE_CLEAR_RAM;
							endcase end
				endcase
		end // End else
	end

	// Button Events
	always@(posedge clk) begin
		// If either reset button or menu button were pressed
		if (reset || menuBtn) begin
			// Reset currenty character column index
			currentCharColumn <= 4'b0010;
		end
		else begin
			// Store current charColumnLeftBtn value
			charColumnLeftBtn_prev <= charColumnLeftBtn;
			// If charColumnLeftBtn was previously 0 but is now 1, then button
			// event has occurred
			if (charColumnLeftBtn == 1 && charColumnLeftBtn_prev == 0) begin
				if (state == STATE_MODIFY_RAM_CHAR_SEL) begin
					case(currentCharColumn)
						4'b0010:	currentCharColumn <= 4'b1111;
						4'b1010:	currentCharColumn <= 4'b0111;
						// Decrement current character column
						default:	currentCharColumn <= currentCharColumn - 1;
					endcase
				end
			end
			// Store current charColumnRightBtn value
			charColumnRightBtn_prev <= charColumnRightBtn;
			// If charColumnRightBtn was previously 0 but is now 1, then button
			// event has occurred
			if (charColumnRightBtn == 1 && charColumnRightBtn_prev == 0) begin
				if (state == STATE_MODIFY_RAM_CHAR_SEL) begin
					case(currentCharColumn)
						4'b0111:	currentCharColumn <= 4'b1010;
						4'b1111:	currentCharColumn <= 4'b0010;
						// Decrement current character column
						default:	currentCharColumn <= currentCharColumn + 1;
					endcase
				end
			end
		end
	end



//	always@(posedge charColumnRightBtn) begin
//		if (state == STATE_MODIFY_RAM_CHAR_POS_SEL) begin
//			case(currentCharColumn)
//				4'b0111:	currentCharColumn <= 4'b1010;
//				4'b1111:	currentCharColumn <= 4'b0010;
//				// Increment current character column
//				default:	currentCharColumn <= currentCharColumn + 1;
//			endcase
//		end
//	end
//	always@(posedge clk) begin
//		// Continuously assign values to LCD ports
//		//assign lcd_WADD = lcdAddress;
//		//assign lcd_DIN = RAM_DOUT;
//		//assign lcd_W = state == STATE_WRITE_TO_LCD;
//
//		// Display to user  using LEDs the address being edited
//		//editAddress <= currentCharPos;
//
//		case(state) begin
//			STATE_REFRESH_LCD_MENU_TITLE:
//					begin
//						// Select Menu RAM
//						lcd_WADD <= RAM_RADD;
//						// Reset address to first character
//						lcd_DIN <= lcdAddress;
//					end
//			STATE_REFRESH_LCD_MENU_OPTION:
//					begin
//						// Select Menu RAM
//						lcd_WADD <= RAM_RADD;
//						// Reset address to first character
//						lcd_DIN <= lcdAddress;
//					end
//		endcase
//	end

endmodule
