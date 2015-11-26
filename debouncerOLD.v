`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    19:11:19 11/19/2013 
// Design Name: 
// Module Name:    debouncer 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module debouncerOLD(
	output reg out,
    input sw,
	 input clk,
	 input reset
    );
	 
	 reg [7:0] count;
	 reg stop;

	always @(posedge clk) begin
		if (reset) begin
			count <= 0;
			out <= 0;
		end
		else begin
			if (sw) begin
				if (count<10) begin
					count <= count + 1;
				end
				else begin
					count <= 0;
					out <= 1;
				end
			end
			else begin
				count <= 0;
				out <= 0;
			end
//			if (count == 10)begin
//				
//			end
		end
	end

endmodule
