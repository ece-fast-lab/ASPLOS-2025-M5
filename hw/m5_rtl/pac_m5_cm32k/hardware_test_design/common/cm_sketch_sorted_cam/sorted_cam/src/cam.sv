module cam_top
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
  logic        [INDEX_SIZE-1:0] insert_index; 

  logic        [ADDR_SIZE-1:0]  addr_array [0:NUM_ENTRY-1]; 
  logic        [CNT_SIZE-1:0]   cnt_array [0:NUM_ENTRY-1];

  logic                         cnt_search_result [0:NUM_ENTRY-1]; 
  
  // Parameters for FSM states
  localparam STATE_IDLE  				= 3'd0;
  localparam STATE_REQ  				= 3'd1;
  localparam STATE_HIT   	      = 3'd2;
  localparam STATE_MISS  				= 3'd3;

  logic        [2:0]            state, next_state;

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
  generate
    for (i = 0; i < NUM_ENTRY; i++) begin
      always_ff @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
          addr_array[i] <= {ADDR_SIZE{1'b0}};
          cnt_array[i] <= {CNT_SIZE{1'b0}};
        end

        else if (state == STATE_HIT) begin
          if ((insert_index < hit_index) && (insert_index != NUM_ENTRY)) begin // Prevent updates to lower counts
            if (i == insert_index) begin                                       // What doesn't happen in a full system 
              addr_array[i] <= addr;                                           // include CM-sketch
              cnt_array[i] <= cnt;  
            end
            else if ((i > insert_index) && (i <= hit_index)) begin
              addr_array[i] <= addr_array[i-1];
              cnt_array[i] <= cnt_array[i-1];
            end
            else begin
              addr_array[i] <= addr_array[i];
              cnt_array[i] <= cnt_array[i];
            end
          end
          else if (insert_index == hit_index) begin
            if (i == insert_index) begin
              addr_array[i] <= addr;
              cnt_array[i] <= cnt; 
            end
            else begin
              addr_array[i] <= addr_array[i];
              cnt_array[i] <= cnt_array[i];
            end
          end
          else begin
            addr_array[i] <= addr_array[i];
            cnt_array[i] <= cnt_array[i];
          end
        end 

        else if ((state == STATE_MISS) && (insert_index != NUM_ENTRY)) begin
          if (i == insert_index) begin
            addr_array[i] <= addr;
            cnt_array[i] <= cnt;            
          end
          else if (i > insert_index) begin
            addr_array[i] <= addr_array[i-1];
            cnt_array[i] <= cnt_array[i-1];
          end
          else begin
            addr_array[i] <= addr_array[i];
            cnt_array[i] <= cnt_array[i];
          end
        end
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
  generate
    for (i = 0; i < NUM_ENTRY; i++) begin
      always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
          cnt_search_result[i] <= 0;
        end
        else if (state == STATE_REQ) begin
          cnt_search_result[i] <= (cnt > cnt_array[i]);
        end
        else begin
          cnt_search_result[i] <= 1'b0;
        end
      end
    end
  endgenerate

  always_comb begin
    insert_index = NUM_ENTRY;
    for(k = 0; k < NUM_ENTRY; k++) begin
      insert_index -= cnt_search_result[k];
    end  
  end

  /////////////////////////////////////////////////////////////

endmodule


