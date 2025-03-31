`timescale 1ps/1ps
`define TOP cm_sketch_tb_random

`define NUM_HASH 4
`define W 16
`define HASH_SIZE $clog2(`W)
`define ADDR_SIZE 28
`define CNT_SIZE 32

module cm_sketch_tb_random();

localparam NUM_INPUT = 100;
localparam CMD_WIDTH = 4;
localparam TCQ = 100;

localparam FREQ = 450; // MAX: 450 MHz

logic                     clk, rstn;
logic [`CNT_SIZE-1:0]     output_cnt;
logic [`ADDR_SIZE-1:0]    input_addr, output_addr;
logic                     valid;

integer f, hash;
integer trace_file;
integer iter;
integer i, j;
logic [31:0] num_access;

initial begin
  clk = 1'b0;
  forever #(1000*1000/FREQ/2) clk = ~clk;
end

initial begin
  f = $fopen("./verify/result.txt","w");
  hash = $fopen("./verify/hash.txt","w");

  rstn = 1;
  #100ns
  rstn = 0;
  #100ns
  rstn = 1;
  #100ns

  for(i = 0; i < `NUM_HASH; i++) begin
    for(j = 0; j < 32; j++) begin
      $fwrite(hash,"%x", cm_sketch_top0.compute_hash.q_debug[i][j]);
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
      $finish;
    end
  end
end


always_ff @ (posedge clk or negedge rstn) begin
  if (!rstn) begin
    num_access <= 0;
  end
  else begin
    if (cm_sketch_top0.sketch_.input_valid) begin  
      num_access <= num_access + 1;
    end
    else begin
      num_access <= num_access;
    end
  end
end


cm_sketch_top
#(  
  .W(`W),
  .NUM_HASH(`NUM_HASH),
  .HASH_SIZE(`HASH_SIZE),
  .ADDR_SIZE(`ADDR_SIZE),
  .CNT_SIZE(`CNT_SIZE)
)
  cm_sketch_top0
(
  // Input
  .clk(clk), 
  .rst_n(rstn), 

  .input_valid(valid),  
  .input_addr(input_addr),

  // Output
  .output_valid(output_valid),
  .output_addr(output_addr),
  .output_cnt(output_cnt)
);

`ifdef WAVE 
  initial begin
    $shm_open("WAVE");
    $shm_probe("ASM");
  end  
`endif

initial begin
  forever begin
    @ (posedge clk); 
    /*
    if (cm_sketch_top0.sketch_.input_valid) begin 
      $fwrite(f,"Hash value of addr %5d is: ", cm_sketch_top0.sketch_.input_addr);
      for(i = 0; i < `NUM_HASH; i++) begin
        $fwrite(f,"%5d,", cm_sketch_top0.sketch_.input_hash_array[i]);
      end
      $fwrite(f,"\n");
    end

    if (cm_sketch_top0.sketch_.output_valid) begin
      $fwrite(f,"///// Hash table (%8d) /////\n", num_access);
      for(i = 0; i < `NUM_HASH; i++) begin
        for(j = 0; j < `W; j++) begin  
          $fwrite(f,"%5d,", cm_sketch_top0.sketch_.cnt_array[i][j]);
        end
        $fwrite(f,"\n");
      end
    end
    */
    if (cm_sketch_top0.compute_min.output_valid) begin 
      $fwrite(f,"count of addr %5d is: ", cm_sketch_top0.compute_min.min_addr);
      $fwrite(f,"%5d", cm_sketch_top0.compute_min.min_cnt);
      $fwrite(f,"\n");
    end

  end
end

endmodule
