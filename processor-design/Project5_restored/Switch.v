module Switch(CLK, ADDRBUS, DATABUS, WE, RESET, DEVICE, IRQ);

	parameter BITS = 32;
	parameter DEVICEBITS = 10;
	parameter CONTROLBITS = 4;
	parameter BASE = 32'hFFFF0120;
	parameter CONTROLBASE = BASE + DEVICEBITS;
	parameter END = CONTROLBASE + CONTROLBITS;

	input CLK, WE, RESET;
	input unsigned [(BITS-1):0] ADDRBUS;
	inout [(BITS-1):0] DATABUS;
	input [(DEVICEBITS-1):0] DEVICE;
	output IRQ;

	// signals
	wire deviceEnable = ADDRBUS == BASE;
	wire controlEnable = ADDRBUS == CONTROLBASE;
	
	wire readEnable = !WE && deviceEnable;
	wire readControl = !WE && controlEnable;
	wire writeControl = WE && controlEnable;
	
	// status and data registers
	// control:
	// 0 - ready
	// 1 - overrun
   // 3 - interrupt enable	
	reg [(DEVICEBITS-1):0] data;
	wire [(DEVICEBITS-1):0] dataWire;
	reg ready, overrun, interruptEnable;
	
	// read from Switch device
	// (debounced)
	Debouncer #(
		.FRQ(50000000),
		.TIME(1),
		.BITS(BITS)
	) debounce(
		.CLK(CLK), 
		.RESET(RESET), 
		.DIN(DEVICE), 
		.DOUT(dataWire)
	);
	
	wire [BITS-1:0] controlOut = {
		{BITS-4{1'b0}}, interruptEnable, 1'b0, overrun, ready
	};
	
	// put data on databus
	assign DATABUS = (readEnable) ? 
	  data : (readControl) ? 
	  controlOut :  {BITS{1'bZ}};
	
   // assign interrupt signal
	assign IRQ = ready && interruptEnable;
	
	always @(posedge CLK or posedge RESET) begin
		if (RESET) begin
		
			// reset device
			data <= {DEVICEBITS{1'b0}};
			ready <= 1'b0;
			overrun <= 1'b0;
			interruptEnable <= 1'b1;
		end
		else begin			
			// update data register if dataWire
			// has changed
			if (data != dataWire) begin
				data <= dataWire;
				// set overrun bit if 
				// ready bit is set
				overrun = ready;
				ready = 1'b1;
			end
			
			// write to control registers
			// update control
			if (writeControl) begin
				ready <= DATABUS[0];
				interruptEnable <= DATABUS[4];
				if (DATABUS[1] == 1'b0)
					overrun <= 1'b0;
			end 
			else if (readEnable) begin
				ready <= 1'b0;
				overrun <= 1'b0;
			end
		end
	end

endmodule 