// Data memory and I/O
// Benjamin Newcomer

module Dmem(RESET, CLK, DIN, ADDRIN, DOUT, WE);

	parameter ADDRHEX;
	parameter LEDR;
	parameter LEDG
	


	// Output Hex reg to actual output
	reg [15:0] HEXOut;
	SevenSeg ss3(.OUT(HEX3),.IN(HexOut[15:12]));
	SevenSeg ss2(.OUT(HEX2),.IN(HexOut[11:8]));
	SevenSeg ss1(.OUT(HEX1),.IN(HexOut[7:4]));
	SevenSeg ss0(.OUT(HEX0),.IN(HexOut[3:0]));
	
	always @(posedge clk or posedge reset)
		if(RESET)
			HEXOut <= 16'hDEAD;
		else if (WE) 
			if (ADDRIN == ADDRHEX)
				HEXOut <= DOUT[15:0];
			else if (ADDRIN == ADDRLEDR)
				LEDROut <= DOUT[9:0]
			
			

endmodule
			
//	// TODO: Write the code for LEDG and LEDR devices
//	
//	// Now the real data memory
//	wire MemEnable=!(memaddr_M[(DBITS-1):DMEMADDRBITS]);
//	wire MemWE=lock&wrmem_M&MemEnable;
//	(* ram_init_file = DMEMINITFILE, ramstyle="no_rw_check" *)
//	reg [(DBITS-1):0] dmem[(DMEMWORDS-1):0];
//	always @(posedge clk)
//		if(MemWE)
//			dmem[memaddr_M[(DMEMADDRBITS-1):DMEMWORDBITS]]<=wmemval_M;
//	wire [(DBITS-1):0] MemVal=MemWE?{DBITS{1'bX}}:dmem[memaddr_M[(DMEMADDRBITS-1):DMEMWORDBITS]];
//	// Connect memory and input devices to the bus
//	wire [(DBITS-1):0] memout_M=
//		MemEnable?MemVal:
//		(memaddr_M==ADDRKEY)?{12'b0,~KEY}:
//		(memaddr_M==ADDRSW)? { 6'b0,SW}:
//		32'hDEADBEEF;
//		
//	// TODO: Write code that produces wmemval_M, wrmem_M, wrreg_M, etc.
//
//	// TODO: Decide what gets written into the destination register (wregval_M)
//
//	always @(posedge clk)
//		if(wrreg_M&&lock)
//			regs[wregno_M]<=wregval_M;