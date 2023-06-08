`default_nettype none
/*
 This module interface the tremor extraction system with the tremor reproduction system running on Teency
  
  ・9bytes of data are sent between systems in asingle communication.
    The communication standards between systems are shown in the tavle below.
 
    number of transmission order               data
---------------------------------------------------------------------
                1                  |            0xFF
                2                  |    number of frame(1~8bits) 
                3                  |    number of frame(9~16bits) 
                4                  |    number of frame(17~24bits) 
                5                  |    number of frame(25~32bits) 
                6                  |    postion data(1~8bits) 
                7                  |    postion data(9~16bits) 
                8                  |    postion data(17~24bits) 
                9                  |    postion data(25~32bits) 

   
 ・this interface has tree outputs modes.
   MODE:
     MODE_NO_FILTERING: output the cumulative value of extarction results 
       MODE_FILTERING : output the acccumlated value filtered by a dynamic acerage filter
     MODE_REMOVE_DRIFT: output the value after remocing drift
    
   Mode can be changed dynamically with Mode_Postidata.
 
  There are also other parameters that can be changed dynamically
    ConstCValue            :  constant value of output
    DetcData               :  extraction result of tremor extraction system
    Mode_PostiData         :  output mode selection signal
    AveFilterSampleSize,   :  Sample size of average filter
 
 ・It is assumed that the communication speed between the systems is sufficiently faster than the FPS of the target video

  */
module top_Teensy_interface#(
//		      parameter integer	CLK_FREQ = 100e6,
		      parameter		MODE_NO_FILTERING = 2'b00,
		      parameter		MODE_FILTERING = 2'b01,
		      parameter		MODE_REMOVE_DRIFT = 2'b10,
		      parameter integer	FRAME_BYTES = 4,              //bites of frame data to be transmit 
		      parameter integer	POSTI_BYTES = 4,              //bites of postion data to be transmit 
		      parameter integer	DETC_DATA_WIDTH = 13,         // bitwidth of extraction
		      parameter integer	MAX_AVE_SAMPLE_SIZE = 128)
   (
    input wire			     clk,
    input wire			     n_rst,
    input wire			     ExtractFlag,                     //flag of extraction for tremor extraction system
    input wire [(POSTI_BYTES*8)-1:0] ConstValue,                      //constant value of output
    input wire [DETC_DATA_WIDTH-1:0] DetcData,                        //extraction result of tremor extraction system
    input wire [1:0]		     ModePostiData,                   //output mode selection signal
    input wire [31:0]		     AveFilterSampleSize,             //Sample size of average filter 
    input wire [31:0]		     TxdMaxCount,
    input wire			     En240Hz,                        //enable signal of output freq si 240Hz
    output wire			     Txd                          //rs232c transmit data
    );



   localparam			     HEADER = 8'hFF;                    //header
   localparam			     FRAME_BIT_WIDTH = FRAME_BYTES * 8; //bit width of frame data
   localparam integer		     POSTI_BIT_WIDTH = POSTI_BYTES * 8; //bit width of frame data
   localparam integer		     UART_BIT_WIDTH = 8;

    	     
   
   logic [1:0]			     StartFlag;                         //flags of start in transmit .....  01:60Hz  10:240Hz
   wire [(POSTI_BIT_WIDTH+FRAME_BIT_WIDTH)-1:0]	SendData;
   

   wire						TransBusy;
   
   wire				     Entrans;                           //enable signal that rs232c_send module can be transmit data
   wire [UART_BIT_WIDTH-1:0]	     TransData;
   
   wire [31:0]			     FrameNum;
   
   


   //######## detecion 60Hz or 240Hz#####
   always_comb begin
      if(ExtractFlag) begin
	 if(En240Hz)
	   StartFlag = 2'b10;
	 else
	   StartFlag = 2'b01;
      end	
      else
	StartFlag = 2'b00;
   end   
   //####################################

   
	  
   
   //################calculation output data module########################
   NextPostion_calculator
     #(
       .MODE_NO_FILTERING(MODE_NO_FILTERING),
       .MODE_FILTERING(MODE_FILTERING),
       .MODE_REMOVE_DRIFT(MODE_REMOVE_DRIFT),
       .DETC_DATA_WIDTH(DETC_DATA_WIDTH),
       .POSTI_BIT_WIDTH(POSTI_BIT_WIDTH),
       .FRAME_BIT_WIDTH(FRAME_BIT_WIDTH),
       .MAX_AVE_SAMPLE_SIZE(MAX_AVE_SAMPLE_SIZE)
       )
   calc_postion_inst
     (
      .clk(clk),
      .n_rst(n_rst),
      .startFlag(ExtractFlag),
      .constValue(ConstValue),
      .detcData(DetcData),
      .Mode_PostiData(ModePostiData),
      .AveFilter_SampleSize(AveFilterSampleSize),
      .frameNum(FrameNum),
      .SendData(SendData)
      );  
   //#####################################################################

   

   TransData_generator#(
			.HEADER(HEADER),
			.FRAME_BYTES(FRAME_BYTES),
			.POSTI_BYTES(POSTI_BYTES),
			.FRAME_BIT_WIDTH(FRAME_BIT_WIDTH),
			.POSTI_BIT_WIDTH(POSTI_BIT_WIDTH),
			.DETC_DATA_WIDTH(DETC_DATA_WIDTH),
			.UART_BIT_WIDTH(UART_BIT_WIDTH)
			)
   generate_trans_data_inst(
			    .clk(clk),
			    .n_rst(n_rst),
			    .ExtractFlag(ExtractFlag),
			    .En240Hz(En240Hz),
			    .CalcData(SendData),
			    .TransBusy(TransBusy),
			    .EnTrans(Entrans),
			    .TransData(TransData)
			    );
   
   

   rs232c_transmitter#(
		      .BIT_WIDTH(UART_BIT_WIDTH)
		      )
   transmitter_inst(
		    .clk(clk),
		    .n_rst(n_rst),
		    .send_data(TransData),
		    .te(Entrans),
		    .max_count(TxdMaxCount),
		    .t_busy(TransBusy),
		    .txd(Txd)
		    );
   

   
   
endmodule
   

`default_nettype wire
