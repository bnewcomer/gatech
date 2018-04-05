// Benjamin Newcomer & Casey Evanish
// CS 3220 Project 2

module Project2(SW,KEY,LEDR,LEDG,HEX0,HEX1,HEX2,HEX3,CLOCK_50);
  input  [9:0] SW;
  input  [3:0] KEY;
  input  CLOCK_50;
  output [9:0] LEDR;
  output [7:0] LEDG;
  output [6:0] HEX0,HEX1,HEX2,HEX3;
 
 ////////////////////////// PARAMETERS & TIMING  //////////////////////////////////
 
  parameter DBITS    = 32; // word size
  parameter INSTSIZE = 32'd4; // instruction size (bytes). used to increment PC.
  parameter INSTBITS = 32; // instruction width
  parameter REGNOBITS = 5; // number of bits required to specify a register
  parameter NOREGS = 32; // number of regs in register file
  parameter IMMBITS  = 17; // number of bits in immediate
  parameter STARTPC  = 32'h60; // starting value of PC
  parameter ADDRHEX  = 32'hFFFF0000; // I/O address of HEX
  parameter ADDRLEDR = 32'hFFFF0020; // I/O address of LEDR
  parameter ADDRLEDG = 32'hFFFF0040; // I/O address of LEDG
  parameter ADDRKEY  = 32'hFFFF0100; // I/O address of KEY
  parameter ADDRSW   = 32'hFFFF0120; // I/O address of SW
<<<<<<< HEAD
  parameter IMEMINITFILE = "Sorter2.mif"; // MIF file that initializes memory
=======
  parameter IMEMINITFILE = "Test2.mif"; // MIF file that initializes memory
