`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer:        Adrian Reyes
// Module Name:     ram-controller
// Project Name:    I2C-MasterSlave-Verilog
// Target Devices:  SPARTAN 3E
// Description:     I2C RAM Controller
//                  This controller contains within it two separate RAMs.
//                  *   Local RAM is used for storing local data.
//                      When in master mode, local RAM is data that can be written
//                      to the slave by the master.
//                      When in slave mode, local RAM is data that can be read by
//                      the master from the slave.
//                  *   Remote RAM is used for storing remote data.
//                      When in master mode, remote RAM is where data that has been
//                      read from the slave by the master is stored.
//                      When in slave mode, remote RAM is where data that has been
//                      written to the slave by the master is stored.
// Dependencies:
//////////////////////////////////////////////////////////////////////////////////
module ram-controller(
    output reg [7:0]LocalRAM_DOUT,     // Local RAM data out
    output reg [7:0]RemoteRAM_DOUT,    // Remote RAM data out
    input [4:0]LocalRAM_RADD,          // Local RAM read address
    input [7:0]LocalRAM_DIN,           // Local RAM data in
    input LocalRAM_W,                  // Local RAM write port
    input [4:0]LocalRAM_WADD,          // Local RAM write address
    input LocalRAM_Clear,              // Local RAM clear port
    input [4:0]RemoteRAM_RADD,         // Remote RAM read address
    input [4:0]RemoteRAM_WADD,         // Remote RAM write address
    input [7:0]RemoteRAM_DIN,          // Remote RAM data in
    input RemoteRAM_W,                 // Remote RAM write port
    input RemoteRAM_Clear,             // Remote RAM clear port
    input clk
    );

    reg [7:0]localRAM[0:31];            // 8x32 Local LCD character RAM
    reg [7:0]remoteRAM[0:31];           // 8x32 Remote LCD character RAM

    reg [7:0]clearRAMChar = CHAR_SPACE;

    integer i, j;
    initial begin
        for (i = 0; i < 32; i = i + 1) begin
            localRAM[i] = clearRAMChar;
        end
    end

    always@(posedge clk) begin
        //  RAM read
        LocalRAM_DOUT <= localRAM[LocalRAM_RADD];
        RemoteRAM_DOUT <= remoteRAM[RemoteRAM_RADD];
        // RAM write
        if (LocalRAM_W)
            localRAM[LocalRAM_WADD] <= LocalRAM_DIN;
        if (RemoteRAM_W)
            remoteRAM[RemoteRAM_WADD] <= RemoteRAM_DIN;
        // RAM clear
        if (LocalRAM_Clear) begin
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
        if (RemoteRAM_Clear) begin
            remoteRAM[0] <= clearRAMChar; remoteRAM[16] <= clearRAMChar;
            remoteRAM[1] <= clearRAMChar; remoteRAM[17] <= clearRAMChar;
            remoteRAM[2] <= clearRAMChar; remoteRAM[18] <= clearRAMChar;
            remoteRAM[3] <= clearRAMChar; remoteRAM[19] <= clearRAMChar;
            remoteRAM[4] <= clearRAMChar; remoteRAM[20] <= clearRAMChar;
            remoteRAM[5] <= clearRAMChar; remoteRAM[21] <= clearRAMChar;
            remoteRAM[6] <= clearRAMChar; remoteRAM[22] <= clearRAMChar;
            remoteRAM[7] <= clearRAMChar; remoteRAM[23] <= clearRAMChar;
            remoteRAM[8] <= clearRAMChar; remoteRAM[24] <= clearRAMChar;
            remoteRAM[9] <= clearRAMChar; remoteRAM[25] <= clearRAMChar;
            remoteRAM[10] <= clearRAMChar; remoteRAM[26] <= clearRAMChar;
            remoteRAM[11] <= clearRAMChar; remoteRAM[27] <= clearRAMChar;
            remoteRAM[12] <= clearRAMChar; remoteRAM[28] <= clearRAMChar;
            remoteRAM[13] <= clearRAMChar; remoteRAM[29] <= clearRAMChar;
            remoteRAM[14] <= clearRAMChar; remoteRAM[30] <= clearRAMChar;
            remoteRAM[15] <= clearRAMChar; remoteRAM[31] <= clearRAMChar;
        end
    end

endmodule
