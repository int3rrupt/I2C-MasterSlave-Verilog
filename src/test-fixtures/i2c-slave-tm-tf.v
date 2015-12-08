`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   22:48:44 11/11/2015
// Design Name:   I2C_Slave_TM
// Module Name:   C:/Users/Adrian/Dropbox/Cal Poly/ECE 431L/Source/I2C_Slave-LCD_Buttons_Switches/I2C_Slave_TM_TF.v
// Project Name:  I2C_Slave-LCD_Buttons_Switches
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: I2C_Slave_TM
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module I2C_Slave_TM_TF;

	// Inputs Slave
	reg Slave_rotary_a;
	reg Slave_rotary_b;
	reg Slave_rotary_center;
	reg Slave_btn_west;
	reg Slave_btn_east;
	reg Slave_btn_north;
	// Inputs Master
	reg Master_rotary_a;
	reg Master_rotary_b;
	reg Master_rotary_center;
	reg Master_btn_west;
	reg Master_btn_east;
	reg Master_btn_north;
	reg clk;
	reg reset;

	// Outputs
	wire [3:0] Slave_dataout;
	wire [2:0] Slave_control;
	wire [3:0] Master_dataout;
	wire [2:0] Master_control;
	
	// Bidirs
	wire scl;
	wire sda;

	// Instantiate the Unit Under Test (UUT)
	I2C_Slave_TM uut_slave (
		.dataout(Slave_dataout),
		.control(Slave_control),
		.btn_west(Slave_btn_west),
		.btn_east(Slave_btn_east),
		.btn_north(Slave_btn_north),
		.rotary_center(Slave_rotary_center),
		.rotary_a(Slave_rotary_a),
		.rotary_b(Slave_rotary_b),
		.scl(scl),
		.sda(sda),
		.clk(clk),
		.reset(reset)
	);
	
	I2C_Master_TM uut_master (
		.dataout(Master_dataout),
		.control(Master_control),
		.btn_west(Master_btn_west),
		.btn_east(Master_btn_east),
		.btn_north(Master_btn_north),
		.rotary_center(Master_rotary_center),
		.rotary_a(Master_rotary_a),
		.rotary_b(Master_rotary_b),
		.scl(scl),
		.sda(sda),
		.clk(clk),
		.reset(reset)
	);

	initial begin
		// Initialize Inputs
		Slave_rotary_a = 0;
		Slave_rotary_b = 0;
		Slave_rotary_center = 0;
		Slave_btn_west = 0;
		Slave_btn_east = 0;
		Slave_btn_north = 0;
		Master_rotary_a = 0;
		Master_rotary_b = 0;
		Master_rotary_center = 0;
		Master_btn_west = 0;
		Master_btn_east = 0;
		Master_btn_north = 0;
		clk = 1;
		reset = 0;

		// Wait at least 15ms for LCDI initialization to complete
		#15_000_100;
		reset = 1;

		#20;
		reset = 0;

		#7001000;
		//////////////////////// Slave Clear Local RAM
		
//		// Left Rotate to I2C Actions
//		#1500; Slave_rotary_a = 1;
//		#20; Slave_rotary_b = 1;
//		#20; Slave_rotary_a = 0;
//		#20; Slave_rotary_b = 0;
//		
//		// Left Rotate to Clear Local RAM
//		#1500; Slave_rotary_a = 1;
//		#20; Slave_rotary_b = 1;
//		#20; Slave_rotary_a = 0;
//		#20; Slave_rotary_b = 0;
//		
//		// Select Clear Local RAM
//		#1500;
//		Slave_rotary_center = 1; #7001000; Slave_rotary_center = 0; #7001000;
//		
//		// Confirm Clear Local RAM
//		#1500;
//		Slave_rotary_center = 1; #7001000; Slave_rotary_center = 0; #7001000;

		/////////////////////////// Master Read Remote
		// Left Rotate to I2C Actions
		#1500; Master_rotary_a = 1;
		#20; Master_rotary_b = 1;
		#20; Master_rotary_a = 0;
		#20; Master_rotary_b = 0;
		
		// Select I2C Actions
		#1500;
		Master_rotary_center = 1; #7001000; Master_rotary_center = 0; #7001000;
		
		// Right rotate to Read From Slave
//		#1500; Master_rotary_b = 1;
//		#20; Master_rotary_a = 1;
//		#20; Master_rotary_b = 0;
//		#20; Master_rotary_a = 0;
		
		// Select Read From Slave
		#1500;
		Master_rotary_center = 1; #7001000; Master_rotary_center = 0; #7001000;
		
		#150000000;
		
		#1500; Master_rotary_b = 1;
		#20; Master_rotary_a = 1;
		#20; Master_rotary_b = 0;
		#20; Master_rotary_a = 0;

	end
	
	pullup (scl);
	pullup (sda);
	
	always clk = #10 ~clk;
	
endmodule