>>>>>>> 20ef29e347c1a2766e0bceb44669a2d94dc61958
  parameter IMEMADDRBITS = 13; // Instruction memory address width
  parameter IMEMWORDBITS = 2; // ?
  parameter IMEMWORDS = 2048; // Size of instruction memory (words)
  parameter DMEMADDRBITS = 13; // Data memory address width
  parameter DMEMWORDBITS = 2; // ?
  parameter DMEMWORDS = 2048; // Size of data memory (words)
  parameter OPCODEBITS = 5; // number of bits in the [primary/secondary] opcode
  parameter BUSZ={DBITS{1'bZ}}; // high impedance value used to 'block' signals
  
  // primary opcodes
  parameter OP1_ALUR = 5'b00000; // ext, use secondary opcode
  parameter OP1_LW   = 5'b01010; // load word
  parameter OP1_SW   = 5'b01110; // save word
  parameter OP1_BEQ  = 5'b10000; // branch if equal
  parameter OP1_BLT  = 5'b10001; // branch if less than
  parameter OP1_BLE  = 5'b10010; // branch if less than or equal to
  parameter OP1_BNE  = 5'b10011; // branch if not equal
  parameter OP1_JAL  = 5'b10111; // jump
  parameter OP1_ADDI = 5'b11000; // add immediate
  parameter OP1_ANDI = 5'b11100; // and immediate
  parameter OP1_ORI  = 5'b11101; // or immediate
  parameter OP1_XORI = 5'b11110; // xor immediate
  
  // secondary opcodes
  parameter OP2_ADD  = 5'b11000; // add
  parameter OP2_AND  = 5'b11100; // and
  parameter OP2_OR   = 5'b11101; // or
  parameter OP2_XOR  = 5'b11110; // xor
  parameter OP2_SUB  = 5'b01000; // subtract
  parameter OP2_NAND = 5'b01100; // nand
  parameter OP2_NOR  = 5'b01101; // nor
  parameter OP2_NXOR = 5'b01110; // not xor
  parameter OP2_EQ   = 5'b10000; // equal
  parameter OP2_LT   = 5'b10001; // less than
  parameter OP2_LE   = 5'b10010; // less than or equal to
  parameter OP2_NE   = 5'b10011; // not equal
  
  // states for microcontroller
  parameter S_BITS=5;
  parameter [(S_BITS-1):0]
    S_ZERO   = {(S_BITS){1'b0}},
    S_ONE    = {{(S_BITS-1){1'b0}},1'b1},
    S_FETCH1 = 5'd0,
	 S_FETCH2 = 5'd1,
	 S_ALUR1  = 5'd2,
	 S_ALUR2  = 5'd3,
	 S_ALUR3  = 5'd4,
	 S_ALUI1  = 5'd5,
	 S_ALUI2  = 5'd6,
	 S_ALUI3  = 5'd7,
	 S_ERROR  = 5'd8,
	 S_LW1    = 5'd9,
	 S_LW2    = 5'd10,
	 S_LW3    = 5'd11,
	 S_LW3_5  = 5'd12,
	 S_LW4    = 5'd13,
	 S_SW1    = 5'd14,
	 S_SW2    = 5'd15,
	 S_SW3    = 5'd16,
	 S_SW4    = 5'd17,
	 S_B1     = 5'd18,
	 S_B2     = 5'd19,
	 S_B3     = 5'd20,
	 S_B4     = 5'd21,
	 S_B5     = 5'd22,
	 S_JAL1   = 5'd23,
	 S_JAL2   = 5'd24,
	 S_JAL3   = 5'd25,
	 S_JAL4   = 5'd26;

  
  // timing and reset
  wire clk,lock;
  wire reset = !lock || !KEY[0];
  Pll pll(.inclk0(CLOCK_50),.c0 (clk),.locked(lock));
  
//////////////////////////////////  BUS, PC  ///////////////////////////////////////
  
  // Create the processor's bus and PC
  tri [(DBITS-1):0] thebus;
  reg [(DBITS-1):0] PC;
  
  // microcontroller signals
  reg LdPC, DrPC, IncPC;
   
  // increment or reset PC
  always @(posedge clk) begin
  
    if(reset)
	   PC <= STARTPC;
	 else if(LdPC)
      PC <= thebus;
    else if(IncPC)
      PC <= PC + INSTSIZE;
  end
  
  // connect PC to the bus
  assign thebus = DrPC ? PC : BUSZ; // driver for PC
  
  
//  ///////////////////////////////  MEMORY,I/O  /////////////////////////////////////
  
  // instantiate instruction memory
  (* ram_init_file = IMEMINITFILE *)
  reg [(DBITS-1):0] imem[(IMEMWORDS-1):0];
  wire [(DBITS-1):0] iMemOut = imem[PC[(IMEMADDRBITS-1):IMEMWORDBITS]];
  reg [(INSTBITS-1):0] IR;
  
  // instantiate data memory and handle memory-mapped I/O
  (* ram_init_file = IMEMINITFILE *)
  reg [(DBITS-1):0] dmem[(DMEMWORDS-1):0];
  reg [(DBITS-1):0] MAR, MDR;
  reg [(DBITS-1):0] HEXOut, LEDROut, LEDGOut;
  wire WE = WrMem && !reset;
  wire [(DBITS-1):0] dMemOut = WE ? {DBITS{1'bX}} : MDR;
  
  // microcontroller signal
  reg WrMem, DrMem, LdMAR, LdIR;
 
  // update MAR and connect I/O to memory
  always @(posedge clk) begin
	 
	// reset or update MAR
	if (reset) begin
	  MAR <= {DBITS{1'bX}};
	  MDR <= {DBITS{1'bX}};
	end
	else begin 
		if (LdMAR)
			MAR <= thebus;
		if (LdIR)
			IR <= iMemOut;
		if (WrMem && WE) begin
			if (MAR == ADDRHEX)
				HEXOut <= thebus;
			else if (MAR == ADDRLEDG)
				LEDGOut <= thebus;
			else if (MAR == ADDRLEDR)
				LEDROut <= thebus;
			else 
				dmem[(MAR[DMEMADDRBITS-1:0] >> DMEMWORDBITS)] <= thebus;
		end
		if (MAR == ADDRKEY)
			MDR <= {28'b0,KEY};
		else if (MAR == ADDRSW)
			MDR <= {12'b0,SW}; 
		else
			MDR <= dmem[(MAR[DMEMADDRBITS-1:0] >> DMEMWORDBITS)];	
   end

  end
  
  
	// assign reg values to I/O peripherals and connect dmem to bus
	SevenSeg s0(.IN(HEXOut[3:0]),.OUT(HEX0));
	SevenSeg s1(.IN(HEXOut[7:4]),.OUT(HEX1));
	SevenSeg s2(.IN(HEXOut[11:8]),.OUT(HEX2));
	SevenSeg s3(.IN(HEXOut[15:12]),.OUT(HEX3));		
	assign LEDR = LEDROut;
	assign LEDG = LEDGOut[7:0];
	assign thebus = DrMem ? dMemOut : BUSZ; // driver for dmem
	
//////////////////////////////// INSTR, IR  ////////////////////////////////////////
	
  // split IR into op1, op2, rx, ry, rz, imm and sxt imm
  wire [(OPCODEBITS-1):0] op1, op2;
  wire [(REGNOBITS-1):0] rx,ry,rz;
  wire [(IMMBITS-1):0] preImm;
  wire [(DBITS-1):0] imm;
  
  // microcontroller signals
  reg DrOff, ShOff;
  
   // comments show what IR values would be given
	// assuming 32 bit words, 1 word instructions,
	// 5 bit opcode, 5 bits to specify a register,
	// and 17 bit immediate
	assign op1 = IR[(INSTBITS-1):(INSTBITS-OPCODEBITS)]; //IR[31:27]
	assign op2 = IR[(OPCODEBITS-1):0]; //IR[4:0]
	assign rx = IR[(INSTBITS-OPCODEBITS-1):
		(INSTBITS-OPCODEBITS-REGNOBITS)]; //IR[26:22]
	assign ry = IR[(INSTBITS-OPCODEBITS-REGNOBITS-1):
		(INSTBITS-OPCODEBITS-2*REGNOBITS)]; //IR[21:17]
	assign rz = IR[(INSTBITS-OPCODEBITS-2*REGNOBITS-1):
		(INSTBITS-OPCODEBITS-3*REGNOBITS)]; //IR[16:12];
	assign preImm = {{(DBITS-IMMBITS){IR[INSTBITS-OPCODEBITS-2*REGNOBITS-1]}},
		IR[(INSTBITS-OPCODEBITS-2*REGNOBITS-1):0]}; //IR[16:0], sxt->32 bits
  
  // sign extend preImm and hook up to imm
  SXT #(.IBITS(IMMBITS),.OBITS(DBITS)) sxtImm(.IN(preImm),.OUT(imm));
  
  // connect offset to bus. DrOff drives offset, ShOff
  // drives offset x instruction size (for branches and whatnot)
  assign thebus = (DrOff) ? imm : BUSZ;
  assign thebus = (ShOff) ? (imm << DMEMWORDBITS) : BUSZ;
		
  ////////////////////////////// REGISTER FILE ///////////////////////////////////
		
  // Create register file
  reg [(DBITS-1):0] regs[(NOREGS-1):0];
  reg [(REGNOBITS-1):0] RegNo;
  wire [(DBITS-1):0] RegOut = WrReg ? {DBITS{1'bX}} : regs[RegNo];
  integer i;
  
  // microcontroller signals
  reg WrReg,DrReg;
  
  // write to reg file (except Zero)
  always @(posedge clk) begin
    if (reset) begin
	   RegNo <= {REGNOBITS{1'bX}};
		for (i=0;i<NOREGS;i=i+1)
			regs[i] <= {DBITS{1'b0}};
	 end
	 else if(WrReg && RegNo != {REGNOBITS{1'b0}})
      regs[RegNo] <= thebus;
	end
  
  // connect reg file to the bus
  assign thebus = DrReg ? RegOut : BUSZ; // driver for reg file
  
  
//  ////////////////////////////// ALU, Z //////////////////////////////////////////////
  
  // Create ALU, A, B, Z (z is used in comparisons)
  reg signed [(DBITS-1):0] A,B;
  reg Z = 1'b0;
  reg [(OPCODEBITS-1):0] ALUfunc;
  reg signed [(DBITS-1):0] ALUOut;
  
  // microcontroller signals
  reg LdA, LdB, DrALU, LdZ;
  
  // Update A, B, ALUfunc
  always @(posedge clk) begin
    // reset or load A or B
	 if(reset) begin
	   {A,B} <= {DBITS{1'bX}};
		Z <= 1'b0;
	 end
	 else begin
      if(LdA)
        A <= thebus;
      if(LdB)
        B <= thebus;
		if (LdZ)
		  Z <= (thebus == 32'b1);
    end
  end
  
  // Do arithmetic! assign ALU output
  always @(A or B or ALUfunc) begin
    case (ALUfunc)
	   OP2_ADD, OP1_ADDI, OP1_LW, 
			OP1_SW, OP1_JAL: ALUOut <= A + B;
		OP2_AND, OP1_ANDI: ALUOut <= A & B;
		OP2_OR, OP1_ORI: ALUOut <= A | B;
		OP2_XOR, OP1_XORI: ALUOut <= A ^ B;
		OP2_SUB: ALUOut <= A - B;
		OP2_NAND: ALUOut <= ~(A & B);
		OP2_NOR: ALUOut <= ~(A | B);
		OP2_NXOR: ALUOut <= ~(A ^ B);
		OP1_BEQ: ALUOut <= (A == B);
		OP1_BLT: ALUOut <= (A < B);
		OP1_BLE: ALUOut <= (A <= B);
		OP1_BNE: ALUOut <= (A != B);
	   default: ALUOut <= {DBITS {1'bX}};
	 endcase
  end
  
  // Connect ALU output to the bus
  assign thebus = DrALU ? ALUOut : BUSZ; // driver for the ALU
  
//  /////////////////////////// STATE MACHINE (MICROCONTROLLER) //////////////////////
	 
  reg [(S_BITS-1):0] state, next_state;
  
  // assert or disable signals depending on the state of the processor
  always @(state or op1 or rx or ry or rz or op2 or ALUOut[0]) begin
	
	// reset all signals
	{LdPC,DrPC,IncPC,LdMAR,WrMem,DrMem,LdIR,DrOff,
	  ShOff, LdA, LdB, LdZ, DrALU, DrReg, WrReg} = {15{1'b0}};
	RegNo = 5'b0;
	next_state = state + S_ONE;
	ALUfunc = (op1 == OP1_ALUR) ? op2 : op1;
   
	// assert signals depending on state
	case(state)
		// fetch next instruction and branch to instruction states
		// FETCH: Load IR, increment PC; dispatch to instruction
      S_FETCH1: {LdIR,IncPC} = {2{1'b1}};
      S_FETCH2: begin
	     case(op1)
		  OP1_ALUR: begin
		  	   case(op2)
				  OP2_SUB, OP2_NAND, OP2_NOR, OP2_NXOR,
				  OP2_EQ, OP2_LT, OP2_LE, OP2_NE, OP2_ADD,
				  OP2_AND, OP2_OR, OP2_XOR:
				    next_state = S_ALUR1;
				  default: next_state = S_ERROR;
			   endcase
			   end
			OP1_ADDI, OP1_ANDI, OP1_ORI, OP1_XORI: 
			   next_state = S_ALUI1;
			OP1_LW: next_state = S_LW1;
			OP1_SW: next_state = S_SW1;
			OP1_BEQ, OP1_BLT, OP1_BLE, OP1_BNE:
				next_state = S_B1;
		   OP1_JAL: next_state = S_JAL1;
			default: next_state = S_ERROR;
			endcase
      end
		// ALUR: Load A,B from reg file; drive ALU result into reg
		S_ALUR1: {LdA, DrReg, RegNo} = {{2{1'b1}}, IR[26:22]}; //ry,r
		S_ALUR2: {LdB, DrReg, RegNo} = {{2{1'b1}}, IR[21:17]}; //rz,r
		S_ALUR3: {DrALU, WrReg, RegNo, next_state} = {{2{1'b1}}, IR[16:12], S_FETCH1}; //rx,r
		// ALUI: Load A from reg file; load B from offset; drive
		// ALU result into reg file (uses S_ALUR3)
		S_ALUI1: {LdA, DrReg, RegNo} = {{2{1'b1}}, IR[26:22]}; //ry,i
		S_ALUI2: {LdB, DrOff} = {2{1'b1}};
		S_ALUI3: {DrALU, WrReg, RegNo, next_state} = {{2{1'b1}}, IR[21:17], S_FETCH1}; //rx,r
		// ERROR: something!
		S_ERROR: next_state = S_FETCH1; // something!!!!!!!!!!!!!!!!!
		// LW: load (ry + imm) into MAR; drive mem into reg file
		S_LW1: {LdA, DrReg, RegNo} = {{2{1'b1}}, IR[26:22]}; //ry,i
		S_LW2: {LdB, DrOff} = {2{1'b1}};
		S_LW3: {DrALU, LdMAR} = {2{1'b1}};
		S_LW3_5:;
		S_LW4: {DrMem, WrReg, RegNo, next_state} = {{2{1'b1}}, IR[21:17], S_FETCH1}; //rx,i
		// SW: drive (ry + imm) into MAR; drive rx into memory
		S_SW1: {LdA, DrReg, RegNo} = {{2{1'b1}}, IR[26:22]}; //ry,i
		S_SW2: {LdB, DrOff} = {2{1'b1}};
		S_SW3: {DrALU, LdMAR} = {2{1'b1}};
		S_SW4: {WrMem, DrReg, RegNo, next_state} = {{2{1'b1}}, IR[21:17], S_FETCH1}; //rx,i
		// Branches: BEQ, BLT, BLE, BNE. Load rx, ry into A,B; perform comparison;
		// If z == 1, PC<= PC + 4*imm, else do nothing
		S_B1: {LdA, DrReg, RegNo} = {{2{1'b1}}, IR[26:22]}; //rx,i
		S_B2: {LdB, DrReg, RegNo} = {{2{1'b1}}, IR[21:17]}; //ry
		S_B3: {DrALU, LdZ} = {2{1'b1}};
		S_B4: if (!Z) next_state = S_FETCH1;
		S_B5: {LdA, DrPC, next_state} = {{2{1'b1}}, S_JAL3}; 
		// JAL: ry <= PC + 4; PC <= rx + 4*imm
		S_JAL1: {DrPC, WrReg, RegNo} = {{2{1'b1}}, IR[26:22]}; //rx
		S_JAL2: {LdA, DrReg, RegNo} = {{2{1'b1}}, IR[21:17]}; //ry
		S_JAL3: {LdB, ShOff} = {2{1'b1}};
		S_JAL4: {DrALU, LdPC, ALUfunc, next_state} = {{2{1'b1}}, OP2_ADD, S_FETCH1}; 
		default:  next_state=S_ERROR;
    endcase
  end
  always @(posedge clk or posedge reset)
	if(reset)
	  state<=S_FETCH1;
	else
	  state<=next_state;
	  
endmodule


//////////////////////////// ADDNL MODULES  ///////////////////////////////////////

module SXT(IN,OUT);
  parameter IBITS;
  parameter OBITS;
  input  [(IBITS-1):0] IN;
  output [(OBITS-1):0] OUT;
  assign OUT={{(OBITS-IBITS){IN[IBITS-1]}},IN};
endmodule

// takes in a clock signal and key signal of 
// KEYSIZE bits. Asserts OUT on the appropriate
// wire only once when a key is pressed
module KEYPRESS(CLK, KEYIN, OUT);
	parameter KEYSIZE = 4;
	
	input CLK;
	input [KEYSIZE-1:0] KEYIN;
	output [KEYSIZE-1:0] OUT;
	
	reg [KEYSIZE-1:0] oldKEY;
	
	always @(CLK)
		oldKEY <= KEYIN;
	
	assign OUT = {
		oldKEY[3] && !KEYIN[3],
		oldKEY[2] && !KEYIN[2],
		oldKEY[1] && !KEYIN[1],
		oldKEY[0] && !KEYIN[0],
	};

endmodule
	
