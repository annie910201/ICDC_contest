module SET ( clk , rst, en, central, radius, mode, busy, valid, candidate );

input clk, rst;
input en;
input [23:0] central;
input [11:0] radius;
input [1:0] mode;
output reg busy;
output reg valid;
output reg [7:0] candidate;

reg [1:0] mode_use;
reg [3:0] current_state;
reg [3:0] next_state;
reg [3:0] counter;
reg in_a;
reg in_b;
reg [3:0] xa;
reg [3:0] ya;
reg [3:0] xb;
reg [3:0] yb;
reg [3:0] xc;
reg [3:0] yc;
reg [7:0] ra;
reg [7:0] rb;
reg [7:0] rc;
reg [3:0] x;
reg [3:0] y;
parameter INIT = 0;
parameter READ = 1;
parameter RADIUS_SQUARE = 2;
parameter MODE_0 = 3;
parameter MODE_1 = 4;
parameter MODE_2 = 5;
parameter MODE_3 = 6;
parameter OUTPUT = 7;
parameter PAUSE = 8;
reg signed [4:0] temp_mul;
reg [7:0] temp_add_1;
reg [7:0] temp_add_2;
reg [3:0] temp_sub_1;
reg [3:0] temp_sub_2;
wire [7:0] mul;
wire [7:0] add;
wire signed [4:0] sub; 
assign mul = temp_mul * temp_mul ;
assign add = temp_add_1 + temp_add_2;
assign sub = temp_sub_1 - temp_sub_2;
always @(posedge clk) begin
    if(rst)
        current_state <= INIT;
    else
        current_state <= next_state;    
end

