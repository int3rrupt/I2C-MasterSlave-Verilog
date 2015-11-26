`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////

module I2C_Slave_MenuRAM32x8x10(
	output [7:0]lcdData[0:31],
	input [3:0]titleSelect,
	input [3:0]optionSelect
	);

	reg [7:0]menuROM[0:10][0:15];		// 16x8x11 RAM

	integer i, j;

	initial begin
		// Initialize RAM with spaces
		for (i = 0; i < 11; i = i + 1) begin
			for (j = 0; j < 16; j = j + 1) begin
				menuROM[i][j] = 8'hFE;	// Space
			end
		end
		// Main Menu
		menuROM[0][0] = 8'h4D;	// M
		menuROM[0][1] = 8'h41;	// A
		menuROM[0][2] = 8'h49;	// I
		menuROM[0][3] = 8'h4E;	// N
		menuROM[0][5] = 8'h4D;	// M
		menuROM[0][6] = 8'h45;	// E
		menuROM[0][7] = 8'h4E;	// N
		menuROM[0][8] = 8'h55;	// U
		// Display Master - Display Data Read From Master
		menuROM[1][0] = 8'h44;	// D
		menuROM[1][1] = 8'h69;	// i
		menuROM[1][2] = 8'h73;	// s
		menuROM[1][3] = 8'h70;	// p
		menuROM[1][4] = 8'h6C;	// l
		menuROM[1][5] = 8'h61;	// a
		menuROM[1][6] = 8'h79;	// y
		menuROM[1][8] = 8'h4D;	// M
		menuROM[1][9] = 8'h61;	// a
		menuROM[1][10] = 8'h73;	// s
		menuROM[1][11] = 8'h74;	// t
		menuROM[1][12] = 8'h65;	// e
		menuROM[1][13] = 8'h72;	// r
		// Display RAM - Display RAM Contents
		menuROM[2][0] = 8'h44;	// D
		menuROM[2][1] = 8'h69;	// i
		menuROM[2][2] = 8'h73;	// s
		menuROM[2][3] = 8'h70;	// p
		menuROM[2][4] = 8'h6C;	// l
		menuROM[2][5] = 8'h61;	// a
		menuROM[2][6] = 8'h79;	// y
		menuROM[2][8] = 8'h52;	// R
		menuROM[2][9] = 8'h41;	// A
		menuROM[2][10] = 8'h4D;	// M
		// Modify RAM - Modify RAM Contents
		menuROM[3][0] = 8'h4D;	// M
		menuROM[3][1] = 8'h6F;	// o
		menuROM[3][2] = 8'h64;	// d
		menuROM[3][3] = 8'h69;	// i
		menuROM[3][4] = 8'h66;	// f
		menuROM[3][5] = 8'h79;	// y
		menuROM[3][7] = 8'h52;	// R
		menuROM[3][8] = 8'h41;	// A
		menuROM[3][9] = 8'h4D;	// M
		// Clear RAM - Clear RAM Contents
		menuROM[4][0] = 8'h43;	// C
		menuROM[4][1] = 8'h6C;	// l
		menuROM[4][2] = 8'h65;	// e
		menuROM[4][3] = 8'h61;	// a
		menuROM[4][4] = 8'h72;	// r
		menuROM[4][6] = 8'h52;	// R
		menuROM[4][7] = 8'h41;	// A
		menuROM[4][8] = 8'h4D;	// M
		// Slave Actions
		menuROM[5][0] = 8'h53;	// S
		menuROM[5][1] = 8'h6C;	// l
		menuROM[5][2] = 8'h61;	// a
		menuROM[5][3] = 8'h76;	// v
		menuROM[5][4] = 8'h65;	// e
		menuROM[5][6] = 8'h41;	// A
		menuROM[5][7] = 8'h63;	// c
		menuROM[5][8] = 8'h74;	// t
		menuROM[5][9] = 8'h69;	// i
		menuROM[5][10] = 8'h6F;	// o
		menuROM[5][11] = 8'h6E;	// n
		menuROM[5][12] = 8'h73;	// s
		// Are you sure?
		menuROM[6][0] = 8'h41;	// A
		menuROM[6][1] = 8'h72;	// r
		menuROM[6][2] = 8'h65;	// e
		menuROM[6][4] = 8'h79;	// y
		menuROM[6][5] = 8'h6F;	// o
		menuROM[6][6] = 8'h75;	// u
		menuROM[6][8] = 8'h73;	// s
		menuROM[6][9] = 8'h75;	// u
		menuROM[6][10] = 8'h72;	// r
		menuROM[6][11] = 8'h65;	// e
		menuROM[6][12] = 8'h3F;	// ?
		// Set Slave Addr
		menuROM[7][0] = 8'h53;	// S
		menuROM[7][1] = 8'h65;	// e
		menuROM[7][2] = 8'h74;	// t
		menuROM[7][4] = 8'h53;	// S
		menuROM[7][5] = 8'h6C;	// l
		menuROM[7][6] = 8'h61;	// a
		menuROM[7][7] = 8'h76;	// v
		menuROM[7][8] = 8'h65;	// e
		menuROM[7][10] = 8'h41;	// A
		menuROM[7][11] = 8'h64;	// d
		menuROM[7][12] = 8'h64;	// d
		menuROM[7][13] = 8'h72;	// r
	end

	always@(posedge clk) begin
		lcdData[0:15] = menuROM[titleSelect];
		lcdData[16:31] = menuROM[optionSelect];
	end

endmodule
