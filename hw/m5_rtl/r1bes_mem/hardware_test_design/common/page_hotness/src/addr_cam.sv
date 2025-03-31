module addr_cam
#(
  parameter WORD_SIZE = 28,
  parameter CNT_SIZE = 13,
  parameter NUM_ENTRY = 50,
  parameter ENTRY_WIDTH = 6, // [log2(NUM_ENTRY)]
  parameter TOP_K = 5
)
(
  input                   clk,
  input                   reset,
  input                   search_en,
  input                   write_en,
  input                   sort_en,
  input                   mig_en,
  input [WORD_SIZE-1:0]   search_addr,
  input [WORD_SIZE-1:0]   write_addr,
  input [ENTRY_WIDTH-1:0] write_rank,
  input [ENTRY_WIDTH-1:0] sort_hit_rank,
  input [ENTRY_WIDTH-1:0] sort_new_rank,
  input [ENTRY_WIDTH-1:0] minptr,

  output                   match,
  output [ENTRY_WIDTH-1:0] match_rank,
  output [WORD_SIZE-1:0]   top_1,
  output [WORD_SIZE-1:0]   top_2,
  output [WORD_SIZE-1:0]   top_3,
  output [WORD_SIZE-1:0]   top_4,
  output [WORD_SIZE-1:0]   top_5,
  input  [2:0]             num_mig
);

  wire                 we_array             [NUM_ENTRY-1:0];
  wire [WORD_SIZE-1:0] data_array_in        [0:NUM_ENTRY-1];
  wire [NUM_ENTRY-1:0] match_array;

  reg  [WORD_SIZE-1:0] sort_data_array_in   [0:NUM_ENTRY-1];
  reg  [WORD_SIZE-1:0] mig_data_array_in    [0:NUM_ENTRY-1];

  wire [WORD_SIZE-1:0] data_array_out       [0:NUM_ENTRY+TOP_K-1];

  wire                 top_k_cache_table_we;
  wire [WORD_SIZE-1:0] top_k_data_array_in  [0:TOP_K-1]; 
  wire [WORD_SIZE-1:0] top_k_data_array_out [0:TOP_K-1]; 

  genvar i, j, k;

  generate for (j = 0; j < NUM_ENTRY; j = j + 1) begin
    always_comb begin   
      if (sort_en) begin
        if(j == sort_new_rank) begin
          sort_data_array_in[j] = data_array_out[sort_hit_rank];
        end
        else if ((j <= sort_hit_rank) && (j > sort_new_rank)) begin
          sort_data_array_in[j] = data_array_out[j-1];
        end 
        else begin
          sort_data_array_in[j] = data_array_out[j];
        end
      end
      else begin
        sort_data_array_in[j] = {WORD_SIZE{1'b1}};
      end
    end

    always_comb begin   
      if (mig_en & (minptr >= num_mig) & (j < (minptr - num_mig))) begin
        mig_data_array_in[j] = data_array_out[j+num_mig];
      end
      else begin
        mig_data_array_in[j] = {WORD_SIZE{1'b1}};
      end
    end
  end
  endgenerate

  generate for (i = 0; i < NUM_ENTRY; i = i+1) begin: ffarray_inst
    assign we_array[i]      = reset ? 1 : (write_en & (write_rank == i)) || sort_en || mig_en;
    assign data_array_in[i] = reset ? {WORD_SIZE{1'b1}} : 
                                      write_en ? write_addr : 
                                                 sort_en ? sort_data_array_in[i] : 
                                                           mig_en ? mig_data_array_in[i] : 
                                                                    {WORD_SIZE{1'b1}};

    FF_array
    #(
        .WORD_SIZE ( WORD_SIZE )
    )
      FF_array_
    (
        .clk       ( clk               ),
        .data_in   ( data_array_in[i]  ),
        .write_en  ( we_array[i]       ),
        .search_en ( search_en         ),
        .data_out  ( data_array_out[i] ),
        .match     ()
    );

    assign match_array[i] = search_en ? (data_array_out[i] == search_addr) : 0;
  end
  endgenerate


  /*
  assign top_k_cache_table_we = reset ? 1 : mig_en; 

  generate for (k = 0; k < TOP_K; k = k+1) begin: top_k_cache_table_inst
          
      assign top_k_data_array_in[k] = reset ? 0 : data_array_out[k];

      FF_array #(.WORD_SIZE(WORD_SIZE)) top_k_cache_table(.clk (clk), .data_in(top_k_data_array_in[k]), 
        .write_en(top_k_cache_table_we), .search_en(1'b0), .data_out(top_k_data_array_out[k]), .match());
      end
  endgenerate


  assign top_1 = top_k_data_array_out[0];
  assign top_2 = (TOP_K > 1) ? top_k_data_array_out[1] : {WORD_SIZE{1'b0}};
  assign top_3 = (TOP_K > 2) ? top_k_data_array_out[2] : {WORD_SIZE{1'b0}};
  assign top_4 = (TOP_K > 3) ? top_k_data_array_out[3] : {WORD_SIZE{1'b0}};
  assign top_5 = (TOP_K > 4) ? top_k_data_array_out[4] : {WORD_SIZE{1'b0}};
  */

  assign top_1 = data_array_out[0];
  assign top_2 = (TOP_K > 1) ? data_array_out[1] : {WORD_SIZE{1'b1}};
  assign top_3 = (TOP_K > 2) ? data_array_out[2] : {WORD_SIZE{1'b1}};
  assign top_4 = (TOP_K > 3) ? data_array_out[3] : {WORD_SIZE{1'b1}};
  assign top_5 = (TOP_K > 4) ? data_array_out[4] : {WORD_SIZE{1'b1}};


  encoder
  #(
    .NUM_ENTRY   ( NUM_ENTRY   ),
    .ENTRY_WIDTH ( ENTRY_WIDTH )
  )
    encoder_
  (
    .match_array ( match_array ),
    .match       ( match       ),
    .match_addr  ( match_rank  )
  );

endmodule
