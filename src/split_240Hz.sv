`default_nettype none

module split_240Hz#(
		    parameter	      HEADER = -1,
		    parameter integer REG_SIZE = -1,
		    parameter integer FRAME_BIT_WIDTH = -1,
		    parameter integer POSTI_BIT_WIDTH = -1,	      
		    parameter integer UART_BIT_WIDTH = -1
		    )  
   (
    input wire					       clk,
    input wire					       n_rst,
    input wire [(FRAME_BIT_WIDTH+POSTI_BIT_WIDTH)-1:0] iData, //iData = {PostiData,frameNum}
    output logic [UART_BIT_WIDTH-1:0]    DataReg [REG_SIZE-1:0]
    );

   localparam integer			 SUB_REG_SIZE = REG_SIZE / 4;
   

   wire unsigned [FRAME_BIT_WIDTH-1:0]	 FrameData;
   logic unsigned [3:0][FRAME_BIT_WIDTH-1:0] FrameSplitData;
   wire signed [POSTI_BIT_WIDTH-1:0]	 PostiData;
   logic signed [POSTI_BIT_WIDTH-1:0]	 PostiQuo;
   wire signed [POSTI_BIT_WIDTH-1:0]	 PostiRemain;
  
   logic [3:0][SUB_REG_SIZE-1:0][UART_BIT_WIDTH-1:0] SubReg;
	       
   integer				 m,i,j,k,l;
   
   assign FrameData = iData[0 +: FRAME_BIT_WIDTH];
   assign PostiData = iData[(FRAME_BIT_WIDTH+POSTI_BIT_WIDTH-1) -: POSTI_BIT_WIDTH];

   
   always_comb begin
      for(m=0;m<4;m=m+1) 
	FrameSplitData[m] <= (FrameData<<<2) + m;
   end
   

   
   always_comb begin
      if((PostiData[POSTI_BIT_WIDTH-1] == 1'b1) && (PostiData[3:0] != 3'b000))
	PostiQuo <= PostiData >>> 2 +1;
      else
	PostiQuo <= PostiData >>> 2;
   end
   
 
   //############data / 4####################
//   assign PostiQuo = PostiData >>> 2;
   //#######################################
   
   assign PostiRemain = PostiData - PostiQuo*3;

   
   always_comb begin
      for(i = 0;i<4;i = i+1) begin
	 
      //##############################################################################
	 for(j=0;j<SUB_REG_SIZE;j=j+1) begin
	    if(j == 0)
	      SubReg[i][j] <= HEADER;
	    else if(j <= 4)
	      SubReg[i][j] <= FrameSplitData[i][(j-1)*UART_BIT_WIDTH +: UART_BIT_WIDTH];
	    else
	      SubReg[i][j] <= PostiQuo[(j-5)*UART_BIT_WIDTH +: UART_BIT_WIDTH];

	    
	    //##################################################################
	    // if(i!=3) begin
	    //    if(j == 0)
	    // 	 SubReg[i][j] <= HEADER;
	    //    else if(j <= 4)
	    // 	 SubReg[i][j] <= FrameSplitData[i][(j-1)*UART_BIT_WIDTH +: UART_BIT_WIDTH];
	    //    else
	    // 	 SubReg[i][j] <= PostiQuo[(j-5)*UART_BIT_WIDTH +: UART_BIT_WIDTH];
	    // end
            // //##################################################################
	    
	    // //##################################################################
	    // else begin
	    //    if(j == 0)
	    // 	 SubReg[i][j] <= HEADER;
	    //    else if(j <= 4)
	    // 	 SubReg[i][j] <= FrameSplitData[i][(j-1)*UART_BIT_WIDTH +: UART_BIT_WIDTH];
	    //    else
	    // 	 SubReg[i][j] <= PostiRemain[(j-5)*UART_BIT_WIDTH +: UART_BIT_WIDTH];
	    // end // else: !if(i!=3)
	    //##################################################################
	        
	 end
	 
      //#############################################################################
      end 
   end // always_comb


   always_comb begin
      for(k=0;k<4;k=k+1) begin
	 for(l=0;l<SUB_REG_SIZE;l=l+1) 
	   DataReg[(k*SUB_REG_SIZE)+l] <=  SubReg[k][l];
      end
   end
   
endmodule

`default_nettype wire

