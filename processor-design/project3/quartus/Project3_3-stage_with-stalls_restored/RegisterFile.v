// Register File module
// author: Benjamin Newcomer

module RegisterFile(
		READREG1, READREG2, READVAL1, READVAL2,
		WRITEREG, WRITEVAL, WE, CLK, RESET
	);
	
	// inputs
	input [(REGNOBITS-1):0] READREG1; // first register to read
	input [(REGNOBITS-1):0] READREG2; // second register to read
	input [(REGNOBITS-1):0] WRITEREG; // register to write to
	input [(DBITS-1):0] WRITEVAL; // data to write to reg
	input CLK, WE, RESET; // clock, write enable and write reg signal
	
	// outputs
	output [(DBITS-1):0] READVAL1; // value of first register
	output [(DBITS-1):0] READVAL2; // value of second register
	//output BUSYBIT1, BUSYBIT2; // busy bits for read regs
	
	// parameters (with defaults)
	parameter INITFILE = "Regs.mif"; // mif
	parameter DBITS = 32; // word size/reg size (bits)
	parameter NUMREGS = 32; // number of registers in reg file
	parameter REGNOBITS = 5; // number of bits required to specify a register
	
	// assign read output ports (only if busy bit is not set)
	//assign BUSYBIT1 = busy[READREG1];
	//assign BUSYBIT2 = busy[READREG2];
	
	assign READVAL1 = regs[READREG1];
	assign READVAL2 = regs[READREG2];
	  
	// declare registers
   (*ram_init_file = INITFILE, ramstyle="logic"*)
	reg [(DBITS-1):0] regs[(NUMREGS-1):0];
	
	always @(posedge CLK) begin
		// reset regs/busy bits to 0
		if (RESET) begin
			integer i;
			for (i = 0; i < NUMREGS; i = i+1) begin
				regs[i] <= {DBITS{1'b0}};
			end
		end
		else begin 
			
			// write back to register
			if (WE) regs[WRITEREG] <= WRITEVAL;

		end
	end
	
endmodule
	
