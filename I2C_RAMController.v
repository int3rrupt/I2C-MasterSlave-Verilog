module I2C_RAMController(
	output reg [7:0]MultiRAM_DOUT,	// RAM data out (Menu Controller)
	output reg [7:0]LocalRAM_DOUT,	// Local RAM data out (Master read)
	input [3:0]MenuRAM_Select,			// Menu select
	input [1:0]MultiRAM_SEL,			// RAM select
	input [4:0]MultiRAM_ADD,			// RAM address (Menu Controller)
	input [7:0]MultiRAM_DIN,			// RAM data in (Menu Controller)
	input MultiRAM_W,						// RAM write port (Menu Controller)
	input MultiRAM_Clear,				// Clear the contents of the selected RAM
	input [4:0]RemoteRAM_WADD,			// Master RAM write address
	input [7:0]RemoteRAM_DIN,			// Master RAM data in
	input RemoteRAM_W,					// Master RAM Write port
	input [4:0]LocalRAM_RADD,			// Slave RAM Address (Master read)
	input clk
	);

	// Menu parameters
	parameter MENU_TITLE_MAIN = 0, MENU_OPTION_DISPLAY_REMOTE = 1,
		MENU_OPTION_DISPLAY_LOCAL = 2, MENU_OPTION_MODIFY_LOCAL_RAM = 3,
		MENU_OPTION_CLEAR_LOCAL_RAM = 4, MENU_OPTION_I2C_ACTIONS = 5,
		MENU_TITLE_I2C_ACTIONS = 6, MENU_TITLE_ARE_YOU_SURE = 7,
		MENU_OPTION_YES = 8, MENU_OPTION_NO = 9, MENU_OPTION_WRITE_TO_REMOTE = 10,
		MENU_OPTION_READ_FROM_REMOTE = 11, MENU_OPTION_SET_LOCAL_ADDR = 12;
	// Menu RAM select parameters
	parameter RAM_SEL_MENU = 0, RAM_SEL_REMOTE = 1, RAM_SEL_LOCAL = 2;
	// Characters
	parameter
		CHAR_A = 8'h41, CHAR_H = 8'h48, CHAR_O = 8'h4F, CHAR_V = 8'h56,
		CHAR_B = 8'h42, CHAR_I = 8'h49, CHAR_P = 8'h50, CHAR_W = 8'h57,
		CHAR_C = 8'h43, CHAR_J = 8'h4A, CHAR_Q = 8'h51, CHAR_X = 8'h58,
		CHAR_D = 8'h44, CHAR_K = 8'h4B, CHAR_R = 8'h52, CHAR_Y = 8'h59,
		CHAR_E = 8'h45, CHAR_L = 8'h4C, CHAR_S = 8'h53, CHAR_Z = 8'h5A,
		CHAR_F = 8'h46, CHAR_M = 8'h4D, CHAR_T = 8'h54,
		CHAR_G = 8'h47, CHAR_N = 8'h4E, CHAR_U = 8'h55,

		CHAR_a = 8'h61, CHAR_h = 8'h68, CHAR_o = 8'h6F, CHAR_v = 8'h76,
		CHAR_b = 8'h62, CHAR_i = 8'h69, CHAR_p = 8'h70, CHAR_w = 8'h77,
		CHAR_c = 8'h63, CHAR_j = 8'h6A, CHAR_q = 8'h71, CHAR_x = 8'h78,
		CHAR_d = 8'h64, CHAR_k = 8'h6B, CHAR_r = 8'h72, CHAR_y = 8'h79,
		CHAR_e = 8'h65, CHAR_l = 8'h6C, CHAR_s = 8'h73, CHAR_z = 8'h7A,
		CHAR_f = 8'h66, CHAR_m = 8'h6D, CHAR_t = 8'h74,
		CHAR_g = 8'h67, CHAR_n = 8'h6E, CHAR_u = 8'h75,
		CHAR_SPACE = 8'h20, CHAR_2 = 8'h32, CHAR_QUESTION = 8'h3F;

	reg [7:0]menuROM[0:12][0:15];					// 16x8x11 Menu ROM
	reg [7:0]remoteRAM[0:31];
	reg [7:0]localRAM[0:31];

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
		menuROM[0][0] = CHAR_M;		// M
		menuROM[0][1] = CHAR_A;		// A
		menuROM[0][2] = CHAR_I;		// I
		menuROM[0][3] = CHAR_N;		// N
		menuROM[0][5] = CHAR_M;		// M
		menuROM[0][6] = CHAR_E;		// E
		menuROM[0][7] = CHAR_N;		// N
		menuROM[0][8] = CHAR_U;		// U
		// Display Remote - Display Data Read From Remote Device
		menuROM[1][0] = CHAR_D;		// D
		menuROM[1][1] = CHAR_i;		// i
		menuROM[1][2] = CHAR_s;		// s
		menuROM[1][3] = CHAR_p;		// p
		menuROM[1][4] = CHAR_l;		// l
		menuROM[1][5] = CHAR_a;		// a
		menuROM[1][6] = CHAR_y;		// y
		menuROM[1][8] = CHAR_R;		// R
		menuROM[1][9] = CHAR_e;		// e
		menuROM[1][10] = CHAR_m;	// m
		menuROM[1][11] = CHAR_o;	// o
		menuROM[1][12] = CHAR_t;	// t
		menuROM[1][13] = CHAR_e;	// e
		// Display Local - Display Local RAM Contents
		menuROM[2][0] = CHAR_D;		// D
		menuROM[2][1] = CHAR_i;		// i
		menuROM[2][2] = CHAR_s;		// s
		menuROM[2][3] = CHAR_p;		// p
		menuROM[2][4] = CHAR_l;		// l
		menuROM[2][5] = CHAR_a;		// a
		menuROM[2][6] = CHAR_y;		// y
		menuROM[2][8] = CHAR_L;		// L
		menuROM[2][9] = CHAR_o;		// o
		menuROM[2][10] = CHAR_c;	// c
		menuROM[2][11] = CHAR_a;	// a
		menuROM[2][12] = CHAR_l;	// l
		// Modify local RAM - Modify Local RAM Contents
		menuROM[3][0] = CHAR_M;		// M
		menuROM[3][1] = CHAR_o;		// o
		menuROM[3][2] = CHAR_d;		// d
		menuROM[3][3] = CHAR_i;		// i
		menuROM[3][4] = CHAR_f;		// f
		menuROM[3][5] = CHAR_y;		// y
		menuROM[3][7] = CHAR_L;		// L
		menuROM[3][8] = CHAR_o;		// o
		menuROM[3][9] = CHAR_c;		// c
		menuROM[3][10] = CHAR_a;	// a
		menuROM[3][11] = CHAR_l;	// l
		menuROM[3][13] = CHAR_R;	// R
		menuROM[3][14] = CHAR_A;	// A
		menuROM[3][15] = CHAR_M;	// M
		// Clear Local RAM - Clear local RAM Contents
		menuROM[4][0] = CHAR_C;		// C
		menuROM[4][1] = CHAR_l;		// l
		menuROM[4][2] = CHAR_e;		// e
		menuROM[4][3] = CHAR_a;		// a
		menuROM[4][4] = CHAR_r;		// r
		menuROM[4][6] = CHAR_L;		// L
		menuROM[4][7] = CHAR_o;		// o
		menuROM[4][8] = CHAR_c;		// c
		menuROM[4][9] = CHAR_a;		// a
		menuROM[4][10] = CHAR_l;	// l
		menuROM[4][12] = CHAR_R;	// R
		menuROM[4][13] = CHAR_A;	// A
		menuROM[4][14] = CHAR_M;	// M
		// I2C Actions
		menuROM[5][0] = CHAR_I;		// I
		menuROM[5][1] = CHAR_2;		// 2
		menuROM[5][2] = CHAR_C;		// C
		menuROM[5][4] = CHAR_A;		// A
		menuROM[5][5] = CHAR_c;		// c
		menuROM[5][6] = CHAR_t;		// t
		menuROM[5][7] = CHAR_i;		// i
		menuROM[5][8] = CHAR_o;		// o
		menuROM[5][9] = CHAR_n;		// n
		menuROM[5][10] = CHAR_s;	// s
		// I2C ACTIONS - Title
		menuROM[6][0] = CHAR_I;		// I
		menuROM[6][1] = CHAR_2;		// 2
		menuROM[6][2] = CHAR_C;		// C
		menuROM[6][4] = CHAR_A;		// A
		menuROM[6][5] = CHAR_C;		// C
		menuROM[6][6] = CHAR_T;		// T
		menuROM[6][7] = CHAR_I;		// I
		menuROM[6][8] = CHAR_O;		// O
		menuROM[6][9] = CHAR_N;		// N
		menuROM[6][10] = CHAR_S;	// S
		// ARE YOU SURE?
		menuROM[7][0] = CHAR_A;		// A
		menuROM[7][1] = CHAR_R;		// R
		menuROM[7][2] = CHAR_E;		// E
		menuROM[7][4] = CHAR_Y;		// Y
		menuROM[7][5] = CHAR_O;		// O
		menuROM[7][6] = CHAR_U;		// U
		menuROM[7][8] = CHAR_S;		// S
		menuROM[7][9] = CHAR_U;		// U
		menuROM[7][10] = CHAR_R;	// R
		menuROM[7][11] = CHAR_E;	// E
		menuROM[7][12] = CHAR_QUESTION;	// ?
		// Yes
		menuROM[8][1] = CHAR_Y;	// Y
		menuROM[8][2] = CHAR_e;	// e
		menuROM[8][3] = CHAR_s;	// s
		// No
		menuROM[9][1] = CHAR_N;	// N
		menuROM[9][2] = CHAR_o;	// o
		// Write To Remote
		menuROM[10][0] = CHAR_W;		// W
		menuROM[10][1] = CHAR_r;		// r
		menuROM[10][2] = CHAR_i;		// i
		menuROM[10][3] = CHAR_t;		// t
		menuROM[10][4] = CHAR_e;		// e
		menuROM[10][6] = CHAR_T;		// T
		menuROM[10][7] = CHAR_o;		// o
		menuROM[10][9] = CHAR_R;		// R
		menuROM[10][10] = CHAR_e;	// e
		menuROM[10][11] = CHAR_m;	// m
		menuROM[10][12] = CHAR_o;	// o
		menuROM[10][13] = CHAR_t;	// t
		menuROM[10][14] = CHAR_e;	// e
		// Read From Remote
		menuROM[11][0] = CHAR_R;		// R
		menuROM[11][1] = CHAR_e;		// e
		menuROM[11][2] = CHAR_a;		// a
		menuROM[11][3] = CHAR_d;		// d
		menuROM[11][5] = CHAR_F;		// F
		menuROM[11][6] = CHAR_r;		// r
		menuROM[11][7] = CHAR_o;		// o
		menuROM[11][8] = CHAR_m;		// m
		menuROM[11][10] = CHAR_R;		// R
		menuROM[11][11] = CHAR_e;		// e
		menuROM[11][12] = CHAR_m;		// m
		menuROM[11][13] = CHAR_o;		// o
		menuROM[11][14] = CHAR_t;		// t
		menuROM[11][15] = CHAR_e;		// e
		// Set Local Addr
		menuROM[12][0] = CHAR_S;		// S
		menuROM[12][1] = CHAR_e;		// e
		menuROM[12][2] = CHAR_t;		// t
		menuROM[12][4] = CHAR_L;		// L
		menuROM[12][5] = CHAR_o;		// o
		menuROM[12][6] = CHAR_c;		// c
		menuROM[12][7] = CHAR_a;		// a
		menuROM[12][8] = CHAR_l;		// l
		menuROM[12][10] = CHAR_A;		// A
		menuROM[12][11] = CHAR_d;		// d
		menuROM[12][12] = CHAR_d;		// d
		menuROM[12][13] = CHAR_r;		// r
	end

	// RAM read
	always@(posedge clk) begin
		case(MultiRAM_SEL)
			RAM_SEL_MENU:		MultiRAM_DOUT <= menuROM[MenuRAM_Select][MultiRAM_ADD];
			RAM_SEL_REMOTE:	MultiRAM_DOUT <= remoteRAM[MultiRAM_ADD];
			RAM_SEL_LOCAL:		MultiRAM_DOUT <= localRAM[MultiRAM_ADD];
		endcase
	end
	// RAM write
	always@(posedge clk) begin
		if (MultiRAM_W) begin
			localRAM[MultiRAM_ADD] <= MultiRAM_DIN;
		end
		else begin
			if (MultiRAM_Clear && MultiRAM_SEL == RAM_SEL_LOCAL) begin
				localRAM[0] <= clearRAMChar; localRAM[16] <= clearRAMChar;
				localRAM[1] <= clearRAMChar; localRAM[17] <= clearRAMChar;
				localRAM[2] <= clearRAMChar; localRAM[18] <= clearRAMChar;
				localRAM[3] <= clearRAMChar; localRAM[19] <= clearRAMChar;
				localRAM[4] <= clearRAMChar; localRAM[20] <= clearRAMChar;
				localRAM[5] <= clearRAMChar; localRAM[21] <= clearRAMChar;
				localRAM[6] <= clearRAMChar; localRAM[22] <= clearRAMChar;
				localRAM[7] <= clearRAMChar; localRAM[23] <= clearRAMChar;
				localRAM[8] <= clearRAMChar; localRAM[24] <= clearRAMChar;
				localRAM[9] <= clearRAMChar; localRAM[25] <= clearRAMChar;
				localRAM[10] <= clearRAMChar; localRAM[26] <= clearRAMChar;
				localRAM[11] <= clearRAMChar; localRAM[27] <= clearRAMChar;
				localRAM[12] <= clearRAMChar; localRAM[28] <= clearRAMChar;
				localRAM[13] <= clearRAMChar; localRAM[29] <= clearRAMChar;
				localRAM[14] <= clearRAMChar; localRAM[30] <= clearRAMChar;
				localRAM[15] <= clearRAMChar; localRAM[31] <= clearRAMChar;
			end
		end
	end
	// Master write
	always@(posedge clk) begin
		if (RemoteRAM_W) begin
			remoteRAM[RemoteRAM_WADD] = RemoteRAM_DIN;
		end
	end
	// Slave read
	always@(posedge clk) begin
		LocalRAM_DOUT <= localRAM[LocalRAM_RADD];
	end

endmodule
