// Imem module
// Benjamin Newcomer

module Imem(ADDRIN, INSTR);

	parameter INITFILE = "Test2.mif";
	parameter DBITS = 32;
	parameter ADDRBITS = 13; // width of mem address
	parameter WORDBITS = 2;
	parameter OPCODEBITS = 5;
	parameter REGNOBITS = 5;
	parameter MEMWORDS = 2048;
	parameter IMMBITS = 17;

	input [(ADDRBITS-1):0] ADDRIN;
	
	// see p 13 of ProjectISA slides for info
//	output [(OPCODEBITS-1):0] OP1 = inst[31:27];
//	output [(REGNOBITS-1):0] RX = inst[26:22];
//	output [(REGNOBITS-1):0] RY = inst[21:17];
//	output [(REGNOBITS-1):0] RZ = inst[16:12];
//	output [(OPCODEBITS-1):0] OP2 = inst[(OPCODEBITS-1):0];
//	output [(DBITS-1):0] IMM;
	
//	// sign extend immediatemac 
//	wire [(IMMBITS-1):0] rawImm = inst[(IMMBITS-1):0];
//	SignExtend #(.IBITS(IMMBITS),.OBITS(DBITS)) sxt(.IN(rawImm),.OUT(IMM));
	
	(* ram_init_file = INITFILE *)
	reg [(DBITS-1):0] mem[(MEMWORDS-1):0];
	
	// fetch instruction and decode
	wire [(ADDRBITS-1):0] memAddr = ADDRIN[(ADDRBITS-1):WORDBITS];
	output [(DBITS-1):0] INSTR = mem[memAddr];
	
endmodule
