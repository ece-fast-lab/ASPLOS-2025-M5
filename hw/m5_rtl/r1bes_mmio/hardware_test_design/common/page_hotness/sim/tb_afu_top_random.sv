`timescale 1ps/1ps

`include "cxl_ed_defines.svh.iv"

//import afu_axi_if_pkg::*;
import mc_axi_if_pkg::*;
//import cxlip_top_pkg::*;

module tb_afu_top_random();

localparam NUM_ENTRY = 100; 
localparam NUM_ENTRY_BITS = 7; // log2 (NUM_ENTRY)

localparam ADDR_SIZE = 28; 
localparam CNT_SIZE = 32; 
localparam CMD_WIDTH = 4;
localparam TCQ = 100;

localparam FREQ = 450; // MAX: 450 MHz

localparam QUERY_IDLE         = 4'd0;
localparam QUERY_MIG          = 4'd1;
localparam QUERY_FLUSH        = 4'd2;

localparam MIG_TH = 200; 
localparam NUM_INPUT   = 1300;
localparam PAGE_TOP_K  = 5;
localparam CACHE_TOP_K = 2;

reg clk;
reg rstn;

logic [ADDR_SIZE-1:0]   awaddr , awaddr_fifo,  awaddr_r;
logic                   awvalid, awvalid_fifo, awvalid_r;
logic                   awready, awready_fifo, awready_r;
logic [ADDR_SIZE-1:0]   araddr , araddr_fifo,  araddr_r;
logic                   arvalid, arvalid_fifo, arvalid_r;
logic                   arready, arready_fifo, arready_r;

logic                         page_query_en;
logic  [CMD_WIDTH-1:0]        page_query_cmd;
logic                         page_query_ready;
logic                         page_mig_addr_en;
logic  [ADDR_SIZE-1:0]        page_mig_addr;
logic                         page_mig_addr_ready;
logic                         page_mig_addr_en_r;
logic  [ADDR_SIZE-1:0]        page_mig_addr_r;
logic                         page_mig_addr_ready_r;

logic                         cache_query_en;
logic  [CMD_WIDTH-1:0]        cache_query_cmd;
logic                         cache_query_ready;
logic                         cache_mig_addr_en;
logic  [ADDR_SIZE-1:0]        cache_mig_addr;
logic                         cache_mig_addr_ready;
logic                         cache_mig_addr_en_r;
logic  [ADDR_SIZE-1:0]        cache_mig_addr_r;
logic                         cache_mig_addr_ready_r;


logic num_access_valid, num_access_valid_d1, num_access_valid_d2, num_access_valid_d3, num_access_valid_d4;
logic num_query_valid, num_query_valid_d1, num_query_valid_d2, num_query_valid_d3, num_query_valid_d4;

mc_axi_if_pkg::t_to_mc_axi4   cxlip2iafu_to_mc_axi4;
mc_axi_if_pkg::t_from_mc_axi4 mc2iafu_from_mc_axi4;
mc_axi_if_pkg::t_to_mc_axi4   iafu2mc_to_mc_axi4;
mc_axi_if_pkg::t_from_mc_axi4 iafu2cxlip_from_mc_axi4;

integer f;
integer trace_file;
integer iter;
genvar i;
genvar j;
logic  [ADDR_SIZE-1:0]   input_addr;
logic [31:0] num_access, num_query;
logic [31:0] num_access_r;

assign num_access_valid_d4 = u_afu_top.cache_hot_tracker_top.input_addr_valid && u_afu_top.cache_hot_tracker_top.input_addr_ready ;
assign num_query_valid = u_afu_top.cache_hot_tracker_top.query_en && u_afu_top.cache_hot_tracker_top.query_ready ;

always_comb
  begin
    cxlip2iafu_to_mc_axi4.awaddr  = awaddr  ;
    cxlip2iafu_to_mc_axi4.awvalid = awvalid ;
    mc2iafu_from_mc_axi4.awready  = awready ;

    cxlip2iafu_to_mc_axi4.araddr  = araddr  ;
    cxlip2iafu_to_mc_axi4.arvalid = arvalid ;
    mc2iafu_from_mc_axi4.arready  = arready ;
  end

