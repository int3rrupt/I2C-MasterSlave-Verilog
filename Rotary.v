`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    23:24:44 11/20/2013 
// Design Name: 
// Module Name:    Rotary 
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
module Rotary(
	output reg rotateEvent,
	output reg direction,
   input rota,
   input rotb,
	input clk,
	input reset
    );

	reg [1:0] current;
	reg [1:0] prev;
	reg stop;
	
	always @(posedge clk) begin
		if (reset) begin
			rotateEvent = 0;
			direction = 0;
			current = {rotb,rota};
			stop = 0;
		end
		else begin
			rotateEvent = 0;
			prev = current;
			current = {rotb,rota};
			if ((prev == 2'b11 && current == 2'b01) ||
					(prev == 2'b01 && current == 2'b00) ||
					(prev == 2'b00 && current == 2'b10) ||
					(prev == 2'b10 && current == 2'b11)) begin
				if (!stop) begin
					rotateEvent = 1;
					direction = 1;
					stop = 1;
				end
			end
			else begin
				if ((prev == 2'b11 && current == 2'b10) ||
						(prev == 2'b10 && current == 2'b00) ||
						(prev == 2'b00 && current == 2'b01) ||
						(prev == 2'b01 && current == 2'b11) ) begin
					if (!stop) begin
						rotateEvent = 1;
						direction = 0;
						stop = 1;
					end
				end
				else begin
					if (prev == current)
						stop = 0;
				end
			end
		end
	end

endmodule
