module lcd_ctrl(clk, reset, datain, cmd, cmd_valid, dataout, output_valid, busy);
input             clk;
input             reset;
input   [7:0]     datain;
input   [2:0]     cmd;
input             cmd_valid;
output  reg [7:0] dataout;
output  reg       output_valid;
output  reg       busy;

reg  [7:0] image_buf [0:35];
reg  [7:0] out_play [0:8];
reg  [5:0] count_in;//count when datain -> image_buf
reg  [3:0] count_out;//count when out_play -> dataout
reg  [2:0] cmd_use;//the input cmd
reg [2:0] x ;
reg [2:0] y ;
reg [3:0] count;//count when image_buf -> out_play

integer i;

wire  [7:0] loc [8:0];//record the output location 
reg sub_one ;//check if there had substract 1

assign loc[0] =  x + (y<<2) + (y<<1) ;//2 2 14
assign loc[1] =  x + (y<<2) + (y<<1) +1;
assign loc[2] =  x + (y<<2) + (y<<1) +2;
assign loc[3] =  x + (y<<2) + (y<<1) +6 ;
assign loc[4] =  x + (y<<2) + (y<<1) +6 +1;
assign loc[5] =  x + (y<<2) + (y<<1) +6 +2;
assign loc[6] =  x + (y<<2) + (y<<1) +12 ;
assign loc[7] =  x + (y<<2) + (y<<1) +12 +1;
assign loc[8] =  x + (y<<2) + (y<<1) +12 +2;

always@(posedge reset or posedge clk)
begin
    /* reset the variable */
    if(reset)
    begin
        dataout <= 8'b0;
        output_valid <= 0;
        busy <= 0;
        count_in <= 0;
        count_out <= 0;
        cmd_use <= 0;
        for(i=0;i<36;i=i+1)
            image_buf[i] <= 0 ;
        for(i=0;i<9;i=i+1)
            out_play[i] <= 0 ;
        count <= 0;
        x  <= 0;
        y <= 0;
        sub_one <= 0;
    end

    else
    begin
        if(cmd_valid && !busy)//when read the cmd(not read in or read out anything)
        begin
            cmd_use <= cmd;
            busy <= 1;
            count_in <= 0;
            count_out <= 0;
            sub_one <= 0;
        end

        else
        begin
            /* control the cmd */
            case(cmd_use)
                3'b000://reflash
                begin
                    x <= x;
                    y <= y;
                end
                3'b001://load data
                begin
                    x <= 3'b010;
                    y <= 3'b010;
                end
                3'b010://shift right
                begin
                    if(x<3'b011 && sub_one==0)
                    begin
                        x <= x+1;
                        sub_one <= 1;
                    end
                    else
                        x <= x;
                    y <= y;
                end
                3'b011://shift left
                begin
                    if(x>3'b000 && sub_one==0)
                    begin
                        x <= x-1;
                        sub_one <= 1;
                    end
                    else
                        x <= x;
                    y <= y;
                end
                3'b100://shift up
                begin
                    if(y>3'b000 && sub_one==0)
                    begin
                        y <= y-1;
                        sub_one <= 1;
                    end
                    else
                        y <= y;
                    x <= x;

                end
                3'b101://shift down
                begin
                    if(y<3'b011 && sub_one ==0)
                    begin
                        y <= y +1;
                        sub_one <= 1;
                    end
                    else
                        y <= y;
                    x <= x;
                end
            endcase

            if(count != 9)
            begin
                count <= count + 1 ;
                out_play[count] <= image_buf[loc[count]];
            end

            else
            begin
                count <= 0;
                //x <= x;
                //y <= y ;
            end

            /* control the input and output */
            if(count_in == 6'b100100)//36//start to output
            begin
                output_valid <= 1;

                if(count_out == 4'b1001)//9//start the new round
                begin
                    busy <= 0;
                    output_valid <= 0;
                end
                else
                begin
                    count_out <= count_out +1 ;
                    dataout <= out_play[count_out] ;
                end
            end
            else
            begin
                count_in <= count_in+1;
                output_valid <= output_valid ;
                if(cmd_use==3'b001)
                    image_buf[count_in] <= datain;
                else
                    image_buf[count_in] <=image_buf[count_in];
            end

            cmd_use <= cmd_use;
        end
    end
end

endmodule



