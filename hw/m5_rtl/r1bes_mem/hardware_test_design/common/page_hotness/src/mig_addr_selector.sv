module mig_addr_selector
#(
  parameter ADDR_SIZE = 28,
  parameter CNT_SIZE = 13,
  parameter TOP_K = 2
)
(
  input clk,
  input rstn,

  output                 mig_cdc_fifo_valid,
  output [ADDR_SIZE-1:0] mig_cdc_fifo_data_in,
  input                  mig_cdc_fifo_ready,

  // top-k
  input                  even_mig_en,
  input  [ADDR_SIZE-1:0] even_top_1_addr,
  input  [ADDR_SIZE-1:0] even_top_2_addr,
  input  [ADDR_SIZE-1:0] even_top_3_addr,
  input  [ADDR_SIZE-1:0] even_top_4_addr,
  input  [ADDR_SIZE-1:0] even_top_5_addr,
  input  [CNT_SIZE-1:0]  even_top_1_cnt,
  input  [CNT_SIZE-1:0]  even_top_2_cnt,
  input  [CNT_SIZE-1:0]  even_top_3_cnt,
  input  [CNT_SIZE-1:0]  even_top_4_cnt,
  input  [CNT_SIZE-1:0]  even_top_5_cnt,
  output [2:0]           even_num_mig,
  input                  odd_mig_en,
  input  [ADDR_SIZE-1:0] odd_top_1_addr,
  input  [ADDR_SIZE-1:0] odd_top_2_addr,
  input  [ADDR_SIZE-1:0] odd_top_3_addr,
  input  [ADDR_SIZE-1:0] odd_top_4_addr,
  input  [ADDR_SIZE-1:0] odd_top_5_addr,
  input  [CNT_SIZE-1:0]  odd_top_1_cnt,
  input  [CNT_SIZE-1:0]  odd_top_2_cnt,
  input  [CNT_SIZE-1:0]  odd_top_3_cnt,
  input  [CNT_SIZE-1:0]  odd_top_4_cnt,
  input  [CNT_SIZE-1:0]  odd_top_5_cnt,
  output [2:0]           odd_num_mig
);


  /////////////////////////////////
  //--   Wire/Reg Definition   --//
  /////////////////////////////////

  logic [ADDR_SIZE-1:0] mig_addr_d0;
  logic [ADDR_SIZE-1:0] mig_addr_d1;
  logic [ADDR_SIZE-1:0] mig_addr_d2;
  logic [ADDR_SIZE-1:0] mig_addr_d3;
  logic [ADDR_SIZE-1:0] mig_addr_d4;

  logic [2:0]           mig_addr_cnt;

  logic                 mig_cdc_fifo_valid_r;

  logic                 both_mig_en;

  logic [ADDR_SIZE-1:0] final_top_1_addr;
  logic [ADDR_SIZE-1:0] final_top_2_addr;
  logic [ADDR_SIZE-1:0] final_top_3_addr;
  logic [ADDR_SIZE-1:0] final_top_4_addr;
  logic [ADDR_SIZE-1:0] final_top_5_addr;

  logic [2:0]           even_num_mig_r_top5;
  logic [2:0]           odd_num_mig_r_top5;
  logic [2:0]           even_num_mig_r_top2;
  logic [2:0]           odd_num_mig_r_top2;

  logic [2:0]           even_num_mig_wire;
  logic [2:0]           odd_num_mig_wire;
  logic [2:0]           even_num_mig_reg;
  logic [2:0]           odd_num_mig_reg;

  logic [CNT_SIZE-1:0] a1;
  logic [CNT_SIZE-1:0] a2;
  logic [CNT_SIZE-1:0] a3;
  logic [CNT_SIZE-1:0] a4;
  logic [CNT_SIZE-1:0] a5;
  logic [CNT_SIZE-1:0] b1;
  logic [CNT_SIZE-1:0] b2;
  logic [CNT_SIZE-1:0] b3;
  logic [CNT_SIZE-1:0] b4;
  logic [CNT_SIZE-1:0] b5;

  assign a1 = even_top_1_cnt;
  assign a2 = even_top_2_cnt;
  assign a3 = even_top_3_cnt;
  assign a4 = even_top_4_cnt;
  assign a5 = even_top_5_cnt;
  assign b1 = odd_top_1_cnt;
  assign b2 = odd_top_2_cnt;
  assign b3 = odd_top_3_cnt;
  assign b4 = odd_top_4_cnt;
  assign b5 = odd_top_5_cnt;

  assign mig_cdc_fifo_valid = mig_cdc_fifo_valid_r;
  assign even_num_mig       = both_mig_en ? even_num_mig_wire : even_num_mig_reg;
  assign odd_num_mig        = both_mig_en ? odd_num_mig_wire  : odd_num_mig_reg;

  assign even_num_mig_wire  = (TOP_K == 5) ? even_num_mig_r_top5 : (TOP_K == 2) ? even_num_mig_r_top2 : 3'b000;
  assign odd_num_mig_wire   = (TOP_K == 5) ? odd_num_mig_r_top5  : (TOP_K == 2) ? odd_num_mig_r_top2  : 3'b000;

  always_ff @ (posedge clk or negedge rstn) begin
    if (!rstn) begin
      even_num_mig_reg <= 3'b000;
      odd_num_mig_reg  <= 3'b000;
    end 
    else begin
      if (both_mig_en) begin
        even_num_mig_reg <= even_num_mig_wire;
        odd_num_mig_reg  <= odd_num_mig_wire;
      end
      else begin
        even_num_mig_reg <= even_num_mig_reg;
        odd_num_mig_reg  <= odd_num_mig_reg;
      end
    end
  end


  ///////////////////////////////////
  //--   Caculating Final Top 5  --//
  ///////////////////////////////////

  // We deisgined to combinational logic. If timinal violation occurs, change to sequential logic.
  assign both_mig_en = even_mig_en & odd_mig_en;

  // Final Top 1
  always_comb begin
    if      (a1 >= b1) begin
      final_top_1_addr = even_top_1_addr;
    end
    else if (b1 >  a1) begin
      final_top_1_addr = odd_top_1_addr;
    end
    else begin
      final_top_1_addr = {ADDR_SIZE{1'b1}};
    end
  end
 
  // Final Top 2
  always_comb begin
    if      ((b1 >  a1) && (a1 >= b2)) begin
      final_top_2_addr    = even_top_1_addr;
      even_num_mig_r_top2 = 3'd1;
      odd_num_mig_r_top2  = 3'd1;
    end
    else if                (a2 >= b1)  begin
      final_top_2_addr = even_top_2_addr;
      even_num_mig_r_top2 = 3'd2;
      odd_num_mig_r_top2  = 3'd0;
    end
    else if ((a1 >= b1) && (b1 >  a2)) begin
      final_top_2_addr = odd_top_1_addr;
      even_num_mig_r_top2 = 3'd1;
      odd_num_mig_r_top2  = 3'd1;
    end
    else if                (b2 >  a1) begin
      final_top_2_addr = odd_top_2_addr;
      even_num_mig_r_top2 = 3'd0;
      odd_num_mig_r_top2  = 3'd2;
    end
    else begin
      final_top_2_addr = {ADDR_SIZE{1'b1}};
      even_num_mig_r_top2 = 3'd0;
      odd_num_mig_r_top2  = 3'd0;
    end
  end

  // Final Top 3
  always_comb begin
    if      ((b2 >  a1) && (a1 >= b3)) begin
      final_top_3_addr = even_top_1_addr;
    end
    else if ((b1 >  a2) && (a2 >= b2)) begin
      final_top_3_addr = even_top_2_addr;
    end
    else if                (a3 >= b1)  begin
      final_top_3_addr = even_top_3_addr;
    end
    else if ((a2 >= b1) && (b1 >  a3)) begin
      final_top_3_addr = odd_top_1_addr;
    end
    else if ((a1 >= b2) && (b2 >  a2)) begin
      final_top_3_addr = odd_top_2_addr;
    end
    else if                (b3 >  a1) begin
      final_top_3_addr = odd_top_3_addr;
    end
    else begin
      final_top_3_addr = {ADDR_SIZE{1'b1}};
    end
  end

  // Final Top 4
  always_comb begin
    if      ((b3 >  a1) && (a1 >= b4)) begin
      final_top_4_addr = even_top_1_addr;
    end
    else if ((b2 >  a2) && (a2 >= b3)) begin
      final_top_4_addr = even_top_2_addr;
    end
    else if ((b1 >  a3) && (a3 >= b2)) begin
      final_top_4_addr = even_top_3_addr;
    end
    else if                (a4 >= b1)  begin
      final_top_4_addr = even_top_4_addr;
    end
    else if ((a3 >= b1) && (b1 >  a4)) begin
      final_top_4_addr = odd_top_1_addr;
    end
    else if ((a2 >= b2) && (b2 >  a3)) begin
      final_top_4_addr = odd_top_2_addr;
    end
    else if ((a1 >= b3) && (b3 >  a2)) begin
      final_top_4_addr = odd_top_3_addr;
    end
    else if                (b4 >  a1) begin
      final_top_4_addr = odd_top_4_addr;
    end
    else begin
      final_top_4_addr = {ADDR_SIZE{1'b1}};
    end
  end

  // Final Top 5
  always_comb begin
    if      ((b4 >  a1) && (a1 >= b5)) begin
      final_top_5_addr    = even_top_1_addr;
      even_num_mig_r_top5 = 3'd1;
      odd_num_mig_r_top5  = 3'd4;
    end
    else if ((b3 >  a2) && (a2 >= b4)) begin
      final_top_5_addr    = even_top_2_addr;
      even_num_mig_r_top5 = 3'd2;
      odd_num_mig_r_top5  = 3'd3;
    end
    else if ((b2 >  a3) && (a3 >= b3)) begin
      final_top_5_addr    = even_top_3_addr;
      even_num_mig_r_top5 = 3'd3;
      odd_num_mig_r_top5  = 3'd2;
    end
    else if ((b1 >  a4) && (a4 >= b2)) begin
      final_top_5_addr    = even_top_4_addr;
      even_num_mig_r_top5 = 3'd4;
      odd_num_mig_r_top5  = 3'd1;
    end
    else if                (a5 >= b1)  begin
      final_top_5_addr    = even_top_5_addr;
      even_num_mig_r_top5 = 3'd5;
      odd_num_mig_r_top5  = 3'd0;
    end
    else if ((a4 >= b1) && (b1 >  a5)) begin
      final_top_5_addr    = odd_top_1_addr;
      even_num_mig_r_top5 = 3'd4;
      odd_num_mig_r_top5  = 3'd1;
    end
    else if ((a3 >= b2) && (b2 >  a4)) begin
      final_top_5_addr    = odd_top_2_addr;
      even_num_mig_r_top5 = 3'd3;
      odd_num_mig_r_top5  = 3'd2;
    end
    else if ((a2 >= b3) && (b3 >  a3)) begin
      final_top_5_addr    = odd_top_3_addr;
      even_num_mig_r_top5 = 3'd2;
      odd_num_mig_r_top5  = 3'd3;
    end
    else if ((a1 >= b4) && (b4 >  a2)) begin
      final_top_5_addr    = odd_top_4_addr;
      even_num_mig_r_top5 = 3'd1;
      odd_num_mig_r_top5  = 3'd4;
    end
    else if                (b5 >  a1) begin
      final_top_5_addr    = odd_top_5_addr;
      even_num_mig_r_top5 = 3'd0;
      odd_num_mig_r_top5  = 3'd5;
    end
    else begin
      final_top_5_addr    = {ADDR_SIZE{1'b1}};
      even_num_mig_r_top5 = 3'd0;
      odd_num_mig_r_top5  = 3'd0;
    end
  end


  ////////////////////////////////
  //--   Sending Final Top 5  --//
  ////////////////////////////////

  assign mig_cdc_fifo_data_in = mig_addr_d0;

  always_ff @(posedge clk or negedge rstn) begin
    if(!rstn) begin
      mig_cdc_fifo_valid_r <= 1'b0;
    end
    else begin
      if (both_mig_en) begin
        mig_cdc_fifo_valid_r <= 1'b1;
      end 
      else if (mig_addr_cnt == TOP_K) begin
        mig_cdc_fifo_valid_r <= 1'b0;
      end
      else begin
        mig_cdc_fifo_valid_r <= mig_cdc_fifo_valid_r;
      end
    end
  end

  always_ff @ (posedge clk or negedge rstn) begin
    if (!rstn) begin
      mig_addr_d0 <= {28{1'b1}};
      mig_addr_d1 <= {28{1'b1}};
      mig_addr_d2 <= {28{1'b1}};
      mig_addr_d3 <= {28{1'b1}};
      mig_addr_d4 <= {28{1'b1}};
    end
    else begin
      // send mig address
      if (mig_cdc_fifo_valid_r & mig_cdc_fifo_ready) begin
        mig_addr_d0 <= mig_addr_d1;
        mig_addr_d1 <= mig_addr_d2;
        mig_addr_d2 <= mig_addr_d3;
        mig_addr_d3 <= mig_addr_d4;
        mig_addr_d4 <= {28{1'b1}};
      end
      // insert top-k address
      else if (both_mig_en) begin
        mig_addr_d0 <= final_top_1_addr;
        mig_addr_d1 <= final_top_2_addr;
        mig_addr_d2 <= final_top_3_addr;
        mig_addr_d3 <= final_top_4_addr;
        mig_addr_d4 <= final_top_5_addr;
      end
      else begin 
        mig_addr_d0 <= mig_addr_d0;
        mig_addr_d1 <= mig_addr_d1;
        mig_addr_d2 <= mig_addr_d2;
        mig_addr_d3 <= mig_addr_d3;
        mig_addr_d4 <= mig_addr_d4;
      end
    end
  end

  always_ff @ (posedge clk or negedge rstn) begin
    if (!rstn) begin
      mig_addr_cnt <= 3'd0;
    end
    else begin
      if (mig_cdc_fifo_valid_r & mig_cdc_fifo_ready) begin
        mig_addr_cnt <= mig_addr_cnt + 3'd1;
      end
      else if (both_mig_en) begin
        mig_addr_cnt <= 3'd1;
      end
      else begin 
        mig_addr_cnt <= mig_addr_cnt;
      end
    end
  end

endmodule
