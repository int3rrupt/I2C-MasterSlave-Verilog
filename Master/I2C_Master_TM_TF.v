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
		.scl(scl),
		.sda(sda),
		.clk(clk),
		.reset(reset)
	);
	
	initial begin
		// Initialize Inputs
		clk = 1;
		reset = 0;

		// Wait 100 ns for global reset to finish
		#4500000;
		reset = 1;
		#4;
		reset = 0;
		

		// Add stimulus here

	end
	
	pullup (scl);
	pullup (sda);

	always clk = #2 ~clk;

endmodule
