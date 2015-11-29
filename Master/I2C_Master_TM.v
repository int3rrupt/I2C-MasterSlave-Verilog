`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer:			Adrian Reyes
// Module Name:		I2C_Master_TM
// Project Name:		I2C_Master-LCD_TempSensor
// Target Devices:	SPARTAN 3E
// Description:		I2C Master Top Module
// Dependencies:		I2C_Master
//							I2C_Master_Controller
//							LCDI

//////////////////////////////////////////////////////////////////////////////////
module I2C_Master_TM(
	output [3:0] dataout,
	output [2:0] control,
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

	wire go;
	wire done;
	wire ready;
	wire rw;
	wire [5:0] N_Byte;
	wire [6:0] dev_add;
	wire [7:0] dwr_DataWriteReg;
	wire [7:0] R_Pointer;
	wire [7:0] drd_lcdData;
	wire ack_e;
	wire W;
	wire [4:0] WADD;
	wire [7:0] DIN;

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

	I2C_MenuController(
		.lcd_WADD(lcd_WADD),
		.lcd_DIN(lcd_DIN),
		.lcd_W(lcd_W),
		.remoteRWControl(remoteRWControl),
		.enableCursor(enableCursor),
		.cursorLeft(cursorLeft),
		.cursorRight(cursorRight),
		.localRAM_DOUT(localRAM_DOUT),
		.editAddress(editAddress),
		.enableControllers(enableControllers),
		.localRAM_RADD(localRAM_RADD),
		.masterRAM_WADD(masterRAM_WADD),
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

	I2C_Master i2cMaster (
		.go(go),
		.done(done),
		.ready(ready),
		.rw(rw),
		.N_Byte(N_Byte),
		.dev_add(dev_add),
		.dwr_DataWriteReg(dwr_DataWriteReg),
		.R_Pointer(R_Pointer),
		.drd_lcdData(drd_lcdData),
		.ack_e(ack_e),
		.scl(scl),
		.sda(sda),
		.clk(clk),
		.reset(reset)
		);

	I2C_Master_SpartanSlaveController(
		.RAM_RADD(localRAM_RADD),
		.RAM_WADD(WADD),
		.RAM_DIN(DIN),
		.RAM_W(W),
		.Master_Go(go),
		.Master_RW(rw),
		.Master_NumOfBytes(N_Byte),
		.Master_SlaveAddr(dev_add),
		.Master_DataWriteReg(dwr_DataWriteReg),
		.Master_SlaveRegAddr(R_Pointer),
		.Master_Stop(stop),
		.Controller_Enable(enableControllers[0]),
		.Menu_SlaveAddr(),
		.Menu_uRWControl(menuRWControl),
		.Master_Done(done),
		.Master_Ready(read),
		.Master_ACK(ack_e),
		.Master_ReadData(),
		.Master_RDOUT(RDOUT),
		.clk(clk),
		.reset(reset)
		);

	I2C_Master_Controller controller (
		.clk(clk),
		.reset(reset),
		.W(W),
		.WADD(WADD),
		.DIN(DIN),
		.go(go),
		.done(done),
		.ready(ready),
		.rw(rw),
		.N_Byte(N_Byte),
		.dev_add(dev_add),
		.dwr_DataWriteReg(dwr_DataWriteReg),
		.R_Pointer(R_Pointer),
		.drd_lcdData(drd_lcdData),
		.ack_e(ack_e)
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

endmodule
