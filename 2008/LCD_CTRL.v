module LCD_CTRL(clk, reset, datain, cmd, cmd_valid, dataout, output_valid, busy);
input             clk;
input             reset;
input       [7:0] datain;
input       [2:0] cmd;
input             cmd_valid;
output  reg [7:0] dataout;
output  reg       output_valid;
output  reg       busy;

reg  [7:0] image_buf [107:0];
reg  [7:0] out_play [15:0];
reg  [6:0] count_in;//count when datain -> image_buf  1111111 127
reg  [4:0] count_out;//count when out_play -> dataout  11111 31
reg  [2:0] cmd_use;//the input cmd  111 7
reg [3:0] x ; //1111 15
reg [3:0] y ;//1111 15
reg [4:0] count;//count when image_buf -> out_play

integer i;

wire  [7:0] loc [15:0];//record the output location
wire  [7:0] loc_zoomfit [15:0];//record the output location
/* d,10,13,16,25,28,2b,2e,3d,40,43,46,55,58,5b,5e */

reg sub_one ;//check if there had substract 1
reg zoomin;

assign loc[0] =  x + (y<<3) + (y<<2) -24-2; //6 5 40
assign loc[1] =  x + (y<<3) + (y<<2) -24-1;
assign loc[2] =  x + (y<<3) + (y<<2) -24;
assign loc[3] =  x + (y<<3) + (y<<2) -24+1;
assign loc[4] =  x + (y<<3) + (y<<2) -12-2 ;
assign loc[5] =  x + (y<<3) + (y<<2) -12-1 ;
assign loc[6] =  x + (y<<3) + (y<<2) -12 ;
assign loc[7] =  x + (y<<3) + (y<<2) -12+1 ;
assign loc[8] =  x + (y<<3) + (y<<2) -2 ;
assign loc[9] =  x + (y<<3) + (y<<2) -1 ;
assign loc[10] =  x + (y<<3) + (y<<2)  ;
assign loc[11] =  x + (y<<3) + (y<<2) +1 ;
assign loc[12] =  x + (y<<3) + (y<<2) +12-2 ;
assign loc[13] =  x + (y<<3) + (y<<2) +12-1 ;
assign loc[14] =  x + (y<<3) + (y<<2) +12 ;
assign loc[15] =  x + (y<<3) + (y<<2) +12+1 ;

assign loc_zoomfit[0] =  32'hd; //6 5 40
assign loc_zoomfit[1] =  32'h10;
assign loc_zoomfit[2] =  32'h13;
assign loc_zoomfit[3] =  32'h16;
assign loc_zoomfit[4] =  32'h25;
assign loc_zoomfit[5] = 32'h28;
assign loc_zoomfit[6] =  32'h2b;
assign loc_zoomfit[7] =  32'h2e;
assign loc_zoomfit[8] =  32'h3d;
assign loc_zoomfit[9] =  32'h40;
assign loc_zoomfit[10] =  32'h43;
assign loc_zoomfit[11] =  32'h46;
assign loc_zoomfit[12] =  32'h55;
assign loc_zoomfit[13] =  32'h58;
assign loc_zoomfit[14] =  32'h5b;
assign loc_zoomfit[15] =  32'h5e;

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
        zoomin <= 0;
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
                3'b000://load data
                begin
                    x <= x;
                    y <= y;
                    zoomin <= 0;
                end
                3'b001://zoom in
                begin
                    if(zoomin)
                    begin
                      zoomin <= zoomin;
                      x <= x;
                      y <= y;
                    end
                    else
                    begin
                      zoomin <= 1;
                      x <= 4'b0110;//6
                    y <= 4'b0101;//5
                    end
                end
                3'b010://zoom out
                begin
                    x <= x;
                    y <= y;
                    zoomin <= 0;
                end
                3'b011://shift right //10
                begin
                    if(x<4'b1010 && sub_one==0 && zoomin)
                    begin
                        x <= x+1;
                        sub_one <= 1;
                    end
                    else
                        x <= x;
                    y <= y;
                end
                3'b100://shift left
                begin
                    if(x>4'b0010 && sub_one==0 && zoomin)
                    begin
                        x <= x-1;
                        sub_one <= 1;
                    end
                    else
                        x <= x;
                    y <= y;
                end
                3'b101://shift up
                begin
                    if(y>4'b0010 && sub_one==0 && zoomin)
                    begin
                        y <= y-1;
                        sub_one <= 1;
                    end
                    else
                        y <= y;
                    x <= x;

                end
                3'b110://shift down
                begin
                    if(y<4'b1010 && sub_one ==0 &&zoomin)
                    begin
                        y <= y +1;
                        sub_one <= 1;
                    end
                    else
                        y <= y;
                    x <= x;
                end
            endcase

            if(count != 5'b10000)//16
            begin
                count <= count + 1 ;
                if((cmd_use==3'b000 || cmd_use==3'b010 ) || !zoomin)
                    out_play[count] <= image_buf[loc_zoomfit[count]];
                else
                    out_play[count] <= image_buf[loc[count]];
            end

            else
            begin
                count <= 0;
            end

            /* control the input and output */
            if(count_in == 7'b1101100)//108//start to output
            begin
                output_valid <= 1;

                if(count_out == 5'b10000)//16//start the new round
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
                if(cmd_use==3'b000)
                    image_buf[count_in] <= datain;
                else
                    image_buf[count_in] <=image_buf[count_in];
            end
            cmd_use <= cmd_use;
        end
    end
end



endmodule

