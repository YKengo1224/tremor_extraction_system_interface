`default_nettype none

//------samole_size only(2,4,8,16,32,64,128)-------------------------------
module average#(  
		parameter integer REG_SIZE = -1,
		parameter integer BIT_WIDTH = -1
		)
   (clk,n_rst,sampleSize,din,prevDataReg,dout);
   input wire			  clk;
   input wire			  n_rst;
   input wire[31:0]		  sampleSize;
   input wire [BIT_WIDTH-1:0]	  din;
   input wire [BIT_WIDTH-1:0]	  prevDataReg[REG_SIZE-1:0];
   output logic [BIT_WIDTH-1:0]	  dout;

   
   localparam integer		  MAX_TREE_WIDE = REG_SIZE+1;
   localparam integer		  TREE_DEPTH = $clog2(MAX_TREE_WIDE);
   localparam integer		  TREE_BIT_WIDTH = BIT_WIDTH;//+TREE_DEPTH;

  
   logic [TREE_DEPTH:0][MAX_TREE_WIDE-1:0][TREE_BIT_WIDTH-1:0] tree;



   
   genvar						       depth,i;
   
   generate
      for(depth = 0;depth<=TREE_DEPTH;depth=depth+1) begin

	 localparam integer WIDE_DEPTH = MAX_TREE_WIDE >> depth;
	 localparam integer DEPTH_BIT_WIDTH = BIT_WIDTH; //+ depth;
 
         //----------------------depth0--------------------------------------
	 if(depth==0) begin

	    for(i=0;i<WIDE_DEPTH;i = i+1) begin
	       always_comb begin
		  if(i==0) begin
		     tree[depth][i][DEPTH_BIT_WIDTH-1:0] = din;
		     //tree[depth][i][TREE_BIT_WIDTH-1:DEPTH_BIT_WIDTH] = 0;
		  end		  
		  else begin
		     tree[depth][i][DEPTH_BIT_WIDTH-1:0] = prevDataReg[i-1];
		     //tree[depth][i][TREE_BIT_WIDTH-1:DEPTH_BIT_WIDTH] = 0;
		  end
		  
	       end
	       
	    end // always_comb
	    
	 end // if (depth==0)
         //--------------------------------------------------------------------------

         //--------------------------depth1~---------------------------------------------

	 else begin
	
	    for(i=0;i<WIDE_DEPTH;i=i+1) begin
	     
	       always_ff @(posedge clk) begin
 		  if(!n_rst)
		    tree[depth][i] <= 'd0;
		  
		  else begin 
		     tree[depth][i][DEPTH_BIT_WIDTH-1:0]
		       <= tree[depth-1][i*2][DEPTH_BIT_WIDTH-1:0] +
		  	  tree[depth-1][i*2+1][DEPTH_BIT_WIDTH-1:0];
		  end
		  
	       end
	       
	    end // for (i=0;i<WIDE_DEPTH;i=i+1)

	 end	    
	 //----------------------------------------------------------------------------     	 
      
      end // for (depth = 0;depth<TREE_DEPTH;depth=depth+1)
       
      endgenerate


   

   wire signed [TREE_BIT_WIDTH-1:0] tmp;


   function [4:0] log2(input [31:0] sampleSize);
      begin
      case(sampleSize)
	'd2   : log2 = 4'd1;
	'd4   : log2 = 4'd2;
	'd8   : log2 = 4'd3;
	'd16  : log2 = 4'd4;
	'd32  : log2 = 4'd5;
	'd64  : log2 = 4'd6;
	'd128 : log2 = 4'd7;
	default: log2 = 4'd2;
      endcase // case (sampleSize)
      end  	 
   endfunction // log2
   

   
   function [TREE_BIT_WIDTH-1:0] neg_to_pogi(input [TREE_BIT_WIDTH-1:0] neg);
      begin
	 neg_to_pogi =~(neg-1);
      end
   endfunction


   function [TREE_BIT_WIDTH-1:0] pogi_to_neg(input [TREE_BIT_WIDTH-1:0] pogi);
      begin
	 pogi_to_neg =~(pogi)+'d1;
      end
   endfunction
   
   
   assign tmp =  tree[TREE_DEPTH][0];

   
   always_comb begin
      if(tmp[TREE_BIT_WIDTH-1] == 1'b1)
	dout = pogi_to_neg(neg_to_pogi(tmp) >>> log2(sampleSize) + 1);
      else
	dout = tmp >>> log2(sampleSize);
   end 
      
   
   
//   assign dout = tmp >>> log2(sampleSize);

   // always_comb  begin
   //    if(tmp[TREE_BIT_WIDTH-1] == 1'b1)
   // 	dout = (tmp >>> log2(sampleSize)) + 1;     //２の補数のマイナスの右シフトは切り上げた数字になるから
   //    else
   // 	dout = tmp >>> log2(sampleSize);
   // end
   
   
endmodule

`default_nettype wire
