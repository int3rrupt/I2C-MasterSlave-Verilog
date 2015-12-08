`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Engineer:        Adrian Reyes
// Module Name:     I2C_LCD_TempSensor
// Project Name:    I2C
// Target Devices:  SPARTAN 3E
// Description:     I2C_LCD_TempSensor Test Fixture
// Dependencies:    I2C_LCD_TempSensor
//////////////////////////////////////////////////////////////////////////////////

module I2C_Master_TM_TF;

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
	I2C_Master_TM uut (
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

		// Add stimulus here
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
		// Clear Localm RAM
		#1500;
		rotary_center = 1; #7001000; rotary_center = 0; #7001000;
		// Are you sure
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
		
		#1500; rotary_b = 1;
		#20; rotary_a = 1;
		#20; rotary_b = 0;
		#20; rotary_a = 0;
		
		#1500; rotary_b = 1;
		#20; rotary_a = 1;
		#20; rotary_b = 0;
		#20; rotary_a = 0;
		// I2C Actions
		#1500;
		rotary_center = 1; #7001000; rotary_center = 0; #7001000;
		// Write to Remote
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
