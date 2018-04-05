// PC module
// Benjamin Newcomer

module PC(CLK, RESET, JMP, STALL, PCIN, PCOUT, PCINCOUT);

	input CLK, RESET, JMP, STALL;
	input [(DBITS-1):0] PCIN;
	output [(DBITS-1):0] PCOUT, PCINCOUT;

	parameter INSTSIZE = 4; // instr size (bytes)
	parameter STARTPC = 32'h60;
	parameter DBITS = 32;

	// PC
	reg [(DBITS-1):0] PCreg;
	
	// incremented pc
	assign PCINCOUT = PCreg + INSTSIZE;
	
	// output current pc value
	assign PCOUT = PCreg;
	
	// increment pc, jump to new pc value, or stall
	always @(posedge CLK) begin
    if (RESET)
	   PCreg <= STARTPC;
	 else if (JMP)
	   PCreg <= PCIN + INSTSIZE;
	 else if (!STALL)
      PCreg <= PCINCOUT;
  end
  
endmodule
