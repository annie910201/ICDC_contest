module LCD_CTRL(clk, reset, cmd, cmd_valid, IROM_Q, IROM_rd, IROM_A, IRAM_valid, IRAM_D, IRAM_A, busy, done);
input clk;
input reset;
input [3:0] cmd;
input cmd_valid;
input [7:0] IROM_Q;
output reg IROM_rd;
output reg [5:0] IROM_A;
output reg IRAM_valid;
output reg [7:0] IRAM_D;
output reg [5:0] IRAM_A;
output reg busy;
output reg done;

reg [3:0] cmd_use;
reg [1:0] current_state;
reg [1:0] next_state;
reg [7:0] buffer [7:0][7:0];
reg [2:0] out_addr_x;
reg [2:0] out_addr_y;
reg [5:0] read_in_add;//read in buffer
reg [5:0] point_x;
reg [5:0] point_y;
reg out_over;
integer i;
integer j;
reg modified;

wire [7:0] right_up;
wire [7:0] right_down;
wire [7:0] left_up;
wire [7:0] left_down;

reg [7:0] replace_value;

assign right_up = buffer[point_y][point_x+1];
assign right_down = buffer[point_y+1][point_x+1];
assign left_up = buffer[point_y][point_x];
assign left_down = buffer[point_y+1][point_x];

/* current_state */
always @(posedge clk)
begin
    if(reset)
    begin
        current_state = 0;
    end
    else
    begin
        current_state = next_state;
    end
end

