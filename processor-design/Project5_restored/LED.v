 module LED(CLK, ADDRBUS, DATABUS, WE, RESET, DEVICE);

	parameter BITS = 32;
	parameter DEVICEBITS = 8;
	parameter BASE = 32'hFFFF0100;
	parameter END = BASE + DEVICEBITS;

	input CLK, WE, RESET;
	input unsigned [(BITS-1):0] ADDRBUS;
	inout [(BITS-1):0] DATABUS;
	output [(DEVICEBITS-1):0] DEVICE;

	// signals
	wire deviceEnable = ADDRBUS == BASE;
	wire readEnable = !WE && deviceEnable;
	wire writeEnable = WE && deviceEnable;
	
	// data register	
	reg [(DEVICEBITS-1):0] data;
	
	// hook up data register to output
	assign DEVICE = data;
	
	// put data on databus
	assign DATABUS = (readEnable) ? data : {BITS{1'bZ}};
	
	always @(posedge CLK or posedge RESET) begin
		if (RESET) begin
			// reset device
			data <= {DEVICEBITS{1'b0}};
		end
		else begin	
			if (writeEnable)
				// write to device
				data <= DATABUS[DEVICEBITS-1:0];
		end
	end

endmodule 