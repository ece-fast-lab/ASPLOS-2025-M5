`timescale 1ps/1ps
`define TOP cm_sketch_cam_tb_random

// common parameter
`define ADDR_SIZE 28
`define CNT_SIZE 32

// CM-sketch parameter
`define W 16
`define NUM_HASH 4
`define HASH_SIZE $clog2(`W)

// sorted CAM parameter
`define NUM_ENTRY 25
`define INDEX_SIZE $clog2(`NUM_ENTRY)

module cm_sketch_cam_tb_random();

localparam NUM_INPUT = 100;
localparam CMD_WIDTH = 4;
localparam TCQ = 100;

localparam FREQ = 450; // MAX: 450 MHz

logic                     clk, rst_n;
logic                     valid;
logic [`ADDR_SIZE-1:0]    input_addr;

integer f, hash;
integer trace_file;
integer i, j;
logic [31:0] num_access;

logic cam_valid_d1;
logic cam_valid_d2;

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
  #100ns
  
  for(i = 0; i < `NUM_HASH; i++) begin
    for(j = 0; j < 32; j++) begin
      $fwrite(hash,"%x", cm_sketch_cam_top_0.cm_sketch_0.compute_hash.q_debug[i][j]);
      if (j != 31) begin
        $fwrite(hash," ");
      end
    end
    $fwrite(hash,"\n");
  end
  
  repeat (10000000) @(posedge clk);

  $fclose(f);
  $fclose(hash);
end

// Heap insert start
initial begin
  trace_file = $fopen("./verify/rtrace.txt", "r");

  valid = 1'b0;
  input_addr = {`ADDR_SIZE{1'b0}};

  #1500ns
  @(posedge clk);

  forever begin
    repeat(1)@(posedge clk); //#TCQ ;
    
    // not finished
    if (!($feof(trace_file))) begin
      //#TCQ;
      valid = 1'b1;
      $fscanf(trace_file, "%d\n", input_addr);
      repeat (1) @(posedge clk); //#TCQ;
      valid = 1'b0;
    end

    else if ($feof(trace_file)) begin
      #5000ns;
      #5000ns;
      #5000ns;
      print_table();
      //$display("NUM INPUT ADDR = %5d", num_access);
      //$display("NUM Query      = %5d", num_query);
      $finish;
    end
  end
end


initial begin
  forever begin
    @ (posedge clk); 
    if ((num_access != 0) && cam_valid_d2) begin
      print_table();
    end
  end
end

always_ff @ (posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    cam_valid_d1 <= 0;
    cam_valid_d2 <= 0;
  end
  else begin
    cam_valid_d1 <= cm_sketch_cam_top_0.cam_0.input_valid;
    cam_valid_d2 <= cam_valid_d1;
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


cm_sketch_cam_top
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
  cm_sketch_cam_top_0
(
  // Input
  .clk(clk), 
  .rst_n(rst_n), 

  .input_valid(valid),  
  .input_addr(input_addr)

  // Output
  /* TODO */
);

`ifdef WAVE 
  initial begin
    $shm_open("WAVE");
    $shm_probe("ASM");
  end  
`endif

task print_table;
  integer i;
  // $display("\n///// Print table (%8d) /////", num_access);
  $fwrite(f,"///// Print table (%8d) /////\n", num_access);
  for(i = 0; i < `NUM_ENTRY; i = i+1) begin
    //$display("%3d:  %5d  %7x", i, cam_top_0.cnt_array[i], cam_top_0.addr_array[i]);
    $fwrite(f,"%3d:  %5d  %7x\n", i, cm_sketch_cam_top_0.cam_0.cnt_array[i], cm_sketch_cam_top_0.cam_0.addr_array[i]);
  end
  //$display("///////////////////////////////\n");
  $fwrite(f,"///////////////////////////////\n\n");
endtask

endmodule
