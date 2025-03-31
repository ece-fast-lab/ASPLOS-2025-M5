`timescale 1ps/1ps

`include "cxl_ed_defines.svh.iv"

//import afu_axi_if_pkg::*;
import mc_axi_if_pkg::*;
//import cxlip_top_pkg::*;

module tb_afu_top();

localparam NUM_ENTRY = 100; 
localparam NUM_ENTRY_BITS = 7; // log2 (NUM_ENTRY)
`ifndef SIM
localparam MIG_TH = 450; 
`else
localparam MIG_TH = 45; 
`endif
localparam ADDR_SIZE = 28; 
localparam CNT_SIZE = 32; 
localparam CMD_WIDTH = 4;
localparam TCQ = 100;

localparam FREQ = 450; // MAX: 450 MHz

localparam QUERY_IDLE         = 4'd0;
localparam QUERY_MIG          = 4'd1;
localparam QUERY_FLUSH        = 4'd2;

localparam NUM_INPUT   = 2000;

reg clk;
reg rstn;

logic [ADDR_SIZE-1:0]   awaddr , awaddr_fifo,  awaddr_r;
logic                   awvalid, awvalid_fifo, awvalid_r;
logic                   awready, awready_fifo, awready_r;
logic [ADDR_SIZE-1:0]   araddr , araddr_fifo,  araddr_r;
logic                   arvalid, arvalid_fifo, arvalid_r;
logic                   arready, arready_fifo, arready_r;

logic                         query_en;
logic  [CMD_WIDTH-1:0]        query_cmd;
logic                         query_ready;
logic                         mig_addr_en;
logic  [ADDR_SIZE-1:0]        mig_addr;
logic                         mig_addr_ready;
logic                         mig_addr_en_r;
logic  [ADDR_SIZE-1:0]        mig_addr_r;
logic                         mig_addr_ready_r;

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
integer num_input_addr;

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
  rstn = 1;
  #100ns
  rstn = 0;
  #100ns
  rstn = 1;
end

// Activation
initial begin
  $display("====| [HYNAM] Simulation start (%5d ns) |====", $time/1000);
  trace_file = $fopen("trace.txt", "r");
  num_input_addr = 0;
  input_addr = {ADDR_SIZE{1'b0}};

  araddr_fifo  = {ADDR_SIZE{1'b0}};
  arvalid_fifo = 1'b0;
  
  query_en  = 1'b0;
  query_cmd = 4'b0;

  mig_addr_ready_r = 1'b0;
  
  #1500ns
  @(posedge clk); #TCQ;

  forever begin
    repeat(2)@(posedge clk); #TCQ;
    arvalid_fifo = 1'b1;
    num_input_addr = num_input_addr + 1;
    $fscanf(trace_file, "%d\n", araddr_fifo);
    repeat (1) @(posedge clk); #TCQ
    arvalid_fifo = 1'b0;
    
    // Query 
    if((num_input_addr % MIG_TH) == 0) begin
      //#1000ns
      print_table();
      @(posedge clk); #TCQ;
      query_en  = 1'b1;
      query_cmd = QUERY_MIG;
      wait(query_ready); 
      print_table();
      @(posedge clk); #TCQ;
      query_en  = 1'b0;
      query_cmd = QUERY_IDLE;
      @(posedge clk); #TCQ;
    end

    if ($feof(trace_file)) begin
      #10000ns;
      $display("\n\n====| [HYNAM] Top-K  (%5d ns) |====", $time/1000);
      mig_addr_ready_r = 1'b1;
      #200ns;
      $display("====| [HYNAM] Simulation done  (%5d ns) |====", $time/1000);
      $display("NUM INPUT ADDR = %5d", num_input_addr);
      print_table();
      $finish;
    end
  end
end


// Main Function
/*
initial begin
  f = $fopen("result.txt","w");
  //$fwrite(f,"////////  READ start ////////\n");


  forever begin
    wait(act_cmd == 1'b0);
    wait(act_cmd == 1'b1);
    repeat (16) @(posedge clk);
    $fwrite(f,"////////  REQ %d ////////\n", act_count);
    $fwrite(f,"REQ Address : %d\n", act_addr);
    for(iter = 0; iter < NUM_ENTRY; iter = iter+1) begin
      $fwrite(f,"%d: %d, %d\n", iter, addr_table[iter], cnt_table [iter]);
    end
    $fwrite(f,"\n");
  end

  wait(num_input_addr == NUM_INPUT); 
  @(posedge clk); #TCQ;

  $fclose(f);
  $finish;
end
  */


initial begin 
  awaddr_fifo = 28'h0;
  awvalid_fifo = 1'b0;
  araddr_fifo = 28'h0;
  arvalid_fifo = 1'b0;
  
  awready_r = 1'b0;
  arready_r = 1'b0;
  /*
  #500ns

  // write req 
  @(posedge clk); #TCQ;
  awaddr_fifo = 28'h111_1111;
  awvalid_fifo = 1'b1;
  araddr_fifo = 28'h0;
  arvalid_fifo = 1'b0;
  @(posedge clk); #TCQ;
  awvalid_fifo = 1'b0;
  arvalid_fifo = 1'b0;
  repeat(10) @(posedge clk); #TCQ;
  awready_r = 1'b1;
  arready_r = 1'b0;
  @(posedge clk); #TCQ;
  awready_r = 1'b0;
  arready_r = 1'b0;

  
  #100ns

  // read req 
  @(posedge clk); #TCQ;
  awaddr_fifo = 28'h0;
  awvalid_fifo = 1'b0;
  araddr_fifo = 28'h222_2222;
  arvalid_fifo = 1'b1;
  @(posedge clk); #TCQ;
  awvalid_fifo = 1'b0;
  arvalid_fifo = 1'b0;
  repeat(10) @(posedge clk); #TCQ;
  awready_r = 1'b0;
  arready_r = 1'b1;
  @(posedge clk); #TCQ;
  awready_r = 1'b0;
  arready_r = 1'b0;

  #100ns

  // write, read req 
  @(posedge clk); #TCQ;
  awaddr_fifo = 28'h333_3333;
  awvalid_fifo = 1'b1;
  araddr_fifo = 28'h444_4444;
  arvalid_fifo = 1'b1;
  @(posedge clk); #TCQ;
  awvalid_fifo = 1'b0;
  arvalid_fifo = 1'b0;
  repeat(10) @(posedge clk); #TCQ;
  awready_r = 1'b1;
  arready_r = 1'b1;
  @(posedge clk); #TCQ;
  awready_r = 1'b0;
  arready_r = 1'b0;

  // write req 
  @(posedge clk); #TCQ;
  awaddr_fifo = 28'hAAA_AAAA;
  awvalid_fifo = 1'b1;
  araddr_fifo = 28'h0;
  arvalid_fifo = 1'b0;
  @(posedge clk); #TCQ;
  awvalid_fifo = 1'b0;
  arvalid_fifo = 1'b0;
  repeat(10) @(posedge clk); #TCQ;
  awready_r = 1'b1;
  arready_r = 1'b0;
  @(posedge clk); #TCQ;
  awready_r = 1'b0;
  arready_r = 1'b0;

  
  #100ns

  // read req 
  @(posedge clk); #TCQ;
  awaddr_fifo = 28'h0;
  awvalid_fifo = 1'b0;
  araddr_fifo = 28'hBBB_BBBB;
  arvalid_fifo = 1'b1;
  @(posedge clk); #TCQ;
  awvalid_fifo = 1'b0;
  arvalid_fifo = 1'b0;
  repeat(10) @(posedge clk); #TCQ;
  awready_r = 1'b0;
  arready_r = 1'b1;
  @(posedge clk); #TCQ;
  awready_r = 1'b0;
  arready_r = 1'b0;

  #100ns

  // write, read req 
  @(posedge clk); #TCQ;
  awaddr_fifo = 28'hCCC_CCCC;
  awvalid_fifo = 1'b1;
  araddr_fifo = 28'hDDD_DDDD;
  arvalid_fifo = 1'b1;
  @(posedge clk); #TCQ;
  awvalid_fifo = 1'b0;
  arvalid_fifo = 1'b0;
  repeat(10) @(posedge clk); #TCQ;
  awready_r = 1'b1;
  arready_r = 1'b1;
  @(posedge clk); #TCQ;
  awready_r = 1'b0;
  arready_r = 1'b0;
  */
  $display("=====================");
  $display("====| Test Done |====");
  $display("=====================");
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
  if (mig_addr_en_r & mig_addr_ready_r) begin
    $display("mig addr: %7h (%5d ns)", mig_addr_r[ADDR_SIZE-1:0], $time/1000);
  end
end
  
always_ff @ (posedge clk or negedge rstn) begin
  if (u_afu_top.u_hot_tracker_top.page_hot_tracker.input_addr_valid & u_afu_top.u_hot_tracker_top.page_hot_tracker.input_addr_ready) begin
    $display("                     afu_top addr: %7h (%5d ns)", u_afu_top.u_hot_tracker_top.page_hot_tracker.input_addr[ADDR_SIZE-1:0], $time/1000);
  end
end

always_ff @ (posedge clk or negedge rstn) begin
  if (u_afu_top.u_hot_tracker_top.page_hot_tracker.query_en & u_afu_top.u_hot_tracker_top.page_hot_tracker.query_ready) begin
    $display("                     Receive query!! (%5d ns)", $time/1000);
  end
end

afu_top
#(
  .NUM_ENTRY(NUM_ENTRY),
  .NUM_ENTRY_BITS(NUM_ENTRY_BITS), // log2 (NUM_ENTRY)
  .MIG_TH(MIG_TH),
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
  .query_en                 (query_en),
  .query_cmd                (query_cmd),
  .query_ready              (query_ready),

  .mig_addr_en              (mig_addr_en),
  .mig_addr                 (mig_addr),
  .mig_addr_ready           (mig_addr_ready)
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
  mig_addr_queue
(
  .s_axis_aclk    ( clk            ),
  .s_axis_aresetn ( rstn           ),

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
  $display("\n///// Print Tracker Table /////");
  for(i = 0; i < NUM_ENTRY; i = i+1) begin
    $display("%3d:  %h  %5d",i, u_afu_top.u_hot_tracker_top.page_hot_tracker.u_addr_cam.data_array_out[i], u_afu_top.u_hot_tracker_top.page_hot_tracker.u_cnt_cam.data_array_out[i]);
  end
    $display("minptr is %3d, minptr count is %3d", u_afu_top.u_hot_tracker_top.page_hot_tracker.minptr, u_afu_top.u_hot_tracker_top.page_hot_tracker.cnt_cam_minptr_count); 
  $display("///////////////////////////////\n");
endtask

endmodule
