 module Timer(CLK, CLK50, ADDRBUS, DATABUS, WE, RESET, IRQ);

	parameter BITS = 32;
	parameter TCNTBITS = 32'h4;
	parameter TLIMBITS = 32'h4;
	parameter CONTROLBITS = 32'h4;
	parameter BASE = 32'hFFFF0200;
	parameter COUNTMS = 50000;
	parameter TLIMBASE = BASE + TCNTBITS;
	parameter CTRLBASE = TLIMBASE + CONTROLBITS;
	parameter END = BASE + TCNTBITS + TLIMBITS + CONTROLBITS;

	input CLK, CLK50, WE, RESET;
	input unsigned [(BITS-1):0] ADDRBUS;
	inout [(BITS-1):0] DATABUS;
	output IRQ;

	// signals
	wire countEnable = ADDRBUS == BASE;
	wire limitEnable = ADDRBUS == TLIMBASE;
	wire controlEnable = ADDRBUS == CTRLBASE;
	
	wire readCount = !WE && countEnable;
	wire readLimit = !WE && limitEnable;
	wire readControl = !WE && controlEnable;
	
	wire writeCount = WE && countEnable;
	wire writeLimit = WE && limitEnable;
	wire writeControl = WE &&  controlEnable;
	
	wire limitReached = (limit > 0 && count >= (limit-1));
	wire msElapsed = msCounter >= COUNTMS;
	
	// status and data registers
	// control:
	// 0 - ready
	// 1 - overrun
   // 3 - interrupt enable	
	reg [(BITS-1):0] count, limit;
	reg [31:0] msCounter;
	reg ready, overrun, interruptEnable;
	
	wire [BITS-1:0] controlOut = {
		{BITS-4{1'b0}}, interruptEnable, 1'b0, overrun, ready
	};
	
	// put data on databus
	assign DATABUS = (readCount) ? count : 
	  (readLimit) ? limit : 
	  (readControl) ? controlOut : {BITS{1'bZ}};
	  
	// assign interrupt signal
	assign IRQ = ready && interruptEnable;
	
	always @(posedge CLK or posedge RESET) begin
		if (RESET) begin
		
			// reset device
			count <= {BITS{1'b0}};
			limit <= {BITS{1'b0}};
			ready <= 1'b0;
			overrun <= 1'b0;
			interruptEnable <= 1'b1;
			msCounter <= 32'b0;
		end
		else begin
			
			// update count
			if (writeCount) begin
				count <= DATABUS;
			end
			else if (msElapsed) begin
				count <= count + 1;
				msCounter <= 32'b0;
			end
			else if (limitReached)
				count <= {BITS{1'b0}}; 
			else
				msCounter <= msCounter + 1;
				
			// update limit
			if (writeLimit)
				limit <= DATABUS;
			
			// update control
			if (writeControl) begin
				ready <= DATABUS[0];
				interruptEnable <= DATABUS[4];
				if (DATABUS[1] == 1'b0)
					overrun <= 1'b0;
			end 
			else if (readCount || writeCount || writeLimit) begin
				ready <= 1'b0;
				overrun <= 1'b0;
			end
			else if (limitReached) begin
			   overrun <= ready;
				ready <= 1'b1;
			end
		end
	end

endmodule 