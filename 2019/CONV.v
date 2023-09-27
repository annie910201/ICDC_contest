
`timescale 1ns/10ps

module  CONV(clk,reset,busy,ready,iaddr,idata,cwr,caddr_wr,cdata_wr,crd,caddr_rd,cdata_rd,csel);
input						clk;
input						reset;
output	reg					busy;	
input						ready;	
		
output	reg 		[11:0] 	iaddr;
input 				[19:0]	idata;	

output	reg 				cwr;
output	reg 		[11:0]	caddr_wr;
output  reg signed 	[19:0]	cdata_wr;

output	reg 				crd;
output	reg  		[11:0]	caddr_rd;
input				[19:0] 	cdata_rd;

output	reg 		[2:0] 	csel;
reg signed [19:0] buffer[0:8];
reg 				[3:0] 	current_state;
reg 				[3:0] 	next_state;
reg 				[5:0]	center_x;
reg 				[5:0]	center_y;
reg 				[3:0]	counter;
reg 	signed			[44:0] 	sum ;// 9 * idata(20 bits) * kernel(20 bits) + bias(20 bits) * 9 = 2^20 * 2^20 * 9 + 2^20 * 9 ~= 2^40 * 9 ~= 2^40 * 16 = 2^44
reg write_over;
reg 				[2:0] 	counter_L0;
reg 	signed			[19:0]	max_L0;
reg pooling_over;
wire signed [20:0] tmp_sum;
wire [5:0] x_left;
wire [5:0] x_right;
wire [5:0] y_up;
wire [5:0] y_buttom;
parameter INITIAL = 0;
parameter READ = 1;
parameter CONVOLUTION = 2;
parameter RELU = 3;
parameter WR_L0 = 4;
parameter RD_L0 = 5;
parameter MAX_POOL = 6;
parameter WR_L1 = 7;
parameter FINISH = 8;

parameter signed K0 = 20'h0A89E;
parameter signed K1 = 20'h092D5;
parameter signed K2 = 20'h06D43;
parameter signed K3 = 20'h01004;
parameter signed K4 = 20'hF8F71;
parameter signed K5 = 20'hF6E54;
parameter signed K6 = 20'hFA6D7;
parameter signed K7 = 20'hFC834;
parameter signed K8 = 20'hFAC19;
parameter bias = 20'h01310;

assign tmp_sum = sum[35:15] + 20'd1;
assign x_left = center_x -1;
assign x_right = center_x + 1;
assign y_up = center_y -1;
assign y_buttom = center_y +1;
// state register
always @(posedge clk) begin
	if(reset)
		current_state = INITIAL;
	else
		current_state = next_state;
end

// next state logic 
always @(posedge clk) begin
	if(reset)
		next_state = INITIAL;
	else
	begin
		case(current_state)
		INITIAL:
		begin
			if(ready)
				next_state = READ;
		end
		READ:
		begin
			if(counter==4'd9)
				next_state = CONVOLUTION;
		end
		CONVOLUTION:
		begin
			if(counter == 4'd9)
				next_state = RELU;
		end
		RELU:
			next_state = WR_L0;
		WR_L0:
		begin
			if(write_over)
				next_state = RD_L0;
			else
				next_state = READ;
		end
		RD_L0:
		begin
			if(counter_L0 == 3'd4)
				next_state = WR_L1;
		end
		WR_L1:
		begin
			if(pooling_over)
				next_state = FINISH;
			else
				next_state = RD_L0;
		end
		FINISH:
			next_state = FINISH;
		endcase
	end
end

// output
always @(posedge clk) begin
	if(reset)
	begin
		busy <= 0;
		iaddr <= 0;
		cwr <= 0;
		caddr_wr <=0;
		cdata_wr <= 0;
		crd <= 0;
		caddr_rd <= 0;
		csel <= 0;
	end
	else
	begin
		if(ready)
			busy <= 1;
		else
			busy <= busy;
		if(current_state == READ)
			begin
			case(counter)
			4'd0:
				iaddr <= {y_up, x_left};
			4'd1:
				iaddr <= {y_up, center_x};
			4'd2:
				iaddr <= {y_up, x_right};
			4'd3:
				iaddr <= {center_y, x_left};
			4'd4:
				iaddr <= {center_y, center_x};
			4'd5:
				iaddr <= {center_y, x_right};
			4'd6:
				iaddr <= {y_buttom, x_left};
			4'd7:
				iaddr <= {y_buttom, center_x};
			4'd8:
				iaddr <= {y_buttom, x_right};
			endcase
		end
		else if(current_state == RD_L0)
		begin
			case(counter_L0)
			3'd0:
			begin
				caddr_rd <= {center_y,center_x};
			end
			3'd1:
			begin
				caddr_rd <= {center_y,x_right};
				cdata_wr <= cdata_rd ;
			end
			3'd2:
			begin
				caddr_rd <= {y_buttom,center_x};
				if(cdata_rd > cdata_wr)
					cdata_wr <= cdata_rd ;
			end
			3'd3:
			begin
				caddr_rd <= {y_buttom,x_right};
				if(cdata_rd > cdata_wr)
					cdata_wr <= cdata_rd ;
			end
			3'd4:
			begin
				if(cdata_rd > cdata_wr)
					cdata_wr <= cdata_rd ;
			end
			endcase
		end
		

		if(next_state == WR_L0 )
		begin
			if(sum[35])
				cdata_wr <= 0;
			else
				cdata_wr <= tmp_sum[20:1];//get the 20 bits// int: 2^4 * 2^4 * 9 ~= 2^12(bit 43 to 31), and get 4 bits int and 16 bits float)
			csel <= 3'b001;
			caddr_wr <= {center_y, center_x};
			cwr <= 1;
		end
			
		else if(next_state == RD_L0)
		begin
			csel <= 3'b001;
			cwr <= 0;
			crd <= 1;
			// cdata_wr <= max_L0;
		end
		else if(next_state == WR_L1)
		begin
			csel <= 3'b011;
			cwr <= 1;
			crd <= 0;
			caddr_wr <= {center_y[5:1], center_x[5:1]};
			
		end
		else if(next_state == FINISH)
		begin
			busy <= 0;
		end
		else
		begin
			cwr <= 0;
			// crd <= 0;
			// csel <= 0;
		end
	end	
end

//datepath
always @(posedge clk) begin
	if(reset)
	begin
		write_over <= 0;
		center_x <= 0;
		center_y <= 0;
		counter <= 0;
		sum <= 0;
		max_L0 <= 0;
		counter_L0 <= 0;
		pooling_over <= 0;
		buffer[0] <= 0;
		buffer[1] <= 0;
		buffer[2] <= 0;
		buffer[3] <= 0;
		buffer[4] <= 0;
		buffer[5] <= 0;
		buffer[6] <= 0;
		buffer[7] <= 0;
		buffer[8] <= 0;
	end
	else if (current_state == READ)
	begin
		sum <= 0;
		if(counter == 4'd9)
			counter <= 0;
		else
			counter <= counter +1;
		case(counter)
		4'd1:
		begin
			if(center_y!=0 && center_x !=0)
				buffer[0] <= idata;
			else
				buffer[0] <= 0;
		end
		4'd2:
		begin
			if(center_y!=0)
				buffer[1] <= idata;
			else
				buffer[1] <= 0;
		end
		4'd3:
		begin
		if(center_x!=6'd63 && center_y!=0)
				buffer[2] <= idata;
			else 
				buffer[2] <= 0;
		end
		4'd4:
		begin
			if(center_x!=0)
				buffer[3] <= idata;
			else 
				buffer[3] <= 0;
		end
		4'd5:
			buffer[4] <= idata;
		4'd6:
		begin
			if(center_x!=6'd63)
				buffer[5] <= idata;
			else 
				buffer[5] <= 0;
		end
		4'd7:
		begin
			if(center_x!=0 && center_y != 6'd63)
				buffer[6] <= idata;
			else 
				buffer[6] <= 0;
		end
		4'd8:
		begin
			if(center_y!=6'd63)
				buffer[7] <= idata;
			else 
				buffer[7] <= 0;
		end
		4'd9:
		begin
			if(center_y!=6'd63 && center_x!= 6'd63)
				buffer[8] <= idata;
			else 
				buffer[8] <= 0;
		end
		endcase
	end
	else if(current_state == CONVOLUTION)
	begin
		if(counter == 4'd9)
			counter <= 0;
		else
			counter <= counter +1;
		case(counter)
		4'd0:
			sum <= sum + buffer[0] * K0;
		4'd1:
			sum <= sum + buffer[1] * K1;
		4'd2:
			sum <= sum + buffer[2] * K2;
		4'd3:
			sum <= sum + buffer[3] * K3;
		4'd4:
			sum <= sum + buffer[4] * K4;
		4'd5:
			sum <= sum + buffer[5] * K5;
		4'd6:
			sum <= sum + buffer[6] * K6;
		4'd7:
			sum <= sum + buffer[7] * K7;
		4'd8:
			sum <= sum + buffer[8] * K8;
		4'd9:
			sum <= sum + {bias, 16'd0}; 
		endcase
	end
	else if(current_state == WR_L0)
	begin
		if(center_x == 6'd63 && center_y == 6'd63)
		begin
			write_over <= 1;
			counter_L0 <= 0;
			center_x <= 0;
			center_y <= 0;
		end
		else if(center_x==6'd63)
		begin
			center_x <= 0;
			center_y <= center_y +1;
		end
		else if(!write_over)
			center_x <= center_x + 1;
	end
	else if(current_state == RD_L0)
	begin
		counter_L0 <= counter_L0 + 1;
		// case(counter_L0)
		// 	2'd0:
		// 		max_L0 <= cdata_rd; 
		// 	2'd1:
		// 		if(max_L0 < cdata_rd)
		// 			max_L0 <= cdata_rd;
		// 	2'd2:
		// 		if(max_L0 < cdata_rd)
		// 			max_L0 <= cdata_rd;
		// 	2'd3:
		// 		if(max_L0 < cdata_rd)
		// 			max_L0 <= cdata_rd;
		// endcase
	end
	else if(current_state == WR_L1)
	begin
		counter_L0 <= 0;
		if(center_x == 6'd62 && center_y == 6'd62)
			pooling_over <= 1;
		else if(center_x == 6'd62)
		begin
			center_x <= 0;
			center_y <= center_y + 2;
		end
		else if(!pooling_over)
			center_x <= center_x + 2;
	end
end
endmodule