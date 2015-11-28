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

	LCDI lcdi (
		.clk(clk),
		.DIN(DIN),
		.W(W),
		.WADD(WADD),
		.dataout(dataout),
		.control(control)
		);

endmodule
