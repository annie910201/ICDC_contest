module geofence ( clk,reset,X,Y,valid,is_inside);
input clk;
input reset;
input [9:0] X;
input [9:0] Y;
output reg valid;
output reg is_inside;

reg [3:0] current_state;
reg [3:0] next_state;
parameter INIT = 0;
parameter READ = 1;
parameter SORT_POINT_12 = 2;
parameter SORT_POINT_23 = 3;
parameter SORT_POINT_34 = 4;
parameter SORT_POINT_45 = 5;
parameter CHECK_IN_FENCE_0 = 6;
parameter CHECK_IN_FENCE_1 = 7;
parameter CHECK_IN_FENCE_2 = 8;
parameter CHECK_IN_FENCE_3 = 9;
parameter CHECK_IN_FENCE_4 = 10;
parameter CHECK_IN_FENCE_5 = 11;
parameter OUTPUT = 12;
parameter PAUSE = 13;

reg [2:0] counter;
reg [9:0] X_buffer [0:5];
reg [9:0] Y_buffer [0:5];
reg [9:0] object_X;
reg [9:0] object_Y;
wire signed [20:0] mul;
wire signed [10:0] temp1;
wire signed [10:0] temp2;
reg [10:0] temp1_a;
reg [10:0] temp1_b;
reg [10:0] temp2_a;
reg [10:0] temp2_b;
assign temp1 = temp1_a - temp1_b;
assign temp2 = temp2_a - temp2_b;

reg signed [20:0] mul_temp;
reg all_sign;
assign mul = temp1 * temp2;
wire result_sign;
assign result_sign = (mul_temp < mul )? 1 : 0;
// state register
always @(posedge clk) begin
    if(reset)
        current_state <= INIT;
    else    
        current_state <= next_state;
