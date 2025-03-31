
`define TOP cm_sketch_tb

`define W 4096
`define NUM_HASH 4
`define HASH_SIZE 12
`define ADDR_SIZE 28
`define CNT_SIZE 32


module cm_sketch_tb();

  reg                     CLK, RST_N;
  reg                     INPUT_VALID;
  reg [`ADDR_SIZE-1:0]    INPUT_ADDR;

  wire                    OUTPUT_VALID;
  wire [`ADDR_SIZE-1:0]   OUTPUT_ADDR;
  wire [`CNT_SIZE-1:0]    OUTPUT_CNT;


  cm_sketch_top
  #(  
    .W(`W),
    .NUM_HASH(`NUM_HASH),
    .HASH_SIZE(`HASH_SIZE),
    .ADDR_SIZE(`ADDR_SIZE),
    .CNT_SIZE(`CNT_SIZE)
  )
    cm_sketch_top_test 
  (
    // Input
    .clk(CLK), 
    .rst_n(RST_N), 

    .input_valid(INPUT_VALID),  
    .input_addr(INPUT_ADDR),

    // Output
    .output_valid(OUTPUT_VALID),
    .output_addr(OUTPUT_ADDR),
    .output_cnt(OUTPUT_CNT)
  );

  initial begin
    CLK     = 1'b0;
    RST_N   = 1'b1;
    #20
    RST_N   = 1'b0;
    #60
    RST_N   = 1'b1;
    #2000
    $finish;
  end

  initial begin
    INPUT_VALID = 1'b0;
    #110
    @(posedge CLK)
    INPUT_VALID = 1'b1;
    INPUT_ADDR = `ADDR_SIZE'd107;

    @(posedge CLK)
    INPUT_VALID = 1'b0;

    @(posedge CLK)
    INPUT_VALID = 1'b1;
    INPUT_ADDR = `ADDR_SIZE'd106;

    @(posedge CLK)
    INPUT_VALID = 1'b0;

    @(posedge CLK)
    INPUT_VALID = 1'b1;
    INPUT_ADDR = `ADDR_SIZE'd111;

    @(posedge CLK)
    INPUT_VALID = 1'b0;

    @(posedge CLK)
    INPUT_VALID = 1'b1;
    INPUT_ADDR = `ADDR_SIZE'd105;

    @(posedge CLK)
    INPUT_VALID = 1'b0;

    @(posedge CLK)
    INPUT_VALID = 1'b1;    
    INPUT_ADDR = `ADDR_SIZE'd108;

    @(posedge CLK)
    INPUT_VALID = 1'b0;

    @(posedge CLK)
    INPUT_VALID = 1'b1;
    INPUT_ADDR = `ADDR_SIZE'd103;

    @(posedge CLK)
    INPUT_VALID = 1'b0;

    @(posedge CLK)
    INPUT_VALID = 1'b1;
    INPUT_ADDR = `ADDR_SIZE'd110;

    @(posedge CLK)
    INPUT_VALID = 1'b0;

    @(posedge CLK)
    INPUT_VALID = 1'b1;
    INPUT_ADDR = `ADDR_SIZE'd117;

    @(posedge CLK)
    INPUT_VALID = 1'b0;

    @(posedge CLK)
    INPUT_VALID = 1'b1;
    INPUT_ADDR = `ADDR_SIZE'd118;

    @(posedge CLK)
    INPUT_VALID = 1'b0;

    @(posedge CLK)
    INPUT_VALID = 1'b1;
    INPUT_ADDR = `ADDR_SIZE'd102;

    @(posedge CLK)
    INPUT_VALID = 1'b0;

    @(posedge CLK)
    INPUT_VALID = 1'b1;
    INPUT_ADDR = `ADDR_SIZE'd112;

    @(posedge CLK)
    INPUT_VALID = 1'b0;

    @(posedge CLK)
    INPUT_VALID = 1'b1;
    INPUT_ADDR = `ADDR_SIZE'd128;
    
    @(posedge CLK)
    INPUT_VALID = 1'b0;
  end

  always begin
    #20 CLK = ~CLK;
  end

  `ifdef WAVE 
    initial begin
      $shm_open("WAVE");
      $shm_probe("ASM");
    end  
  `endif

endmodule