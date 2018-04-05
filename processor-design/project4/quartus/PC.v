// PC module
// Benjamin Newcomer

module PC(CLK, RESET, JMP, STALL, PCIN, PCOUT, NOOP);

	input CLK, RESET, JMP, STALL, NOOP;
	input [(DBITS-1):0] PCIN;
	output [(DBITS-1):0] PCOUT;

	parameter INSTSIZE = 4; // instr size (bytes)
	parameter STARTPC = 32'h60;
	parameter DBITS = 32;
	reg [(DBITS-1):0] PCreg;
	wire [(DBITS-1):0] PCInc = PCreg + INSTSIZE;
	//PC
	// output current pc value
	assign PCOUT = PCreg;
	
	// increment pc, jump to new pc value, or stall
	always @(posedge CLK) begin
    if (RESET)
	   PCreg <= STARTPC;
	 else if (JMP)
	   PCreg <= PCIN;
	 else if (!STALL)
      PCreg <= PCInc;
  end
  
endmodule
