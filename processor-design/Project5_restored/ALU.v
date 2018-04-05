// ALU module
// Benjamin Newcomer

module ALU(ALUFUNC, ALUR, A, B, ALUOUT, Z);

	parameter WORDBITS = 2;

  // inputs
  input [(OPCODEBITS-1):0] ALUFUNC;
  input signed [(DBITS-1):0] A, B;
  input ALUR;
  
  // outputs
  output [(DBITS-1):0] ALUOUT;
  output Z;
  
  reg [(DBITS-1):0] ALUResult;
  
  // parameters
  parameter DBITS = 32;
  parameter OPCODEBITS = 5;
  parameter INSTSIZE = 32'd4;
  parameter BEQ  = 5'b10000;
  parameter BLT  = 5'b10001;
  parameter BLE  = 5'b10010;
  parameter BNE  = 5'b10011;
  parameter ADDI = 5'b11000;
  parameter ANDI = 5'b11100;
  parameter ORI  = 5'b11101;
  parameter XORI = 5'b11110;
  parameter LW   = 5'b01010;
  parameter SW   = 5'b01110;
  parameter EQ  =  5'b10000;
  parameter LT  =  5'b10001;
  parameter LE  =  5'b10010;
  parameter NE  =  5'b10011;
  parameter JAL  = 5'b10111;
  parameter ADD =  5'b11000;
  parameter AND =  5'b11100;
  parameter OR  =  5'b11101;
  parameter XOR =  5'b11110;
  parameter SUB  = 5'b01000;
  parameter NAND = 5'b01100;
  parameter NOR  = 5'b01101;
  parameter NXOR = 5'b01110;
  
  // hook up ALUResult reg to output
  assign ALUOUT = ALUResult;
  assign Z = ALUResult[0];
  
  // perform ALU operations
  always @(ALUR or ALUFUNC or A or B)
	if (ALUR) begin
		case (ALUFUNC)
		   // handle secondary opcodes
			ADD:  ALUResult = A + B;
			SUB:  ALUResult = A - B;
			AND:  ALUResult = A & B;
			OR:   ALUResult = A | B;
			XOR:  ALUResult = A ^ B;
			NAND: ALUResult = ~(A & B);
			NOR:  ALUResult = ~(A | B);
			NXOR: ALUResult = ~(A ^ B);
			EQ:   ALUResult = {{(DBITS-1){1'b0}}, A == B};
			LT:   ALUResult = {{(DBITS-1){1'b0}}, A < B};
			LE:   ALUResult = {{(DBITS-1){1'b0}}, A <= B};
			NE:   ALUResult = {{(DBITS-1){1'b0}}, A != B};
			default ALUResult = {DBITS{1'bX}};
		endcase
	end
	else begin
		case (ALUFUNC)
			// handle primary opcodes
			LW, SW: ALUResult = A + B;
			JAL:  ALUResult = A + (B << WORDBITS);
			ADDI: ALUResult = A + B;
			ANDI: ALUResult = A & B;
			ORI:  ALUResult = A | B;
			XORI: ALUResult = A ^ B;
			BEQ: ALUResult = {{(DBITS-1){1'b0}}, A == B};
			BLT: ALUResult = {{(DBITS-1){1'b0}}, A < B};
			BLE: ALUResult = {{(DBITS-1){1'b0}}, A <= B};
			BNE: ALUResult = {{(DBITS-1){1'b0}}, A != B};
			default ALUResult = {DBITS{1'bX}};
		endcase
	end
	
endmodule
