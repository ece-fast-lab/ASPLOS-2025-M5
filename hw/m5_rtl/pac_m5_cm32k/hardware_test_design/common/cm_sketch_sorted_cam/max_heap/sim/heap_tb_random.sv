`timescale 1ps/1ps
`define TOP heap_tb_random
`define CNT_SIZE 20
`define ADDR_SIZE 28
`define TOTAL_LEVEL 6


module heap_tb_random();

localparam NUM_INPUT = 100;
localparam NUM_ENTRY = 63;
localparam CMD_WIDTH = 4;
localparam TCQ = 100;

localparam FREQ = 450; // MAX: 450 MHz

reg                     clk, rstn;
reg [`CNT_SIZE-1:0]     input_cnt;
reg [`ADDR_SIZE-1:0]    input_addr;
reg                     valid, valid_d1, valid_d2, valid_d3;

integer f;
integer addr_trace_file, cnt_trace_file;
integer iter;
genvar i;
genvar j;
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
      repeat (20) @(posedge clk);
    end

    else if ($feof(cnt_trace_file) & ((num_access >= NUM_INPUT))) begin
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
  forever begin
    @ (posedge clk); 
    if (valid_d3) begin 
      #(10*1000*1000/2/FREQ);
      print_table();
    end
  end
end


always_ff @ (posedge clk or negedge rstn) begin
  if (!rstn) begin
    num_access <= 0;
  end
  else begin
    if (valid_d2) begin  
      num_access <= num_access + 1;
    end
    else begin
      num_access <= num_access;
    end
  end
end

always_ff @ (posedge clk or negedge rstn) begin
  if (!rstn) begin
    valid_d1 <= 0;
    valid_d2 <= 0;
    valid_d3 <= 0;
  end
  else begin
    valid_d1 <= valid;
    valid_d2 <= valid_d1;
    valid_d3 <= valid_d2;
  end
end

heap 
#(
  .CNT_SIZE(`CNT_SIZE),
  .ADDR_SIZE(`ADDR_SIZE),
  .TOTAL_LEVEL(`TOTAL_LEVEL)
)
  heap0
(
  .clk(clk), 
  .rst_n(rstn), 
  .input_valid(valid), 
  .input_cnt(input_cnt), 
  .input_addr(input_addr),
  .input_query(1'b0)
);

`ifdef WAVE 
  initial begin
    $shm_open("WAVE");
    $shm_probe("ASM");
  end  
`endif

task print_table;
  integer i;
  $display("\n///// Print heap (%8d) /////", num_access);
  $fwrite(f,"///// Print heap (%8d) /////\n", num_access);
  for(i = 1; i < NUM_ENTRY+1; i = i+1) begin
    $display("%3d:  %5d  %7x", i, heap0.cnt_wire[i], heap0.addr_wire[i]);
    $fwrite(f,"%3d:  %5d  %7x\n", i, heap0.cnt_wire[i], heap0.addr_wire[i]);
  end
  $display("///////////////////////////////\n");
  $fwrite(f,"///////////////////////////////\n\n");
endtask

endmodule
