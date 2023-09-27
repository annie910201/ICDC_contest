`timescale 1ns/10ps
/*
 * IC Contest Computational System (CS)
*/
module CS(Y, X, reset, clk);

input clk, reset; 
input [7:0] X;
output reg [9:0] Y;//remember to set reg

reg [7:0] Xavg;
reg [11:0] Xapp;
reg [7:0] X_series [8:0];//save 9 numbers
reg [3:0] i;//to count 9
reg [10:0] sum;//the sum of 9 number

always@(posedge clk or posedge reset)begin
  if(reset) begin
    for(i=0;i<9;i=i+1)
      X_series[i] <= 0; 
      i <= 0;
      sum <= 0;
  end
  else begin 
    for(i=0;i<8;i=i+1)
      X_series[i] <= X_series[i+1] ;
      /*  X_series[0]=X_series[1];
          X_series[1]=X_series[2];
          X_series[2]=X_series[3];
          X_series[3]=X_series[4];
          X_series[4]=X_series[5];
          X_series[5]=X_series[6];
          X_series[6]=X_series[7];
          X_series[7]=X_series[8];
      */
    X_series[8] <= X;//use new number to replace 
    sum <= sum+X-X_series[0];//delete X_series[0] and add new X
  end
end 


always @(*)begin
  Xapp=0;//remember to initialize 
  
  for(i=0;i<9;i=i+1)begin
    
    if((X_series[i]<=sum/9) && (X_series[i] > Xapp))//find the number which is biggest number of 9 numbers and smaller than average 
      Xapp=X_series[i];
  end
  Y=(sum+(Xapp<<3)+Xapp)>>3;//the devidor is 9-1=8//use shift is fast
end

endmodule