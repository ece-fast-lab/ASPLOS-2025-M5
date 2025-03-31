`timescale 1ps/1ps

`include "cxl_ed_defines.svh.iv"

// common parameter
`define ADDR_SIZE 33
`define CNT_SIZE 18
`define NUM_INPUT 100 

// CM-sketch parameter
`define W 4096
`define NUM_HASH 4
`define HASH_SIZE $clog2(`W)

// sorted CAM parameter
`define NUM_ENTRY 25
`define INDEX_SIZE $clog2(`NUM_ENTRY)

//import afu_axi_if_pkg::*;
import mc_axi_if_pkg::*;
//import cxlip_top_pkg::*;

module tb_afu_top_random();

localparam TCQ = 100;
localparam FREQ = 450; // MAX: 450 MHz

logic                     clk, rst_n;

logic [`ADDR_SIZE-1:0]   awaddr , awaddr_fifo,  awaddr_r;
logic                   awvalid, awvalid_fifo, awvalid_r;
logic                   awready, awready_fifo, awready_r;
logic [`ADDR_SIZE-1:0]   araddr , araddr_fifo,  araddr_r;
logic                   arvalid, arvalid_fifo, arvalid_r;
logic                   arready, arready_fifo, arready_r;

logic                         query_en;
logic                         query_ready;

logic                         mig_addr_en;
logic  [`ADDR_SIZE-1:0]       mig_addr;
logic                         mig_addr_ready;
logic                         mig_addr_en_r;
logic  [`ADDR_SIZE-1:0]       mig_addr_r;
logic                         mig_addr_ready_r;



mc_axi_if_pkg::t_to_mc_axi4   cxlip2iafu_to_mc_axi4;
mc_axi_if_pkg::t_from_mc_axi4 mc2iafu_from_mc_axi4;
mc_axi_if_pkg::t_to_mc_axi4   iafu2mc_to_mc_axi4;
mc_axi_if_pkg::t_from_mc_axi4 iafu2cxlip_from_mc_axi4;

integer f, hash;
integer trace_file;
integer i, j;

logic [`ADDR_SIZE-1:0]    input_addr;
logic [31:0] num_access, num_query;
logic num_access_valid, num_query_valid;

logic cam_valid_d1;
logic cam_valid_d2;
logic cam_valid_d3;

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
  hash = $fopen("./verify/hash.txt","w");

  rst_n = 1;
  #100ns
  rst_n = 0;
  #100ns
  rst_n = 1;

  for(i = 0; i < `NUM_HASH; i++) begin
    for(j = 0; j < 32; j++) begin
      $fwrite(hash,"%x", u_afu_top.u_hot_tracker_top.u_hot_tracker.cm_sketch_0.compute_hash.q_debug[i][j]);
      if (j != 31) begin
        $fwrite(hash," ");
      end
    end
    $fwrite(hash,"\n");
  end

  repeat (10000000) @(posedge clk);
  $fclose(f);
end

