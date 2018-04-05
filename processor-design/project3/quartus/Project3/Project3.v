module Project3(SW,KEY,LEDR,LEDG,HEX0,HEX1,HEX2,HEX3,CLOCK_50);
  ///////////////////////////// Inputs and Outputs ////////////////////////////
  input  [9:0] SW;
  input  [3:0] KEY;
  input  CLOCK_50;
  output [9:0] LEDR;
  output [7:0] LEDG;
  output [6:0] HEX0,HEX1,HEX2,HEX3;
  
    // debug
  //output [1:0] DEBUG = {busybit1, busybit2};

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
  parameter MEMINITFILE = "Sorter2.mif"; // memory initialization file
  parameter IMEMADDRBITS = 13; // instr memory address width (bits)
  parameter IMEMWORDBITS = 2; // value to right shift byte address to get index address
  parameter IMEMWORDS = 2048; // size of instr memory (words)
  parameter DMEMADDRBITS = 13; // data memory address width (bits)
  parameter DMEMWORDBITS = 2; // value to right shift byte address to get index address
  parameter DMEMWORDS = 2048; // size of data memory (words)
  
  // Opcodes (primary)
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
	

  ///////////////////////////// Timing, Reset //////////////////////////////////////////////////
  
  wire clk, lock;
  Pll pll(.inclk0(CLOCK_50),.c0 (clk),.locked(lock));
  wire reset = !lock | !KEY[3];
  
  ////////////////////////////// Fetch/Decode /////////////////////////////////////////////
  
  // PC wires
  wire [(DBITS-1):0] PCIn, curPC, incPC;
  wire jmp, stall, isALUR, isJAL, isLW, isALUI, isWritebackInstr,
		stall_execute, stall_memory;
  
  // imem wires
  wire [(DBITS-1):0] imemAddr;
  wire [(OPCODEBITS-1):0] op1, op2;
  wire [(REGNOBITS-1):0] rx, ry, rz;
  wire [(DBITS-1):0] imm;
  
  // Register file wires
  wire [(REGNOBITS-1):0] readReg1, readReg2, writeReg;
  wire [(DBITS-1):0] readVal1, readVal2, writeVal;
  wire regFileWE;
  
  // hook up imem to PC
  assign imemAddr = curPC;
  
  assign isALUI = op1[(OPCODEBITS-1):(OPCODEBITS-2)] == 2'b11;
  assign isLW = (op1 == OP1_LW);
  assign isJAL = (op1 == OP1_JAL);
  assign isALUR = ((op1 == OP1_ALUR) && op2);
  assign isWritebackInstr = (isALUR || isJAL || isLW || isALUI);
	
  // always read register ry. Conditionally read rx or rz
  // depending on instruction type. We should never need
  // both rx and rz for the same instruction
  assign readReg1 = ry;
  assign readReg2 = (isALUR) ? rz : rx;
  
  // stall PC if any busy bits are set
  assign stall = (stall_execute || stall_memory);
  
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
	.PCINCOUT(incPC)
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
	.ADDRIN(imemAddr), 
	.OP1(op1), 
	.RX(rx), 
	.RY(ry), 
	.RZ(rz), 
	.OP2(op2), 
	.IMM(imm)
  );
  
    RegisterFile #(
	.INITFILE(REGINITFILE),
	.DBITS(DBITS),
	.NUMREGS(NUMREGS),
	.REGNOBITS(REGNOBITS)
  ) regFile(
		.READREG1(readReg1), 
		.READREG2(readReg2), 
		.READVAL1(readVal1), 
		.READVAL2(readVal2),
		.WRITEREG(writeReg), 
		.WRITEVAL(writeVal), 
		.WE(regFileWE), 
		.CLK(clk),
		.RESET(reset)
  );
  
  //////////////////////////////////////////////////////////////////////////////////
  
  // ExecuteBuffer
  reg [(DBITS-1):0] execute_PC;
  reg [(OPCODEBITS-1):0] execute_Op1, execute_Op2;
  reg [(REGNOBITS-1):0] execute_Rx;
  reg [(DBITS-1):0] execute_RxzVal, execute_RyVal, execute_BVal, execute_Imm;
  reg execute_isALUR, execute_isJAL, execute_isLW, execute_isWritebackInstr;
  
  // update execute buffer with outputs from fetch/decode
  always @(posedge clk) begin
	  if (!stall) begin
			execute_PC <= curPC;
			execute_Op1 <= op1;
			execute_Op2 <= op2;
			execute_Rx <= rx;
			execute_RxzVal <= readVal2;
			execute_RyVal <= readVal1;
			execute_isALUR <= isALUR;
			execute_Imm <= imm;
			execute_isJAL <= isJAL;
			execute_isLW <= isLW;
			execute_isWritebackInstr <= isWritebackInstr;
		end 
		else begin 
			execute_PC <= curPC;
			execute_Op1 <= 5'b0;
			execute_Op2 <= 5'b0;
			execute_Rx <= 5'b0;
			execute_RxzVal <= 32'b0;
			execute_RyVal <= 32'b0;
			execute_isALUR <= 0;
			execute_Imm <= 17'b0;
			execute_isJAL <= 1'b0;
			execute_isLW <= 1'b0;
			execute_isWritebackInstr <= 1'b0;
	  end
  end
  
  ////////////////////////////// Execute ///////////////////////////////////////////
  
  // ALU wires
  wire [(OPCODEBITS-1):0] ALUFunc;
  wire [(DBITS-1):0] A, B, ALUOut;
  wire Z, isBranch;
  
  // branch prediction wires
  wire [(DBITS-1):0] predictedPC;
 
  // connect ALU to Execute Buffer. B is either rx_val or rz_val.
  // if it is rx_val, then it is not an ALU instruction and we can ignore the
  // ALU output. But this is hardware so we calculate the output anyway.
  // Only assert isALUR if primary opcode is EXT and secondary opcode is not
  // zero. If both are zero, the instruction is a noop.
  assign isBranch = ((execute_Op1[(OPCODEBITS-1):(OPCODEBITS-2)] == 2'b10)
		&& (execute_Op1 != OP1_JAL));
  assign A = execute_RyVal;
  assign B = (isBranch || execute_isALUR) ? execute_RxzVal : execute_Imm;
  assign ALUFunc = (execute_isALUR) ? execute_Op2 : execute_Op1;
  
  //assign stalls
  assign stall_execute = (isBranch || execute_isJAL)? 1'b1:
							    (execute_isWritebackInstr)?
								 (readReg1 == execute_Rx || readReg2 == execute_Rx): 1'b0;
  
  // branch prediction
  // calculate imm + (PC+4)
  assign predictedPC = execute_PC + execute_Imm;
 
  ALU #(
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
	.ALUFUNC(ALUFunc), 
	.A(A), 
	.B(B), 
	.ALUOUT(ALUOut),
   .ALUR(execute_isALUR),	
	.Z(Z)
  );
  
  /////////////////////////////////////////////////////////////////////////
  
  // Memory Buffer. we only need to remember one opcode from here on out
  // (equivalent to ALUFunc). memory_ALUResult may be ignored depending on
  // instr type and memory_RxVal may be junk depending on instr type.
  reg [(DBITS-1):0] memory_ALUResult, memory_RxzVal;
  reg [(REGNOBITS-1):0] memory_Rx;
  reg [(OPCODEBITS-1):0] memory_Op1;
  reg [(DBITS-1):0] memory_PredictedPC, memory_PC;
  reg memory_Z, memory_isALUR, memory_isBranch, 
		memory_isJAL, memory_isLW, memory_isWritebackInstr;
  
  // update memory buffer values
  always @(posedge clk) begin
    memory_ALUResult <= ALUOut;
	 memory_RxzVal <= execute_RxzVal;
	 memory_Rx <= execute_Rx;
	 memory_Op1 <= execute_Op1;
	 memory_Z <= Z;
	 memory_PredictedPC <= predictedPC;
	 memory_isALUR <= execute_isALUR;
	 memory_isBranch <= isBranch;
	 memory_PC <= execute_PC;
	 memory_isJAL <= execute_isJAL;
	 memory_isLW <= execute_isLW;
	 memory_isWritebackInstr <= execute_isWritebackInstr;
  end
  
	////////////////////////////// Memory/Writeback //////////////////////////////////
  
  // dmem wires
  wire [(DBITS-1):0] dmemDataIn, dmemDataOut, dmemAddrIn, jalTarget;
  wire dmemWE, isWriteInstr;
  

  
  // branch/jump decision signal. jump <= instruction is a branch or jump
  // and Z is true (always true for jump instructions). pcin <= computed address
  // if jump, predictedpc if branch.
  assign jmp = ((memory_Z && memory_isBranch) || memory_isJAL);
  assign jalTarget = memory_ALUResult;
  assign PCIn = (memory_isJAL) ? jalTarget : memory_PredictedPC;
  
  // connect memory inputs to memory buffer. send read/write address if opcode
  // is for a read/write instruction. Send data in if it's a write 
  // instruction. Enable WE if it's a write instruction.
  assign isWriteInstr = memory_Op1[(OPCODEBITS-1):(OPCODEBITS-2)] == 2'b01;
  assign dmemAddrIn = (isWriteInstr) ? memory_ALUResult : {DBITS{1'bX}};
  assign dmemWE = (memory_Op1 == OP1_SW);
  assign dmemDataIn = (dmemWE) ? memory_RxzVal : {DBITS{1'bX}};
  
  //assign stalls
  assign stall_memory = (jmp)? 1'b1:
                        (memory_isWritebackInstr)?
								(readReg1 == memory_Rx || readReg2 == memory_Rx): 1'b0;
  
  // regFileWE is true if opcode is for an
  // instruction that needs to write back to register rx   
  assign regFileWE = memory_isWritebackInstr;
  assign writeReg = memory_Rx;
  assign writeVal = (memory_isLW) ? dmemDataOut :
		(memory_isJAL) ? memory_PC :
		memory_ALUResult;
  
  Dmem #(
	.ADDRHEX(ADDRHEX),
   .ADDRLEDR(ADDRLEDR),
   .ADDRLEDG(ADDRLEDG),
   .ADDRKEY(ADDRKEY),
   .ADDRSW(ADDRSW),
	.DBITS(DBITS),
	.ADDRBITS(DMEMADDRBITS),
	.WORDBITS(DMEMWORDBITS),
	.INITFILE(MEMINITFILE),
	.DMEMWORDS(DMEMWORDS)
  ) dmem(
	.RESET(reset), 
	.CLK(clk), 
	.DIN(dmemDataIn), 
	.ADDRIN(dmemAddrIn), 
	.DOUT(dmemDataOut), 
	.WE(dmemWE), 
	.SW(SW), 
	.KEY(KEY), 
	.HEX0(HEX0), 
	.HEX1(HEX1), 
	.HEX2(HEX2), 
	.HEX3(HEX3), 
	.LEDR(LEDR), 
	.LEDG(LEDG)
  );

endmodule
