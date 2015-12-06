`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer:			Adrian Reyes
// Module Name:		I2C_Slave_TM
// Project Name:		I2C_LCD_Menu_Master
// Target Devices:	SPARTAN 3E
// Description:		I2C Slave Top Module
// Dependencies:		Debouncer
//							RotaryEncoder
//							I2C_Slave
//							I2C_MenuController
//							I2C_RAMController
//							LCDI_Menu
//////////////////////////////////////////////////////////////////////////////////
module I2C_Slave_TM(
	output [3:0]dataout,			// Data out to LCD Controller
	output [2:0]control,			// Control to LCD Controller
	input btn_west,				// Character column index decrement
	input btn_east,				// Character column index increment
	input btn_north,				// Menu button
	input rotary_center,			// Button for selecting menu options
	input rotary_a,				// Button for rotary encoding
	input rotary_b,				// Button for rotary encoding
	inout scl,						// Serial clock
	inout sda,						// Serial data
	input clk,						// I2C driving clock
	input reset
	);

	// I2C Mode Parameters
	parameter I2C_MODE_MASTER = 0, I2C_MODE_SLAVE = 1;
	
	reg I2C_Mode = I2C_MODE_SLAVE;

	// Buttons
	wire charColumnLeftBtn;
	wire charColumnRightBtn;
	wire menuBtn;
	wire rotaryBtn;
	// Rotary
	wire rotary_event;
	wire rotary_left;
	// LCDI
	wire [4:0]LCD_WADD;
	wire [7:0]LCD_DIN;
	wire LCD_W;
	// RAM
	wire [7:0]RAM_ADD;
	wire [7:0]MultiRAM_DOUT;
	wire [7:0]LocalRAM_DOUT;
	wire [4:0]MenuRAM_Select;
	wire [1:0]MultiRAM_SEL;
	wire [4:0]MultiRAM_ADD;
	wire [7:0]MultiRAM_DIN;
	wire MultiRAM_W;
	wire MultiRAM_Clear;
	wire [7:0]RemoteRAM_DIN;
	wire RemoteRAM_W;

	Debouncer debouncerPbWest(
		.E(charColumnLeftBtn),
		.pb(btn_west),
		.clk(clk)
		);
	Debouncer debouncerPbEast(
		.E(charColumnRightBtn),
		.pb(btn_east),
		.clk(clk)
		);
	Debouncer debouncerPbNorth(
		.E(menuBtn),
		.pb(btn_north),
		.clk(clk)
		);
	Debouncer debouncerRotaryCenter(
		.E(rotaryBtn),
		.pb(rotary_center),
		.clk(clk)
		);

	RotaryEncoder rotaryEncoder(
		.rotary_event(rotary_event),
		.rotary_left(rotary_left),
		.rotary_a(rotary_a),
		.rotary_b(rotary_b),
		.clk(clk)
		);

	I2C_Slave slave(
		.RAM_Addr(RAM_ADD),					// Register address (used for read and write)
		.RemoteRAM_DIN(RemoteRAM_DIN),	// Received Data (slave write operation)
		.RemoteRAM_W(RemoteRAM_W),			// Slave write bit
		.LocalRAM_DOUT(LocalRAM_DOUT),	// Local RAM data (slave read operation)
		.scl(scl),								// Serial clock
		.sda(sda),								// Serial data
		.clk(clk),								// I2C driving clock
		.reset(reset)
		);

	I2C_MenuController menuController(
		.LCD_WADD(LCD_WADD),
		.LCD_DIN(LCD_DIN),
		.LCD_W(LCD_W),
		.RemoteRWControl(RemoteRWControl),
		.Controller_Enable(Controller_Enable),
		.MenuRAM_Select(MenuRAM_Select),				//
		.MultiRAM_SEL(MultiRAM_SEL),					// Multi RAM select
		.MultiRAM_ADD(MultiRAM_ADD),					// Multi RAM address (read and write)
		.MultiRAM_DIN(MultiRAM_DIN),					// Multi RAM data in
		.MultiRAM_W(MultiRAM_W),						// Multi RAM write bit
		.MultiRAM_Clear(MultiRAM_Clear),				// Multi RAM clear control bit
		.I2C_Mode(I2C_Mode),								// NOT USED - FUTURE USE
		.SlaveAddr(SlaveAddr),							// NOT USED - FUTURE USE
		.MultiRAM_DOUT(MultiRAM_DOUT),				// Multi RAM data out
		.Controller_Done(Controller_Done),			// NOT USED - MASTER USE ONLY
		.rotary_event(rotary_event),					// Rotary rotate event indicator
		.rotary_left(rotary_left),						// Rotary left rotate indicator
		.rotaryBtn(rotaryBtn),							// Button for selecting menu options
		.charColumnLeftBtn(charColumnLeftBtn),		// Character column index decrement
		.charColumnRightBtn(charColumnRightBtn),	// Character column index increment
		.menuBtn(menuBtn),								// Menu button
		.clk(clk),
		.reset(reset)
		);

	I2C_RAMController ramController(
		.MultiRAM_DOUT(MultiRAM_DOUT),
		.LocalRAM_DOUT(LocalRAM_DOUT),
		.MenuRAM_Select(MenuRAM_Select),
		.MultiRAM_SEL(MultiRAM_SEL),
		.MultiRAM_ADD(MultiRAM_ADD),
		.MultiRAM_DIN(MultiRAM_DIN),
		.MultiRAM_W(MultiRAM_W),
		.MultiRAM_Clear(MultiRAM_Clear),
		.RemoteRAM_WADD(RAM_ADD),
		.RemoteRAM_DIN(RemoteRAM_DIN),
		.RemoteRAM_W(RemoteRAM_W),
		.LocalRAM_RADD(RAM_ADD),
		.clk(clk)
		);

	LCDI_Menu lcdi(
		.dataout(dataout),
		.control(control),
		.WADD(LCD_WADD),
		.DIN(LCD_DIN),
		.W(LCD_W),
		.enableCursor(enableCursor),
		.cursorLeft(cursorLeft),
		.cursorRight(cursorRight),
		.clk(clk)
		);

endmodule