end
// next state
always @(*) begin
    if(reset)
        next_state = INIT;
    else
    begin
        case (current_state)
            INIT: 
                next_state = READ;
            READ:
            begin
                if(counter == 3'd6)
                    next_state = SORT_POINT_12;
                else
                    next_state = READ;
            end
            SORT_POINT_12:
            begin
                if(counter == 3'd6)
                begin
                    if(result_sign == 1'b1)
                        next_state = SORT_POINT_23;
                    else
                        next_state = SORT_POINT_12;
                end
                else
                    next_state = SORT_POINT_12;
            end
            SORT_POINT_23:
            begin
                if(counter == 3'd6)
                begin
                    if(result_sign == 1'b1)
                        next_state = SORT_POINT_34;
                    else
                        next_state = SORT_POINT_12;
                end
                else
                    next_state = SORT_POINT_23;
            end
            SORT_POINT_34:
            begin
                if(counter == 3'd6)
                begin
                    if(result_sign == 1'b1)
                        next_state = SORT_POINT_45;
                    else
                        next_state = SORT_POINT_12;
                end
                else
                    next_state = SORT_POINT_34;
            end
            SORT_POINT_45:
            begin
                if(counter == 3'd6)
                begin
                    if(result_sign == 1'b1)
                        next_state = CHECK_IN_FENCE_0;
                    else
                        next_state = SORT_POINT_12;
                end
                else
                    next_state = SORT_POINT_45;
            end
            CHECK_IN_FENCE_0:
            begin
                if(counter == 3'd6)
                    next_state = (is_inside == 1)? CHECK_IN_FENCE_1 : OUTPUT;
                else
                    next_state = CHECK_IN_FENCE_0;
            end
                
            CHECK_IN_FENCE_1:
            begin
                if(counter == 3'd6)
                    next_state = (is_inside == 1)? CHECK_IN_FENCE_2 : OUTPUT;
                else
                    next_state = CHECK_IN_FENCE_1;
            end
            CHECK_IN_FENCE_2:
            begin
                if(counter == 3'd6)
                    next_state = (is_inside == 1)? CHECK_IN_FENCE_3 : OUTPUT;
                else
                    next_state = CHECK_IN_FENCE_2;
            end
            CHECK_IN_FENCE_3:
            begin
                if(counter == 3'd6)
                    next_state = (is_inside == 1)? CHECK_IN_FENCE_4 : OUTPUT;
                else
                    next_state = CHECK_IN_FENCE_3;
            end
            CHECK_IN_FENCE_4:
            begin
                if(counter == 3'd6)
                    next_state = (is_inside == 1)? CHECK_IN_FENCE_5 : OUTPUT;
                else
                    next_state = CHECK_IN_FENCE_4;
            end
            CHECK_IN_FENCE_5:
            begin
                if(counter == 3'd6)
                    next_state = OUTPUT;
                else
                    next_state = CHECK_IN_FENCE_5;
            end
            OUTPUT:
                next_state = PAUSE;
            PAUSE:
                next_state = READ;
        endcase
    end
end
//is_inside and all_sign
always @(posedge clk)
begin
    if(reset)
    begin
        is_inside <= 1'b1;
        all_sign <= 1'b0;
    end
    else if(current_state == CHECK_IN_FENCE_0)
    begin
        if(counter == 3'd5)
        begin
            if(mul_temp != mul)
                all_sign <= result_sign;
            else
                is_inside <= 1'b0;
        end

    end
    else if(current_state == CHECK_IN_FENCE_1 || current_state == CHECK_IN_FENCE_2 || current_state == CHECK_IN_FENCE_3 || current_state == CHECK_IN_FENCE_4 || current_state == CHECK_IN_FENCE_5)
    begin
        if(counter == 3'd5 && ( result_sign != all_sign || mul_temp == mul))
            is_inside <= 1'b0;
    end
    else if(current_state == OUTPUT)
        is_inside <= 1'b1;
end

//valid
always @(posedge clk)
begin
    if(reset)
        valid <= 1'b0;
    else if(next_state == OUTPUT)
        valid <= 1'b1;
    else
        valid <= 1'b0;
end

// counter
always @(posedge clk)
begin
    if(reset)
        counter <= 3'd0;
    else if (current_state == READ && counter == 3'd6)
        counter <= 3'd0;
    else if((current_state  == SORT_POINT_12 || current_state == SORT_POINT_23 || current_state == SORT_POINT_34 || current_state == SORT_POINT_45 || current_state == CHECK_IN_FENCE_0 || current_state == CHECK_IN_FENCE_1 || current_state == CHECK_IN_FENCE_2 || current_state == CHECK_IN_FENCE_3 || current_state == CHECK_IN_FENCE_4 || current_state == CHECK_IN_FENCE_5) && counter ==3'd6)
        counter <= 3'd0;
    else if(current_state == READ || current_state == SORT_POINT_12 || current_state == SORT_POINT_23 || current_state == SORT_POINT_34 || current_state == SORT_POINT_45 || current_state == CHECK_IN_FENCE_0 || current_state == CHECK_IN_FENCE_1 || current_state == CHECK_IN_FENCE_2 || current_state == CHECK_IN_FENCE_3 || current_state == CHECK_IN_FENCE_4 || current_state == CHECK_IN_FENCE_5)
        counter <= counter + 3'd1;
    else if(current_state == OUTPUT)
        counter <= 3'd0;
end

//X_buffer and Y_buffer and object_X and object_Y
always @(posedge clk)
begin
    if(reset)
    begin
        X_buffer[0] <= 0;
        X_buffer[1] <= 0;
        X_buffer[2] <= 0;
        X_buffer[3] <= 0;
        X_buffer[4] <= 0;
        X_buffer[5] <= 0;
        Y_buffer[0] <= 0;
        Y_buffer[1] <= 0;
        Y_buffer[2] <= 0;
        Y_buffer[3] <= 0;
        Y_buffer[4] <= 0;
        Y_buffer[5] <= 0;
        object_X <= 0;
        object_Y <= 0;
    end
    else
    begin
        if(next_state == READ && (current_state == INIT||current_state == PAUSE))
        begin
            object_X <= X;
            object_Y <= Y;
        end
        else if(current_state == READ)
        begin
            case (counter)
                3'd0:
                begin
                    X_buffer[0] <= X;
                    Y_buffer[0] <= Y;
                end
                3'd1:
                begin
                    X_buffer[1] <= X;
                    Y_buffer[1] <= Y;
                end
                3'd2:
                begin
                    X_buffer[2] <= X;
                    Y_buffer[2] <= Y;
                end
                3'd3:
                begin
                    X_buffer[3] <= X;
                    Y_buffer[3] <= Y;
                end
                3'd4:
                begin
                    X_buffer[4] <= X;
                    Y_buffer[4] <= Y;
                end
                3'd5:
                begin
                    X_buffer[5] <= X;
                    Y_buffer[5] <= Y;
                end
            endcase
        end
        else if(current_state == SORT_POINT_12)
        begin
            if(counter == 3'd5 && result_sign == 0)
            begin
                    X_buffer[2] <= X_buffer[1];
                    X_buffer[1] <= X_buffer[2];
                    Y_buffer[2] <= Y_buffer[1];
                    Y_buffer[1] <= Y_buffer[2];
            end
        end
        else if(current_state == SORT_POINT_23)
        begin
            if(counter == 3'd5 && result_sign == 0)
            begin
                    X_buffer[2] <= X_buffer[3];
                    X_buffer[3] <= X_buffer[2];
                    Y_buffer[2] <= Y_buffer[3];
                    Y_buffer[3] <= Y_buffer[2];
            end
        end
        else if(current_state == SORT_POINT_34)
        begin
            if(counter == 3'd5 && result_sign == 0)
            begin
                    X_buffer[4] <= X_buffer[3];
                    X_buffer[3] <= X_buffer[4];
                    Y_buffer[4] <= Y_buffer[3];
                    Y_buffer[3] <= Y_buffer[4];
            end
        end
        else if(current_state == SORT_POINT_45)
        begin
            if(counter == 3'd5 && result_sign == 0)
            begin
                    X_buffer[4] <= X_buffer[5];
                    X_buffer[5] <= X_buffer[4];
                    Y_buffer[4] <= Y_buffer[5];
                    Y_buffer[5] <= Y_buffer[4];
            end
        end
    end
end

// temp1 and tamp2 and mul_temp
always @(posedge clk) begin
    if(reset)
    begin
        temp1_a <= 10'b0;
        temp1_b <= 0;
        temp2_a <= 0;
        temp2_b <= 0;
        mul_temp <= 11'b0;
    end
    else if(current_state == SORT_POINT_12)
    begin
        case (counter)
            3'd0: 
            begin
                temp1_a <= {1'b0, X_buffer[1]};
                temp1_b <= {1'b0, X_buffer[0]};
                temp2_a <= {1'b0, Y_buffer[2]};
                temp2_b <= {1'b0, Y_buffer[0]};
            end
            3'd2:
                mul_temp <= mul;
            3'd3:
            begin
                temp1_a <= {1'b0, X_buffer[2]};
                temp1_b <= {1'b0, X_buffer[0]};
                temp2_a <= {1'b0, Y_buffer[1]};
                temp2_b <= {1'b0, Y_buffer[0]};
            end
        endcase
    end
    else if(current_state == SORT_POINT_23)
    begin
        case (counter)
            3'd0: 
            begin
                temp1_a <= {1'b0, X_buffer[2]};
                temp1_b <= {1'b0, X_buffer[0]};
                temp2_a <= {1'b0, Y_buffer[3]};
                temp2_b <= {1'b0, Y_buffer[0]};
            end
            3'd2:
                mul_temp <= mul;
            3'd3:
            begin
                temp1_a <= {1'b0, X_buffer[3]};
                temp1_b <= {1'b0, X_buffer[0]};
                temp2_a <= {1'b0, Y_buffer[2]};
                temp2_b <= {1'b0, Y_buffer[0]};
            end
        endcase
    end
    else if(current_state == SORT_POINT_34)
    begin
        case (counter)
            3'd0: 
            begin
                temp1_a <= {1'b0, X_buffer[3]};
                temp1_b <= {1'b0, X_buffer[0]};
                temp2_a <= {1'b0, Y_buffer[4]};
                temp2_b <= {1'b0, Y_buffer[0]};
            end
            3'd2:
                mul_temp <= mul;
            3'd3:
            begin
                temp1_a <= {1'b0, X_buffer[4]};
                temp1_b <= {1'b0, X_buffer[0]};
                temp2_a <= {1'b0, Y_buffer[3]};
                temp2_b <= {1'b0, Y_buffer[0]};
            end
        endcase
    end
    else if(current_state == SORT_POINT_45)
    begin
        case (counter)
            3'd0: 
            begin
                temp1_a <= {1'b0, X_buffer[4]};
                temp1_b <= {1'b0, X_buffer[0]};
                temp2_a <= {1'b0, Y_buffer[5]};
                temp2_b <= {1'b0, Y_buffer[0]};
            end
            3'd2:
                mul_temp <= mul;
            3'd3:
            begin
                temp1_a <= {1'b0, X_buffer[5]};
                temp1_b <= {1'b0, X_buffer[0]};
                temp2_a <= {1'b0, Y_buffer[4]};
                temp2_b <= {1'b0, Y_buffer[0]};
            end
        endcase
    end
    else if(current_state == CHECK_IN_FENCE_0)
    begin
        case(counter)

            3'd0: 
            begin
                temp1_a <= {1'b0, X_buffer[0]};
                temp1_b <= {1'b0, object_X};
                temp2_a <= {1'b0, Y_buffer[1]};
                temp2_b <= {1'b0, Y_buffer[0]};
            end
            3'd2:
                mul_temp <= mul;
            3'd3:
            begin
                temp1_a <= {1'b0, X_buffer[1]};
                temp1_b <= {1'b0, X_buffer[0]};
                temp2_a <= {1'b0, Y_buffer[0]};
                temp2_b <= {1'b0, object_Y};
            end
        endcase
    end
    else if(current_state == CHECK_IN_FENCE_1)
    begin
        case(counter)
            3'd0: 
            begin
                temp1_a <= {1'b0, X_buffer[1]};
                temp1_b <= {1'b0, object_X};
                temp2_a <= {1'b0, Y_buffer[2]};
                temp2_b <= {1'b0, Y_buffer[1]};
            end
            3'd2:
                mul_temp <= mul;
            3'd3:
            begin
                temp1_a <= {1'b0, X_buffer[2]};
                temp1_b <= {1'b0, X_buffer[1]};
                temp2_a <= {1'b0, Y_buffer[1]};
                temp2_b <= {1'b0, object_Y};
            end
        endcase
    end
    else if(current_state == CHECK_IN_FENCE_2)
    begin
        case(counter)
        3'd0: 
            begin
                temp1_a <= {1'b0, X_buffer[2]};
                temp1_b <= {1'b0, object_X};
                temp2_a <= {1'b0, Y_buffer[3]};
                temp2_b <= {1'b0, Y_buffer[2]};
            end
            3'd2:
                mul_temp <= mul;
            3'd3:
            begin
                temp1_a <= {1'b0, X_buffer[3]};
                temp1_b <= {1'b0, X_buffer[2]};
                temp2_a <= {1'b0, Y_buffer[2]};
                temp2_b <= {1'b0, object_Y};
            end
        
        endcase
    end
    else if(current_state == CHECK_IN_FENCE_3)
    begin
        case(counter)
        3'd0: 
            begin
                temp1_a <= {1'b0, X_buffer[3]};
                temp1_b <= {1'b0, object_X};
                temp2_a <= {1'b0, Y_buffer[4]};
                temp2_b <= {1'b0, Y_buffer[3]};
            end
            3'd2:
                mul_temp <= mul;
            3'd3:
            begin
                temp1_a <= {1'b0, X_buffer[4]};
                temp1_b <= {1'b0, X_buffer[3]};
                temp2_a <= {1'b0, Y_buffer[3]};
                temp2_b <= {1'b0, object_Y};
            end
        
        endcase
    end
    else if(current_state == CHECK_IN_FENCE_4)
    begin
        case(counter)
        3'd0: 
            begin
                temp1_a <= {1'b0, X_buffer[4]};
                temp1_b <= {1'b0, object_X};
                temp2_a <= {1'b0, Y_buffer[5]};
                temp2_b <= {1'b0, Y_buffer[4]};
            end
            3'd2:
                mul_temp <= mul;
            3'd3:
            begin
                temp1_a <= {1'b0, X_buffer[5]};
                temp1_b <= {1'b0, X_buffer[4]};
                temp2_a <= {1'b0, Y_buffer[4]};
                temp2_b <= {1'b0, object_Y};
            end
        
        endcase
    end
    else if(current_state == CHECK_IN_FENCE_5)
    begin
        case(counter)
        3'd0: 
            begin
                temp1_a <= {1'b0, X_buffer[5]};
                temp1_b <= {1'b0, object_X};
                temp2_a <= {1'b0, Y_buffer[0]};
                temp2_b <= {1'b0, Y_buffer[5]};
            end
            3'd2:
                mul_temp <= mul;
            3'd3:
            begin
                temp1_a <= {1'b0, X_buffer[0]};
                temp1_b <= {1'b0, X_buffer[5]};
                temp2_a <= {1'b0, Y_buffer[5]};
                temp2_b <= {1'b0, object_Y};
            end
        
        endcase
    end
end

endmodule

