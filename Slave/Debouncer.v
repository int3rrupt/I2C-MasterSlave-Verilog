`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer:			Adrian Reyes
// Module Name:		Debouncer
// Project Name:		I2C_Slave-LCD_Buttons_Switches
// Target Devices:	SPARTAN 3E
// Description:		Push Button Debouncer
// Dependencies:		
//////////////////////////////////////////////////////////////////////////////////
module Debouncer(
	output E,
	input pb,			// Push button
	input clk
	);
	
	reg [19:0]SDC;		// Signal Delay Counter
	reg dpb;				// Q of first flip flop
	reg spb;				// Q of second flip flop
	reg [2:0]currentState;

	initial begin
		currentState = 0;
		dpb = 0;
		spb = 0;
	end

	// Clock in data into flip flops
	always@(posedge clk) begin
		dpb <= pb;
		spb <= dpb;
	end

	// Assert E while current state is 5 (one clock cycle)
	assign E = currentState == 5;

	always@(posedge clk) begin
		case(currentState)
			0:	begin : Button_Pressed_Set_Delay
					if (spb) begin				// If the button was pressed
						SDC <= 350000;			// Set Delay of 7ms in clock cycles
						currentState <= 1;	// Continue
					end
				end
			1:	begin : Wait_Pressed_Delay_Time
					SDC <= SDC - 1;			// Decrement Delay Counter
					if (SDC == 0)				// If Delay counter cleared
						currentState <= 2;	// Continue
				end
			2:	begin : Check_Button_Status
					if (spb)						// If button still pressed
						currentState <= 3;	// Continue
					else							// Else
						currentState <= 0;	// Start over
				end
			3:	begin : Button_Depressed_Set_Delay
					if (!spb) begin			// If button now depressed
						SDC <= 350000;			// Set Delay of 7ms in clock cycles
						currentState <= 4;	// Continue
					end
				end
			4:	begin : Wait_Depressed_Delay_Time
					SDC <= SDC - 1;			// Decrement Delay Counter
					if (SDC == 0)				// If Delay counter cleared
						currentState <= 5;	// Continue
				end
			5:	begin : E_Asserted
					currentState <= 0;		// Start over
				end
		endcase
	end

endmodule
