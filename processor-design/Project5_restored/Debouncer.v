 module Debouncer(CLK, RESET, DIN, DOUT);
 
	parameter FRQ = 50000000; // number of clock cycles in 1s
	parameter TIME = 1; // number of milliseconds to wait
	parameter BITS = 32;
	parameter COUNTEREND = (FRQ >> 3)*TIME;
 
	input CLK, RESET;
	input [BITS-1:0] DIN;
	output [BITS-1:0] DOUT;
	
	reg [31:0] counter = 0;
	reg [(BITS-1):0] oldData;
	reg [(BITS-1):0] goodData;
	wire isDataGood = (counter >= COUNTEREND);
	assign DOUT = goodData;
	
	always @(posedge CLK) begin
	
		if (RESET)
			counter <= 32'b0;
		else begin
			// update oldData
			oldData <= DIN;
			
			if (!isDataGood) begin
				if (oldData == DIN)
					// data is settling, 
					// increment counter
					counter <= counter + 32'b1;
				else 
					// data has changed,
					// reset counter
					counter <= 32'b0;
			end
			else begin
				// data is settled. reset counter
				// and update data out
				counter <= 32'b0;
				goodData <= oldData;
		end
		end
	end
 endmodule
 