`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// 
// 
////////////////////////////////////////////////////////////////////////////////

module I2C_Slave_RAMController_TF;

	// Inputs
	reg [3:0] menuSelect;
	reg [1:0] RAM_RSEL;
	reg [1:0] RAM_WSEL;
	reg [4:0] RAM_RADD;
	reg [4:0] RAM_WADD;
	reg [7:0] RAM_DIN;
	reg RAM_W;
	reg [4:0] masterRAM_WADD;
	reg [7:0] masterRAM_DIN;
	reg masterRAM_W;
	reg [4:0] slaveRAM_RADD;
	reg clk;

	// Outputs
	wire [7:0] RAM_DOUT;
	wire [7:0] slaveRAM_DOUT;

	// Instantiate the Unit Under Test (UUT)
	I2C_Slave_RAMController uut (
		.RAM_DOUT(RAM_DOUT), 
		.slaveRAM_DOUT(slaveRAM_DOUT), 
		.menuSelect(menuSelect), 
		.RAM_RSEL(RAM_RSEL), 
		.RAM_WSEL(RAM_WSEL), 
		.RAM_RADD(RAM_RADD), 
		.RAM_WADD(RAM_WADD), 
		.RAM_DIN(RAM_DIN), 
		.RAM_W(RAM_W), 
		.masterRAM_WADD(masterRAM_WADD), 
		.masterRAM_DIN(masterRAM_DIN), 
		.masterRAM_W(masterRAM_W), 
		.slaveRAM_RADD(slaveRAM_RADD), 
		.clk(clk)
	);

	initial begin
		// Initialize Inputs
		menuSelect = 0;
		RAM_RSEL = 0;
		RAM_WSEL = 0;
		RAM_RADD = 0;
		RAM_WADD = 0;
		RAM_DIN = 0;
		RAM_W = 0;
		masterRAM_WADD = 0;
		masterRAM_DIN = 0;
		masterRAM_W = 0;
		slaveRAM_RADD = 0;
		clk = 1;

		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here
		RAM_RSEL = 0;

	end
	
	always #2 clk = ~clk;
      
endmodule

