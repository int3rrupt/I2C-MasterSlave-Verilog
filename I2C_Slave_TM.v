`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer:			Adrian Reyes
// Module Name:		I2C_Slave_TM
// Project Name:		I2C_Slave-LCD_Buttons_Switches
// Target Devices:	SPARTAN 3E
// Description:		I2C Slave Top Module
// Dependencies:		I2C_Slave
//							I2C_Slave_Controller
//							RAM32x8
//							LCDI
//////////////////////////////////////////////////////////////////////////////////
module I2C_Slave_TM(
	output [3:0]dataout,			// Data out to LCD
	output [2:0]control,			// Control to LCD
	output [7:0]LEDs,
	input rotary_a,				// Push Button Address Increment
	input rotary_b,				// Push Button Address Decrement
	input rotary_center,			// Push Button to signal which nibble being written
	input btn_west,				//
	input btn_east,
	input btn_north,
	inout scl,
	inout sda,
	input clk,
	input reset
	);

	wire rotary_event;
	wire rotary_left;
	wire charColumnLeftBtn;
	wire charColumnRightBtn;
	wire enableCursor;
	wire cursorLeft;
	wire cursorRight;

	wire [4:0]lcd_WADD;
	wire [7:0]lcd_DIN;
	wire lcd_W;
	wire [7:0]slaveRAM_DOUT;
	wire [7:0]editAddress;
	wire [7:0]masterRAM_WADD;
	wire [7:0]masterRAM_DIN;
	wire masterRAM_W;

	assign LEDs = editAddress;

	Debouncer debouncerRotaryCenter(
		.E(rotaryBtn),
		.pb(rotary_center),
		.clk(clk)
		);

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

	RotaryEncoder rotaryEncoder(
		.rotary_event(rotary_event),
		.rotary_left(rotary_left),
		.rotary_a(rotary_a),
		.rotary_b(rotary_b),
		.clk(clk)
		);

	I2C_Slave slave(
		.W(masterRAM_W),
		.addr(masterRAM_WADD),
		.datar(masterRAM_DIN),
		.DOUT(slaveRAM_DOUT),
		.scl(scl),
		.sda(sda),
		.clk(clk),
		.reset(reset)
		);

	I2C_Slave_MenuController menuController(
		.lcd_WADD(lcd_WADD),
		.lcd_DIN(lcd_DIN),
		.lcd_W(lcd_W),
		.enableCursor(enableCursor),
		.cursorLeft(cursorLeft),
		.cursorRight(cursorRight),
		.slaveRAM_DOUT(slaveRAM_DOUT),
		.editAddress(editAddress),
		.slaveRAM_RADD(masterRAM_WADD[4:0]),
		.masterRAM_WADD(masterRAM_WADD[4:0]),
		.masterRAM_DIN(masterRAM_DIN),
		.masterRAM_W(masterRAM_W),
		.rotary_event(rotary_event),
		.rotary_left(rotary_left),
		.rotaryBtn(rotaryBtn),
		.charColumnLeftBtn(charColumnLeftBtn),
		.charColumnRightBtn(charColumnRightBtn),
		.menuBtn(menuBtn),
		.clk(clk),
		.reset(reset)
		);

	LCDI_Menu lcdi(
		.dataout(dataout),
		.control(control),
		.WADD(lcd_WADD),
		.DIN(lcd_DIN),
		.W(lcd_W),
		.enableCursor(enableCursor),
		.cursorLeft(cursorLeft),
		.cursorRight(cursorRight),
		.clk(clk)
		);
		
//	always@(posedge rotary_event) begin
//		if (rotary_left) begin
//			if (LEDs == 8'b10000000)
//				LEDs <= 8'b0000001;
//			else
//				LEDs <= LEDs << 1;
//		end
//		// Otherwise rotary rotate right
//		else begin
//			if (LEDs == 8'b00000001)
//				LEDs <= 8'b10000000;
//			else
//				LEDs <= LEDs >> 1;
//		end
//	end


endmodule
