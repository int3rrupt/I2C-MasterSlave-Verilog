module I2C_Master_RAMController(
	output reg [7:0]RAM_DOUT,			// RAM data out (Menu Controller)
	//output reg [7:0]slaveRAM_DOUT,	// Slave RAM data out (Master read)
	input [3:0]menuSelect,				// Menu select
	input [1:0]RAM_RSEL,					// RAM read select
	input [1:0]RAM_WSEL,					// RAM write select
	input [4:0]RAM_RADD,					// RAM read address (Menu Controller)
	input [4:0]RAM_WADD,					// RAM write address (Menu Controller)
	input [7:0]RAM_DIN,					// RAM data in (Menu Controller)
	input RAM_W,							// RAM write port (Menu Controller)
	input RAM_Clear,						// Clear the contents of the selected RAM
	input [4:0]masterRAM_WADD,			// Master RAM write address
	input [7:0]masterRAM_DIN,			// Master RAM data in
	input masterRAM_W,					// Master RAM Write port
	input [4:0]slaveRAM_RADD,			// Slave RAM Address (Master read)
	input clk
	);

	// Menu parameters
	parameter MENU_MAIN = 4'b0000, MENU_DISPLAY_MASTER = 4'b0001,
		MENU_DISPLAY_RAM = 4'b0010, MENU_MODIFY_RAM = 4'b0011,
		MENU_CLEAR_RAM = 4'b0100, MENU_SLAVE_ACTIONS = 4'b0101,
		MENU_ARE_YOU_SURE = 4'b0110, MENU_SET_SLAVE_ADDR = 4'b0111,
		MENU_YES = 4'b1000, MENU_NO = 4'b1001;
	// Menu RAM select parameters
	parameter RAM_SEL_MENU = 2'b00, RAM_SEL_MASTER = 2'b01, RAM_SEL_SLAVE = 2'b10;
	// Characters
	parameter CHAR_SPACE = 8'h20;

	reg [7:0]menuROM[0:10][0:15];					// 16x8x11 Menu ROM
	reg [7:0]masterRAM[0:31];
	reg [7:0]slaveRAM[0:31];

	reg [7:0]clearRAMChar = CHAR_SPACE;

	integer i, j;
	initial begin
		// ************************** MENU ROM **************************
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
		// Yes
		menuROM[8][1] = 8'h59;	// Y
		menuROM[8][2] = 8'h65;	// e
		menuROM[8][3] = 8'h73;	// s
		// No
		menuROM[9][1] = 8'h4E;	// N
		menuROM[9][2] = 8'h6F;	// o
	end

	// RAM read
	always@(posedge clk) begin
		case(RAM_RSEL)
			RAM_SEL_MENU:		RAM_DOUT <= menuROM[menuSelect][RAM_RADD];
			RAM_SEL_MASTER:	RAM_DOUT <= masterRAM[RAM_RADD];
			RAM_SEL_SLAVE:		RAM_DOUT <= slaveRAM[RAM_RADD];
		endcase
	end
	// RAM write
	always@(posedge clk) begin
		if (RAM_W) begin
			slaveRAM[RAM_WADD] <= RAM_DIN;
		end
		else begin
			if (RAM_Clear && RAM_WSEL == RAM_SEL_SLAVE) begin
				slaveRAM[0] <= clearRAMChar; slaveRAM[16] <= clearRAMChar;
				slaveRAM[1] <= clearRAMChar; slaveRAM[17] <= clearRAMChar;
				slaveRAM[2] <= clearRAMChar; slaveRAM[18] <= clearRAMChar;
				slaveRAM[3] <= clearRAMChar; slaveRAM[19] <= clearRAMChar;
				slaveRAM[4] <= clearRAMChar; slaveRAM[20] <= clearRAMChar;
				slaveRAM[5] <= clearRAMChar; slaveRAM[21] <= clearRAMChar;
				slaveRAM[6] <= clearRAMChar; slaveRAM[22] <= clearRAMChar;
				slaveRAM[7] <= clearRAMChar; slaveRAM[23] <= clearRAMChar;
				slaveRAM[8] <= clearRAMChar; slaveRAM[24] <= clearRAMChar;
				slaveRAM[9] <= clearRAMChar; slaveRAM[25] <= clearRAMChar;
				slaveRAM[10] <= clearRAMChar; slaveRAM[26] <= clearRAMChar;
				slaveRAM[11] <= clearRAMChar; slaveRAM[27] <= clearRAMChar;
				slaveRAM[12] <= clearRAMChar; slaveRAM[28] <= clearRAMChar;
				slaveRAM[13] <= clearRAMChar; slaveRAM[29] <= clearRAMChar;
				slaveRAM[14] <= clearRAMChar; slaveRAM[30] <= clearRAMChar;
				slaveRAM[15] <= clearRAMChar; slaveRAM[31] <= clearRAMChar;
			end
		end
	end
	// Master write
	always@(posedge clk) begin
		if (masterRAM_W) begin
			masterRAM[masterRAM_WADD] = masterRAM_DIN;
		end
	end
	// Slave read
	always@(posedge clk) begin
		slaveRAM_DOUT <= slaveRAM[slaveRAM_RADD];
	end

endmodule
