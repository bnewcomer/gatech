// Benjamin Newcomer & Casey Evanish
// Gatech CS 3220 Project 1
// Feb 9, 2015

module Project1(SW,KEY,LEDR,LEDG,HEX0,HEX1,HEX2,HEX3,CLOCK_50);
	input  [9:0] SW;
	input  [3:0] KEY;
	input  CLOCK_50;
	output [9:0] LEDR;
	output [7:0] LEDG;
	output [6:0] HEX0,HEX1,HEX2,HEX3;
	
	// clock modes
	parameter DISPLAY_MODE = 1'b0;
	parameter SET_MODE = 1'b1;
	parameter NO_TRANSITION = 1'b0;
	parameter TRANSITION = 1'b1;
	
	// Project1 uses the existing 50MHz clock (no need for a PLL)
	wire clk=CLOCK_50;
	
	// disables the screen for blinking in clock-set mode
	reg displayOff;
	
	// stores current clock mode
	reg mode = DISPLAY_MODE;
	
	// stores key presses (1 = pressed)
	// and old key presses so that the system
	// can take action on key press transitions
	reg [3:0] oldKEY = 4'b0;
	wire [3:0] keyTransition;
	
	// register to keep track of time transitions (minutes or hours)
	// if a time transition occurs, then the oldKey register is not
	// updated. This means button presses are ignored, but will be 
	// registered in the next clock cycle, after the time transition happens
	reg timeTransition = NO_TRANSITION;
	
	// Counters for centiseconds (100th of a second), 
	// deciseconds (1/10 second), seconds
	reg [18:0] waitcentisec = 19'd0;
	reg [3:0]  valcentisec = 4'd0;
	reg [3:0] valdecisec = 4'd0;
	reg [5:0] valsec = 6'd58;
	
	// create regs for the individual decimal digits
	// of minutes and hours (these will be displayed)
	reg [3:0] minLSD = 4'd0;
	reg [3:0] minMSD = 4'd0;
	reg [3:0] hourLSD = 4'd0;
	reg [3:0] hourMSD = 4'd0;
	
	// always block
	always @(posedge clk) begin
	
		// set clock mode
		mode <= SW[0] ? SET_MODE : DISPLAY_MODE;
		
		// increment and reset appropriate counters
		waitcentisec <= waitcentisec + 19'b1;
		
		// register no time transition. this can be
		// overwritten lower in the following if block
		timeTransition <= NO_TRANSITION;
		
		if (waitcentisec == 19'd499999) begin
			// execute each centisecond
			waitcentisec <= 19'd0;
			valcentisec <= valcentisec + 4'd1;
			
			if (valcentisec == 4'd9) begin
				// execute each decisecond
				valcentisec <= 4'd0;
				valdecisec <= valdecisec + 4'd1;
				
				if (valdecisec == 4'd9) begin
					// execute each second
					valdecisec <= 4'd0;
					valsec <= valsec + 6'd1;
					
					if (valsec == 6'd59) begin
						// register than a display transition
						// is happening
						timeTransition <= TRANSITION;
					
						// execute each minute
						// XX:XX:59
						valsec <= 6'd0;
						minLSD <= minLSD + 4'd1;
						
						if (minLSD == 4'd9) begin
							// execute every 10 minutes
							// XX:X9:59
							minLSD <= 4'd0;
							minMSD <= minMSD + 4'd1;
							
							if (minMSD == 4'd5) begin
								// execute every 59 minutes
								// XX:59:59
								minMSD <= 4'd0;
								hourLSD <= hourLSD + 4'd1;
								
								if (hourLSD == 4'd9) begin
									// execute every 10 hours
									// X9:59:59
									hourLSD <= 4'd0;
									hourMSD <= hourMSD + 4'd1;
								end
								else if (hourLSD == 4'd3 && hourMSD == 4'd2) begin
									// execute once every 24 hours
									// 23:59:59
									hourLSD <= 4'd0;
									hourMSD <= 4'd0;
								end
							end //if (minMSD == 4'd5)
						end //if (minLSD == 4'd9)
					end //if (valsec == 6'd59)
				end //if (valdecisec == 4'd9)
			end //if (valcentisec == 4'd9)
		end //if (waitcentisec == 19'd499999)
		
		// mode specific behavior
		case (mode)
			SET_MODE: begin
				// blinking action
				displayOff <= valdecisec < 5;
				
				if (timeTransition == NO_TRANSITION) begin
					// move record of key presses to old key presses
					oldKEY <= KEY;
					
					// check key press transitions
					if (keyTransition[0]) begin
						// decrement minute, reset seconds
						if (minLSD == 4'd0) begin
							// XX:X0
							minLSD <= 4'd9;
							minMSD <= (minMSD == 4'd0) ? 4'd5 : minMSD - 4'd1;
						end else 
							// XX:X[1-9]
							minLSD <= minLSD - 4'd1;
						valsec <= 6'd0;
					end
					if (keyTransition[1]) begin
						// increment minutes, reset seconds
						if (minLSD == 4'd9) begin
							// XX:X9
							minLSD <= 4'd0;
							minMSD <= (minMSD == 4'd5) ? 4'd0 : minMSD + 4'd1;
						end else
							// XX:X[1-9]
							minLSD <= minLSD + 4'd1;
						valsec <= 4'd0;
					end
					if (keyTransition[2]) begin
						// decrement hour
						if (hourLSD == 4'd0) begin
							if (hourMSD == 4'd0) begin
								// 00:XX
								hourLSD <= 4'd3;
								hourMSD <= 4'd2;
							end else begin
								// X0:XX
								hourLSD <= 4'd9;
								hourMSD <= hourMSD - 4'd1;
							end
						end else
							// X[1-9]:XX
							hourLSD <= hourLSD - 4'd1;
					end
					if (keyTransition[3]) begin
						// increment hour
						// check for 23:XX
						if (hourMSD == 4'd2 && hourLSD == 4'd3) begin
							// 23:XX
							hourLSD <= 4'd0;
							hourMSD <= 4'd0;
						end else begin
							// X9:XX
							if (hourLSD == 4'd9) begin
								hourLSD <= 4'd0;
								hourMSD <= hourMSD + 4'd1;
							end else
								// XX:XX
								hourLSD <= hourLSD + 4'd1;
						end
					end
				end //if (timeTransition == NO_TRANSITION)
			end //SET_MODE:
			DISPLAY_MODE: begin
				// enable display
				displayOff <= 0;
			end
			default:;
		endcase
		
	end
	
	// Dispay minutes and hours on HEX
	wire [3:0] digit0 = minLSD;
	wire [3:0] digit1 = minMSD;
	wire [3:0] digit2 = hourLSD;
	wire [3:0] digit3 = hourMSD;
	
	// put seconds display on LEDG[6:0]
	// display nothing if displayOff is 1
	assign LEDG = displayOff ? 8'b0 : {2'b0, valsec};
		
	// generate array of key press transitions. These signals
	// are true for only one cycle per key press
	assign keyTransition = 
		{{!KEY[3] && oldKEY[3]},
		 {!KEY[2] && oldKEY[2]},
		 {!KEY[1] && oldKEY[1]},
		 {!KEY[0] && oldKEY[0]}};

	
	// Decode 4-bit values into 7-segment patterns
	SevenSeg s0(.IN(digit0), .OUT(HEX0), .DISABLE(displayOff));
	SevenSeg s1(.IN(digit1), .OUT(HEX1), .DISABLE(displayOff));
	SevenSeg s2(.IN(digit2), .OUT(HEX2), .DISABLE(displayOff));
	SevenSeg s3(.IN(digit3), .OUT(HEX3), .DISABLE(displayOff));
endmodule
