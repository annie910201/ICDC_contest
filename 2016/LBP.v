`timescale 1ns/10ps
module LBP ( clk, reset, gray_addr, gray_req, gray_ready, gray_data, lbp_addr, lbp_valid, lbp_data, finish);
input clk;
input reset;
output reg [13:0] gray_addr;
output reg gray_req;
input gray_ready;
input [7:0] gray_data;
output reg [13:0] lbp_addr;
output reg lbp_valid;
output reg [7:0] lbp_data;
output reg finish;

reg [2:0] current_state;
reg [2:0] next_state;
parameter INITIAL = 3'd0;
parameter READ_GC = 3'd1;
parameter CONSOLE_GD = 3'd2;
parameter WRITE_HOST = 3'd3;
parameter FINIFH = 3'd4;

reg [3:0] counter;
reg [6:0] x;
reg [6:0] y;
reg [7:0] center_value;
wire [6:0] x_after;
wire [6:0] x_before;
wire [6:0] y_after;
wire [6:0] y_before;
assign x_after = x + 1;
assign y_after = y + 1;
assign x_before = x - 1;
assign y_before = y - 1;

// next state
always @(posedge clk or posedge reset) begin
    if(reset)
        current_state <= INITIAL;
    else
        current_state <= next_state;
end

// state logic
always @(*) begin
    if(reset)
        next_state = INITIAL;
    else
    begin
        case(current_state)
        INITIAL:
        begin
            if(gray_ready)
                next_state = READ_GC;
            else
                next_state = INITIAL;
        end
        READ_GC:
            next_state = CONSOLE_GD;
        CONSOLE_GD:
            if(counter == 4'd8)
                next_state = WRITE_HOST;
            else
                next_state = CONSOLE_GD;
        WRITE_HOST:
            if(y == 7'd127)
                next_state = FINIFH;
            else
                next_state = READ_GC;
        FINIFH:
            next_state = FINIFH;
        default:
            next_state = INITIAL;
        endcase
    end
end

/* output */
//gray_addr
always @(posedge clk) begin
    if(reset)
        gray_addr <= 0;
    else if(next_state == READ_GC)
        gray_addr <= {y,x};
    else if(next_state == CONSOLE_GD)
    begin
        case (counter)
            4'd0:
                gray_addr <= {y_before, x_before};
            4'd1:
                gray_addr <= {y_before, x};
            4'd2: 
                gray_addr <= {y_before, x_after};
            4'd3:
                gray_addr <= {y, x_before};
            4'd4:
                gray_addr <= {y, x_after};
            4'd5: 
                gray_addr <= {y_after, x_before};
            4'd6:
                gray_addr <= {y_after, x};
            4'd7:
                gray_addr <= {y_after, x_after};
        endcase
    end
end
//gray_req
always @(posedge clk) begin
    if(reset)
        gray_req <= 1'd0;
    else if(next_state == READ_GC || next_state == CONSOLE_GD)
        gray_req <= 1'd1;
    else
        gray_req <= 1'd0;
end
//lbp_addr
always @(posedge clk) begin
    if(reset)
        lbp_addr <= 1'd0;
    else if (next_state == WRITE_HOST)
        lbp_addr <= {y,x};
end
//lbp_valid
always @(posedge clk) begin
    if(reset)
        lbp_valid <= 1'd0;
    else if(next_state == WRITE_HOST)
        lbp_valid <= 1'd1;
    else 
        lbp_valid <= 1'd0;
end
//lbp_data
always @(posedge clk) begin
    if(reset)
        lbp_data <= 8'd0;
    else if(current_state == CONSOLE_GD)
    begin
        case (counter)
            4'd1:
            begin
                if(gray_data >= center_value)
                    lbp_data <= lbp_data + 8'b00000001;//1
            end
            4'd2:
                if(gray_data >= center_value)
                    lbp_data <= lbp_data + 8'b00000010;//2
            4'd3:
                if(gray_data >= center_value)
                    lbp_data <= lbp_data + 8'b00000100;//4
            4'd4:
                if(gray_data >= center_value)
                    lbp_data <= lbp_data + 8'b00001000;//8
            4'd5:
                if(gray_data >= center_value)
                    lbp_data <= lbp_data + 8'b00010000;//16
            4'd6:
                if(gray_data >= center_value)
                    lbp_data <= lbp_data + 8'b00100000;//32
            4'd7:
                if(gray_data >= center_value)
                    lbp_data <= lbp_data + 8'b01000000;//64
            4'd8: 
                if(gray_data >= center_value)
                    lbp_data <= lbp_data + 8'b10000000;//128
        endcase
    end
    else if(current_state == WRITE_HOST)
        lbp_data <= 0;
end
//finish
always @(posedge clk) begin
    if(reset)
        finish <= 1'd0;
    else if(current_state == FINIFH)
        finish <= 1'd1;
end

/* datapath */
//counter
always @(posedge clk) begin
    if(reset)
        counter <= 4'd0;
    else if(next_state == CONSOLE_GD)
        counter <= counter + 4'd1;
    else if(current_state == WRITE_HOST)
        counter <= 0;
end

//center_value
always @(posedge clk or posedge reset) begin
    if(reset)
        center_value <= 8'd0;
    else if(current_state == READ_GC)
        center_value <= gray_data;
    else
        center_value <= center_value;
end

// x and y
always @(posedge clk) begin
    if(reset)
    begin
        x <= 7'd1;
        y <= 7'd1;
    end
    else if(next_state == WRITE_HOST)
    begin
        if(x == 7'd126)
        begin
            x <= 7'd1 ;
            y <= y + 7'd1 ;
        end
        else
            x <= x + 7'd1;
    end
end

endmodule
