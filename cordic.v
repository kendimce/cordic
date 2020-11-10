	module sinosoidal(clk);
	
	input clk;
	parameter width = 16; //for more precision it can be increased
	parameter N = 31;

	integer i;
	
	reg signed [width-1:0] x [0:N], y [0:N];
	reg signed [width-1:0] x_out, y_out;

	wire signed [width-1:0] x_shr , y_shr;

	reg quad_done;
	reg [1:0] quadrant;

	reg [31:0] atan_table [0:31];
	reg [31:0] cos_table [0:31];
	
	reg signed  [31:0] desired_angle , quad_angle,current_angle;
	
	reg signed [31:0] sine_out, cosine_out;
	
	initial
	begin	
			
			i<=0;

			quad_done <=0;		//quad_done and quad_angle for prerotation	
			quad_angle<=0;		//the angle after prerotation

			desired_angle <= 32'b000000000101101100000101101100000; // starts with 1 degree
			current_angle<=0;

			//Starting with x,y =  ?
			x[0] <= 4096;
			y[0] <= 0;

			x_out<=0;
			y_out<=0;



			//Initializing Arctan table ,	cosine table, and x,y current
			$readmemb("atan_table.txt", atan_table);
			//$readmemb("cos_table.txt", cosine_table);

	end
			
		assign x_shr = x[i] >>> i;	//shifting right i times  //  multiplying by 2**-i
		assign y_shr = y[i] >>> i;	//shifting right i times  //  multiplying by 2**-i
	

	
	always@(posedge clk)
	begin		
		
		if (quad_done == 0)		//prerotation stage. output will be in first quadrant
		begin
			case(desired_angle[31:30])
			
			//2'00 : no need as it's already in first quadrant
			2'b00:
			begin
				quad_angle <= desired_angle;
			end
			2'b01:
			begin
				// substracting - 90 = 2^32*90 / 360 to put first quadrant
				quad_angle <= desired_angle - 32'b01000000000000000000000000000000; 
			end
			
			2'b10:
			begin
				//subtracting 180 degree to put it to first quadrant
				quad_angle <= desired_angle - 32'b10000000000000000000000000000000;

			end
			
			2'b11:
			begin
				// adding 90 degree = 2^32*90 / 360 to put first quadrant
				quad_angle <= desired_angle + 32'b01000000000000000000000000000000 - 32'b11111111111111111111111111111111;

			end
			endcase
			quad_done <= quad_done + 1;
		
		end

		else if( quad_done == 1)		// calculation by rotating.
		begin

			if(i <=31)
			begin
				

				if(current_angle < quad_angle)
				begin
					x[i+1] <= x[i] - y_shr;
					y[i+1] <= y[i] + x_shr;
					current_angle <= current_angle + atan_table[i];
				end
				else if(current_angle >= quad_angle)
				begin
					x[i+1] <= x[i] + y_shr;
					y[i+1] <= y[i] - x_shr;
					current_angle <= current_angle - atan_table[i];
				end			
					i <= i + 1;
			end
			
			else if(i>31)			// assign output based on rotated quadrant
			begin	

				case(desired_angle[31:30])

				
				2'b00:
				begin
					x_out <= x[31];
					y_out <= y[31];

				end

				2'b01:
				begin
					x_out <= -y[31];
					y_out <= x[31];

				end
				
				2'b10:
				begin
					x_out <= -x[31];
					y_out <= -y[31];
	
				end

				2'b11:
				begin

					x_out <= y[31];
					y_out <= -x[31];
				end
				endcase

				//add 1 degree. sampling rate 360/1 = 360 Hz
				desired_angle <= desired_angle + 32'b000000000101101100000101101100000;
				
				current_angle<=0;
				quad_angle<=0;
				i<=0;
				quad_done<=0;
				
			end
			
		end
	end

	endmodule