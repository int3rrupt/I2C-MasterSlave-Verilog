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

	// I2C Mode Parameters
	parameter I2C_MODE_MASTER = 0, I2C_MODE_SLAVE = 1;

	// I2C Mode
	reg I2C_MODE = I2C_MODE_MASTER;
	// Slave Address
	//wire [6:0]SlaveAddr;

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
	wire [4:0]MenuRAM_Select;
	wire [7:0]MultiRAM_DOUT;
	wire [1:0]MultiRAM_SEL;
	wire [4:0]MultiRAM_ADD;
	wire [7:0]MultiRAM_DIN;
	wire MultiRAM_W;
	wire MultiRAM_Clear;
	wire [7:0]RemoteRAM_DIN;
	wire RemoteRAM_W;
	wire [7:0]LocalRAM_DOUT;
	wire [7:0]RemoteLocalRAM_ADD;
	// I2C Controllers
	wire RemoteRWControl;
	wire [1:0]enableControllers;
	wire Controller_Done;
	// Master
	wire Master_scl_out;
	wire Master_sda_out;
	wire scl_in;
	wire sda_in;
	wire Master_Go;
	wire Master_RW;
	wire [5:0]Master_NumOfBytes;
	wire [6:0]Master_SlaveAddr;
	wire [7:0]Master_DataWriteReg;
	wire [7:0]Master_SlaveRegAddr;
	wire Master_Enable;
	wire Master_Stop;
	wire Master_Done;
	wire Master_Ready;
	wire Master_ACK;
	wire [7:0]Master_ReadData;
	wire [4:0]Master_RemoteLocalRAM_ADD;
	wire [7:0]Master_RemoteRAM_DIN;
	wire Master_RemoteRAM_W;
	// Slave
	wire Slave_scl_out;
	wire Slave_sda_out;
	wire Slave_scl_in;
	wire Slave_sda_in;
	wire Slave_Enable;
	wire [4:0]Slave_RemoteLocalRAM_ADD;
	wire [7:0]Slave_RemoteRAM_DIN;
	wire Slave_RemoteRAM_W;






	//assign scl = I2C_MODE == I2C_MODE_MASTER ? Master_scl_out : Slave_scl_out;
	//assign sda = I2C_MODE == I2C_MODE_MASTER ? Master_sda_out : Slave_sda_out;
	//assign scl_in = scl;
	//assign sda_in = sda;
	//assign Slave_scl_in = scl;
	//assign Slave_sda_in = sda;

	assign Master_Enable = I2C_MODE == I2C_MODE_MASTER;
	assign Slave_Enable = I2C_MODE == I2C_MODE_SLAVE;

	assign RemoteLocalRAM_ADD = I2C_MODE == I2C_MODE_MASTER ? Master_RemoteLocalRAM_ADD : Slave_RemoteLocalRAM_ADD;
	assign RemoteRAM_DIN = I2C_MODE == I2C_MODE_MASTER ? Master_RemoteRAM_DIN : Slave_RemoteRAM_DIN;
	assign RemoteRAM_W = I2C_MODE == I2C_MODE_MASTER ? Master_RemoteRAM_W : Slave_RemoteRAM_W;

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

	I2C_Master master (
		.go(Master_Go),
		.done(Master_Done),
		.ready(Master_Ready),
		.rw(Master_RW),
		.N_Byte(Master_NumOfBytes),
		.dev_add(Master_SlaveAddr),
		.dwr_DataWriteReg(Master_DataWriteReg),
		.R_Pointer(Master_SlaveRegAddr),
		.drd_lcdData(Master_ReadData),
		.ack_e(Master_ACK),
		.scl_out(Master_scl_out),
		.sda_out(Master_sda_out),
		.Master_Enable(Master_Enable),
		.stop(Master_Stop),
		.scl_in(scl_in),
		.sda_in(sda_in),
		.clk(clk),
		.reset(reset),
		.scl(scl),
		.sda(sda)
		);

//	I2C_Slave slave(
//		.RAM_Addr(Slave_RemoteLocalRAM_ADD),
//		.RemoteRAM_DIN(Slave_RemoteRAM_DIN),
//		.RemoteRAM_W(Slave_RemoteRAM_W),
//		.Slave_Enable(Slave_Enable),
//		.LocalRAM_DOUT(LocalRAM_DOUT),
//		.scl(Slave_scl),
//		.sda(Slave_sda),
//		.clk(clk),
//		.reset(reset)
//		);

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
		.I2C_Mode(I2C_MODE),
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
		.RemoteRAM_WADD(RemoteLocalRAM_ADD),
		.RemoteRAM_DIN(RemoteRAM_DIN),
		.RemoteRAM_W(RemoteRAM_W),
		.LocalRAM_RADD(RemoteLocalRAM_ADD),
		.clk(clk)
		);

	I2C_Master_SpartanSlaveController spartanSlaveController(
		.RAM_ADD(Master_RemoteLocalRAM_ADD),
		.RAM_DIN(Master_RemoteRAM_DIN),
		.RAM_W(Master_RemoteRAM_W),
		.Master_Go(Master_Go),
		.Master_RW(Master_RW),
		.Master_NumOfBytes(Master_NumOfBytes),
		.Master_SlaveAddr(Master_SlaveAddr),
		.Master_DataWriteReg(Master_DataWriteReg),
		.Master_SlaveRegAddr(Master_SlaveRegAddr),
		.Master_Stop(Master_Stop),
		.Controller_Done(Controller_Done),
		.Controller_Enable(enableControllers[0]),
		.Menu_SlaveAddr(SlaveAddr),
		.Menu_RWControl(RemoteRWControl),
		.Master_Done(Master_Done),
		.Master_Ready(Master_Ready),
		.Master_ACK(Master_ACK),
		.Master_ReadData(Master_ReadData),
		.RAM_RDOUT(LocalRAM_DOUT),
		.clk(clk),
		.reset(reset)
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
