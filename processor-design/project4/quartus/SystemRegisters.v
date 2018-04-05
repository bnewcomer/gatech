 module SystemRegisters(CLK, RESET, PCSIn, IHAIn, IRAIn, IDNIn, PCS, IHA, IRA, IDN);
   
	parameter BITS = 32;
 
	// processor control registers
  // systemRegs[0]: PCS
  //    PCS[0]: IE
  //    PCS[1]: OIE
  //    PCS[4]: CM
  //    PCS[5]: OM
  // systemRegs[1]: IHA
  // systemRegs[2]: IRA
  // systemRegs[3]: IDN
  reg [(BITS-1):0] systemRegs[3:0];
  wire [(BITS-1):0] PCSOut = systemRegs[0];
  wire [(BITS-1):0] IHAOut = systemRegs[1];
  wire [(BITS-1):0] IRAOut = systemRegs[2];
  wire [(BITS-1):0] IDNOut = systemRegs[3];
  
  // decode signals
  wire isSystemMode = PCSOut[4];
  wire interruptEnable = PCSOut[0];
  
  // read
  
  // write
  always @(posedge clk)
    if (reset) begin
	 
	 end
//	 else if (takeInterrupt)
//	   // IHA <= PC
//		systemRegs[2] <= memory_PC;
	 else if (memory_isWSR && isSystemMode)
		systemRegs[memory_writeSysReg] <= memory_RyVal;
 
 
 
 endmodule
 