initial begin
  cxlip2iafu_to_mc_axi4.wdata   = 'd0;
  cxlip2iafu_to_mc_axi4.wvalid  = 'd0;
  cxlip2iafu_to_mc_axi4.rready  = 'd0;
  mc2iafu_from_mc_axi4.wready   = 'd0;
  mc2iafu_from_mc_axi4.rdata    = 'd0;
  mc2iafu_from_mc_axi4.rvalid   = 'd0;
end

initial begin
  clk = 1'b0;
  forever #(1000*1000/FREQ/2) clk = ~clk;
end

initial begin
  f = $fopen("./verify/result.txt","w");
  rstn = 1;
  #100ns
  rstn = 0;
  #100ns
  rstn = 1;

  repeat (10000000) @(posedge clk);
  $fclose(f);
end

// Page, Cacheline access
initial begin
  trace_file = $fopen("./verify/rtrace.txt", "r");
  input_addr = {ADDR_SIZE{1'b0}};

  araddr_fifo  = {ADDR_SIZE{1'b0}};
  arvalid_fifo = 1'b0;
  
  page_query_en   = 1'b0;
  page_query_cmd  = 4'b0;
  cache_query_en  = 1'b0;
  cache_query_cmd = 4'b0;

  page_mig_addr_ready_r   = 1'b0;
  cache_mig_addr_ready_r  = 1'b0;
  
  #1500ns
  @(posedge clk);

  forever begin
    repeat(1)@(posedge clk); #TCQ ;

    if(((num_access % MIG_TH) == MIG_TH-1)& (num_access != 0) & (num_query < NUM_INPUT / MIG_TH)) begin
      @(posedge clk); #TCQ;
      page_query_en  = 1'b1;
      page_query_cmd = QUERY_MIG;
      cache_query_en  = 1'b1;
      cache_query_cmd = QUERY_MIG;
      wait(page_query_ready & cache_query_ready); 
      @(posedge clk); #TCQ;
      page_query_en  = 1'b0;
      page_query_cmd = QUERY_IDLE;
      cache_query_en  = 1'b0;
      cache_query_cmd = QUERY_IDLE;
      @(posedge clk); #TCQ;
    end
    //$display("NUM INPUT ADDR = %5d", num_access);
    //$display("NUM Query      = %5d", num_query);


    // not finished
    else if (!($feof(trace_file))) begin
      #TCQ;
      arvalid_fifo = 1'b1;
      $fscanf(trace_file, "%d\n", araddr_fifo);
      repeat (1) @(posedge clk); #TCQ;
      arvalid_fifo = 1'b0;
    end

    
    else if ($feof(trace_file) & ((num_access >= NUM_INPUT))) begin
      #5000ns;
      #5000ns;
      #5000ns;
      //print_table();
      //$display("NUM INPUT ADDR = %5d", num_access);
      //$display("NUM Query      = %5d", num_query);
      $finish;
    end
  end
end


initial begin 
  awaddr_fifo = 28'h0;
  awvalid_fifo = 1'b0;
  araddr_fifo = 28'h0;
  arvalid_fifo = 1'b0;
  
  awready_r = 1'b0;
  arready_r = 1'b0;

  wait(arvalid_r); #TCQ;
  arready_r = 1'b1;
  repeat(NUM_INPUT) @(posedge clk); #TCQ
  arready_r = 1'b0;
end



always_ff @ (posedge clk or negedge rstn) begin
  if (awvalid_r & awready_r) begin
    $display("Read awaddr: %7h (%5d ns)", awaddr_r[ADDR_SIZE-1:0], $time/1000);
  end
end

always_ff @ (posedge clk or negedge rstn) begin
  if (arvalid_r & arready_r) begin
    $display("Read araddr: %7h (%5d ns)", araddr_r[ADDR_SIZE-1:0], $time/1000);
  end
end

always_ff @ (posedge clk or negedge rstn) begin
  if (cache_mig_addr_en_r & cache_mig_addr_ready_r) begin
    $display("Cache addr: %7h (%5d ns)", cache_mig_addr_r[ADDR_SIZE-1:0], $time/1000);
  end
end

always_ff @ (posedge clk or negedge rstn) begin
  if (page_mig_addr_en_r & page_mig_addr_ready_r) begin
    $display("Page addr: %7h (%5d ns)", {page_mig_addr_r[ADDR_SIZE-1:6], 6'h0}, $time/1000);
  end
end

initial begin
  forever begin
    @ (posedge clk); 
    if (num_access_valid) begin 
      #(1000*1000/2/FREQ);
      print_table();
    end
  end
end

always_ff @ (posedge clk or negedge rstn) begin
  if (num_access_valid) begin  
    $display("                     afu_top addr: %7d (%5d ns)", u_afu_top.cache_hot_tracker_top.u_hot_tracker.input_addr[ADDR_SIZE-1:0], $time/1000);
    //$fwrite(f,"                     afu_top addr: %7d (%5d ns)", u_afu_top.cache_hot_tracker_top.u_hot_tracker.input_addr[ADDR_SIZE-1:0], $time/1000);
    //print_table();
  end
end

initial begin
  forever begin
    @ (posedge clk); 
    if (num_query_valid) begin
      #(1000*1000/2/2/FREQ);
      print_table_query();
    end
  end
end

always_ff @ (posedge clk or negedge rstn) begin
  if (num_query_valid) begin
    $display("                     Receive query!! (%5d ns)", $time/1000);
    //$fwrite(f,"                     Receive query!! (%5d ns)", $time/1000);
    //print_table_query();
  end
end

always_ff @ (posedge clk or negedge rstn) begin
  if (!rstn) begin
    num_query <= 0;
  end
  else begin
    if (num_query_valid) begin
      num_query <= num_query + 1;
    end
    else begin
      num_query <= num_query;
    end
  end
end

always_ff @ (posedge clk or negedge rstn) begin
  if (!rstn) begin
    num_access <= 0;
  end
  else begin
    if (num_access_valid_d4) begin  
      num_access <= num_access + 1;
    end
    else begin
      num_access <= num_access;
    end
  end
end


always_ff @ (posedge clk or negedge rstn) begin
  if (!rstn) begin
    num_access_valid    <= 0;
  end
  else begin
    num_access_valid    <= num_access_valid_d4;
    //num_access_valid_d1 <= num_access_valid_d2;
    //num_access_valid_d2 <= num_access_valid_d3;
    //num_access_valid_d3 <= num_access_valid_d4;
    //num_query_valid     <= num_query_valid_d4;//1;
    //num_query_valid_d1  <= num_query_valid_d2;
    //num_query_valid_d2  <= num_query_valid_d3;
    //num_query_valid_d3  <= num_query_valid_d4;
  end
end


afu_top
#(
  .NUM_ENTRY(NUM_ENTRY),
  .NUM_ENTRY_BITS(NUM_ENTRY_BITS), // log2 (NUM_ENTRY)
  .PAGE_TOP_K(PAGE_TOP_K),
  .CACHE_TOP_K(CACHE_TOP_K),
  .ADDR_SIZE(ADDR_SIZE),
  .CNT_SIZE(CNT_SIZE),
  .CMD_WIDTH(CMD_WIDTH)
)
  u_afu_top
(
  .afu_clk(clk),
  .afu_rstn(rstn),
  .cxlip2iafu_to_mc_axi4(cxlip2iafu_to_mc_axi4),
  .iafu2mc_to_mc_axi4(iafu2mc_to_mc_axi4),
  .mc2iafu_from_mc_axi4(mc2iafu_from_mc_axi4),
  .iafu2cxlip_from_mc_axi4(iafu2cxlip_from_mc_axi4),

  // hot tracker interface
  .page_query_en                  (page_query_en),
  .page_query_cmd                 (page_query_cmd),
  .page_query_ready               (page_query_ready),
  .cache_query_en                 (cache_query_en),
  .cache_query_cmd                (cache_query_cmd),
  .cache_query_ready              (cache_query_ready),

  .page_mig_addr_en               (page_mig_addr_en),
  .page_mig_addr                  (page_mig_addr),
  .page_mig_addr_ready            (page_mig_addr_ready),
  .cache_mig_addr_en              (cache_mig_addr_en),
  .cache_mig_addr                 (cache_mig_addr),
  .cache_mig_addr_ready           (cache_mig_addr_ready)
);

axis_data_fifo_0 // hot to cxl(h2c), cxl to hot(c2h)
  master_write
(
  .s_axis_aclk    ( clk            ),
  .s_axis_aresetn ( rstn           ),

  .s_axis_tdata   ( awaddr_fifo  ),
  .s_axis_tvalid  ( awvalid_fifo ),
  .s_axis_tready  ( awready_fifo ),

  .m_axis_tdata   ( awaddr   ),
  .m_axis_tvalid  ( awvalid  ),
  .m_axis_tready  ( awready )
);

axis_data_fifo_0 // hot to cxl(h2c), cxl to hot(c2h)
  slave_write
(
  .s_axis_aclk    ( clk            ),
  .s_axis_aresetn ( rstn           ),

  .s_axis_tdata   ( awaddr  ),
  .s_axis_tvalid  ( awvalid ),
  .s_axis_tready  ( awready ),

  .m_axis_tdata   ( awaddr_r   ),
  .m_axis_tvalid  ( awvalid_r  ),
  .m_axis_tready  ( awready_r )
);

axis_data_fifo_0 // hot to cxl(h2c), cxl to hot(c2h)
  master_read
(
  .s_axis_aclk    ( clk            ),
  .s_axis_aresetn ( rstn           ),

  .s_axis_tdata   ( araddr_fifo  ),
  .s_axis_tvalid  ( arvalid_fifo ),
  .s_axis_tready  ( arready_fifo ),

  .m_axis_tdata   ( araddr   ),
  .m_axis_tvalid  ( arvalid  ),
  .m_axis_tready  ( arready )
);

axis_data_fifo_0 // hot to cxl(h2c), cxl to hot(c2h)
  slave_read
(
  .s_axis_aclk    ( clk            ),
  .s_axis_aresetn ( rstn           ),

  .s_axis_tdata   ( araddr  ),
  .s_axis_tvalid  ( arvalid ),
  .s_axis_tready  ( arready ),

  .m_axis_tdata   ( araddr_r   ),
  .m_axis_tvalid  ( arvalid_r  ),
  .m_axis_tready  ( arready_r )
);

axis_data_fifo_0 // hot to cxl(h2c), cxl to hot(c2h)
  page_addr_queue
(
  .s_axis_aclk    ( clk            ),
  .s_axis_aresetn ( rstn           ),

  .s_axis_tdata   ( page_mig_addr  ),
  .s_axis_tvalid  ( page_mig_addr_en ),
  .s_axis_tready  ( page_mig_addr_ready ),

  .m_axis_tdata   ( page_mig_addr_r   ),
  .m_axis_tvalid  ( page_mig_addr_en_r  ),
  .m_axis_tready  ( page_mig_addr_ready_r )
);

axis_data_fifo_0 // hot to cxl(h2c), cxl to hot(c2h)
  cache_addr_queue
(
  .s_axis_aclk    ( clk            ),
  .s_axis_aresetn ( rstn           ),

  .s_axis_tdata   ( cache_mig_addr  ),
  .s_axis_tvalid  ( cache_mig_addr_en ),
  .s_axis_tready  ( cache_mig_addr_ready ),

  .m_axis_tdata   ( cache_mig_addr_r   ),
  .m_axis_tvalid  ( cache_mig_addr_en_r  ),
  .m_axis_tready  ( cache_mig_addr_ready_r )
);

`ifdef WAVE 
  initial begin
    $shm_open("WAVE");
    $shm_probe("ASM");
  end  
`endif



task print_table;
  integer i;
  $display("\n///// Print Tracker Table (%8d) /////", num_access);
  $fwrite(f,"///// Print Tracker Table (%8d) /////\n", num_access);
  for(i = 0; i < NUM_ENTRY; i = i+1) begin
    $display("%3d:  %7x  %5d | %7x  %5d",i, u_afu_top.cache_hot_tracker_top.u_hot_tracker.u_addr_cam.data_array_out[i], u_afu_top.cache_hot_tracker_top.u_hot_tracker.u_cnt_cam.data_array_out[i], u_afu_top.page_hot_tracker_top.u_hot_tracker.u_addr_cam.data_array_out[i], u_afu_top.page_hot_tracker_top.u_hot_tracker.u_cnt_cam.data_array_out[i]);
    $fwrite(f,"%3d:  %7x  %5d | %7x  %5d\n",i, u_afu_top.cache_hot_tracker_top.u_hot_tracker.u_addr_cam.data_array_out[i], u_afu_top.cache_hot_tracker_top.u_hot_tracker.u_cnt_cam.data_array_out[i], u_afu_top.page_hot_tracker_top.u_hot_tracker.u_addr_cam.data_array_out[i], u_afu_top.page_hot_tracker_top.u_hot_tracker.u_cnt_cam.data_array_out[i]);
  end
    $display("minptr is %3d, minptr count is %3d", u_afu_top.cache_hot_tracker_top.u_hot_tracker.minptr, u_afu_top.cache_hot_tracker_top.u_hot_tracker.cnt_cam_minptr_count);
    //$fwrite(f,"minptr is %3d, minptr count is %3d", u_afu_top.cache_hot_tracker_top.u_hot_tracker.minptr, u_afu_top.cache_hot_tracker_top.u_hot_tracker.cnt_cam_minptr_count);  
  $display("///////////////////////////////\n");
  $fwrite(f,"///////////////////////////////\n\n");
endtask

task print_table_query;
  integer i;
  //$display("\n///// Print Tracker Table (Query %8d) /////", num_query);
  $fwrite(f,"///// Print Tracker Table (Query %8d) /////\n", num_query);
  for(i = 0; i < NUM_ENTRY; i = i+1) begin
    //$display("%3d:  %6d  %5d",i, u_afu_top.u_hot_tracker_top.page_hot_tracker.u_addr_cam.data_array_out[i], u_afu_top.u_hot_tracker_top.page_hot_tracker.u_cnt_cam.data_array_out[i]);
    $fwrite(f,"%3d:  %7x  %5d | %7x  %5d\n",i, u_afu_top.cache_hot_tracker_top.u_hot_tracker.u_addr_cam.data_array_out[i], u_afu_top.cache_hot_tracker_top.u_hot_tracker.u_cnt_cam.data_array_out[i], u_afu_top.page_hot_tracker_top.u_hot_tracker.u_addr_cam.data_array_out[i], u_afu_top.page_hot_tracker_top.u_hot_tracker.u_cnt_cam.data_array_out[i]);
  end
    //$display("minptr is %3d, minptr count is %3d", u_afu_top.u_hot_tracker_top.page_hot_tracker.minptr, u_afu_top.u_hot_tracker_top.page_hot_tracker.cnt_cam_minptr_count);
    //$fwrite(f,"minptr is %3d, minptr count is %3d", u_afu_top.u_hot_tracker_top.page_hot_tracker.minptr, u_afu_top.u_hot_tracker_top.page_hot_tracker.cnt_cam_minptr_count);  
  //$display("///////////////////////////////\n");
  $fwrite(f,"///////////////////////////////\n\n");
endtask

endmodule
