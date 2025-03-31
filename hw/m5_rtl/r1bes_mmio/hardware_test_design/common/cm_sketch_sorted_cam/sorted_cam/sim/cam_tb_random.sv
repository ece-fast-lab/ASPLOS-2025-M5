`timescale 1ps/1ps
`define TOP cam_tb_random

`define NUM_ENTRY 25
`define INDEX_SIZE $clog2(`NUM_ENTRY)
`define ADDR_SIZE 22
`define CNT_SIZE 32

module cam_tb_random();

localparam NUM_INPUT = 100;
localparam CMD_WIDTH = 4;
localparam TCQ = 100;

localparam FREQ = 450; // MAX: 450 MHz

reg                     clk, rstn;
reg [`CNT_SIZE-1:0]     input_cnt;
reg [`ADDR_SIZE-1:0]    input_addr;
reg                     valid;

integer f, hash;
integer addr_trace_file, cnt_trace_file;
integer iter;
integer i, j;
logic [31:0] num_access;

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
  #100ns

  repeat (10000000) @(posedge clk);

  $fclose(f);
end

// Heap insert start
initial begin
  addr_trace_file = $fopen("./verify/addr_trace.txt", "r");
  cnt_trace_file = $fopen("./verify/cnt_trace.txt", "r");

  valid = 1'b0;
  input_addr = {`ADDR_SIZE{1'b0}};
  input_cnt = {`CNT_SIZE{1'b0}};

  #1500ns
  @(posedge clk);

  forever begin
    repeat(1)@(posedge clk); //#TCQ ;
    
    // not finished
    if (!($feof(addr_trace_file)) && !($feof(cnt_trace_file))) begin
      //#TCQ;
      valid = 1'b1;
      $fscanf(cnt_trace_file, "%d\n", input_cnt);
      $fscanf(addr_trace_file, "%d\n", input_addr);
      repeat (1) @(posedge clk); //#TCQ;
      valid = 1'b0;
    end

    else if ($feof(addr_trace_file) && $feof(cnt_trace_file)) begin
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
    if ((num_access != 0) && cam_top_0.input_valid) begin 
      print_table();
    end
  end
end


always_ff @ (posedge clk or negedge rstn) begin
  if (!rstn) begin
    num_access <= 0;
  end
  else begin
    if (cam_top_0.input_valid) begin  
      num_access <= num_access + 1;
    end
    else begin
      num_access <= num_access;
    end
  end
end


cam_top
#(  
  .NUM_ENTRY(`NUM_ENTRY),
  .INDEX_SIZE(`INDEX_SIZE),
  .ADDR_SIZE(`ADDR_SIZE),
  .CNT_SIZE(`CNT_SIZE)
)
  cam_top_0
(
  // Input
  .clk(clk), 
  .rst_n(rstn), 

  .input_valid(valid),  
  .input_addr(input_addr),
  .input_cnt(input_cnt)

  // Output
  /*TODO*/
);

`ifdef WAVE 
  initial begin
    $shm_open("WAVE");
    $shm_probe("ASM");
  end  
`endif

/*
initial begin
  forever begin
    @ (posedge clk); 

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

    if (cm_sketch_top0.compute_min.output_valid) begin 
      $fwrite(f,"count of addr %5d is: ", cm_sketch_top0.compute_min.min_addr);
      $fwrite(f,"%5d", cm_sketch_top0.compute_min.min_cnt);
      $fwrite(f,"\n");
    end

  end
end
*/

task print_table;
  integer i;
  // $display("\n///// Print table (%8d) /////", num_access);
  $fwrite(f,"///// Print table (%8d) /////\n", num_access);
  for(i = 0; i < `NUM_ENTRY; i = i+1) begin
    //$display("%3d:  %5d  %7x", i, cam_top_0.cnt_array[i], cam_top_0.addr_array[i]);
    $fwrite(f,"%3d:  %5d  %7x\n", i, cam_top_0.cnt_array[i], cam_top_0.addr_array[i]);
  end
  //$display("///////////////////////////////\n");
  $fwrite(f,"///////////////////////////////\n\n");
endtask

endmodule
