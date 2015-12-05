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
	input btn_west,				//
	input btn_east,
	input btn_north,
	input rotary_center,			// Push Button to signal which nibble being written
	input rotary_a,				// Push Button Address Increment
	input rotary_b,				// Push Button Address Decrement
	inout scl,
	inout sda,
	input clk,
	input reset
	);

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
	wire enableCursor;
	wire cursorLeft;
	wire cursorRight;
	wire editAddress;
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
	// controller
	wire EnableController;
	wire Controller_Done;
	wire [6:0]SlaveAddr;
	wire RemoteRWControl;
	// Master
	wire Master_Done;
	wire Master_Ready;
	wire Master_ACK;
	wire [7:0]Master_ReadData;
	wire Master_Go;
	wire Master_Stop;
	wire Master_RW;
	wire [5:0]Master_NumOfBytes;
	wire [6:0]Master_SlaveAddr;
	wire [7:0]Master_SlaveRegAddr;
	wire [7:0]Master_DataWriteReg;

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

	I2C_Master master (
		.done(Master_Done),
		.ready(Master_Ready),
		.ack_e(Master_ACK),
		.drd_lcdData(Master_ReadData),
		.go(Master_Go),
		.stop(Master_Stop),
		.rw(Master_RW),
		.N_Byte(Master_NumOfBytes),
		.dev_add(Master_SlaveAddr),
		.dwr_DataWriteReg(Master_DataWriteReg),
		.R_Pointer(Master_SlaveRegAddr),
		.scl(scl),
		.sda(sda),
		.clk(clk),
		.reset(reset)
		);

	I2C_Master_SpartanSlaveController spartanSlaveController(
		.RAM_ADD(RAM_ADD),
		.RemoteRAM_DIN(RemoteRAM_DIN),
		.RemoteRAM_W(RemoteRAM_W),
		.Master_Go(Master_Go),
		.Master_Stop(Master_Stop),
		.Master_RW(Master_RW),
		.Master_NumOfBytes(Master_NumOfBytes),
		.Master_SlaveAddr(Master_SlaveAddr),
		.Master_SlaveRegAddr(Master_SlaveRegAddr),
		.Master_DataWriteReg(Master_DataWriteReg),
		.Controller_Done(Controller_Done),
		.Controller_Enable(enableControllers[0]),
		.Menu_SlaveAddr(SlaveAddr),
		.Menu_RWControl(RemoteRWControl),
		.RAM_RDOUT(LocalRAM_DOUT),
		.Master_Done(Master_Done),
		.Master_Ready(Master_Ready),
		.Master_ACK(Master_ACK),
		.Master_ReadData(Master_ReadData),
		.clk(clk),
		.reset(reset)
		);

	I2C_MenuController menuController(
		.LCD_WADD(LCD_WADD),
		.LCD_DIN(LCD_DIN),
		.LCD_W(LCD_W),
		.RemoteRWControl(RemoteRWControl),
		.enableCursor(enableCursor),
		.cursorLeft(cursorLeft),
		.cursorRight(cursorRight),
		.editAddress(editAddress),
		.enableControllers(enableControllers),
		.MenuRAM_Select(MenuRAM_Select),
		.MultiRAM_SEL(MultiRAM_SEL),
		.MultiRAM_ADD(MultiRAM_ADD),
		.MultiRAM_DIN(MultiRAM_DIN),
		.MultiRAM_W(MultiRAM_W),
		.MultiRAM_Clear(MultiRAM_Clear),
		.SlaveAddr(SlaveAddr),
		.MultiRAM_DOUT(MultiRAM_DOUT),
		.Controller_Done(Controller_Done),
		.rotary_event(rotary_event),
		.rotary_left(rotary_left),
		.rotaryBtn(rotaryBtn),
		.charColumnLeftBtn(charColumnLeftBtn),
		.charColumnRightBtn(charColumnRightBtn),
		.menuBtn(menuBtn),
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



//	I2C_Master_Controller controller (
//		.clk(clk),
//		.reset(reset),
//		.W(W),
//		.WADD(WADD),
//		.DIN(DIN),
//		.go(go),
//		.done(done),
//		.ready(ready),
//		.rw(rw),
//		.N_Byte(N_Byte),
//		.dev_add(dev_add),
//		.dwr_DataWriteReg(dwr_DataWriteReg),
//		.R_Pointer(R_Pointer),
//		.drd_lcdData(drd_lcdData),
//		.ack_e(ack_e)
//		);

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
