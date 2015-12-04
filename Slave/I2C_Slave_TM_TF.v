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

	// Inputs
	reg rotary_a;
	reg rotary_b;
	reg rotary_center;
	reg btn_west;
	reg btn_east;
	reg btn_north;
	reg clk;
	reg reset;

	// Outputs
	wire [3:0] dataout;
	wire [2:0] control;

	// Bidirs
	wire scl;
	wire sda;

	// Instantiate the Unit Under Test (UUT)
	I2C_Slave_TM uut_master (
		.dataout(dataout),
		.control(control),
		.btn_west(btn_west),
		.btn_east(btn_east),
		.btn_north(btn_north),
		.rotary_center(rotary_center),
		.rotary_a(rotary_a),
		.rotary_b(rotary_b),
		.scl(scl),
		.sda(sda),
		.clk(clk),
		.reset(reset)
	);
	
//	I2C_Slave_TM uut_slave(
//		.dataout(dataout),
//		.control(control),
//		.btn_west(btn_west),
//		.btn_east(btn_east),
//		.btn_north(btn_north),
//		.rotary_center(rotary_center),
//		.rotary_a(rotary_a),
//		.rotary_b(rotary_b),
//		.scl(scl),
//		.sda(sda),
//		.clk(clk),
//		.reset(reset)
//	);

	initial begin
		// Initialize Inputs
		rotary_a = 0;
		rotary_b = 0;
		rotary_center = 0;
		btn_west = 0;
		btn_east = 0;
		btn_north = 0;
		clk = 1;
		reset = 0;

		// Wait at least 15ms for LCDI initialization to complete
		#15_000_100;
		reset = 1;

		#20;
		reset = 0;

		#7001000;

		// Left Rotate
		#1500; rotary_a = 1;
		#20; rotary_b = 1;
		#20; rotary_a = 0;
		#20; rotary_b = 0;
		
		#1500;
		rotary_center = 1; #7001000; rotary_center = 0; #7001000;
		
		#1500;
		rotary_center = 1; #7001000; rotary_center = 0; #7001000;
		
		#150000000;
		
		#1500; rotary_b = 1;
		#20; rotary_a = 1;
		#20; rotary_b = 0;
		#20; rotary_a = 0;
		
		#1500; rotary_b = 1;
		#20; rotary_a = 1;
		#20; rotary_b = 0;
		#20; rotary_a = 0;
		
		#1500; rotary_b = 1;
		#20; rotary_a = 1;
		#20; rotary_b = 0;
		#20; rotary_a = 0;
		
		#1500;
		rotary_center = 1; #7001000; rotary_center = 0; #7001000;
		
		#1500;
		rotary_center = 1; #7001000; rotary_center = 0; #7001000;
		
		#1500; rotary_b = 1;
		#20; rotary_a = 1;
		#20; rotary_b = 0;
		#20; rotary_a = 0;
		
		#1500;
		rotary_center = 1; #7001000; rotary_center = 0; #7001000;
		
		#1500; rotary_b = 1;
		#20; rotary_a = 1;
		#20; rotary_b = 0;
		#20; rotary_a = 0;
		
		#1500; rotary_b = 1;
		#20; rotary_a = 1;
		#20; rotary_b = 0;
		#20; rotary_a = 0;
		
		#1500;
		rotary_center = 1; #7001000; rotary_center = 0; #7001000;
		
		#1500; rotary_b = 1;
		#20; rotary_a = 1;
		#20; rotary_b = 0;
		#20; rotary_a = 0;
		
		#1500;
		rotary_center = 1; #7001000; rotary_center = 0; #7001000;
		
		#2500; rotary_b = 1;
		#20; rotary_a = 1;
		#20; rotary_b = 0;
		#20; rotary_a = 0;
		
		#1500; rotary_b = 1;
		#20; rotary_a = 1;
		#20; rotary_b = 0;
		#20; rotary_a = 0;
		
		#1500; rotary_b = 1;
		#20; rotary_a = 1;
		#20; rotary_b = 0;
		#20; rotary_a = 0;
		
		#1500; rotary_center = 1; #7001000; rotary_center = 0; #7001000;
		
		#1500; rotary_b = 1;
		#20; rotary_a = 1;
		#20; rotary_b = 0;
		#20; rotary_a = 0;
		
		#1500; rotary_b = 1;
		#20; rotary_a = 1;
		#20; rotary_b = 0;
		#20; rotary_a = 0;
		
		#1500; rotary_b = 1;
		#20; rotary_a = 1;
		#20; rotary_b = 0;
		#20; rotary_a = 0;

	end
	
	pullup (scl);
	pullup (sda);
	
	always clk = #10 ~clk;
	
endmodule

