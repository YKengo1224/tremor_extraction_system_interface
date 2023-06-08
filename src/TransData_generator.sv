`default_nettype none

module TransData_generator#(
			    parameter	      HEADER = -1,
			    parameter	      FRAME_BYTES = -1,
			    parameter	      POSTI_BYTES = -1,
			    parameter integer FRAME_BIT_WIDTH = -1,
			    parameter integer POSTI_BIT_WIDTH = -1,
			    parameter integer DETC_DATA_WIDTH = 13,
			    parameter integer UART_BIT_WIDTH = -1
			    )
      (
       input wire					clk,
       input wire					n_rst,
       input wire					ExtractFlag, //-------データを検出する
       input wire					En240Hz,
       input wire [FRAME_BIT_WIDTH+POSTI_BIT_WIDTH-1:0]	CalcData,
       input wire					TransBusy,
       output reg					EnTrans,
       output reg [UART_BIT_WIDTH-1:0]			TransData
       );

   
   localparam integer					REG_SIZE = (FRAME_BYTES + POSTI_BYTES+1) * 4;
   localparam integer					MAX_COUNT_240HZ = REG_SIZE;
   localparam integer					MAX_COUNT_60HZ = REG_SIZE/4;
   localparam integer					COUNT_BIT_WIDTH = $clog2(MAX_COUNT_240HZ);
   

   reg [COUNT_BIT_WIDTH:0]				count;
   logic [UART_BIT_WIDTH-1:0]				DataReg_60Hz [REG_SIZE-1:0];
   logic [UART_BIT_WIDTH-1:0]				DataReg_240Hz [REG_SIZE-1:0];
   logic [UART_BIT_WIDTH-1:0]				OutPutDataReg[REG_SIZE-1:0];



   reg				     TransBusyPrev;
   wire				     TransBusyEdge;


   
   always_ff @(posedge clk) begin
      if(!n_rst)
	count <= 'b0;
      else if(ExtractFlag && count == 'b0)
	count <= 'b1;
      
      else if(En240Hz) begin
	 if(count == MAX_COUNT_240HZ && TransBusyEdge)
	   count <= 'b0;
	 else if(count != 'b0 && TransBusyEdge)
	   count <= count + 'b1;
	 else
	   count = count;
      end
      
      else  begin
	 if(count == MAX_COUNT_60HZ && TransBusyEdge)
	   count <= 'b0;
	 else if(count != 'b0 && TransBusyEdge)
	   count <= count + 'b1;
	 else
	   count = count;
      end

   end     




   integer i;
   
   
   always_comb begin
      for(i=0;i<REG_SIZE;i=i+1) begin
	 if(i==0)
	   DataReg_60Hz[i] <= HEADER;
	 else if(i<MAX_COUNT_60HZ)
	   DataReg_60Hz[i] <= CalcData[(i-1)*UART_BIT_WIDTH +: UART_BIT_WIDTH];
	 else
	   DataReg_60Hz[i] <= 'd0;
      end
   end
   

   split_240Hz #(
                 .HEADER(HEADER),
                 .REG_SIZE(REG_SIZE),
                 .FRAME_BIT_WIDTH(FRAME_BIT_WIDTH),
                 .POSTI_BIT_WIDTH(POSTI_BIT_WIDTH),
                 .UART_BIT_WIDTH(UART_BIT_WIDTH)
                 )
   split_240Hz_inst(
                    .clk(clk),
                    .n_rst(n_rst),
                    .iData(CalcData),
                    .DataReg(DataReg_240Hz)
                    );


   integer j;

   
   always_comb begin
      for(int j=0;j<REG_SIZE;j=j+1) begin
	 if(En240Hz)
	   OutPutDataReg[j] <= DataReg_240Hz[j];
	 else
	   OutPutDataReg[j] <= DataReg_60Hz[j];
      end
   end



   
   always_ff @(posedge clk) begin
      if(!n_rst)
	TransData <= 'd0;
      else if(count == 'd0)
	TransData <= 'd0;
      else
	TransData <= OutPutDataReg[count-1];
   end


   

   always_ff @(posedge clk) begin
      if(!n_rst)
	TransBusyPrev <= 1'b0;
      else
	TransBusyPrev <= TransBusy;
   end

   assign TransBusyEdge = !TransBusy && TransBusyPrev;

   
   
   always_ff @(posedge clk) begin
      if(!n_rst)
	EnTrans <= 'd0;
      
      else if(ExtractFlag)
	EnTrans <= 1'b1;
      
      else if(TransBusyEdge) begin
	 if(En240Hz && (count != MAX_COUNT_240HZ))
	   EnTrans <= 1'b1;
	 else if(!En240Hz && (count != MAX_COUNT_60HZ))
	   EnTrans<= 1'b1;
      end
      
      else
	EnTrans <= 1'b0;
   end
	  
endmodule
   
`default_nettype wire