always @(*) begin
    if(rst)
        next_state = INIT;
    else
    begin
        case (current_state)
            INIT:
                next_state = (en==1)?READ:INIT;
            READ:
                next_state = RADIUS_SQUARE;
            RADIUS_SQUARE:
            begin
                if(counter == 3'd4)
                begin
                    if(mode_use == 2'd0)
                        next_state = MODE_0;
                    else if(mode_use == 2'd1)
                        next_state = MODE_1;
                    else if(mode_use == 2'd2)
                        next_state = MODE_2;
                    else if(mode_use == 2'd3)
                        next_state = MODE_3;
                end
                else
                    next_state = RADIUS_SQUARE;
            end
            MODE_0:
            begin
                if(y == 4'd9)
                    next_state = OUTPUT;
                else
                    next_state = MODE_0;
            end
            MODE_1:
            begin
                if(y == 4'd9)
                    next_state = OUTPUT;
                else
                    next_state = MODE_1;
            end
            MODE_2:
            begin
                if(y == 4'd9)
                    next_state = OUTPUT;
                else
                    next_state = MODE_2;
            end
            MODE_3:
            begin
                if(y == 4'd9)
                    next_state = OUTPUT;
                else
                    next_state = MODE_3;
            end
            OUTPUT:
                next_state = PAUSE;
            PAUSE:
                next_state = READ;
        endcase
    end
end
//counter
always @(posedge clk) begin
    if(rst)
        counter <= 0;
    else if(current_state == READ)
        counter <= 0;
    else if(current_state == RADIUS_SQUARE)
    begin
        if(counter == 4'd4)
            counter <= 0;
        else
            counter <= counter +1;
    end
    else if(current_state == MODE_0)
    begin
        if(counter == 4'd4)
            counter <= 0;
        else
            counter <= counter + 1;
    end
    else if(current_state == MODE_1 || current_state == MODE_2)
    begin
        if(counter == 4'd7)
            counter <= 0;
        else
            counter <= counter + 1;
    end
    else if(current_state == MODE_3)
    begin
        if(counter == 4'd10)
            counter <= 0;
        else
            counter <= counter + 1;
    end
end

// x and y
always @(posedge clk) begin
    if(rst)
    begin
        x <= 1;
        y <= 1;
    end
    else if((current_state == MODE_0 && counter == 4'd4) || (current_state == MODE_1 && counter == 4'd7) || (current_state == MODE_2 && counter == 4'd7) ||  (current_state == MODE_3 && counter == 4'd10))
    begin
        if(x == 4'd8)
        begin
            x <= 1;
            y <= y + 1;
        end
        else
            x <= x + 1;
    end
    else if(current_state == OUTPUT)
    begin
        x <= 1;
        y <= 1;
    end
end

// candidate and in_a and in_b
always @(posedge clk) begin
    if(rst)
    begin
        candidate <= 0;
        in_a <= 0;
        in_b <= 0;
    end
    else if(current_state == MODE_0)
    begin
        if(counter == 4'd4)
        begin
            if(add <= ra)
                candidate <= candidate +1;
        end
    end
    else if(current_state == MODE_1)
    begin
        if(counter == 4'd4)
        begin
            if(add <= ra)
                in_a <= 1;
        end
        else if(counter == 4'd7)
        begin
            if(add <= rb && in_a)
                candidate <= candidate + 1;
            in_a <= 0;
        end
    end
    else if(current_state == MODE_2)
    begin
        if(counter == 4'd4)
        begin
            if(add <= ra)
                in_a <= 1;
        end
        else if(counter == 4'd7)
        begin
            if((add <= rb || in_a) && !(add <= rb && in_a))
                candidate <= candidate + 1;
            in_a <= 0;
        end
    end
    else if(current_state == MODE_3)
    begin
        if(counter == 4'd4)
        begin
            if(add <= ra)
                in_a <= 1;
        end
        else if(counter == 4'd7)
        begin
            if(add <= rb)
                in_b <= 1;
        end
        else if(counter == 4'd10)
        begin
            in_a <= 0;
            in_b <= 0;
            if(((in_a && in_b)||(in_a && add<= rc)||(in_b && add<= rc)) && !(in_a && in_b && add <= rc))
                candidate <= candidate + 1;
        end
    end
    else if(current_state == OUTPUT)
        candidate <= 0;
end
//busy 
always @(posedge clk) begin
    if(rst)
        busy <= 0;
    else if(current_state == READ)
        busy <= 1;
    else if(current_state == OUTPUT)
        busy <= 0;
end

//valid
always @(posedge clk) begin
    if(rst)
        valid <= 0;
    else if(next_state == OUTPUT)
        valid <= 1;
    else
        valid <= 0;
end

//x and y and mode_use and temp
always @(posedge clk) begin
    if(rst)
    begin
        xa <= 0;
        ya <= 0;
        xb <= 0;
        yb <= 0;
        xc <= 0;
        yc <= 0;
        ra <= 0;
        rb <= 0;
        rc <= 0;
        temp_mul <= 0;
        temp_sub_1 <= 0;
        temp_add_2 <= 0;
        temp_add_1 <= 0;
        temp_sub_2 <= 0;
    end
    else if(current_state == READ)
    begin
        xa <= central[23:20];
        ya <= central[19:16];
        xb <= central[15:12];
        yb <= central[11:8];
        xc <= central[7:4];
        yc <= central[3:0];
        ra <= {4'b0, radius[11:8]};
        rb <= {4'b0, radius[7:4]};
        rc <= {4'b0, radius[3:0]};
        mode_use <= mode;
    end
    else if(current_state == RADIUS_SQUARE)
    begin
        case (counter)
            4'd0:
                temp_mul <= ra;
            4'd1:
            begin
                ra <= mul;
                temp_mul <= rb;
            end
            4'd2:
            begin
                rb <= mul;
                temp_mul <= rc;
            end
            4'd3:
                rc <= mul;
        endcase
    end
    else if(current_state == MODE_0)
    begin
        case (counter)
        4'd0:
        begin
            temp_sub_1 <= xa;
            temp_sub_2 <= x;
        end
        4'd1:
        begin
            temp_mul <= sub;
            temp_sub_1 <= ya;
            temp_sub_2 <= y;
        end
        4'd2:
        begin
            temp_add_1 <= mul;
            temp_mul <= sub;
        end
        4'd3:
            temp_add_2 <= mul;

        endcase
    end
    else if(current_state == MODE_1 || current_state == MODE_2)
    begin
        case (counter)
        4'd0:
        begin
            temp_sub_1 <= xa;
            temp_sub_2 <= x;
        end
        4'd1:
        begin
            temp_mul <= sub;
            temp_sub_1 <= ya;
            temp_sub_2 <= y;
        end
        4'd2:
        begin
            temp_add_1 <= mul;
            temp_mul <= sub;
        end
        4'd3:
        begin
            temp_add_2 <= mul;
            temp_sub_1 <= xb;
            temp_sub_2 <= x;
        end
        4'd4:
        begin
            temp_mul <= sub;
            temp_sub_1 <= yb;
            temp_sub_2 <= y;
        end
        4'd5:
        begin
            temp_add_1 <= mul;
            temp_mul <= sub;
        end
        4'd6:
        begin
            temp_add_2 <= mul;
        end
        endcase
    end
    else if(current_state == MODE_3)
    begin
        case (counter)
        4'd0:
        begin
            temp_sub_1 <= xa;
            temp_sub_2 <= x;
        end
        4'd1:
        begin
            temp_mul <= sub;
            temp_sub_1 <= ya;
            temp_sub_2 <= y;
        end
        4'd2:
        begin
            temp_add_1 <= mul;
            temp_mul <= sub;
        end
        4'd3:
        begin
            temp_add_2 <= mul;
            temp_sub_1 <= xb;
            temp_sub_2 <= x;
        end
        4'd4:
        begin
            temp_mul <= sub;
            temp_sub_1 <= yb;
            temp_sub_2 <= y;
        end
        4'd5:
        begin
            temp_add_1 <= mul;
            temp_mul <= sub;
        end
        4'd6:
        begin
            temp_add_2 <= mul;
            temp_sub_1 <= xc;
            temp_sub_2 <= x;
        end
        4'd7:
        begin
            temp_mul <= sub;
            temp_sub_1 <= yc;
            temp_sub_2 <= y;
        end
        4'd8:
        begin
            temp_add_1 <= mul;
            temp_mul <= sub;
        end
        4'd9:
            temp_add_2 <= mul;
        endcase
    end
end
endmodule


