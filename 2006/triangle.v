module triangle (clk, reset, nt, xi, yi, busy, po, xo, yo);
input clk, reset, nt;
input [2:0] xi, yi;
output reg busy, po;
output reg [2:0] xo, yo;
reg current_state;
reg next_state;
reg input_over;
reg translate_over;
reg [3:0] x1, y1, x2, y2, x3, y3; 
reg [7:0] oper;
reg [1:0] count_input;
reg [3:0] count_output_x;
reg [3:0] count_output_y;
parameter INPUT_MODE = 0, 
          TRANSLATE_MODE = 1;

/* state register*/
always @(posedge clk or posedge reset) begin
  if(reset)
    current_state = INPUT_MODE;
  else
    current_state = next_state ;
end                   

/* next state logic */ 
always @(input_over or translate_over)begin
  case(current_state)
    INPUT_MODE:
    begin
      if(input_over)
        next_state = TRANSLATE_MODE;
      else
        next_state = INPUT_MODE;
    end
    TRANSLATE_MODE:
    begin
      if(translate_over)
        next_state = INPUT_MODE;
      else
        next_state = TRANSLATE_MODE;
    end
  endcase
end

/* output */ 
always@(posedge clk)begin
  if(reset)
  begin
    busy = 0;
    po = 0;
    xo = 0;
    yo = 0;
  end
  else
  begin
    if(nt)
      busy = 1;
    else if(translate_over)
      busy = 0;
    else
      busy = busy;
      
    oper = (x2-count_output_x)*(y3-y2) - (x2-x3)* (count_output_y-y2);
    if(oper[7]==0 && current_state == TRANSLATE_MODE)
      po = 1;
    else
      po = 0;
    xo = count_output_x;
    yo = count_output_y;
  end
end

/* datapath */ 
always@(posedge clk)begin
  if(reset)
  begin
    x1 <= 0;
    x2 <= 0;
    x3 <= 0;
    y1 <= 0;
    y2 <= 0;
    y3 <= 0;
    count_input <= 1;
    count_output_x <= 1;
    count_output_y <= 1;
    input_over <= 0;
    translate_over <= 0;
  end
  else
  begin
    case (current_state)
      INPUT_MODE: 
      begin
        case (count_input)
          2'b01:
          begin
            if(nt)
            begin
              input_over <= 0;
              translate_over <= 0;
              count_input <= count_input +1;
              x1 <= {1'b0, xi};
              y1 <= {1'b0, yi};
            end
          end
          2'b10:
          begin
            count_input <= count_input +1;
            x2 <= {1'b0, xi};
            y2 <= {1'b0, yi};
            count_output_x <= x1;
            count_output_y <= y1;
          end
          2'b11: 
          begin
            input_over <= 1;
            count_input <= 1;
            x3 <= {1'b0, xi};
            y3 <= {1'b0, yi};
          end
          default:
          begin
            input_over <= input_over;
            count_input <= count_input;
          end
        endcase
      end
      TRANSLATE_MODE:
      begin
        if(count_output_y == y3 && count_output_x == x2)
          translate_over <= 1;
        else if(count_output_x == x2)
        begin
          count_output_x <= x1;
          count_output_y <= count_output_y + 1;
        end 
        else
          count_output_x <= count_output_x +1;
      end
    endcase
  end
  
end

endmodule
