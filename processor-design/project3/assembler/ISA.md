word size: 32 bits
opcode size: 5 bits
reg size: 5 bits
imm size: 17 bits

R-Type:
	OP rx, ry, rz
	sbz    rx    ry    rz    sbz  opcode2
	31:27  26:22 21:17 16:12 11:4 3:0

	SUB  01000
    NAND 01100
    NOR  01101
    NXOR 01110
    EQ   10000
    LT   10001
    LE   10010
    NE   10011
    ADD  11000
    AND  11100
    OR   11101
    XOR  11110

J-Type:
	OP rx, imm(ry)
	opcode rx    ry    imm
	31:27  26:22 21:17 16:0
    
    LW   01010
    SW   01110
    JAL  10111

I-Type:
	OP rx, ry, imm
	opcode rx    ry    imm
	31:27  26:22 21:17 16:0

	BEQ  10000
    BLT  10001
    BLE  10010
    BNE  10011
    ADDI 11000
    ANDI 11100
    ORI  11101
    XORI 11110

