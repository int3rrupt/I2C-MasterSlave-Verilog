`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: CalPoly Pomona
// Engineer:Dr. Toma Sacco 
//////////////////////////////////////////////////////////////////////////////////
module LCDI(clk, DIN, W, WADD, dataout, control);
	input clk;
	input [7:0] DIN;
	input W;
	input [4:0] WADD;
	output [3:0] dataout;
	output [2:0] control;
	 
	 reg [2:0] sel;
	 reg [25:0] delay;  
	 reg [5:0] state;
	 reg [3:0] dataout;
	 reg [2:0] control;	// [LCD_E, LCD_RS , LCD_R/W']
	 reg [7:0] DR;			// Data Register
	 reg [4:0] add;
	 reg [7:0] datain;
	 reg R;

	 initial state=0;
	 reg [7:0]LCDRAM[0:31];


	integer i;
	initial
		begin
		for (i = 0; i < 32; i = i+1)
			begin
				LCDRAM[i]= 8'hFE;
			end

	end


	always@(posedge clk) begin
		if(W) begin
			LCDRAM[WADD]<= DIN;
		end // end if
	end

	always@(R,add)
		if(R)datain=LCDRAM[add];
		else datain=0;
	 
	 always @ (posedge clk)
	 begin
	 case(state)
	 // ------------------------- Power-On Initialization --------------------------
	 0:begin
		delay <= 750_000; state<= 1;control[2:1] <= 0; control[0] <= 0;   end			// Set delay to 15 ms
																												// E RS RW'		D7 D6 D5 D4
																												// 0  0  0
	 1:begin
	   if(delay==0)begin state <= 2; delay<=12; dataout<= 4'h3; control<=3'h4; end	// E RS RW'		D7 D6 D5 D4
		else delay <= delay -1;																			// 1  0  0		0  0  1  1
		end
	 2:begin if(delay==0)begin delay <= 205_000; state<= 3;control <= 0; end			// E RS RW'		D7 D6 D5 D4
	   else delay <= delay -1 ;																		// 0  0  0
		end
	 3:begin 
	   if(delay==0)begin state <= 4; delay<=12; dataout<= 4'h3; control<=3'h4; end	// E RS RW'		D7 D6 D5 D4
		else delay <= delay -1;																			// 1  0  0		0	0	1	1
		end
	 4:begin if(delay==0)begin delay <= 5_000; state<= 5;control <= 0; end				// E RS RW'		D7 D6 D5 D4
	   else delay <= delay -1 ;																		// 0  0  0
		end
	 5:begin 
	   if(delay==0)begin state <= 6; delay<=12; dataout<= 4'h3; control<=3'h4; end	// E RS RW'		D7 D6 D5 D4
		else delay <= delay -1;																			// 1  0  0		0  0  1  1
		end
	 6:begin if(delay==0)begin delay <= 2_000; state<= 7;control <= 0; end				// E RS RW'		D7 D6 D5 D4
	   else delay <= delay -1 ;																		// 0  0  0
		end
	 7:begin 
	   if(delay==0)begin state <= 8; delay<=12; dataout<= 4'h2; control<=3'h4; end	// E RS RW'		D7 D6 D5 D4
		else delay <= delay -1;																			// 1  0  0		0  0  1  0
		end
	 8:begin if(delay==0)begin delay <= 2_000; state<= 9;control <= 0; end  			// E RS RW'		D7 D6 D5 D4	wait for 40 microsecond
	   else delay <= delay -1;																			// 0  0  0
		end
	 9:begin
	   if(delay==0)begin state <= 10;sel <= 4; end												// E RS RW'		D7 D6 D5 D4
		else delay <= delay -1;																			// 
		end
		
	// ------------------------------- Display Configuration -----------------------------
	10:begin  
	   case(sel)	// sel initially = 4, then decrements
			 0: begin state <= 20; delay <= 82_000; end	// 
			 1: begin state <= 11; DR <= 8'h01; end		// Clear Display
			 2: begin state <= 11; DR <= 8'h0C; end		// Display ON, Cursor OFF, Blinking Cursor OFF
			 3: begin state <= 11; DR <= 8'h06; end		// Entry Mode Set - Auto Increment Address Counter
			 4: begin state <= 11; DR <= 8'h28; end		// Function Set
	 default: state <= 0 ;
		endcase end
	11:begin state <= 12; control <= 0; dataout <= DR[7:4]; delay <= 2; sel <= sel -1; end		// E RS RW'		D7 D6 D5 D4
																															// 0  0  0		0  0  1  0
																															
	12:begin if(delay==0)begin delay <= 12; state<= 13; control<=3'h4; end							// E RS RW'
	         else delay <= delay -1 ;end																		// 1  0  0
				
	13:begin if(delay==0)begin delay <= 2; state<= 14; control<=0; end								// E RS RW'
	         else delay <= delay -1 ; end																		// 0  0  0
				
	14:begin if(delay==0)begin delay <= 50 ; state<= 15; end												// Delay
	         else delay <= delay -1 ; end
				
	15:begin if(delay==0)begin state <= 16; control <= 0; dataout <=DR[3:0]; delay <= 2;end	// E RS RW'		D7 D6 D5 D4
	         else delay <= delay -1 ; end																		// 0  0  0		1  0  0  0
				
	16:begin if(delay==0)begin delay <= 12; state<= 17; control<=3'h4; end							// E RS RW'
	         else delay <= delay -1 ; end																		// 1  0  0
				
	17:begin if(delay==0)begin delay <= 2; state<= 18; control<=0; end								// E RS RW'
	         else delay <= delay -1 ; end																		// 0  0  0
				
	18:begin if(delay==0)begin delay <= 2_000 ; state<= 19; end											// Delay
	         else delay <= delay -1 ; end
				
	19:begin if(delay==0)begin state<= 10; end																// State = 10
	         else delay <= delay -1 ; end
				
	20:begin if(delay==0)begin state<= 21; end																// Continue
	   else delay <= delay -1 ; 
		end
	
	// ----------------------------- Displaying -----------------------------
	21:begin state <= 22;add <= 0;R <=1; end
	// setting the line starting address
	22:begin state <= 23; if(add==0)DR <=8'h80;else DR<=8'hC0;  end//line 1=8'h80 , line 2=8'hC0
	23:begin state <= 24; control <= 0; dataout <= DR[7:4]; delay <= 2;end							// E RS RW'		D7 D6 D5 D4
																															// 0  0  0		1  0  0  0
																															
	24:begin if(delay==0)begin delay <= 12; state<= 25; control<=3'h4; end							// E RS RW'
	         else delay <= delay -1 ;end																		// 1  0  0
				
	25:begin if(delay==0)begin delay <= 2; state<= 26; control<=0; end								// E RS RW'
	         else delay <= delay -1 ; end																		// 0  0  0
				
	26:begin if(delay==0)begin delay <= 50 ; state<= 27; end												// Delay
	         else delay <= delay -1 ; end
				
	27:begin if(delay==0)begin state <= 28; control <= 0; dataout <=DR[3:0]; delay <= 2;end	// E RS RW'		D3 D2 D1 D0
	         else delay <= delay -1 ; end																		// 0  0  0		0  0  0  0
				
	28:begin if(delay==0)begin delay <= 12; state<= 29; control<=3'h4; end							// E RS RW'
	         else delay <= delay -1 ; end																		// 1  0  0
				
	29:begin if(delay==0)begin delay <= 2; state<= 30; control<=0; end								// E RS RW'
	         else delay <= delay -1 ; end																		// 0  0  0
				
	30:begin if(delay==0)begin delay <= 2_000 ; state<= 31; end											// Delay
	         else delay <= delay -1 ; end
				
	31:begin if(delay==0)begin state<= 32; end																// Continue
	         else delay <= delay -1 ; end
	
	// ----------------------------- Writing data to the display -----------------------------
	32:begin
			state <= 33;
			DR <= datain;		// datain to DR
			if(add==31)
				add<=0;
			else
				add<= add+1;	// add + 1
		end																								
	33:begin state <= 34; control <= 3'b010; dataout <= DR[7:4]; delay <= 2; end					// E RS RW'		D3 D2 D1 D0
																															// 0  1  0		datain[7:4]
																															
	34:begin if(delay==0)begin delay <= 12; state<= 35; control<=3'b110; end						// E RS RW'
	         else delay <= delay -1 ;end																		// 1  1  0
				
	35:begin if(delay==0)begin delay <= 2; state<= 36; control<=3'b010; end							// E RS RW'
	         else delay <= delay -1 ; end																		// 0  1  0
				
	36:begin if(delay==0)begin delay <= 50 ; state<= 37;control<=0; end								// E RS RW'
	         else delay <= delay -1 ; end																		// 0  0  0
				
	37:begin if(delay==0)begin state <= 38; control <= 3'b010; dataout <=DR[3:0]; delay <= 2;end	// E RS RW'		D3 D2 D1 D0
	         else delay <= delay -1 ; end																			// 0  1  0		datain[3:0]
				
	38:begin if(delay==0)begin delay <= 12; state<= 39; control<=3'b110; end						// E RS RW'
	         else delay <= delay -1 ; end																		// 1  1  0
				
	39:begin if(delay==0)begin delay <= 2; state<= 40; control<=3'b010; end							// E RS RW'		D3 D2 D1 D0
	         else delay <= delay -1 ; end																		// 0  1  0
				
	40:begin if(delay==0)begin delay <= 2_000 ; state<= 41;control<=0; end							// E RS RW'		D3 D2 D1 D0
	         else delay <= delay -1 ; end																		// 0  0  0
				
	41:begin if(delay==0)begin if(add==0 | add==16)state<= 42;else state<= 32;  end				// 
	         else delay <= delay -1 ; end																		// 
	
	// delay between displaying
	42:begin if(add==0)begin state <= 43; delay <= 1_000_000;end else state<=22; end				// E RS RW'		D3 D2 D1 D0
        43:begin if(delay==0)begin state<= 22; end
	         else delay <= delay -1 ; end	
	default: state <= 0;
	endcase
	 end

   

endmodule

