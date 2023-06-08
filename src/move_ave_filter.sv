`default_nettype none

module shift_reg
  #(
    parameter integer BIT_WIDTH = -1,
    parameter integer REG_SIZE = -1
    )
   
   (
    input wire		       clk,
    input wire		       n_rst,
    input wire [31:0]	       ShiftSize,
    input wire		       shift_e,
    input wire [BIT_WIDTH-1:0] din,
    output reg [BIT_WIDTH-1:0] DoutReg[REG_SIZE-1:0]
    );
   

   integer			      i;
   
   always_ff @(posedge clk) begin
      if(!n_rst) begin
	 for(i=0;i < REG_SIZE;i=i+1) 
	   DoutReg[i] <= 'd0;
      end      
      else if(shift_e)begin
	 for(i=REG_SIZE-1;i > 0;i=i-1) begin
	   if(i < (ShiftSize-1))
	     DoutReg[i] <= DoutReg[i-1];
	   else
	     DoutReg[i] <= 'd0;
	 end
	 
	 DoutReg[0] <= din;
      end
      else begin
	 for(i=0;i < REG_SIZE;i=i+1) 
	   DoutReg[i] <= DoutReg[i];
      end
   end // always_ff @ (posedge clk)
   
endmodule

  
module move_average_filter
  #(
    parameter integer MAX_SAMPLE_SIZE = -1,
    parameter integer BIT_WIDTH = -1
    )
   (
    input wire			clk,
    input wire			n_rst,
    input wire [31:0]		sampleSize,
    input wire			startFlag,
    input wire [BIT_WIDTH-1:0]	din,
    output wire [BIT_WIDTH-1:0]	dout,
    output logic		endFlag
    );

   
   
   localparam integer		       REG_SIZE = MAX_SAMPLE_SIZE-1;
   localparam integer		       MAX_COUNT = $clog2(MAX_SAMPLE_SIZE)-1;
   localparam integer		       COUNT_WIDTH = $clog2(MAX_COUNT);
  


   reg [COUNT_WIDTH:0]		       count;
   reg				       busy;
      
   
   reg [BIT_WIDTH-1:0]		       PrevDataReg[REG_SIZE-1:0];

 //-------------フィルタの計算結果が出るまで数える-------------------------------    
   always_ff@(posedge clk) begin
      if(!n_rst)
	count <= 'd0;
      else if(startFlag)
	count <= 'd1;
      else if(count==MAX_COUNT)
	count <= 'd0;
      else if(busy)
	count <= count+1;
      else
	count <= count;
   end // always_ff@ (posedge clk)
   
   
   always_ff@(posedge clk) begin
      if(!n_rst)
	busy <=1'b0;
      else if(startFlag)
	busy <= 1'b1;
      else if(count == MAX_COUNT)
	busy<= 1'b0;
      else
	busy <= busy;
   end

   
   always_ff @(posedge clk) begin
      if(!n_rst)
	endFlag <= 1'b0;
      else if(count == MAX_COUNT)
	endFlag <= 1'b1;
      else
	endFlag <= 1'b0;
   end
   //----------------------------------------------------------------------------
      
   
   //----------計算結果が出たら過去のデータを保存するシフトレジスタを更新-----------------
      shift_reg
     #(
       .BIT_WIDTH(BIT_WIDTH),
       .REG_SIZE(REG_SIZE)
       )
   shit_reg_inst
     (
      .clk(clk),
      .n_rst(n_rst),
      .ShiftSize(sampleSize),
      .shift_e(endFlag),
      .din(din),
      .DoutReg(PrevDataReg)
      );
   
   //---------------------------------------------------------------------------



   average#(
	    .REG_SIZE(REG_SIZE),
	    .BIT_WIDTH(BIT_WIDTH)
	    )
   average_inst(
		.clk(clk),
		.n_rst(n_rst),
		.sampleSize(sampleSize),
		.din(din),
		.prevDataReg(PrevDataReg),
		.dout(dout)
		); 
 
endmodule



`default_nettype wire
