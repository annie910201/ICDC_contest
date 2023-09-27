module JAM (CLK, RST, W,J, Cost,MatchCount,MinCost, Valid );
input CLK;
input RST;
output reg [2:0] W;
output reg [2:0] J;
input [6:0] Cost;
output reg [3:0] MatchCount;
output reg [9:0] MinCost;
output reg Valid ;
reg [3:0] current_state;
reg [3:0] next_state;
parameter INIT = 0;
parameter GET_DATA = 1;
parameter CHECK_MIN = 2;
parameter FIND_PIVOT = 3;
parameter FIND_BIGGER_THAN_MIN = 4;
parameter EXCHANGE = 5;
parameter FLIP_NUMBER = 6;
parameter OUTPUT = 7;
parameter FINISH = 8;

reg [2:0] pivot;
reg [2:0] head;
reg [2:0] tail;
reg [2:0] exchange_point;
reg [2:0] tmp_exchange_point;
reg [9:0] tmp_min;
reg [2:0] buffer [0:7];
reg [3:0] counter;
wire sort_over;
assign sort_over = (buffer[0] == 7 && buffer[1] == 6 && buffer[2] == 5 && buffer[3] == 4 && buffer[4] == 3 && buffer[5] == 2&& buffer[6] == 1&& buffer[7] == 0) ? 1 : 0;


// reg min_change;
always @(posedge CLK) begin
if(RST)
    current_state <= INIT;
else
    current_state <= next_state;
end

always @(*) begin
    case(current_state)
    INIT:
        next_state = GET_DATA;
    GET_DATA:
        next_state = (counter == 4'd7) ? CHECK_MIN : GET_DATA;
    CHECK_MIN:
        next_state = FIND_PIVOT;
    FIND_PIVOT:
        if(sort_over)
            next_state = OUTPUT;
        else if(buffer[counter] > buffer[counter+1])
            next_state = FIND_PIVOT;
        else
            next_state = FIND_BIGGER_THAN_MIN;
    FIND_BIGGER_THAN_MIN:
        next_state = (tmp_exchange_point == 3'd7 || buffer[tmp_exchange_point] == buffer[pivot] + 1) ? EXCHANGE : FIND_BIGGER_THAN_MIN;
    EXCHANGE:
        next_state = FLIP_NUMBER;
    FLIP_NUMBER:
        next_state = (head < tail) ? FLIP_NUMBER : GET_DATA ;
    OUTPUT:
        next_state = FINISH;
    FINISH:
        next_state = FINISH;
    endcase

end
// counter
always @(posedge CLK) begin
if(RST)
    counter <= 0;
else if((current_state == INIT || current_state == FLIP_NUMBER) && next_state == GET_DATA)
    counter <= 0;
else if(current_state == CHECK_MIN)
    counter <= 4'd6;
else if(current_state == FIND_PIVOT)
    counter <= counter - 1;
else 
    counter <= counter + 1;
end

// pivot and head and tail
always @(posedge CLK) begin
if(RST)
begin
    buffer[0] <= 0;
    buffer[1] <= 1;
    buffer[2] <= 2;
    buffer[3] <= 3;
    buffer[4] <= 4;
    buffer[5] <= 5;
    buffer[6] <= 6;
    buffer[7] <= 7;
    pivot <= 0;
    head <= 0;
    tail <= 0;
    tmp_exchange_point <=0;
    exchange_point <=0;
end
else if(current_state == FIND_PIVOT)
begin
    if(buffer[counter] < buffer[counter +1] )
    begin
        pivot <= counter;
        head <= counter + 1;
        tail <= 3'd7;
        tmp_exchange_point <= counter + 1;
        exchange_point <= counter + 1;
    end
end
else if(current_state == FIND_BIGGER_THAN_MIN)
begin
    if(buffer[tmp_exchange_point] > buffer[pivot] && buffer[tmp_exchange_point] <= buffer[exchange_point])
    begin
        exchange_point <= tmp_exchange_point;
        tmp_exchange_point <= tmp_exchange_point + 1;
    end
    else
        tmp_exchange_point <= tmp_exchange_point + 1;
end
else if(current_state == EXCHANGE) 
begin
    buffer[exchange_point] <= buffer[pivot];
    buffer[pivot] <= buffer[exchange_point];
end
else if(current_state == FLIP_NUMBER)
begin
    if(head < tail)
    begin
        buffer[head] <= buffer[tail];
        buffer[tail] <= buffer[head];
        head <= head + 1;
        tail <= tail - 1;
    end
end
end


// MinCost and MatchCount and valid
always @(posedge CLK) begin
if(RST)
begin
    MinCost <= 10'd1023;
    MatchCount <= 0;
    Valid <= 0;
end
else if(current_state == CHECK_MIN)
begin
    if(tmp_min < MinCost)
    begin
        MinCost <= tmp_min;
        MatchCount <= 1;
    end
    else if(tmp_min == MinCost)
        MatchCount <= MatchCount + 1;
end
else if(next_state == OUTPUT)
    Valid <= 1;
end

// tmp_min
always @(posedge CLK) begin
if(RST)
    tmp_min <= 0;
else if(current_state == GET_DATA)
    tmp_min <= tmp_min + Cost;
else if(current_state == CHECK_MIN)
    tmp_min <= 0;
end

// W and J
always @(posedge CLK) begin
if(RST)
begin
    W <= 0;
    J <= 0;
end
else if(current_state == GET_DATA)
begin
    W <= W + 1;
    J <= buffer[W + 1];
end
else if(current_state == CHECK_MIN)
begin
    W <= 0;
    J <= buffer[0];
end
end
endmodule