module Hex(CLK, ADDRBUS, DATABUS, WE, RESET, DEVICE0, DEVICE1, DEVICE2, DEVICE3);

	parameter BITS = 32;
	parameter DEVICEDBITS = 16;
	parameter DEVICEBITS = 7;
	parameter BASE = 32'hFFFF0000;
	parameter END = BASE + DEVICEDBITS;

	input CLK, WE, RESET;
	input unsigned [(BITS-1):0] ADDRBUS;
	inout [(BITS-1):0] DATABUS;
	output [(DEVICEBITS-1):0] DEVICE0, DEVICE1, DEVICE2, DEVICE3;

	// signals
	wire deviceEnable = ADDRBUS == BASE;
	wire readEnable = !WE && deviceEnable;
	wire writeEnable = WE && deviceEnable;
	
	// data register
	reg [(DEVICEDBITS-1):0] data;
	
	// reg to hold data to write
	SevenSeg ss3(.OUT(DEVICE3),.IN(data[15:12]));
	SevenSeg ss2(.OUT(DEVICE2),.IN(data[11:8]));
	SevenSeg ss1(.OUT(DEVICE1),.IN(data[7:4]));
	SevenSeg ss0(.OUT(DEVICE0),.IN(data[3:0]));
	
	// put data on databus
	assign DATABUS = (readEnable) ? data : {BITS{1'bZ}};
	
	always @(posedge CLK or posedge RESET) begin
		if (RESET) begin
			// reset device
			data <= {DEVICEDBITS{1'b0}};
		end
		else begin
			// write to hex
			if (writeEnable)
				data <= DATABUS[DEVICEDBITS-1:0];
		end
	end

endmodule  