/* next_state */
always@(current_state or cmd_valid or reset or read_in_add)
begin
    if(reset)
    begin
        next_state = 0;
    end
    else
    begin
        case (current_state)
            2'd0://read in buffer
            begin
                if(read_in_add == 6'd63)
                begin
                    next_state = 2'd1;
                end
                else
                begin
                    next_state = current_state;
                end
            end
            2'd1://read in cmd
            begin
                if(cmd_valid)
                begin
                    next_state = 2'd2;
                end
                else
                begin
                    next_state = current_state;
                end
            end
            2'd2://do
            begin
                if(cmd_use==0)
                    next_state = 2'd3;
                else
                    next_state = 2'd1;
            end
            2'd3://output
            begin
                next_state = 2'd3;
            end

        endcase
    end
end

/* output */
always@(posedge clk)
begin
    if(reset==1)
    begin
        busy <= 1;
        IROM_rd <= 1;
        out_addr_x<= 0 ;
        out_addr_y <= 0 ;
        read_in_add <= 0;
        IROM_A <= 0;
        done <= 0;
        out_over <= 0;
    end
    else
    begin
        case (current_state)
            2'd0:
            begin
                if(read_in_add == 6'd63)
                begin
                    busy <= 0;
                    IROM_rd <= 0;
                end
                else
                begin
                    busy <= 1;
                    IROM_A <= read_in_add+1;
                    read_in_add <= read_in_add +1;
                end
            end
            2'd1:
            begin
                if(cmd_valid)
                begin
                    busy <= 1;
                    cmd_use <= cmd;
                end

                else
                begin
                    busy <= busy;
                    cmd_use <= cmd_use;
                end

            end
            2'd2:
            begin
                busy <= 0;
            end
            2'd3:
            begin
                if(cmd_use==0)
                begin
                    IRAM_valid <= 1;
                    IRAM_A <= (out_addr_y<<3) + out_addr_x;//addr = 8 * x + y
                    IRAM_D <= buffer[out_addr_y][out_addr_x];
                    if(out_over)
                    begin
                        done <= 1;
                        IRAM_valid <= 0;
                        busy <= 0;
                    end

                    if(out_addr_x < 3'b111)
                        out_addr_x <= out_addr_x +1;
                    else if(out_addr_y<3'b111)
                    begin
                        out_addr_y <= out_addr_y +1;
                        out_addr_x <= 0;
                    end
                    else
                    begin
                        out_over <= 1;
                    end
                end
            end
        endcase
    end
end

/* deal with cmd */
always @(posedge clk)
begin
    if(reset)
    begin
        point_x = 3;
        point_y = 3;
        for(i=0;i<8;i=i+1)
        begin
            for(j = 0;j<8;j=j+1)
                buffer[i][j] = 0;
        end
        modified = 0;
    end
    else if(current_state==2'd0)
    begin
        if(read_in_add == 6'd63)
        begin
            buffer[7][7] = IROM_Q;
        end
        else
        begin
            buffer[read_in_add>>3][read_in_add%8] = IROM_Q ;
        end
    end
    else if(current_state == 2'd1)
    begin
        modified = 0;
    end
    else if(current_state == 2'd2 && modified==0)
    begin
        modified = 1;
        case (cmd_use)
            4'b0001://shift up
            begin
                if(point_y > 0)
                    point_y = point_y - 1 ;
            end
            4'b0010://shift down
            begin
                if(point_y < 6)
                    point_y = point_y + 1 ;
            end
            4'b0011:
            begin
                if(point_x > 0)
                    point_x = point_x - 1 ;
            end
            4'b0100:
            begin
                if(point_x < 6)
                    point_x = point_x + 1 ;
            end
            4'b0101://MAX
            begin
                replace_value = right_down;
                if(right_up > replace_value)
                    replace_value = right_up;
                if(left_down > replace_value)
                    replace_value = left_down;
                if(left_up > replace_value )
                    replace_value = left_up;
                buffer[point_y][point_x] = replace_value;
                buffer[point_y+1][point_x] = replace_value;
                buffer[point_y][point_x+1] = replace_value;
                buffer[point_y+1][point_x+1] = replace_value;
            end
            4'b0110://MIN
            begin
                replace_value = right_down;
                if(right_up < replace_value)
                    replace_value = right_up;
                if(left_down < replace_value)
                    replace_value = left_down;
                if(left_up < replace_value )
                    replace_value = left_up;
                buffer[point_y][point_x] = replace_value;
                buffer[point_y+1][point_x] = replace_value;
                buffer[point_y][point_x+1] = replace_value;
                buffer[point_y+1][point_x+1] = replace_value;
            end
            4'b0111://AVERAGE
            begin
                replace_value = (left_down + left_up + right_down+ right_up )/4;
                buffer[point_y][point_x] = replace_value;
                buffer[point_y+1][point_x] = replace_value;
                buffer[point_y][point_x+1] = replace_value;
                buffer[point_y+1][point_x+1] = replace_value;
            end
            4'b1000://Counterclockwise Rotation
            begin
                replace_value = left_up;
                buffer[point_y][point_x] = buffer[point_y][point_x+1];
                buffer[point_y][point_x+1] = buffer[point_y+1][point_x+1];
                buffer[point_y+1][point_x+1] = buffer[point_y+1][point_x];
                buffer[point_y+1][point_x] = replace_value;
            end
            4'b1001://Clockwise Rotation)
            begin
                replace_value = left_up;
                buffer[point_y][point_x] = buffer[point_y+1][point_x];
                buffer[point_y+1][point_x] = buffer[point_y+1][point_x+1];
                buffer[point_y+1][point_x+1] = buffer[point_y][point_x+1];
                buffer[point_y][point_x+1] = replace_value;
            end
            4'b1010://Mirror X
            begin
                replace_value = left_up;
                buffer[point_y][point_x] = buffer[point_y+1][point_x];
                buffer[point_y+1][point_x] = replace_value;
                replace_value = right_up;
                buffer[point_y][point_x+1] = buffer[point_y+1][point_x+1];
                buffer[point_y+1][point_x+1] = replace_value;
            end
            4'b1011:
            begin
                replace_value = left_up;
                buffer[point_y][point_x] = buffer[point_y][point_x+1];
                buffer[point_y][point_x+1] = replace_value;
                replace_value = left_down;
                buffer[point_y+1][point_x] = buffer[point_y+1][point_x+1];
                buffer[point_y+1][point_x+1] = replace_value;
            end
        endcase
    end
end

endmodule



