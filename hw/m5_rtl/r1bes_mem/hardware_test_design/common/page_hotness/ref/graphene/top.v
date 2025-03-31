module top (clk, act_addr, reset, ref_read_en, ref_addr, alert);

parameter ADDRESS_SIZE = 16;  // 64K
parameter COUNT_SIZE = 14;     // # of counter bits & overflow bit
parameter ROW_NUM = 512;        // # of entries 
parameter ENTRY_WIDTH = 7;    // [log2(ROW_NUM)] entries
parameter THRESHOLD = 50000;

input clk;
input [ADDRESS_SIZE-1:0] act_addr;
input reset;
input ref_read_en;
output reg [ADDRESS_SIZE-1:0] ref_addr;
output reg alert;

/* state */
reg [1:0] state;
always @(posedge clk) begin
  if (reset) begin
    state <= 0;
  end
  else if (ref_read_en) begin
    state <= 2'b11;
  end
  else if (state == 2'b10) begin
    state <= 0;
  end
  else state <= state + 1;

end

/* phase signals */
wire act, d_1, d_2;
assign act = state == 2'b00;
assign d_1 = state == 2'b01;
assign d_2 = state == 2'b10;



/* SPC */
reg [COUNT_SIZE-1:0] SPC;
wire spc;
assign spc = SPC;

/* CONTROL SIGNALS */
wire case_1, case_2, case_3;

/* ADDRESS CAM */
wire [ADDRESS_SIZE-1:0] addr_cam_data_in;
wire [ENTRY_WIDTH-1:0] addr_cam_addr_in;
wire addr_cam_read_en;
wire addr_cam_write_en;
wire addr_cam_search_en;
wire addr_cam_reset;
wire [ADDRESS_SIZE-1:0] addr_cam_data_out;
wire [ENTRY_WIDTH-1:0] addr_cam_addr_out;
wire addr_cam_match;

/* COUNT CAM */
wire [COUNT_SIZE-1:0] cnt_cam_data_in;
wire [ENTRY_WIDTH-1:0] cnt_cam_addr_in;
wire cnt_cam_read_en;
wire cnt_cam_write_en;
wire cnt_cam_search_en;
wire cnt_cam_reset;
wire [COUNT_SIZE-1:0] cnt_cam_data_out;
wire [ENTRY_WIDTH-1:0] cnt_cam_addr_out;
wire cnt_cam_match;

/* CAM INSTANTIATION */
cam #(.WORD_SIZE(ADDRESS_SIZE), .ROW_NUM(ROW_NUM), .ENTRY_WIDTH(ENTRY_WIDTH)) addr_cam (addr_cam_data_in, addr_cam_addr_in, addr_cam_read_en, addr_cam_write_en, addr_cam_search_en,
  addr_cam_reset, addr_cam_data_out, addr_cam_addr_out, addr_cam_match);

cam #(.WORD_SIZE(COUNT_SIZE), .ROW_NUM(ROW_NUM), .ENTRY_WIDTH(ENTRY_WIDTH)) cnt_cam (cnt_cam_data_in, cnt_cam_addr_in, cnt_cam_read_en, cnt_cam_write_en, cnt_cam_search_en,
  cnt_cam_reset, cnt_cam_data_out, cnt_cam_addr_out, cnt_cam_match);

/* ADDR CAM SIGNALS */
assign addr_cam_data_in = act_addr;
assign addr_cam_addr_in = cnt_cam_addr_out;        
assign addr_cam_read_en = ref_read_en;
assign addr_cam_write_en = d_2 && case_2;
assign addr_cam_search_en = act;
assign addr_cam_reset = reset;

/* COUNT CAM SIGNALS */
wire [COUNT_SIZE-1:0] incremented_count;
overflow_counter #(.COUNT_SIZE(COUNT_SIZE)) overflow_counter_ (.count(cnt_cam_data_out), .incremented_count(incremented_count));

assign cnt_cam_data_in = d_1 ? spc : 
                   d_2 && case_1 ? incremented_count :
       spc + 1;
assign cnt_cam_addr_in = case_1 ? addr_cam_addr_out :
                   case_2 ? cnt_cam_addr_out :
       cnt_cam_addr_in;      
assign cnt_cam_read_en = d_1; 
assign cnt_cam_write_en = d_2 && (~case_3); 
assign cnt_cam_search_en = d_1 && (~case_1);
assign cnt_cam_reset = reset;

/* CONTROL SIGNAL UPDATE */
assign case_1 = addr_cam_match;
assign case_2 = (~addr_cam_match) && cnt_cam_match;
assign case_3 = (~addr_cam_match) && (~cnt_cam_match);

/* SPC UPDATE */
always @(posedge clk) begin
  if (reset) begin
    SPC <= 0;
  end
  if (d_2 && case_3) begin
    SPC <= SPC + 1;
  end
end

/* ALERT & REF_ADDR UPDATE */
integer i;
always @(*) begin
  if (reset) begin
    alert <= 0;
    ref_addr <= 0;
  end
  else if (ref_read_en) begin
    alert <= 0;
  end
  else if (cnt_cam_write_en && (cnt_cam_data_in == THRESHOLD)) begin
    alert <= 1;
    ref_addr <= addr_cam_data_out;
  end
end

endmodule

module overflow_counter (count, incremented_count);
parameter COUNT_SIZE = 15;

input [COUNT_SIZE-1:0] count;
output [COUNT_SIZE-1:0] incremented_count;

wire [COUNT_SIZE-2:0] count_;

assign count_ = count[COUNT_SIZE-2:0] + 1;

assign incremented_count = count[COUNT_SIZE-1] ? {1'b1, count_} : count+1;

endmodule

