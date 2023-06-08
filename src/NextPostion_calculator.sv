`default_nettype none

module NextPostion_calculator#(
			    parameter	      MODE_NO_FILTERING = -1,
			    parameter	      MODE_FILTERING = -1,
			    parameter	      MODE_REMOVE_DRIFT = -1,
			    parameter integer DETC_DATA_WIDTH = -1,
			    parameter integer POSTI_BIT_WIDTH = -1,
			    parameter integer FRAME_BIT_WIDTH = -1,
			    parameter integer MAX_AVE_SAMPLE_SIZE = -1
		     )
   (
    input wire					       clk,
    input wire					       n_rst,
    input wire					       startFlag,
    input wire [POSTI_BIT_WIDTH-1:0]		       constValue,
    input wire [DETC_DATA_WIDTH-1:0]		       detcData,
    input wire [1:0]				       Mode_PostiData,
    input wire [31:0]				       AveFilter_SampleSize,
    output reg [FRAME_BIT_WIDTH-1:0]		       frameNum,
    output reg [(POSTI_BIT_WIDTH+FRAME_BIT_WIDTH)-1:0] SendData
    );
   
 
   logic signed [POSTI_BIT_WIDTH-1:0]		       signedData;
   reg [POSTI_BIT_WIDTH-1:0]			       accum;
   logic [POSTI_BIT_WIDTH-1:0]			       accumData;
   
   
   wire [POSTI_BIT_WIDTH-1:0]			       AveData; 
   wire						       CalcAve_EndFlag;
   
   logic [POSTI_BIT_WIDTH-1:0]			       PostionData;
   
   
   //-------------------detcDataを見て符号を決める---------------------
   always_comb begin
      if(detcData == 'd0)
	signedData = 'd0;
      else if(detcData[DETC_DATA_WIDTH-1] == 1'b1)
	signedData = (~constValue) + 1;
      else
	signedData = constValue;
   end
   //------------------------------------------------------------------

   
   //-----------------------累積値＋現在のデータ-----------------------
    always_comb begin
      accumData = accum+signedData;
   end
   //------------------------------------------------------------------


   
   //------------------------移動平均フィルタの計算--------------------
   move_average_filter
     #(
       .MAX_SAMPLE_SIZE(MAX_AVE_SAMPLE_SIZE),
       .BIT_WIDTH(POSTI_BIT_WIDTH)
       )
   move_average_filter_inst
     (
      .clk(clk),
      .n_rst(n_rst),
      .sampleSize(AveFilter_SampleSize),
      .startFlag(startFlag),
      .din(accumData),
      .dout(AveData),
      .endFlag(CalcAve_EndFlag)
      );
   //------------------------------------------------------------------


   
   
   //--------平均の計算が完了したタイミングで累積値を更新--------------
   always_ff @(posedge clk) begin
      if(!n_rst)
	accum <= 'd0;
      else if(CalcAve_EndFlag)
	accum <= accum + signedData;
      else accum <= accum;
   end
   //------------------------------------------------------------------- 
  
 
   //--------平均の計算が完了した対キングでフレーム数を更新-------------
   always_ff @(posedge clk) begin
      if(!n_rst)
	frameNum <= 'b0;
      else if(CalcAve_EndFlag)
	frameNum <= frameNum +1;
      else
	frameNum <=frameNum;
   end 
   //-------------------------------------------------------------------

   
   always_comb begin
      case(Mode_PostiData)
	MODE_NO_FILTERING : PostionData = accumData;
	MODE_FILTERING    : PostionData = AveData;
	MODE_REMOVE_DRIFT : PostionData = accumData - AveData;
	default: PostionData = 0;
      endcase
   end
     
   
  
   always_ff@(posedge clk) begin
      if(!n_rst)
	SendData <= 'd0;
      else if(CalcAve_EndFlag)
	SendData <= {PostionData ,frameNum};
      else
	SendData <= SendData;
   end
   
endmodule 


`default_nettype wire
