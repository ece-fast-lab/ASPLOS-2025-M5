module cam
#(
  parameter NUM_ENTRY = 25,
  parameter INDEX_SIZE = 5, // $clog2(NUM_ENTRY)
  parameter ADDR_SIZE = 22,
  parameter CNT_SIZE = 32
)
(
  input                        clk,
  input                        rst_n,

  input                        input_valid,
  input        [ADDR_SIZE-1:0] input_addr,
  input        [CNT_SIZE-1:0]  input_cnt
);
  
  /////////////////////////////////////////////////////////////
  genvar i;
  integer j, k;

  logic        [ADDR_SIZE-1:0]  addr;
  logic        [CNT_SIZE-1:0]   cnt;

  logic                         hit;
  logic        [INDEX_SIZE-1:0] hit_index, hit_index_wire; 
  //logic        [INDEX_SIZE-1:0] insert_index; 

  logic        [ADDR_SIZE-1:0]  addr_array [0:NUM_ENTRY-1]; 
  logic        [CNT_SIZE-1:0]   cnt_array [0:NUM_ENTRY-1];

  (* preserve_for_debug *) logic        [CNT_SIZE-1:0]   cnt_array_0;
  assign cnt_array_0 = cnt_array[0];


  logic        [NUM_ENTRY:0]    cnt_search_result;

  logic                         xor_array [0:NUM_ENTRY-1];
  logic                         and_array [0:NUM_ENTRY-1];
  
  // Parameters for FSM states
  localparam STATE_IDLE  				= 3'd0;
  localparam STATE_REQ  				= 3'd1;
  localparam STATE_HIT   	      = 3'd2;
  localparam STATE_MISS  				= 3'd3;

  (* preserve_for_debug *) logic        [2:0]            state, next_state;

  /////////////////////////////////////////////////////////////
  // State transition
  always_comb begin
    next_state = STATE_IDLE;
    case(state)
      STATE_IDLE: begin
        if (input_valid) begin
          next_state = STATE_REQ;
        end
      end
      STATE_REQ: begin
        if (hit) begin
          next_state = STATE_HIT;
        end
        else begin
          next_state = STATE_MISS;
        end
      end
      STATE_HIT: begin
        if (input_valid) begin
          next_state = STATE_REQ;
        end
      end
      STATE_MISS: begin
        if (input_valid) begin
          next_state = STATE_REQ;
        end
      end
      default:;
    endcase 
  end

  always_ff @ (posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state <= 3'b0;
    end
    else begin
      state <= next_state;
    end
  end

  /////////////////////////////////////////////////////////////
  // input addr, cnt capture
  always_ff @ (posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      addr <= 3'b0;
      cnt <= 3'b0;
    end
    else if (input_valid && ((state == STATE_IDLE) || (state == STATE_HIT) || (state == STATE_MISS))) begin
      addr <= input_addr;
      cnt <= input_cnt;
    end
    else begin
      addr <= addr;
      cnt <= cnt;
    end
  end

  /////////////////////////////////////////////////////////////
  // addr, cnt table update
  // index 0
  always_ff @ (posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      addr_array[0] <= {ADDR_SIZE{1'b0}};
      cnt_array[0] <= {CNT_SIZE{1'b0}};
    end
    else if (state == STATE_HIT) begin
      if (xor_array[0]) begin
        addr_array[0] <= addr;
        cnt_array[0] <= cnt; 
      end
      else begin
        addr_array[0] <= addr_array[0];
        cnt_array[0] <= cnt_array[0];     
      end
    end
    else if (state == STATE_MISS) begin
      if (xor_array[0]) begin
        addr_array[0] <= addr;
        cnt_array[0] <= cnt; 
      end
      else begin
        addr_array[0] <= addr_array[0];
        cnt_array[0] <= cnt_array[0];     
      end
    end
    else begin
      addr_array[0] <= addr_array[0];
      cnt_array[0] <= cnt_array[0];   
    end
  end
  // index 1 ~ NUM_ENTRY-1
  generate
    for (i = 1; i < NUM_ENTRY; i++) begin
      always_ff @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
          addr_array[i] <= {ADDR_SIZE{1'b0}};
          cnt_array[i] <= {CNT_SIZE{1'b0}};
        end
        // hit
        else if ((state == STATE_HIT) && (i <= hit_index)) begin
          if (xor_array[i]) begin
            addr_array[i] <= addr;
            cnt_array[i] <= cnt; 
          end
          else if (and_array[i]) begin
            addr_array[i] <= addr_array[i-1];
            cnt_array[i] <= cnt_array[i-1];
          end
          else begin
            addr_array[i] <= addr_array[i];
            cnt_array[i] <= cnt_array[i];
          end              
        end
        // miss
        else if (state == STATE_MISS) begin
          if (xor_array[i]) begin
            addr_array[i] <= addr;
            cnt_array[i] <= cnt;            
          end
          else if (and_array[i]) begin
            addr_array[i] <= addr_array[i-1];
            cnt_array[i] <= cnt_array[i-1];
          end
          else begin
            addr_array[i] <= addr_array[i];
            cnt_array[i] <= cnt_array[i];
          end
        end
        // default
        else begin
          addr_array[i] <= addr_array[i];
          cnt_array[i] <= cnt_array[i];
        end
      end
    end
  endgenerate

  /////////////////////////////////////////////////////////////
  // addr CAM search
  always_comb begin
    hit = 1'b0;
    hit_index_wire = {INDEX_SIZE{1'b0}};
    for (j = 0; j < NUM_ENTRY; j++) begin
      if ((addr_array[j] == addr)) begin
        hit = 1'b1;
        hit_index_wire = j;
      end
    end
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      hit_index <= {INDEX_SIZE{1'b0}};
    end
    else if (state == STATE_REQ) begin
      hit_index <= hit_index_wire;
    end
    else begin
      hit_index <= {INDEX_SIZE{1'b0}};
    end
  end

  // count CAM search
  always_ff @(posedge clk or negedge rst_n) begin
    cnt_search_result[0] <= 0;
  end

  generate
    for (i = 0; i < NUM_ENTRY; i++) begin
      always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
          cnt_search_result[i+1] <= 0;
        end
        else begin
          cnt_search_result[i+1] <= (cnt > cnt_array[i]);
        end
      end
    end
  endgenerate

  always_comb begin
    for (k = 0; k < NUM_ENTRY; k++) begin
      xor_array[k] = cnt_search_result[k] ^ cnt_search_result[k+1];
      and_array[k] = cnt_search_result[k] & cnt_search_result[k+1];
    end
  end

  // Count CAM search method 1 : basic
  /*
  always_comb begin
    insert_index = NUM_ENTRY;
    for(k = 0; k < NUM_ENTRY; k++) begin
      insert_index -= cnt_search_result[k];
    end  
  end
  */

  // Count CAM search method 2 : using lookup table
  /*
  always_comb begin
    case(cnt_search_result)
      25'b0000000000000000000000000: insert_index = {INDEX_SIZE{5'd25}};
      25'b1000000000000000000000000: insert_index = {INDEX_SIZE{5'd24}};
      25'b1100000000000000000000000: insert_index = {INDEX_SIZE{5'd23}};
      25'b1110000000000000000000000: insert_index = {INDEX_SIZE{5'd22}};
      25'b1111000000000000000000000: insert_index = {INDEX_SIZE{5'd21}};
      25'b1111100000000000000000000: insert_index = {INDEX_SIZE{5'd20}};
      25'b1111110000000000000000000: insert_index = {INDEX_SIZE{5'd19}};
      25'b1111111000000000000000000: insert_index = {INDEX_SIZE{5'd18}};
      25'b1111111100000000000000000: insert_index = {INDEX_SIZE{5'd17}};
      25'b1111111110000000000000000: insert_index = {INDEX_SIZE{5'd16}};
      25'b1111111111000000000000000: insert_index = {INDEX_SIZE{5'd15}};
      25'b1111111111100000000000000: insert_index = {INDEX_SIZE{5'd14}};
      25'b1111111111110000000000000: insert_index = {INDEX_SIZE{5'd13}};
      25'b1111111111111000000000000: insert_index = {INDEX_SIZE{5'd12}};
      25'b1111111111111100000000000: insert_index = {INDEX_SIZE{5'd11}};
      25'b1111111111111110000000000: insert_index = {INDEX_SIZE{5'd10}};
      25'b1111111111111111000000000: insert_index = {INDEX_SIZE{5'd9}};
      25'b1111111111111111100000000: insert_index = {INDEX_SIZE{5'd8}};
      25'b1111111111111111110000000: insert_index = {INDEX_SIZE{5'd7}};
      25'b1111111111111111111000000: insert_index = {INDEX_SIZE{5'd6}};
      25'b1111111111111111111100000: insert_index = {INDEX_SIZE{5'd5}};
      25'b1111111111111111111110000: insert_index = {INDEX_SIZE{5'd4}};
      25'b1111111111111111111111000: insert_index = {INDEX_SIZE{5'd3}};
      25'b1111111111111111111111100: insert_index = {INDEX_SIZE{5'd2}};
      25'b1111111111111111111111110: insert_index = {INDEX_SIZE{5'd1}};
      25'b1111111111111111111111111: insert_index = {INDEX_SIZE{5'd0}};
      default: insert_index = {INDEX_SIZE{5'd25}};
    endcase
  end
  */
  /////////////////////////////////////////////////////////////

endmodule


