System Registers:

	IRA (Interrrupt Return Register)
		System Register 2
	IHA (Interrupt handler address)
		System Register 1
	IDN (Interrupt Device Number)
		System Register 3
	PCS (Processor Control Register)
		System Register 0
		bit[0]: global interrupt enable
		bot[1]: previous interrrupt enable
		bit[4]: control mode (user/system)
		bit[5]: previous control mode

New User Register:

	SSP (System Stack Pointer)
		User Register 24

System Instructions:

	R is user register, S is system register

	Op1: 00111 (5'h7)

	RETI
	op2: 5'h10
	{5'h7, 22'b0, 5'h10}

	RSR  Rx, Sy
	op2: 5'h11
	{5'h7, rx, sy, 12'b0, 5'h11}

	WSR Sx, Ry
	op2: 5'h12
	{5'h7, sx, ry, 12'b0, 5'h12}

	SYS
	op2: 5'h0
	{5'h7, 22'b0, 5'h0}

	    behavior:
		switch(A0):
			case 1: WRHEX <= A1
			case 2: RV <= RDHEX
			case 3: WRLEDG <= A1	
			case 4: RV <= RDLEDG
			case 5: WRLEDR <= A1
			case 6: RV <= RDHEX

R-Type:

	OP rz, rx, ry
	{5'h0, rx, ry, rz, 7'h0, op2}

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

	OP ry, imm(rx)
	{op1, rx, ry, imm}
    
    LW   01010
    SW   01110
    JAL  10111

I-Type:

	OP ry, rx, imm
	{op1, rx, ry, imm}

	BEQ  10000
    BLT  10001
    BLE  10010
    BNE  10011
    ADDI 11000
    ANDI 11100
    ORI  11101
    XORI 11110














