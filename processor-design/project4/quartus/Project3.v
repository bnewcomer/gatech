module Project3(SW,KEY,LEDR,LEDG,HEX0,HEX1,HEX2,HEX3,CLOCK_50);
  ///////////////////////////// Inputs and Outputs ////////////////////////////
  input  [9:0] SW;
  input  [3:0] KEY;
  input  CLOCK_50;
  output [9:0] LEDR;
  output [7:0] LEDG;
  output [6:0] HEX0,HEX1,HEX2,HEX3;

  ///////////////////////////// Parameters ////////////////////////////////////
  
  // General Parameters
  parameter DBITS = 32; // width of the bus/size of one word
  
  // Instruction Parameters
  parameter INSTSIZE = 32'd4; // instruction size (bytes)
  parameter INSTBITS = 32; // instructions size (bits)
  parameter OPCODEBITS = 5; // bits required to specify opcode
  parameter IMMBITS  = 17; // size of immediate (bits)
  
  // Register File Parameters
  parameter REGNOBITS = 5; // bits required to specify a register
  parameter NUMREGS = 32; // number of registers in reg file
  parameter REGINITFILE = "Regs.mif"; // register file initialization file
  
  // PC Parameters
  parameter STARTPC  = 32'h60; // starting value of PC
  
  // Memory/IO Parameters
  parameter ADDRHEX  = 32'hFFFF0000; // I/O address of HEX (output)
  parameter ADDRLEDR = 32'hFFFF0020; // I/O address of LEDR (output)
  parameter ADDRLEDG = 32'hFFFF0040; // I/O address of LEDG (output)
  parameter ADDRKEY  = 32'hFFFF0100; // I/O address of KEY (input)
  parameter ADDRSW   = 32'hFFFF0120; // I/O address of SW (input)
  parameter ADDRTIMER = 32'hFFFF0200;
  parameter ADDRTLIM = 32'hFFFF0204;
  parameter MEMINITFILE = "Combined.mif";
  parameter IMEMADDRBITS = 13; // instr memory address width (bits)
  parameter IMEMWORDBITS = 2; // value to right shift byte address to get index address
  parameter IMEMWORDS = 2048; // size of instr memory (words)
  parameter DMEMADDRBITS = 13; // data memory address width (bits)
  parameter DMEMWORDBITS = 2; // value to right shift byte address to get index address
  parameter DMEMWORDS = 2048; // size of data memory (words)
  parameter DMEMBASEADDR = 32'b0; // base address of dmem
  parameter TIMERMS = 85*1000000/1000; // number of cycles in 1 millisecond (x*1000000/1000)
													// where x is the frequency in MHz
													
  parameter DEFAULTIE = 1'b1; // default for interrupt enable
  parameter DEFAULTMODE = 1'b0; // whether or not to allow SW/LW for IO devices
  parameter DEFAULTIHA = 32'h10;
  
  // Opcodes (primary)
  parameter OP1_SYS  = 5'b00111;
  parameter OP1_ALUR = 5'b00000;
  parameter OP1_LW   = 5'b01010;
  parameter OP1_SW   = 5'b01110;
  parameter OP1_BEQ  = 5'b10000;
  parameter OP1_BLT  = 5'b10001;
  parameter OP1_BLE  = 5'b10010;
  parameter OP1_BNE  = 5'b10011;
  parameter OP1_JAL  = 5'b10111;
  parameter OP1_ADDI = 5'b11000;
  parameter OP1_ANDI = 5'b11100;
  parameter OP1_ORI  = 5'b11101;
  parameter OP1_XORI = 5'b11110;
  
  // Opcodes (secondary)
  parameter OP2_SUB  = 5'b01000;
  parameter OP2_NAND = 5'b01100;
  parameter OP2_NOR  = 5'b01101;
  parameter OP2_NXOR = 5'b01110;
  parameter OP2_EQ   = OP1_BEQ;
  parameter OP2_LT   = OP1_BLT;
  parameter OP2_LE   = OP1_BLE;
  parameter OP2_NE   = OP1_BNE;
  parameter OP2_ADD  = OP1_ADDI;
  parameter OP2_AND  = OP1_ANDI;
  parameter OP2_OR   = OP1_ORI;
  parameter OP2_XOR  = OP1_XORI;
  
  // Opcodes (system)
  parameter OPS_RETI = 5'b10000;
  parameter OPS_RSR  = 5'b10001;
  parameter OPS_WSR  = 5'b10010;
  parameter OPS_SYS  = 5'b00000;
  
  // user register encodings
  parameter A0 = 5'd1;
  parameter A1 = 5'd2;
  parameter RV = 5'd5;
  
  // sys action encodings
  parameter SYSWRHEX  = 1;
  parameter SYSRDHEX  = 2;
  parameter SYSWRLEDG = 3;
  parameter SYSRDLEDG = 4;
  parameter SYSWRLEDR = 5;
  parameter SYSRDLEDR = 6;
  parameter SYSRDKEY = 7;
  parameter SYSRDSW = 8;
  parameter SYSRDCNT = 9;
  parameter SYSWRTLIM = 10;
  parameter SYSRDTLIM = 11;
  parameter SYSWRCNT = 12;
  
  // io device numbers
  parameter TIMER_DN = 4'h1;
  parameter KEY_DN = 4'h2;
  parameter SWITCH_DN = 4'h3;
  
  ///////////////////////////// Timing, Reset //////////////////////////////////////////////////
  
  wire clk, lock;
  Pll pll(.inclk0(CLOCK_50),.c0 (clk),.locked(lock));
  wire reset = !lock;
  
  ////////////////////////////// Fetch /////////////////////////////////////////////
  
  // PC wires
  wire [(DBITS-1):0] PCIn, curPC, instr;
  wire jmp, stall;
  
  /////////////////////// decode ////////////////////////////////////////
	// decode instruction
	wire [(OPCODEBITS-1):0] decode_Op1 = instr[31:27];
	wire [(OPCODEBITS-1):0] decode_Op2 = instr[(OPCODEBITS-1):0];
   wire [(REGNOBITS-1):0] decode_Rx = instr[26:22];
	wire [(REGNOBITS-1):0] decode_Ry = instr[21:17];
	wire [(REGNOBITS-1):0] decode_Rz = instr[16:12];
   wire [(DBITS-1):0] decode_Imm;
	wire [(IMMBITS-1):0] rawImm = instr[(IMMBITS-1):0];
	SignExtend #(.IBITS(IMMBITS),.OBITS(DBITS)) sxt(.IN(rawImm),.OUT(decode_Imm));
	
	// decode system instructions
	wire isSYSInstr = (decode_Op1 == OP1_SYS);
	wire isSYS = isSYSInstr && (decode_Op2 == OPS_SYS);
	wire isRSR = isSYSInstr && (decode_Op2 == OPS_RSR);
	wire isWSR = isSYSInstr && (decode_Op2 == OPS_WSR);
	wire isRETI = isSYSInstr && (decode_Op2 == OPS_RETI);
	
	// decode user instructions
   wire isBranch = ((decode_Op1[(OPCODEBITS-1):(OPCODEBITS-2)] == 2'b10)
	 	&& (decode_Op1 != OP1_JAL));
   wire isALUI = decode_Op1[(OPCODEBITS-1):(OPCODEBITS-2)] == 2'b11;
   wire isLW = (decode_Op1 == OP1_LW);
   wire isJAL = (decode_Op1 == OP1_JAL);
   wire isALUR = ((decode_Op1 == OP1_ALUR) && decode_Op2);
   wire isWritebackInstr = (isALUR || isJAL || isLW || isALUI);
   wire isMemInstr = decode_Op1[(OPCODEBITS-1):(OPCODEBITS-2)] == 2'b01;
	
	/////////// reg file ///////////////
	// rx is a source register for all 
	// instructions. ry is source only for 
	// ALUR instructions. Destination is 
	// rz for ALUR and ry for all others. 
	// see p 13 of ProjectISA slides for info.
   wire [(REGNOBITS-1):0] readReg1 =
		(!isSYSInstr) ? decode_Rx : 
		(isSYS) ? A0 : 
		{REGNOBITS{1'bX}};
   wire [(REGNOBITS-1):0] readReg2 = 
		(isSYS) ? A1 : 
		(isALUR || isWSR) ? decode_Ry :
		{REGNOBITS{1'bX}};
   wire [(REGNOBITS-1):0] writeReg = 
		(isRSR) ? decode_Rx : 
		(isALUR) ? decode_Rz :
	   (isSYS) ? RV :	
		decode_Ry;
   wire [(REGNOBITS-1):0] readSysReg = 
		(isRSR) ? decode_Ry : 
		{REGNOBITS{1'bX}};
	wire [(REGNOBITS-1):0] writeSysReg = 
		(isWSR) ? decode_Rx : 
		{REGNOBITS{1'bX}};
   wire [(DBITS-1):0] readVal1, readVal2, writeVal;
   wire [(REGNOBITS-1):0] writeRegIn;
   wire regFileWE;
  
  
  PC #(
	.INSTSIZE(INSTSIZE),
	.STARTPC(STARTPC),
	.DBITS(DBITS)
  ) pc(
	.CLK(clk), 
	.RESET(reset), 
	.JMP(jmp), 
	.STALL(stall), 
	.PCIN(PCIn), 
	.PCOUT(curPC),
	.NOOP(execute_isNOOP)
  );
  
  Imem #(
	.INITFILE(MEMINITFILE),
	.DBITS(DBITS),
	.ADDRBITS(IMEMADDRBITS),
	.WORDBITS(IMEMWORDBITS),
	.OPCODEBITS(OPCODEBITS),
	.REGNOBITS(REGNOBITS),
	.MEMWORDS(IMEMWORDS),
	.IMMBITS(IMMBITS)
  ) imem(
	.ADDRIN(curPC), 
	.INSTR(instr)
  );
  
  ////////////////////////////// Decode Buffer /////////////////////////////////////
  
  reg [(DBITS-1):0] readReg_PC;
  
  reg [(OPCODEBITS-1):0] readReg_Op1, readReg_Op2;
  
  reg signed [(DBITS-1):0] readReg_Imm;
  
  reg [(REGNOBITS-1):0] readReg_writeReg, 
							   readReg_readSysReg, 
								readReg_writeSysReg,
								readReg_readReg1,
								readReg_readReg2;
  reg readReg_isALUR,
		readReg_isJAL,
		readReg_isLW,
		readReg_isWritebackInstr,
		readReg_isBranch,
		readReg_isMemInstr,
		readReg_isSYS,
		readReg_isRSR,
		readReg_isWSR,
		readReg_isRETI,
		readReg_isNOOP;
  
  always @(posedge clk) begin
		if (jmp) begin
			//decode_Instr <= {DBITS{1'b0}};
			readReg_PC <= {DBITS{1'b0}};
			readReg_Op1 <= {OPCODEBITS{1'b0}};
			readReg_Op2 <= {OPCODEBITS{1'b0}};
			readReg_Imm <= {IMMBITS{1'b0}};
			
			// Register Values & writeback address
			// (RyVal == X if instruction is not ALUR)
			readReg_readReg1 <= {REGNOBITS{1'b0}};
			readReg_readReg2 <= {REGNOBITS{1'b0}};
			readReg_writeReg <= {REGNOBITS{1'b0}};
			readReg_readSysReg <= {REGNOBITS{1'b0}};
			readReg_writeSysReg <= {REGNOBITS{1'b0}};
			
			// decode signals
			readReg_isALUR <= 1'b0;
			readReg_isJAL <= 1'b0;
			readReg_isLW <= 1'b0;
			readReg_isWritebackInstr <= 1'b0;
			readReg_isBranch <= 1'b0;
			readReg_isMemInstr <= 1'b0;
		   readReg_isSYS <= 1'b0;
			readReg_isRSR <= 1'b0;
			readReg_isWSR <= 1'b0;
			readReg_isRETI <= 1'b0;
			readReg_isNOOP <= 1'b1;
		end
		else if (!stall) begin
			//decode_Instr <= instr;
			readReg_PC <= curPC;
			readReg_Op1 <= decode_Op1;
			readReg_Op2 <= decode_Op2;
			readReg_Imm <= decode_Imm;
			
			// Register Values & writeback address
			// (RyVal == X if instruction is not ALUR)
			readReg_readReg1 <= readReg1;
			readReg_readReg2 <= readReg2;
			readReg_writeReg <= writeReg;
			readReg_readSysReg <= readSysReg;
			readReg_writeSysReg <= writeSysReg;
			
			// decode signals
			readReg_isALUR <= isALUR;
			readReg_isJAL <= isJAL;
			readReg_isLW <= isLW;
			readReg_isWritebackInstr <= isWritebackInstr;
			readReg_isBranch <= isBranch;
			readReg_isMemInstr <= isMemInstr;
		   readReg_isSYS <= isSYS;
			readReg_isRSR <= isRSR;
			readReg_isWSR <= isWSR;
			readReg_isRETI <= isRETI;
			readReg_isNOOP <= 1'b0;
		end
  end
  
  //////////////////////////////// Decode //////////////////////////////////////////
  
  // stall PC if stall is asserted 
  // from execute stage
  assign stall = stall_execute;
  
  // forwarding: decode_Vals can come from regfile, alu output, or memory value
  wire [DBITS-1:0] Val1 = (forward_execute && execute_writeReg == readReg_readReg1) ? 
	  execute_writeback : (forward_memory && memory_writeReg == readReg_readReg1) ?
	  writeVal : readVal1;
  wire [DBITS-1:0] Val2 = (forward_execute && execute_writeReg == readReg_readReg2) ? 
	  execute_writeback : (forward_memory && memory_writeReg == readReg_readReg2) ?
	  writeVal : readVal2;
	
	
    RegisterFile #(
	.INITFILE(REGINITFILE),
   .DBITS(DBITS),
	.NUMREGS(NUMREGS),
	.REGNOBITS(REGNOBITS)
  ) regFile(
	 .READREG1(readReg_readReg1), 
	 .READREG2(readReg_readReg2), 
	 .READVAL1(readVal1), 
	 .READVAL2(readVal2),
	 .WRITEREG(writeRegIn), 
	 .WRITEVAL(writeVal), 
	 .WE(regFileWE), 
	 .CLK(clk),
	 .RESET(reset)
  );
  
  //////////////////////////////////////////////////////////////////////////////////
  
   // ExecuteBuffer
  reg [(DBITS-1):0] execute_PC;
  reg [(OPCODEBITS-1):0] execute_Op1, execute_Op2;
  reg [(REGNOBITS-1):0] execute_writeReg, 
							   execute_readSysReg, 
								execute_writeSysReg;
  reg [(DBITS-1):0] execute_RxVal, execute_RyVal;
  reg signed [(DBITS-1):0] execute_Imm;
  reg execute_isALUR, 
      execute_isJAL, 
		execute_isLW, 
		execute_isBranch,
      execute_isWritebackInstr, 
		execute_isMemInstr, 
		execute_isSYS, 
		execute_isRSR, 
		execute_isWSR,
		execute_isRETI,
		execute_isNOOP;
  
  // update execute buffer with outputs from fetch/decode
  always @(posedge clk) begin
	  if (stall | jmp | readReg_isNOOP) begin
	  
	      // for NOPS, do not update the PC. This means that
			// the PC will always contain the address of the last
			// good instruction. This is important for executing
			execute_PC <= {DBITS{1'b0}};
			execute_Op1 <= {OPCODEBITS{1'b0}};
			execute_Op2 <= {OPCODEBITS{1'b0}};
			execute_Imm <= {IMMBITS{1'b0}};
			execute_RxVal <= {DBITS{1'b0}};
			execute_RyVal <= {DBITS{1'b0}};
			execute_writeReg <= {REGNOBITS{1'b0}};
			execute_readSysReg <= {REGNOBITS{1'b0}};
			execute_writeSysReg <= {REGNOBITS{1'b0}};
			execute_isALUR <= 1'b0;
			execute_isJAL <= 1'b0;
			execute_isLW <= 1'b0;
			execute_isWritebackInstr <= 1'b0;
			execute_isBranch <= 1'b0;
			execute_isSYS <= 1'b0;
			execute_isRSR <= 1'b0;
			execute_isWSR <= 1'b0;
			execute_isRETI <= 1'b0;
			execute_isNOOP <= 1'b1;
		end 
		else begin 
			// PC and instruction
			execute_PC <= readReg_PC;
			execute_Op1 <= readReg_Op1;
			execute_Op2 <= readReg_Op2;
			execute_Imm <= readReg_Imm;
			
			// Register Values & writeback address
			// (RyVal == X if instruction is not ALUR)
			execute_RxVal <= Val1;
			execute_RyVal <= Val2;
			execute_writeReg <= readReg_writeReg;
			execute_readSysReg <= readReg_readSysReg;
			execute_writeSysReg <= readReg_writeSysReg;
			
			// decode signals
			execute_isALUR <= readReg_isALUR;
			execute_isJAL <= readReg_isJAL;
			execute_isLW <= readReg_isLW;
			execute_isWritebackInstr <= readReg_isWritebackInstr;
			execute_isBranch <= readReg_isBranch;
			execute_isMemInstr <= readReg_isMemInstr;
		   execute_isSYS <= readReg_isSYS;
			execute_isRSR <= readReg_isRSR;
			execute_isWSR <= readReg_isWSR;
			execute_isRETI <= readReg_isRETI;
			execute_isNOOP <= 1'b0;
	  end
  end
  
  ////////////////////////////// Execute ///////////////////////////////////////////
  
  // ALU wires
  wire [(OPCODEBITS-1):0] execute_ALUFunc;
  wire [(DBITS-1):0] execute_A, execute_B, execute_ALUOut, execute_jalTarget;
  wire execute_Z;
  wire [(DBITS-1):0] execute_PredictedPC, execute_PCPlus,
    execute_writeback;
	 
	 
 
  //////////////////// ALU ///////////////////
  // A gest RxVal, which is a source register
  assign execute_A = execute_RxVal;
  // B gets RyVal for instructions where RyVal 
  // has a valid value, otherwise it gets the 
  // immediate
  assign execute_B = 
    (execute_isBranch || execute_isALUR) ? 
    execute_RyVal : execute_Imm;
  // The alu function is op2 for ALUR and op1 
  // for all others
  assign execute_ALUFunc = 
    (execute_isALUR || execute_isSYS) ? 
    execute_Op2 : execute_Op1;
  
  
  
  
  //////////////////// stall and forward ///////////////////////
  // assign stalls if the instruction currently in Decode
  // wants to read a register that this instruction will write to.
  // also stall for branches or JALs.
  wire stall_execute = 
    (execute_isLW || isSYSRead) ? 
	 (readReg_readReg1 == execute_writeReg || readReg_readReg2 == execute_writeReg): 
	 (execute_isRSR || execute_isWSR);
  // forward for writeback instructions that that determine their
  // value in the execute stage (ALUR, ALUI)
  wire forward_execute = 
    (execute_isWritebackInstr && !execute_isLW) ?
    (readReg_readReg1 == execute_writeReg || readReg_readReg2 == execute_writeReg) : 
	 1'b0;
  // forward the value that will be written back in the mem stage
  assign execute_writeback = (execute_isJAL) ? 
    execute_PCPlus : execute_ALUOut;
  

  
  ////////////////////////////// PC ////////////
  // predict branch value for branches 
  // (PC + 4 + (InstructionOffset << 2))
  assign execute_PCPlus = execute_PC + INSTSIZE;
  assign execute_PredictedPC = execute_PCPlus + 
    (execute_Imm << IMEMWORDBITS);
  // jmp is asserted if a jump (branch or JAL) 
  // or interrupt should be taken
  assign jmp = 
    ((execute_isBranch && execute_Z) || 
	   execute_isJAL || 
		takeInterrupt ||
		execute_isRETI);
  // PCIn get predicted pc (pc + imm) for branches, 
  // aluout for JAL, or IHA for interrupts. If jmp 
  // is also asserted, then the PC changed to PCIn
  wire [DBITS-1:0] PCGood = (execute_isJAL) ? execute_ALUOut :  
	 (execute_isBranch && execute_Z) ? execute_PredictedPC :
	 execute_PCPlus;
  
  assign PCIn = 
	 (takeInterrupt) ? IHA :
	 (execute_isRETI) ? IRA :
	 PCGood;
	 
  
  
  //////////////////////////// SYS and IO Address ////////////////////////////
  // perform next step of decoding a SYS instruction. Check A0 (execute_RxVal)
  // and choose appropriate memory address to pass on
  // ioAddr gets the appropriate memory address for io operations, or gets ALUOut
  // if not a SYS instruction
  wire [DBITS-1:0] ioAddr = (execute_isSYS) ? 
	(execute_RxVal == SYSWRHEX || 
	  execute_RxVal == SYSRDHEX) ? ADDRHEX :
	(execute_RxVal == SYSWRLEDG || 
	  execute_RxVal == SYSRDLEDG) ? ADDRLEDG :
	(execute_RxVal == SYSWRLEDR || 
	  execute_RxVal == SYSRDLEDR) ? ADDRLEDR :
	(execute_RxVal == SYSRDCNT ||
	  execute_RxVal == SYSWRCNT) ? ADDRTIMER :
	(execute_RxVal == SYSWRTLIM ||
	  execute_RxVal == SYSRDTLIM) ? ADDRTLIM : 
	(execute_RxVal == SYSRDKEY) ? ADDRKEY :
	(execute_RxVal == SYSRDSW) ? ADDRSW :
	{DBITS{1'bX}} : 
	execute_ALUOut;
  wire isSYSWrite = (execute_isSYS && 
    (execute_RxVal == SYSWRHEX) ||
	 (execute_RxVal == SYSWRLEDG) ||
	 (execute_RxVal == SYSWRLEDR) ||
	 (execute_RxVal == SYSWRCNT) ||
	 (execute_RxVal == SYSWRTLIM));
  wire isSYSRead = (execute_isSYS && !isSYSWrite);
  
  ALU #(
	.WORDBITS(IMEMWORDBITS),
   .DBITS(DBITS),
   .OPCODEBITS(OPCODEBITS),
	.INSTSIZE(INSTSIZE),
   .SUB(OP2_SUB),
   .NAND(OP2_NAND),
   .NOR(OP2_NOR),
   .NXOR(OP2_NXOR),
   .EQ(OP2_EQ),
   .LT(OP2_LT),
   .LE(OP2_LE),
   .NE(OP2_NE),
   .ADD(OP2_ADD),
   .AND(OP2_AND),
   .OR(OP2_OR),
   .XOR(OP2_XOR),
	.LW(OP1_LW),
   .SW(OP1_SW),
   .BEQ(OP1_BEQ),
   .BLT(OP1_BLT),
   .BLE(OP1_BLE),
   .BNE(OP1_BNE),
   .JAL(OP1_JAL),
   .ADDI(OP1_ADDI),
   .ANDI(OP1_ANDI),
   .ORI(OP1_ORI),
   .XORI(OP1_XORI)
  ) alu(
	.ALUFUNC(execute_ALUFunc), 
	.A(execute_A), 
	.B(execute_B), 
	.ALUOUT(execute_ALUOut),
   .ALUR(execute_isALUR),	
	.Z(execute_Z)
  );
  
  /////////////////////////////////////////////////////////////////////////
  
  // Memory Buffer
  reg [(DBITS-1):0] memory_ALUResult, 
						  memory_RyVal,
						  memory_ioAddr;
  reg [(REGNOBITS-1):0] memory_writeReg, 
								memory_readSysReg, 
								memory_writeSysReg;
  reg [(OPCODEBITS-1):0] memory_Op1;
  reg [(DBITS-1):0] memory_PCPlus,
						  memory_PC,
						  memory_PCGood;
  reg memory_isJAL, 
      memory_isLW, 
		memory_isWritebackInstr, 
		memory_isMemInstr,  
		memory_isRSR, 
		memory_isWSR,
		memory_isSYS,
		memory_isSYSWrite,
		memory_isSYSRead,
		memory_isRETI;
  
  // update memory buffer values
  always @(posedge clk) begin
	 // PC and instruction
	 if (!execute_isNOOP)
		memory_PCGood <= PCGood;
	 memory_PC <= execute_PC;
	 memory_PCPlus <= execute_PCPlus;
	 memory_Op1 <= execute_Op1;
	 
	 // Register values and addresses
	 memory_ioAddr <= ioAddr;
	 memory_RyVal <= execute_RyVal;
	 memory_writeReg <= execute_writeReg;
	 memory_readSysReg <= execute_readSysReg;
	 memory_writeSysReg <= execute_writeSysReg;
	 
	 // values calculated in Execute stage
	 memory_ALUResult <= execute_ALUOut;
	 
	 // decode signals
	 memory_isJAL <= execute_isJAL;
	 memory_isLW <= execute_isLW;
	 memory_isWritebackInstr <= execute_isWritebackInstr;
	 memory_isMemInstr <= execute_isMemInstr;
	 memory_isRSR <= execute_isRSR;
	 memory_isWSR <= execute_isWSR;
	 memory_isSYS <= execute_isSYS;
	 memory_isSYSWrite <= isSYSWrite;
	 memory_isSYSRead <= isSYSRead;
	 memory_isRETI <= execute_isRETI;
  end
  
	////////////////////////////// Memory/Writeback //////////////////////////////////
	
  // memory bus wires
  wire [(DBITS-1):0] addressBus;
  tri [(DBITS-1):0] dataBus;
  wire busWE;
  
  
  
  /////////// interrupts ///////////////
  // interrupt signals
  wire keyInterrupt, 
       switchInterrupt, 
		 timerInterrupt;
  //assign interrupt device 
  // number; this signal is 
  // stored in IDN when
  // an interrupt is taken
  wire [3:0] interruptDN = 
    timerInterrupt ? TIMER_DN :
	 keyInterrupt ? KEY_DN :
	 switchInterrupt ? SWITCH_DN :
	 4'hF;
  // 1 if an interrupt should be taken. 
  // 0 if no action is required.
  // check for not reset and global 
  // interrupt enable and global interrupt.
  wire takeInterrupt = 
	!reset && 
	interruptEnable && 
	globalInterrupt;
  // assign gloablIRQ if an 
  // interrupt has been 
  // signalled by any device
  wire globalInterrupt = 
    keyInterrupt || 
	 switchInterrupt || 
	 timerInterrupt;

  
  
  
  ////////////  system registers //////////////
    // processor control registers
  //    PCS[0]: IE
  //    PCS[1]: OIE
  //    PCS[4]: CM
  //    PCS[5]: OM
  reg [(DBITS-1):0] PCS, IHA, IRA, IDN;
  wire isSystemMode = PCS[4];
  wire oldMode = PCS[5];
  wire interruptEnable = PCS[0];
  wire oldInterruptEnable = PCS[1];

  always @(posedge clk) begin
    if (reset) begin
	   PCS <= {
			27'b0, 
			DEFAULTMODE, 
			3'b0, 
			DEFAULTIE
		}; //PCS
		IHA <= DEFAULTIHA; // IHA
		IRA <= {DBITS{1'b0}}; // IRA
		IDN <= {DBITS{1'b0}}; // IDN
	 end
	 else if (takeInterrupt) begin
	   // IRA <= PC 
		// (interrupt occurs in execute)
		IRA <= memory_PCGood;
		// IDN <= device_num
		IDN <= interruptDN;
		
		// change interrupts
		// and mode
		PCS <= {
		  26'b0, 
		  isSystemMode, // OM 
		  1'b1, // CM
		  2'b0, 
		  interruptEnable, // OIE 
		  1'b0 // IE
		};
		
	 end
	 else if (memory_isWSR && isSystemMode)
		case (memory_writeSysReg)
			0: PCS <= memory_RyVal;
			1: IHA <= memory_RyVal;
			2: IRA <= memory_RyVal;
			3: IDN <= memory_RyVal;
			default:;
		endcase
	  else if (memory_isRETI) begin
	    PCS <= {
			26'b0,
			PCS[5], // OM
			PCS[5], // CM
			2'b0,
			PCS[1], // OIE
			PCS[1] // IE
		 };
	  end
	end
		
		
		
  
  ///////////////////////// bus ///////////////////////
  // addressBus gets either the computed 
  // address (alu out) or nothin (not a read)
  assign addressBus = 
	(memory_isMemInstr || memory_isSYS) ? 
    memory_ioAddr : {DBITS{1'bX}};
  // writes only enabled for intstructions that are SW or system writes
  assign busWE = ((memory_Op1 == OP1_SW) || (memory_isSYSWrite));
  // data is passed in from RyVal if write is enabled.
  assign dataBus = (busWE) ? memory_RyVal : {DBITS{1'bZ}};
  
  
  
  
  
  /////////////////////////// reg file //////////////////
  // regFileWE is true if opcode is for an
  // instruction that needs to write back to register rx   
  assign regFileWE = 
    (memory_isWritebackInstr || 
	  memory_isRSR || 
	  memory_isSYSRead);
  // address of destination register
  assign writeRegIn = memory_writeReg;
  // value to write to register. Can be memory value,
  // PC for this instruction, or ALU output
  assign writeVal = 
    ((memory_isSYSRead && isSystemMode) || 
	   memory_isLW) ? dataBus :
    (memory_isJAL) ? memory_PCPlus : 
	 (memory_isRSR) ? 
			(memory_readSysReg == 0) ? PCS :
			(memory_readSysReg == 1) ? IHA :
			(memory_readSysReg == 2) ? IRA :
			(memory_readSysReg == 3) ? IDN :
			32'bX :
	  memory_ALUResult;
	  
	  
	  
	  
  ///////////////////////// forwarding //////////////////////////////
  // forward memory values for writeback or sysread instructions where
  // the instruction in decode wants to read the register that is going
  // to be written by this instruction
  wire forward_memory = 
    (memory_isWritebackInstr || memory_isSYSRead) ?
    (readReg_readReg1 == memory_writeReg || readReg_readReg2 == memory_writeReg) : 
	 1'b0;
	 
	 
	 
  
  // memory
  Dmem #(
	.DBITS(DBITS),
	.ADDRBITS(DMEMADDRBITS),
	.WORDBITS(DMEMWORDBITS),
	.INITFILE(MEMINITFILE),
	.BASE(DMEMBASEADDR),
	.DMEMWORDS(DMEMWORDS)
  ) dmem( 
	.CLK(clk),
	.DATA(dataBus), 
	.ADDRIN(addressBus),  
	.WE(busWE)
  );
  
  // output devices
  Hex #(
    .BITS(DBITS),
	 .BASE(ADDRHEX)
  ) hex(
    .CLK(clk), 
	 .ADDRBUS(addressBus), 
	 .DATABUS(dataBus), 
	 .WE(busWE), 
	 .RESET(reset), 
	 .DEVICE0(HEX0), 
	 .DEVICE1(HEX1), 
	 .DEVICE2(HEX2), 
	 .DEVICE3(HEX3)
  );
  
  LED #(
    .BITS(DBITS),
	 .BASE(ADDRLEDG),
	 .DEVICEBITS(8)
  ) ledg(
    .CLK(clk), 
	 .ADDRBUS(addressBus), 
	 .DATABUS(dataBus), 
	 .WE(busWE), 
	 .RESET(reset), 
	 .DEVICE(LEDG)
  );
  
  LED #(
    .BITS(DBITS),
	 .BASE(ADDRLEDR),
	 .DEVICEBITS(10)
  ) ledr(
    .CLK(clk), 
	 .ADDRBUS(addressBus), 
	 .DATABUS(dataBus), 
	 .WE(busWE), 
	 .RESET(reset), 
	 .DEVICE(LEDR)
  );
  
  // input devices (can interrupt)
  Key #(
    .BITS(DBITS),
	 .BASE(ADDRKEY)
  ) key(
    .CLK(clk),
	 .ADDRBUS(addressBus),
	 .DATABUS(dataBus),
	 .WE(busWE),
	 .RESET(reset),
	 .DEVICE(KEY),
	 .IRQ(keyInterrupt)
  );
  
  Switch #(
    .BITS(DBITS),
	 .BASE(ADDRSW),
	 .DEVICEBITS(10)
  ) switch(
    .CLK(clk), 
	 .ADDRBUS(addressBus), 
	 .DATABUS(dataBus), 
	 .WE(busWE), 
	 .RESET(reset), 
	 .DEVICE(SW),
	 .IRQ(switchInterrupt)
  );
  
  Timer #(
    .BITS(DBITS), 
	 .BASE(ADDRTIMER),
	 .COUNTMS(TIMERMS)
  ) timer(
  .CLK(clk), 
  .CLK50(CLOCK_50), 
  .ADDRBUS(addressBus), 
  .DATABUS(dataBus), 
  .WE(busWE), 
  .RESET(reset),
  .IRQ(timerInterrupt)
  );
  
endmodule
