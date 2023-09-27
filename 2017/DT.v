module DT(
	input 					clk, 
	input					reset,
	output	reg				done ,
	output	reg				sti_rd ,
	output	reg 	[9:0]	sti_addr ,
	input			[15:0]	sti_di,
	output	reg				res_wr ,
	output	reg				res_rd ,
	output	reg 	[13:0]	res_addr ,
	output	reg 	[7:0]	res_do,
	input			[7:0]	res_di
	);

reg [3:0] current_state;
reg [3:0] next_state;
reg [7:0] tmp_min;
reg [3:0] counter;
parameter INITIAL = 1;
parameter READ_INIT = 2;
parameter WRITE_INIT = 3;
parameter WRITE_INIT_FINISH = 4; // delay 1 clk

parameter READ_FORWARD = 5; 
parameter FORWARD = 6;
parameter WRITE_FORWARD = 7; 
parameter FORWARD_FINISH = 8;

parameter READ_BACKWARD = 9; 
parameter BACKWARD = 10;
parameter WRITE_BACKWARD = 11;
parameter BACKWARD_FINISH = 12;

wire [7:0] add_one;
assign add_one = res_di +1;

// state register
always @(posedge clk or negedge reset) begin
	if(!reset)
		current_state = INITIAL;
	else 
		current_state = next_state;
end

// next state logic
always @(*) begin
	if(!reset)
		next_state = INITIAL;
	else 
	begin
		case (current_state)
		INITIAL:
			next_state = READ_INIT;
		READ_INIT:
			next_state = WRITE_INIT;
		WRITE_INIT:
		begin
			if(counter == 4'd15)
			begin
				if(res_addr == 14'd16383)
					next_state = WRITE_INIT_FINISH;
				else
					next_state = READ_INIT;
			end
			else
				next_state = WRITE_INIT;
		end
		WRITE_INIT_FINISH:
		begin
			next_state = READ_FORWARD;
		end
		READ_FORWARD:
		begin
			if(res_di)//物件像素
				next_state = FORWARD;
			else
			begin
				if(res_addr == 14'd16255) //16383-128 = 16255 //倒數第二行最右邊後面都是背景像素
					next_state = FORWARD_FINISH;
				else 
					next_state = READ_FORWARD;
			end
		end
		FORWARD:
		begin
			if(counter == 4'd5)
				next_state = WRITE_FORWARD;
			else
				next_state = FORWARD;
		end
		WRITE_FORWARD: 
		begin
			next_state = READ_FORWARD;
		end
		FORWARD_FINISH:
		begin
			next_state = READ_BACKWARD;
		end
		READ_BACKWARD:
		begin
			if(res_di)//物件像素
				next_state = BACKWARD;
			else
			begin
				if(res_addr == 14'd128)
					next_state = BACKWARD_FINISH;
				else 
					next_state = READ_BACKWARD;
			end
		end
		BACKWARD:
		begin
			if(counter == 4'd5)
				next_state = WRITE_BACKWARD;
			else
				next_state = BACKWARD;
		end
		WRITE_BACKWARD: 
		begin
			next_state = READ_BACKWARD;
		end
		BACKWARD_FINISH:
		begin
			next_state = BACKWARD_FINISH;
		end
		default:
			next_state = INITIAL;
		endcase
	end
end

/* output */
// 	sti_rd
always @(posedge clk or negedge reset) begin
	if(!reset)
		sti_rd <= 0;
	else if(next_state == READ_INIT)
		sti_rd <= 1;
	else
		sti_rd <= 0;
end
// 	sti_addr 
always @(posedge clk or negedge reset) begin
	if(!reset)
		sti_addr <= 0;
	else if(current_state == READ_INIT)
		sti_addr <= sti_addr +1;
end
// 	res_wr 
always @(posedge clk or negedge reset) begin
	if(!reset)
		res_wr <= 0;
	else if(next_state == WRITE_INIT || next_state == WRITE_FORWARD || next_state == WRITE_BACKWARD)
		res_wr <= 1;
	else
		res_wr <= 0;
end
// 	res_rd
always @(posedge clk or negedge reset) begin
	if(!reset)
		res_rd <= 0;
	else if(next_state == READ_FORWARD || next_state == READ_BACKWARD || next_state == FORWARD || next_state == BACKWARD)
		res_rd <= 1;
	else
		res_rd <= 0;
end
// 	res_addr 
always @(posedge clk or negedge reset) begin
	if(!reset)
		res_addr <= 14'd16383;
	else
	begin
		if(next_state == WRITE_INIT)
			res_addr <= res_addr +1;
		else if(current_state == WRITE_INIT_FINISH)
			res_addr <= 14'd129;
		else if(current_state == FORWARD_FINISH)
			res_addr <= 14'd16254;
		else if(current_state == FORWARD || next_state == FORWARD)
		begin
			case (counter)
				4'd0:
					res_addr <= res_addr - 129;//NW
				4'd1:
					res_addr <= res_addr + 1;//N
				4'd2:
					res_addr <= res_addr + 1;//NE
				4'd3:
					res_addr <= res_addr + 126;//W
				4'd4: 
					res_addr <= res_addr + 1;//PXY
			endcase
		end
		else if(current_state == BACKWARD || next_state == BACKWARD)
		begin
			case (counter)
				4'd0:
					res_addr <= res_addr + 129;//SE
				4'd1:
					res_addr <= res_addr - 1;//S
				4'd2:
					res_addr <= res_addr - 1;//SW
				4'd3:
					res_addr <= res_addr - 126;//E
				4'd4: 
					res_addr <= res_addr - 1;//PXY
			endcase
		end
		else if(current_state == WRITE_FORWARD || current_state == READ_FORWARD)
			res_addr <= res_addr +1;
		else if(current_state == WRITE_BACKWARD || current_state == READ_BACKWARD)
			res_addr <= res_addr -1;
	end
end
// 	res_do
always @(posedge clk or negedge reset) begin
	if(!reset)
		res_do <= 0;
	else
	begin
		if(next_state == WRITE_INIT)
			res_do <= sti_di[counter];
		else if(next_state == WRITE_FORWARD)
			res_do <= tmp_min +1;
		else if(next_state == WRITE_BACKWARD)
			res_do <= tmp_min;
	end
end
// 	done
always @(posedge clk or negedge reset) begin
	if(!reset)
		done <= 0;
	else if(current_state == BACKWARD_FINISH)
		done <= 1;
end

/* datapath */
// counter
always @(posedge clk or negedge reset) begin
	if(!reset)
	begin
		counter <= 4'd15;
	end
	else
	begin
		if(next_state == READ_INIT )
			counter <= 4'd15;
		else if(next_state == WRITE_INIT)
			counter <= counter - 1;//high byte to low byte
		else if(next_state == FORWARD || next_state == BACKWARD)
			counter <= counter + 1;
		else  if(next_state == WRITE_BACKWARD || next_state == WRITE_FORWARD)
			counter <= 0;
	end
end

//tmp_min
always @(posedge clk or negedge reset) begin
	if(!reset)
		tmp_min <= 0;
	else
	begin
		if(current_state == FORWARD)
		begin
			if(counter == 1)
				tmp_min <= res_di;
			else if(tmp_min > res_di)
				tmp_min <= res_di;
		end
		else if(current_state == READ_BACKWARD)//pxy
			tmp_min <= res_di;
		else if(current_state == BACKWARD)
		begin
			if(tmp_min > add_one )
				tmp_min <= add_one;
		end
	end
end

endmodule
