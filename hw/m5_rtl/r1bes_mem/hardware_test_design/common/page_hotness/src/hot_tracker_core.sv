`timescale 1ns / 1ps

module hot_tracker_core
#(
  parameter NUM_ENTRY = 50,
  parameter NUM_ENTRY_BITS = 6, // log2 (NUM_ENTRY)
  //parameter NUM_ENTRY = 16,
  //parameter NUM_ENTRY_BITS = 4, // log2 (NUM_ENTRY)
  parameter TOP_K = 5,
  parameter ADDR_SIZE = 28, // Cache line input size
  parameter CNT_SIZE = 13,
  parameter CMD_WIDTH = 4
)
(
  input clk,
  input rstn,

  input  [ADDR_SIZE-1:0]        input_addr,
  input                         input_addr_valid,
  output logic                  input_addr_ready,

  // hot tracker interface
  input                         query_en,
  input  [CMD_WIDTH-1:0]        query_cmd,
  output logic                  query_ready,
  input logic                   both_query_ready,
//  output logic                  mig_addr_en,
//  output logic [ADDR_SIZE-1:0]  mig_addr,
//  input                         mig_addr_ready,

  // top-k
  output                        mig_en,
  output [ADDR_SIZE-1:0]        top_1_addr,
  output [ADDR_SIZE-1:0]        top_2_addr,
  output [ADDR_SIZE-1:0]        top_3_addr,
  output [ADDR_SIZE-1:0]        top_4_addr,
  output [ADDR_SIZE-1:0]        top_5_addr,
  output [CNT_SIZE-1:0]         top_1_cnt,
  output [CNT_SIZE-1:0]         top_2_cnt,
  output [CNT_SIZE-1:0]         top_3_cnt,
  output [CNT_SIZE-1:0]         top_4_cnt,
  output [CNT_SIZE-1:0]         top_5_cnt,

  input  [2:0]                  num_mig
);

localparam UPDATE_TIME = 5'd1;

// Parameters for FSM states
localparam STATE_IDLE  				= 3'd0;
localparam STATE_REQ  				= 3'd1;
localparam STATE_HIT   				= 3'd2;
localparam STATE_MISS  				= 3'd3;
localparam STATE_MIG   				= 3'd4;
localparam STATE_TOPK_READY   = 3'd5;
localparam STATE_FLUSH        = 3'd6;

// query opcode
localparam QUERY_IDLE         = 4'd0;
localparam QUERY_MIG          = 4'd1;
localparam QUERY_FLUSH        = 4'd2;

logic [2:0]   state, next_state;

logic         table_hit;
logic [NUM_ENTRY_BITS-1:0] minptr;
//logic [NUM_ENTRY_BITS-1:0] new_minptr;
//logic [CNT_SIZE-1:0]       minptr_count;
logic [NUM_ENTRY_BITS-1:0] hit_rank;
logic                      minptr_update_stall;

//logic [ADDR_SIZE-1:0]   mig_addr_d0;
//logic [ADDR_SIZE-1:0]   mig_addr_d1;
//logic [ADDR_SIZE-1:0]   mig_addr_d2;
//logic [ADDR_SIZE-1:0]   mig_addr_d3;
//logic [ADDR_SIZE-1:0]   mig_addr_d4;
//logic [ADDR_SIZE-1:0]   top_1;
//logic [ADDR_SIZE-1:0]   top_2;
//logic [ADDR_SIZE-1:0]   top_3;
//logic [ADDR_SIZE-1:0]   top_4;
//logic [ADDR_SIZE-1:0]   top_5;


/* ADDRESS CAM */
wire 													addr_cam_search_en;                
wire [ADDR_SIZE-1:0] 					addr_cam_search_addr;            
wire 													addr_cam_write_en;                 
wire [NUM_ENTRY_BITS-1:0]	 		addr_cam_write_rank;               
wire [ADDR_SIZE-1:0]       		addr_cam_write_addr;               
wire 													addr_cam_sort_en;                 
wire [NUM_ENTRY_BITS-1:0]			addr_cam_sort_hit_rank;                   
wire 													addr_cam_mig_en;
wire [NUM_ENTRY_BITS-1:0] 		addr_cam_minptr;
wire 													addr_cam_reset; 
wire 													addr_cam_match;
wire [NUM_ENTRY_BITS-1:0] 		addr_cam_match_rank;

/* COUNT CAM */
wire 													cnt_cam_incremental_en;
wire [NUM_ENTRY_BITS-1:0] 		cnt_cam_incremental_rank;
wire [NUM_ENTRY_BITS-1:0] 		cnt_cam_hit_compare_rank;
wire 													cnt_cam_sort_en;
wire [NUM_ENTRY_BITS-1:0] 		cnt_cam_sort_hit_rank;
//wire [NUM_ENTRY_BITS-1:0] 		cnt_cam_sort_new_rank;
wire 													cnt_cam_mig_en;
wire [NUM_ENTRY_BITS-1:0] 		cnt_cam_minptr;        
wire 													cnt_cam_reset;
wire [NUM_ENTRY_BITS-1:0] 		cnt_cam_new_rank;
wire [NUM_ENTRY_BITS-1:0] 		cnt_cam_new_minptr;

//assign mig_addr = mig_addr_d0;

reg  query_en_d;
wire query_en_r;
reg  [CMD_WIDTH-1:0] query_cmd_d;
wire [CMD_WIDTH-1:0] query_cmd_r;

always_comb begin
  next_state = STATE_IDLE;

  case(state)
    STATE_IDLE: begin
      if (query_en_r & (~both_query_ready)) begin
        next_state = STATE_IDLE;
      end
      else if (query_en_r & both_query_ready & (query_cmd_r == QUERY_FLUSH)) begin
        next_state = STATE_FLUSH;
      end
      else if (query_en_r& both_query_ready & (query_cmd_r == QUERY_MIG)) begin
        next_state = STATE_MIG;
      end
      else if (input_addr_valid & ~(query_en_r & (query_cmd_r == QUERY_MIG))) begin
        next_state = STATE_REQ;
      end
      else begin
        next_state = STATE_IDLE;
      end
    end
    STATE_REQ: begin
      if (input_addr_valid & input_addr_ready) begin
        if (table_hit) begin
          next_state = STATE_HIT;
        end
        else begin
          next_state = STATE_MISS;
        end
      end
      else if (~input_addr_valid) begin
        next_state = STATE_IDLE;
      end
      else begin
        next_state = STATE_REQ;
      end
    end
    STATE_HIT: begin
      next_state = STATE_IDLE;
      if (query_en_r & (~both_query_ready)) begin
        next_state = STATE_IDLE;
      end
      else if (query_en_r & both_query_ready & (query_cmd_r == QUERY_MIG)) begin
        next_state = STATE_MIG;
      end
      else if (input_addr_valid & ~(query_en_r & (query_cmd_r == QUERY_MIG))) begin
        next_state = STATE_REQ;
      end
    end
    STATE_MISS: begin
      next_state = STATE_IDLE;
      if (query_en_r & (~both_query_ready)) begin
        next_state = STATE_IDLE;
      end
      else if (query_en_r & both_query_ready & (query_cmd_r == QUERY_MIG)) begin
        next_state = STATE_MIG;
      end
      else if (input_addr_valid & ~(query_en_r & (query_cmd_r == QUERY_MIG))) begin
        next_state = STATE_REQ;
      end
    end
    STATE_MIG: begin
      next_state = STATE_TOPK_READY;
    end
    STATE_TOPK_READY: begin
      next_state = STATE_IDLE;
      if (input_addr_valid) begin
        next_state = STATE_REQ;
      end
    end
    STATE_FLUSH: begin // We don't use STATE_FLUSH
      next_state = STATE_IDLE;
      if (query_en_r & (~both_query_ready)) begin
        next_state = STATE_IDLE;
      end
      else if (query_en_r & both_query_ready & (query_cmd_r == QUERY_MIG)) begin
        next_state = STATE_MIG;
      end
      else if (input_addr_valid & ~(query_en_r & (query_cmd_r == QUERY_MIG))) begin
        next_state = STATE_REQ;
      end
    end
    default:;
  endcase
end

always_ff @ (posedge clk or negedge rstn) begin
  if (!rstn) begin
    state <= 3'b0;
  end
  else begin
    state <= next_state;
  end
end

always_ff @ (posedge clk or negedge rstn) begin
  if (!rstn) begin
    input_addr_ready <= 1'b1;
  end
  else begin
    if (next_state == STATE_REQ) begin
      if (input_addr_valid)
        input_addr_ready <= 1'b1;
      else 
        input_addr_ready <= 1'b0;
    end
    else begin
      input_addr_ready <= 1'b0;
    end
  end
end

assign query_ready = query_en_r & ((state == STATE_IDLE) | (state == STATE_HIT) | (state == STATE_MISS));

assign mig_en = (state==STATE_MIG);


// hit_rank 
always_ff @(posedge clk or negedge rstn) begin
  if(!rstn) begin
		hit_rank <= {NUM_ENTRY_BITS{1'b0}};
  end
  else begin
    if ((state == STATE_REQ) && table_hit) begin
		  hit_rank <= addr_cam_match_rank;
    end
    else begin
      hit_rank <= hit_rank;
    end
  end
end


// minptr
always_ff @(posedge clk or negedge rstn) begin
  if(!rstn) begin
    minptr <= {NUM_ENTRY_BITS{1'b0}};
  end
  else begin
    if ((state == STATE_REQ) && minptr_update_stall) begin
      minptr <= cnt_cam_new_minptr;
    end
    else if ((state == STATE_HIT) & (cnt_cam_new_rank == minptr)) begin
      minptr <= cnt_cam_new_rank + 1;
    end
    else if (state == STATE_MISS) begin
      if (minptr == (NUM_ENTRY-1)) begin
        minptr <= minptr;
      end
      else begin
        minptr <= minptr + 1;
      end
    end
    else if (state == STATE_TOPK_READY) begin
      //if (minptr >= TOP_K) begin
        //minptr <= minptr - TOP_K;
      if (minptr >= num_mig) begin
        minptr <= minptr - num_mig;
      end
      else begin
        minptr <= {NUM_ENTRY_BITS{1'b0}};
      end
    end
    else begin
      minptr <= minptr;
    end
  end
end

// minptr_update_stall
always_ff @(posedge clk or negedge rstn) begin
  if(!rstn) begin
    minptr_update_stall <= 1'b0;
  end
  else begin
    if ((state == STATE_REQ) && minptr_update_stall) begin
      minptr_update_stall <= 1'b0;
    end
    else if ((state == STATE_MISS) && (minptr == (NUM_ENTRY-1)))begin
      minptr_update_stall <= 1'b1;
    end
    else begin
      minptr_update_stall <= minptr_update_stall; 
    end
  end
end


assign table_hit = addr_cam_match;

/* ADDR CAM input signal */
assign addr_cam_search_en               = (state == STATE_REQ);
assign addr_cam_search_addr             = input_addr;

assign addr_cam_write_en                = (state == STATE_MISS);
assign addr_cam_write_rank              = minptr;
assign addr_cam_write_addr              = input_addr;

assign addr_cam_sort_en                 = (state == STATE_HIT);
assign addr_cam_sort_hit_rank           = hit_rank; 

assign addr_cam_mig_en                  = (state == STATE_MIG);
assign addr_cam_minptr                  = minptr;

assign addr_cam_reset                   = ~rstn;

/* COUNTER CAM input signal */
assign cnt_cam_incremental_en           = (state == STATE_MISS);
assign cnt_cam_incremental_rank         = (state == STATE_HIT) ? hit_rank : minptr;

assign cnt_cam_hit_compare_rank         = addr_cam_match_rank;

assign cnt_cam_sort_en                  = (state == STATE_HIT);
assign cnt_cam_sort_hit_rank            = hit_rank; 

assign cnt_cam_mig_en                   = (state == STATE_MIG);
assign cnt_cam_minptr                   = minptr;

assign cnt_cam_reset                    = ~rstn;



// Query enable
always_ff @ (posedge clk or negedge rstn) begin
  if (!rstn) begin
    query_en_d <= 1'b0;
  end
  else begin
    if (query_en & (~both_query_ready)) begin
      query_en_d <= 1'b1;
    end
    else if (query_en_d & both_query_ready) begin
      query_en_d <= 1'b0;
    end
    else begin
      query_en_d <= query_en_d;
    end
  end
end

assign query_en_r = query_en ? query_en : query_en_d;

// Query Command
always_ff @ (posedge clk or negedge rstn) begin
  if (!rstn) begin
    query_cmd_d <= {CMD_WIDTH{1'b0}};
  end
  else begin
    if (query_en) begin
      query_cmd_d <= query_cmd;
    end
    else if (query_en_d & both_query_ready) begin
      query_cmd_d <= {CMD_WIDTH{1'b0}};
    end
    else begin
      query_cmd_d <= query_cmd_d;
    end
  end
end

assign query_cmd_r = query_en ? query_cmd : query_cmd_d;



addr_cam 
#(
  .WORD_SIZE(ADDR_SIZE),
  .CNT_SIZE(CNT_SIZE), 
  .NUM_ENTRY(NUM_ENTRY), 
  .ENTRY_WIDTH(NUM_ENTRY_BITS),
  .TOP_K(TOP_K)
) 
  u_addr_cam 
(
  .clk(clk), 
  .reset(addr_cam_reset), 

  .search_en(addr_cam_search_en), 
  .search_addr(addr_cam_search_addr), 

  .write_en(addr_cam_write_en), 
  .write_rank(addr_cam_write_rank), 
  .write_addr(addr_cam_write_addr), 

  .sort_en(addr_cam_sort_en), 
  .sort_hit_rank(addr_cam_sort_hit_rank), 
  .sort_new_rank(cnt_cam_new_rank), 
  .mig_en(addr_cam_mig_en), 
  .minptr(addr_cam_minptr),

  .match(addr_cam_match), 
  .match_rank(addr_cam_match_rank), 

  .top_1(top_1_addr),
  .top_2(top_2_addr), 
  .top_3(top_3_addr), 
  .top_4(top_4_addr), 
  .top_5(top_5_addr),

  .num_mig(num_mig)
);

cnt_cam 
#(
  .CNT_SIZE(CNT_SIZE), 
  .NUM_ENTRY(NUM_ENTRY), 
  .ENTRY_WIDTH(NUM_ENTRY_BITS),
  .TOP_K(TOP_K)
) 
  u_cnt_cam 
(
  .clk(clk), 
  .reset(cnt_cam_reset), 

  .incremental_en(cnt_cam_incremental_en), 
  .incremental_rank(cnt_cam_incremental_rank), 

  .hit_compare_rank(cnt_cam_hit_compare_rank), 

  .sort_en(cnt_cam_sort_en), 
  .sort_hit_rank(cnt_cam_sort_hit_rank), 
  .mig_en(cnt_cam_mig_en), 

  .minptr(cnt_cam_minptr), 
  .new_rank(cnt_cam_new_rank), 
  .new_minptr(cnt_cam_new_minptr),

  .top_1(top_1_cnt),
  .top_2(top_2_cnt), 
  .top_3(top_3_cnt), 
  .top_4(top_4_cnt), 
  .top_5(top_5_cnt),

  .num_mig(num_mig)
);

endmodule
