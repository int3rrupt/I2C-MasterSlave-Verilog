`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: CalPoly Pomona
// Engineer:Dr. Toma Sacco
//////////////////////////////////////////////////////////////////////////////////
module LCDI_Menu(
	output reg [3:0]dataout,
	output reg [2:0]control,	// [LCD_E, LCD_RS , LCD_R/W']
	input [4:0]WADD,
	input [7:0]DIN,
	input W,
	input enableCursor,
	input cursorLeft,
	input cursorRight,
	input clk);

	////////////////////////////// STATE PARAMETERS ////////////////////////////
	////////////////////////////////////////////////////////////////////////////
	parameter STATE_SET_DISPLAY_LINE = 22, STATE_CURSOR_ENABLE_DISABLE = 44,
		STATE_CURSOR_MOVE = 55, STATE_CURSOR_RETURN_HOME = 66;
	////////////////////////////// DELAY PARAMETERS ////////////////////////////
	////////////////////////////////////////////////////////////////////////////
	parameter DELAY_40us = 2_000, DELAY_1p64ms = 82_000, DELAY_4p1ms = 205_000, DELAY_15ms = 750_000;

	reg [2:0] sel;
	reg [25:0] delay;
	reg [5:0] state;
	reg [7:0] DR;			// Data Register
	reg [4:0] add;
	reg [7:0] datain;
	reg R;
	// Cursor
	reg [7:0]cursorControl;
	reg cursorEventEnable;
	reg cursorEventDisable;
	reg enableCursorPrev;
	reg [7:0]cursorMoveControl;
	reg cursorLeftEvent;
	reg cursorLeftPrev;
	reg cursorRightEvent;
	reg cursorRightPrev;

	initial state=0;
	reg [7:0]LCDRAM[0:31];


	integer i;
	initial begin
		for (i = 0; i < 32; i = i+1) begin
			LCDRAM[i]= 8'hFE;
		end
	end

	always@(posedge clk) begin
		if(W) begin
			LCDRAM[WADD]<= DIN;
		end // end if
	end

	always@(R, add) begin
		if (R) datain = LCDRAM[add];
		else datain = 0;
	end

	// Cursor Enable/Move Event Watch
	always@(posedge clk) begin
		enableCursorPrev <= enableCursor;
		// If enable cursor pos edge
		if (enableCursor == 1 && enableCursorPrev == 0)
			cursorEventEnable <= 1;
		else begin
			cursorEventEnable <= 0;
			// If enable cursor neg edge
			if (enableCursor == 0 && enableCursorPrev == 1)
				cursorEventDisable <= 1;
			else
				cursorEventDisable <= 0;
		end

		cursorLeftPrev <= cursorLeft;
		// If cursor left pos edge
		if (cursorLeft == 1 && cursorLeftPrev == 0)
			cursorLeftEvent <= 1;
		else
			cursorLeftEvent <= 0;

		cursorRightPrev <= cursorRight;
		// If cursor left pos edge
		if (cursorRight == 1 && cursorRightPrev == 0)
			cursorRightEvent <= 1;
		else
			cursorRightEvent <= 0;
	end


	always@(posedge clk) begin
		if (cursorEventEnable || cursorEventDisable ||
				cursorLeftEvent || cursorRightEvent) begin
			if (cursorEventEnable) begin
				cursorControl <= 8'h0F;		// Display ON, Cursor ON, Blinking Cursor ON
				state <= STATE_CURSOR_ENABLE_DISABLE;
			end
			else begin
				if (cursorEventDisable) begin
					cursorControl <= 8'h0C;	// Display ON, Cursor OFF, Blinking Cursor OFF
					state <= STATE_CURSOR_ENABLE_DISABLE;
				end
				else begin
					if (cursorLeftEvent) begin
						cursorMoveControl <= 8'h10;
						state <= STATE_CURSOR_MOVE;
					end
					else begin
						cursorMoveControl <= 8'h14;
						state <= STATE_CURSOR_MOVE;
					end
				end
			end
		end
		else begin
			case(state)
				// -------------------- Power-On Initialization --------------------
				0:		begin state <= 1; delay <= DELAY_15ms; control[2:1] <= 0; control[0] <= 0; end
								// E RS RW'
								// 0  0  0
				1:		begin	if (delay == 0) begin state <= 2; delay <= 12; control <= 3'h4; dataout <= 4'h3; end
								// E RS RW'		D7 D6 D5 D4
								// 1  0  0		0  0  1  1
								else delay <= delay - 1; end
				2:		begin	if (delay == 0) begin state <= 3; delay <= DELAY_4p1ms; control <= 0; end
								// E RS RW'
								// 0  0  0
								else delay <= delay - 1; end
				3:		begin	if (delay == 0) begin state <= 4; delay <= 12; control <= 3'h4; dataout <= 4'h3; end
								// E RS RW'		D7 D6 D5 D4
								// 1  0  0		0  0  1  1
								else delay <= delay - 1; end
				4:		begin	if (delay == 0) begin state <= 5; delay <= 5_000; control <= 0; end
								// E RS RW'
								// 0  0  0
								else delay <= delay - 1; end
				5:		begin	if (delay == 0) begin state <= 6; delay <= 12; control <= 3'h4; dataout <= 4'h3; end
								// E RS RW'		D7 D6 D5 D4
								// 1  0  0		0  0  1  1
								else delay <= delay - 1; end
				6:		begin	if (delay == 0) begin state <= 7; delay <= DELAY_40us; control <= 0; end
								// E RS RW'
								// 0  0  0
								else delay <= delay - 1; end
				7:		begin	if (delay == 0) begin state <= 8; delay <= 12; control <= 3'h4; dataout <= 4'h2; end
								// E RS RW'		D7 D6 D5 D4
								// 1  0  0		0  0  1  0
								else delay <= delay - 1; end
				8:		begin	if (delay == 0) begin state <= 9; delay <= DELAY_40us; control <= 0; end
								// E RS RW'
								// 0  0  0
								else delay <= delay - 1; end
				9:		begin	if (delay == 0) begin state <= 10; sel <= 4; end
								else delay <= delay - 1; end
				// ------------------------------- Display Configuration -----------------------------
				10:	begin case(sel)	// sel initially = 4, then decrements
								0: begin state <= 20; delay <= DELAY_1p64ms; end
								1: begin state <= 11; DR <= 8'h01; end	// Clear Display
								2: begin state <= 11; DR <= 8'h0F; end	// Display ON, Cursor OFF, Blinking Cursor OFF
								3: begin state <= 11; DR <= 8'h06; end	// Entry Mode Set - Auto Increment Address Counter
								4: begin state <= 11; DR <= 8'h28; end	// Function Set
								default: state <= 0;
						endcase end
				11:	begin state <= 12; delay <= 2; control <= 0; dataout <= DR[7:4]; sel <= sel - 1; end
								// E RS RW'		D7 D6 D5 D4
								// 0  0  0
				12:	begin if(delay==0)begin delay <= 12; state<= 13; control<=3'h4; end							// E RS RW'
								else delay <= delay -1 ;end																		// 1  0  0

				13:	begin if(delay==0)begin delay <= 2; state<= 14; control<=0; end								// E RS RW'
								else delay <= delay -1 ; end																		// 0  0  0

				14:	begin if(delay==0)begin delay <= 50 ; state<= 15; end												// Delay
								else delay <= delay -1 ; end

				15:	begin if(delay==0)begin state <= 16; control <= 0; dataout <= DR[3:0]; delay <= 2;end	// E RS RW'		D7 D6 D5 D4
								else delay <= delay -1 ; end																		// 0  0  0		1  0  0  0

				16:	begin if(delay==0)begin delay <= 12; state<= 17; control<=3'h4; end							// E RS RW'
								else delay <= delay -1 ; end																		// 1  0  0

				17:	begin if(delay==0)begin delay <= 2; state<= 18; control<=0; end								// E RS RW'
								else delay <= delay -1 ; end																		// 0  0  0

				18:	begin if(delay==0)begin delay <= DELAY_40us ; state<= 19; end											// Delay
								else delay <= delay -1 ; end

				19:	begin if(delay==0)begin state<= 10; end																// State = 10
								else delay <= delay -1 ; end

				20:	begin if(delay==0)begin state<= 21; end																// Continue
							else delay <= delay - 1; end
				// -------------------------- Displaying ---------------------------
				21:	begin state <= STATE_SET_DISPLAY_LINE; add <= 0; R <= 1; end
				// setting the line starting address
				STATE_SET_DISPLAY_LINE:
						begin state <= 23; if (add == 0) DR <= 8'h80;	// Line 1
								else DR <= 8'hC0; end							// Line 2
				23:	begin state <= 24; delay <= 2; control <= 0; dataout <= DR[7:4]; end
				24:	begin if (delay == 0) begin state <= 25; delay <= 12; control <=3'h4; end
								else delay <= delay - 1; end
				25:	begin if (delay == 0) begin state <= 26; delay <= 2; control <= 0; end
								else delay <= delay - 1; end
				26:	begin if (delay == 0) begin state <= 27; delay <= 50; end
								else delay <= delay - 1; end
				27:	begin if (delay == 0) begin state <= 28; delay <= 2; control <= 0; dataout <= DR[3:0]; end
								else delay <= delay - 1; end
				28:	begin if (delay == 0) begin state <= 29; delay <= 12; control <= 3'h4; end
								else delay <= delay - 1; end
				29:	begin if (delay == 0) begin state <= 30; delay <= 2; control <= 0; end
								else delay <= delay - 1; end
				30:	begin if (delay == 0) begin state <= 31; delay <= DELAY_40us; end
								else delay <= delay - 1; end
				31:	begin if (delay == 0) begin state <= 32; end
								else delay <= delay - 1; end
				// ------------------ Writing data to the display ------------------
				32:	begin state <= 33; DR <= datain;
								if (add == 31) add<=0;
								else add <= add + 1; end
				33:	begin state <= 34; delay <= 2; control <= 3'b010; dataout <= DR[7:4]; end
				34:	begin if(delay==0)begin delay <= 12; state<= 35; control<=3'b110; end						// E RS RW'
								else delay <= delay -1 ;end																		// 1  1  0

				35:	begin if(delay==0)begin delay <= 2; state<= 36; control<=3'b010; end							// E RS RW'
								else delay <= delay -1 ; end																		// 0  1  0

				36:	begin if(delay==0)begin delay <= 50 ; state<= 37;control<=0; end								// E RS RW'
								else delay <= delay -1 ; end																		// 0  0  0

				37:	begin if(delay==0)begin state <= 38; control <= 3'b010; dataout <=DR[3:0]; delay <= 2;end	// E RS RW'		D3 D2 D1 D0
								else delay <= delay -1 ; end																			// 0  1  0		datain[3:0]

				38:	begin if(delay==0)begin delay <= 12; state<= 39; control<=3'b110; end						// E RS RW'
								else delay <= delay -1 ; end																		// 1  1  0

				39:	begin if(delay==0)begin delay <= 2; state<= 40; control<=3'b010; end							// E RS RW'		D3 D2 D1 D0
								else delay <= delay -1 ; end																		// 0  1  0

				40:	begin if(delay==0)begin delay <= DELAY_40us ; state<= 41;control<=0; end							// E RS RW'		D3 D2 D1 D0
								else delay <= delay -1 ; end																		// 0  0  0
				41:	begin if (delay == 0) begin
									if (add == 0 | add == 16) state <= 42;
									else state <= 32; end
								else delay <= delay - 1; end
				// delay between displaying
				42:	begin if (add == 0) begin state <= 43; delay <= 1_000_000; end
								else state <= STATE_SET_DISPLAY_LINE; end
				43:	begin if (delay == 0) state <= STATE_SET_DISPLAY_LINE;
								else delay <= delay - 1; end
				// ------------------------ Enable Cursor --------------------------
				// E RS RW'		D7 D6 D5 D4			D3 D2 D1 D0
				// x  0  0		0  0  0  0			1  cursor control
				STATE_CURSOR_ENABLE_DISABLE:
						// Assign cursor control value (enable/disable) to DR data write queue register
						begin state <= 45; DR <= cursorControl; end
						// Clear control bits, assign first half of data write reg to dataout bus
				45:	begin state <= 46; delay <= 2; control <= 0; dataout <= DR[7:4]; end
						// Set Enable
				46:	begin if (delay == 0) begin state <= 47; delay <= 12; control <= 3'h4; end
								else delay <= delay - 1; end
						// Clear Enable
				47:	begin if (delay == 0) begin state <= 48; delay <= 2; control <= 0; end
								else delay <= delay - 1; end
						// Delay
				48:	begin if (delay == 0) begin state <= 49; delay <= 50; end
								else delay <= delay - 1; end
						// Clear Enable, assign second half of data write reg to dataout bus
				49:	begin if (delay == 0) begin state <= 50; delay <= 2; control <= 0; dataout <= DR[3:0]; end
								else delay <= delay - 1; end
						// Set Enable
				50:	begin if (delay == 0) begin state <= 51; delay <= 12; control <= 3'h4; end
								else delay <= delay - 1; end
						// Clear Enable
				51:	begin if (delay == 0) begin state<= 52; delay <= 2; control <= 0; end
								else delay <= delay - 1; end
						// Delay
				52:	begin if (delay == 0) begin state <= 53; delay <= DELAY_40us; end
								else delay <= delay - 1; end
						// Delay of 40us
				53:	begin if (delay == 0) begin state <= 54; delay <= DELAY_1p64ms; end
								else delay <= delay - 1; end
						// Delay of 1.64ms then continue writing to LCD
				54:	begin if (delay == 0) state <= STATE_CURSOR_RETURN_HOME;
								else delay <= delay - 1; end
				// -------------------------- Move Cursor --------------------------
				// E RS RW'		D7 D6 D5 D4			D3 D2 D1 D0
				// x  0  0		0  0  0  1			cursor control
				STATE_CURSOR_MOVE:
						begin state <= 56; DR <= cursorMoveControl; end
				56:	begin state <= 57; delay <= 2; control <= 0; dataout <= DR[7:4]; end
				57:	begin if (delay == 0) begin state <= 58; delay <= 12; control <= 3'h4; end
								else delay <= delay - 1;end
				58:	begin if (delay == 0) begin state <= 59; delay <= 2; control <= 0; end
								else delay <= delay - 1; end
				59:	begin if (delay == 0) begin state <= 60; delay <= 50; end
								else delay <= delay - 1; end
				60:	begin if (delay == 0) begin state <= 61; delay <= 2; control <= 0; dataout <= DR[3:0]; end
								else delay <= delay - 1; end
				61:	begin if (delay == 0) begin state <= 62; delay <= 12; control <= 3'h4; end
								else delay <= delay - 1; end
				62:	begin if (delay == 0) begin state <= 63; delay <= 2; control <= 0; end
								else delay <= delay - 1; end
						// Delay
				63:	begin if (delay == 0) begin state <= 64; delay <= DELAY_40us; end
								else delay <= delay - 1; end
						// Delay of 40us
				64:	begin if (delay == 0) begin state <= 65; delay <= DELAY_1p64ms; end
								else delay <= delay - 1; end
						// Delay of 1.64ms then continue to return cursor to home position
				65:	begin if (delay == 0) begin state <= 21; end
								else delay <= delay - 1; end
				// ---------------------- Return Cursor Home -----------------------
				// E RS RW'		D7 D6 D5 D4			D3 D2 D1 D0
				// x  0  0		0  0  0  0			0  0  1  0
				STATE_CURSOR_RETURN_HOME:
						// Assign cursor return home value to DR data write queue register
						begin state <= 67; DR <= 8'h02; end
						// Clear control bits, assign first half of data write reg to dataout bus
				67:	begin state <= 68; delay <= 2; control <= 0; dataout <= DR[7:4]; end
						// Set Enable
				68:	begin if (delay == 0) begin state <= 69; delay <= 12; control <= 3'h4; end
								else delay <= delay - 1; end
						// Clear Enable
				69:	begin if (delay == 0) begin state <= 70; delay <= 2; control <= 0; end
								else delay <= delay - 1; end
						// Delay
				70:	begin if (delay == 0) begin state <= 71; delay <= 50; end
								else delay <= delay - 1; end
						// Clear Enable, assign second half of data write reg to dataout bus
				71:	begin if (delay == 0) begin state <= 72; delay <= 2; control <= 0; dataout <= DR[3:0]; end
								else delay <= delay - 1; end
						// Set Enable
				72:	begin if (delay == 0) begin state <= 73; delay <= 12; control <= 3'h4; end
								else delay <= delay - 1; end
						// Clear Enable
				73:	begin if (delay == 0) begin state <= 74; delay <= 2; control <= 0; end
								else delay <= delay - 1; end
						// Delay
				74:	begin if (delay == 0) begin state <= 75; delay <= DELAY_40us; end
								else delay <= delay - 1; end
						// Delay of 40us
				75:	begin if (delay == 0) begin state <= 76; delay <= DELAY_1p64ms; end
								else delay <= delay - 1; end
						// Delay of 1.64ms then continue writing to LCD
				76:	begin if (delay == 0) state <= 21;
								else delay <= delay - 1; end
				default: state <= 0;
			endcase
		end // End else
	end



endmodule
