`default_nettype none


module rs232c_transmitter #(
		   //   parameter integer	CLK_FREQ = 100e6,
		      //parameter integer BITRATE = 9600,
		      parameter integer	BIT_WIDTH = 8	
		      )
   (clk,n_rst,send_data,te,max_count,t_busy,txd);

   
   localparam integer			MAX_BIT_COUNT = BIT_WIDTH+2;
   localparam integer			BIT_COUNT_WIDTH = $clog2(MAX_BIT_COUNT);
   
//   localparam integer			MAX_COUNT = CLK_FREQ / BITRATE;
//   localparam integer			COUNT_WIDTH = $clog2(MAX_COUNT);
   
   localparam				DEFAULT_BIT = 1'b1;
   localparam				START_BIT = !DEFAULT_BIT;
   localparam				END_BIT = DEFAULT_BIT;

   
   
   input wire				clk;
   input wire				n_rst; 
   input wire [BIT_WIDTH-1:0]		send_data;
   input wire				te;
   input wire [31:0]			max_count;
   output reg				t_busy;
   output reg				txd;


   reg [31:0]			count;
   reg					bitFlag;
   
   reg [BIT_COUNT_WIDTH:0]		bit_count;

   

   always_ff @(posedge clk) begin
      if(!n_rst)
	count <= '0;
      else if(te && count==0)
	count <= 'd1;
      else if(count == max_count)
	count <= 'b0;
      else if(t_busy)
	count <= count + 1;
      else
	count <= 'd0;
   end // always_ff @ (posedge clk)
   
   always_ff @(posedge clk) begin
      if(!n_rst)
	bitFlag <= 1'b0;
      else if(count == max_count)
	bitFlag <= 1'b1;
      else
	bitFlag <= 1'b0;
   end
   

	
   always_ff @(posedge clk) begin
      if(!n_rst)
	t_busy <= 1'b0;
      else if(te && !t_busy)
	t_busy <= 1'b1;
      else if(t_busy &&(bitFlag && bit_count==MAX_BIT_COUNT))
	t_busy <= 1'b0;
      else
	t_busy <= t_busy;
   end
   

   always_ff @(posedge clk) begin
      if(!n_rst)
	bit_count <= 'd0;
      else if(te)
	bit_count <= 'd1;
      else if(bitFlag && (bit_count==MAX_BIT_COUNT))
	bit_count <= 'd0;
      else if(bitFlag)
	bit_count <= bit_count +1;
      else
	bit_count <= bit_count;
   end // always_ff @ (posedge clk)
      

   always_ff @(posedge clk) begin
      if(!n_rst)
	txd <= DEFAULT_BIT;
      else if(te)
	txd <= START_BIT;
      else if(!t_busy)
	txd <= DEFAULT_BIT;
      else if(bitFlag && (bit_count==BIT_WIDTH+1))
	txd <= END_BIT;
   
      else if(bitFlag && (bit_count==MAX_BIT_COUNT))
	txd <= DEFAULT_BIT;
      else if(bitFlag)
	txd <= send_data[bit_count-1];
      else if(t_busy)
	txd <= txd;
      else
	txd <= DEFAULT_BIT;
   end // always_ff @ (posedge clk)

   
endmodule


`default_nettype wire