// Page, Cacheline access
initial begin
  trace_file = $fopen("./verify/rtrace.txt", "r");
  input_addr = {`ADDR_SIZE{1'b0}};

  araddr_fifo  = {`ADDR_SIZE{1'b0}};
  arvalid_fifo = 1'b0;
  
  query_en   = 1'b0;

  mig_addr_ready_r   = 1'b0;

  #1500ns
  @(posedge clk);

  forever begin
    repeat(1)@(posedge clk); #TCQ ;

    if((num_access != 0) && (num_access % 2000 == 0)) begin 
      @(posedge clk); #TCQ;
      query_en  = 1'b1;

      wait(query_ready); 
      @(posedge clk); #TCQ;
      query_en  = 1'b0;

      @(posedge clk); #TCQ;
    end
    //$display("NUM INPUT ADDR = %5d", num_access);
    //$display("NUM Query      = %5d", num_query);

    // not finished
    else if (!($feof(trace_file))) begin
      //repeat (1) @(posedge clk); // simulate intensivity
      #TCQ;
      arvalid_fifo = 1'b1;
      $fscanf(trace_file, "%d\n", araddr_fifo);
      repeat (1) @(posedge clk); #TCQ;
      arvalid_fifo = 1'b0;
    end

    else if ($feof(trace_file)) begin
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
  repeat(`NUM_INPUT) @(posedge clk); #TCQ
  repeat(`NUM_INPUT) @(posedge clk); #TCQ
  arready_r = 1'b0;
end

always_ff @ (posedge clk or negedge rst_n) begin
  if (awvalid_r & awready_r) begin
    $display("Read awaddr: %7h (%5d ns)", awaddr_r[`ADDR_SIZE-1:0], $time/1000);
  end
end

always_ff @ (posedge clk or negedge rst_n) begin
  if (arvalid_r & arready_r) begin
    $display("Read araddr: %7h (%5d ns)", araddr_r[`ADDR_SIZE-1:0], $time/1000);
  end
end

always_ff @ (posedge clk or negedge rst_n) begin
  if (mig_addr_en_r & mig_addr_ready_r) begin
    $display("addr: %7h (%5d ns)", mig_addr_r, $time/1000);
  end
end

initial begin
  forever begin
    @ (posedge clk); 
    if ((num_access != 0) && cam_valid_d3) begin 
      print_table();
    end
  end
end

always_ff @ (posedge clk or negedge rst_n) begin
  if (num_access_valid) begin  
    //$display("                     afu_top addr: %7x (%5d ns)", u_afu_top.cache_hot_tracker_top.u_hot_tracker.input_addr[`ADDR_SIZE-1:0], $time/1000);
    //$fwrite(f,"                     afu_top addr: %7x (%5d ns)", u_afu_top.cache_hot_tracker_top.u_hot_tracker.input_addr[`ADDR_SIZE-1:0], $time/1000);
    //print_table();
  end
end

always_ff @ (posedge clk or negedge rst_n) begin
  if (num_query_valid) begin
    $display("                     Receive query!! (%5d ns)", $time/1000);
    //$fwrite(f,"                     Receive query!! (%5d ns)", $time/1000);
  end
end

always_ff @ (posedge clk or negedge rst_n) begin
  if (!rst_n) begin
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

always_ff @ (posedge clk or negedge rst_n) begin 
  if (!rst_n) begin
    cam_valid_d1 <= 0;
    cam_valid_d2 <= 0;
    cam_valid_d3 <= 0;
  end
  else begin
    cam_valid_d1 <= u_afu_top.u_hot_tracker_top.u_hot_tracker.cam_0.input_valid;
    cam_valid_d2 <= cam_valid_d1;
    cam_valid_d3 <= cam_valid_d2;
  end
end

always_ff @ (posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    num_access <= 0;
  end
  else begin
    if (cam_valid_d2) begin  
      num_access <= num_access + 1;
    end
    else begin
      num_access <= num_access;
    end
  end
end

afu_top
#(
  // common parameter
  .ADDR_SIZE(`ADDR_SIZE),
  .CNT_SIZE(`CNT_SIZE),

  // CM-sketch parameter
  .W(`W),
  .NUM_HASH(`NUM_HASH),
  .HASH_SIZE(`HASH_SIZE),

  // sorted CAM parameter
  .NUM_ENTRY(`NUM_ENTRY),
  .INDEX_SIZE(`INDEX_SIZE)
)
  u_afu_top
(
  .afu_clk(clk),
  .afu_rstn(rst_n),

  .cxlip2iafu_to_mc_axi4(cxlip2iafu_to_mc_axi4),
  .iafu2mc_to_mc_axi4(iafu2mc_to_mc_axi4),
  .mc2iafu_from_mc_axi4(mc2iafu_from_mc_axi4),
  .iafu2cxlip_from_mc_axi4(iafu2cxlip_from_mc_axi4),

  // hot tracker interface
  .query_en                  (query_en),
  .query_ready               (query_ready),

  .mig_addr_en               (mig_addr_en),
  .mig_addr                  (mig_addr),
  .mig_addr_ready            (mig_addr_ready)
);

axis_data_fifo_0 // hot to cxl(h2c), cxl to hot(c2h)
  master_write
(
  .s_axis_aclk    ( clk            ),
  .s_axis_aresetn ( rst_n           ),

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
  .s_axis_aresetn ( rst_n           ),

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
  .s_axis_aresetn ( rst_n           ),

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
  .s_axis_aresetn ( rst_n           ),

  .s_axis_tdata   ( araddr  ),
  .s_axis_tvalid  ( arvalid ),
  .s_axis_tready  ( arready ),

  .m_axis_tdata   ( araddr_r   ),
  .m_axis_tvalid  ( arvalid_r  ),
  .m_axis_tready  ( arready_r )
);

axis_data_fifo_0 // hot to cxl(h2c), cxl to hot(c2h)
  addr_queue
(
  .s_axis_aclk    ( clk            ),
  .s_axis_aresetn ( rst_n           ),

  .s_axis_tdata   ( mig_addr  ),
  .s_axis_tvalid  ( mig_addr_en ),
  .s_axis_tready  ( mig_addr_ready ),

  .m_axis_tdata   ( mig_addr_r   ),
  .m_axis_tvalid  ( mig_addr_en_r  ),
  .m_axis_tready  ( mig_addr_ready_r )
);


`ifdef WAVE 
  initial begin
    $shm_open("WAVE");
    $shm_probe("ASM");
  end  
`endif


task print_table;
  integer i;
  //$display("\n///// Print Tracker Table (%8d) /////", num_access);
  $fwrite(f,"///// Print Tracker table (%8d) /////\n", num_access);
  for(i = 0; i < `NUM_ENTRY; i = i+1) begin
    //$display("%3d:  %7x  %5d  %5d  %5d | %7x  %5d  %5d  %5d",i, u_afu_top.cache_hot_tracker_top.u_hot_tracker.u_addr_cam.addr_array_out[i], u_afu_top.cache_hot_tracker_top.u_hot_tracker.u_cnt_cam.cnt_array_out[i], u_afu_top.cache_hot_tracker_top.u_hot_tracker.u_cnt_cam.head_array_out[i], u_afu_top.cache_hot_tracker_top.u_hot_tracker.u_cnt_cam.tail_array_out[i], u_afu_top.page_hot_tracker_top.u_hot_tracker.u_addr_cam.addr_array_out[i], u_afu_top.page_hot_tracker_top.u_hot_tracker.u_cnt_cam.cnt_array_out[i], u_afu_top.page_hot_tracker_top.u_hot_tracker.u_cnt_cam.head_array_out[i], u_afu_top.page_hot_tracker_top.u_hot_tracker.u_cnt_cam.tail_array_out[i]);
    $fwrite(f,"%3d:  %5d  %7x\n", i, u_afu_top.u_hot_tracker_top.u_hot_tracker.cam_0.cnt_array[i], u_afu_top.u_hot_tracker_top.u_hot_tracker.cam_0.addr_array[i]);
  end
    //$display("minptr is %3d", u_afu_top.cache_hot_tracker_top.u_hot_tracker.minptr);
    //$fwrite(f,"minptr is %3d", u_afu_top.cache_hot_tracker_top.u_hot_tracker.minptr);  
  //$display("///////////////////////////////\n");
  $fwrite(f,"///////////////////////////////\n\n");
endtask


endmodule
