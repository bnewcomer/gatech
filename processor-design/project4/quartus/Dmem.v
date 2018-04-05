// Data memory and I/O
// Benjamin Newcomer

module Dmem(CLK, DATA, ADDRIN, WE);

	parameter DMEMWORDS = 2048;
	parameter DBITS = 32;
	parameter ADDRBITS = 13;
	parameter WORDBITS = 2;
	parameter INITFILE = "DataMem.mif";
	parameter BASE = 32'b0; // base address
	parameter SIZE = DMEMWORDS * 4; // size of address space in bytes
	
	// inputs
	input CLK, WE;
	inout [(DBITS-1):0] DATA;
	input unsigned [(DBITS-1):0] ADDRIN;
	
	// control signals
	wire deviceEnable = (ADDRIN >= BASE) && (ADDRIN <= (BASE + SIZE));
	wire readEnable = deviceEnable && !WE;
	wire writeEnable = deviceEnable && WE;
	
	// memory address;
	wire [(ADDRBITS-1):WORDBITS] memAddr = ADDRIN[(ADDRBITS-1):WORDBITS];

	// dmem memory array
	(* ram_init_file = INITFILE, ramstyle="no_rw_check" *)
   reg [(DBITS-1):0] dmem[(DMEMWORDS-1):0];
	
	// read memory
	assign DATA = 
		(readEnable) ? dmem[memAddr] : {DBITS{1'bZ}}; 
	
	// write to memory
	always @(posedge CLK)
		if (writeEnable) 
			dmem[memAddr] <= DATA;

endmodule
