// Data memory and I/O
// Benjamin Newcomer

module Dmem(RESET, CLK, DIN, ADDRIN, DOUT, WE, 
	SW, KEY, HEX0, HEX1, HEX2, HEX3, LEDR, LEDG);

	parameter ADDRHEX = 32'hFFFF0000; // I/O address of HEX (output)
   parameter ADDRLEDR = 32'hFFFF0020; // I/O address of LEDR (output)
   parameter ADDRLEDG = 32'hFFFF0040; // I/O address of LEDG (output)
   parameter ADDRKEY = 32'hFFFF0100; // I/O address of KEY (input)
   parameter ADDRSW = 32'hFFFF0120; // I/O address of SW (input)
	parameter DMEMWORDS = 2048;
	parameter DBITS = 32;
	parameter ADDRBITS = 13;
	parameter WORDBITS = 2;
	parameter INITFILE = "DataMem.mif";
	
	// inputs
	input RESET, CLK, WE;
	input [(DBITS-1):0] DIN;
	input [(DBITS-1):0] ADDRIN;
	input  [9:0] SW;
   input  [3:0] KEY;
	
	// outputs
	output [(DBITS-1):0] DOUT;
	output [9:0] LEDR;
   output [7:0] LEDG;
   output [6:0] HEX0,HEX1,HEX2,HEX3;

	// actual dmem
	(* ram_init_file = INITFILE, ramstyle="no_rw_check" *)
   reg [(DBITS-1):0] dmem[(DMEMWORDS-1):0];

	// Output Hex reg to actual output
	reg [15:0] HexOut;
	SevenSeg ss3(.OUT(HEX3),.IN(HexOut[15:12]));
	SevenSeg ss2(.OUT(HEX2),.IN(HexOut[11:8]));
	SevenSeg ss1(.OUT(HEX1),.IN(HexOut[7:4]));
	SevenSeg ss0(.OUT(HEX0),.IN(HexOut[3:0]));
	
	// output to LEDR, LEDG
	reg [9:0] LEDROut;
	reg [7:0] LEDGOut;
	assign LEDR = LEDROut[9:0];
	assign LEDG = LEDGOut[7:0];
	
	// disable memory if addr is all 0
	wire [(ADDRBITS-1):WORDBITS] memAddr;
	//wire MemEnable = !memAddr;
	assign memAddr = ADDRIN[(ADDRBITS-1):WORDBITS];
	
	// read memory or input device
	wire [9:0] SWIn = SW;
	wire [3:0] KeyIn = ~KEY;
	wire [(DBITS-1):0] DOUT = (ADDRIN == ADDRSW) ? 
		{{(DBITS-10){1'b0}}, SWIn} :
		(ADDRIN == ADDRKEY) ? 
		{{(DBITS-4){1'b0}}, KeyIn} :
		dmem[memAddr]; 
	
	// write to memory or I/O peripherals
	always @(posedge CLK or posedge RESET) begin
		if(RESET) begin
			HexOut <= 16'hbeef;
			LEDROut <= 10'b0;
			LEDGOut <= 8'b0;
		end
		else if (WE) 
			if (ADDRIN == ADDRHEX)
				HexOut <= DIN;
			else if (ADDRIN == ADDRLEDR)
				LEDROut <= DIN;
			else if (ADDRIN == ADDRLEDG)
				LEDGOut <= DIN;
			else 
				dmem[memAddr] <= DIN;
		end
endmodule
