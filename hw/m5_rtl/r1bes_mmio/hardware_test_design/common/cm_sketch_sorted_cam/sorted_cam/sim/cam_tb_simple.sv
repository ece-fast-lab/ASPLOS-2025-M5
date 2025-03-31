
`define TOP cam_tb

`define NUM_ENTRY 25
`define INDEX_SIZE 5
`define ADDR_SIZE 22
`define CNT_SIZE 32

module cam_tb();

  reg                     CLK, RST_N;
  reg                     INPUT_VALID;
  reg [`ADDR_SIZE-1:0]    INPUT_ADDR;
  reg [`CNT_SIZE-1:0]    INPUT_CNT;

  cam_top
  #(  
    .NUM_ENTRY(`NUM_ENTRY),
    .INDEX_SIZE(`INDEX_SIZE),
    .ADDR_SIZE(`ADDR_SIZE),
    .CNT_SIZE(`CNT_SIZE)
  )
    cam_top_test
  (
    // Input
    .clk(CLK), 
    .rst_n(RST_N), 

    .input_valid(INPUT_VALID),  
    .input_addr(INPUT_ADDR),
    .input_cnt(INPUT_CNT)
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
    INPUT_CNT = `CNT_SIZE'd32;
    @(posedge CLK)
    INPUT_VALID = 1'b0;

    @(posedge CLK)
    INPUT_VALID = 1'b1;
    INPUT_ADDR = `ADDR_SIZE'd106;
    INPUT_CNT = `CNT_SIZE'd30;
    @(posedge CLK)
    INPUT_VALID = 1'b0;

    @(posedge CLK)
    INPUT_VALID = 1'b1;
    INPUT_ADDR = `ADDR_SIZE'd111;
    INPUT_CNT = `CNT_SIZE'd13;
    @(posedge CLK)
    INPUT_VALID = 1'b0;

    @(posedge CLK)
    INPUT_VALID = 1'b1;
    INPUT_ADDR = `ADDR_SIZE'd105;
    INPUT_CNT = `CNT_SIZE'd31;
    @(posedge CLK)
    INPUT_VALID = 1'b0;

    @(posedge CLK)
    INPUT_VALID = 1'b1;    
    INPUT_ADDR = `ADDR_SIZE'd107;
    INPUT_CNT = `CNT_SIZE'd40;
    @(posedge CLK)
    INPUT_VALID = 1'b0;

    @(posedge CLK)
    INPUT_VALID = 1'b1;
    INPUT_ADDR = `ADDR_SIZE'd103;
    INPUT_CNT = `CNT_SIZE'd10;
    @(posedge CLK)
    INPUT_VALID = 1'b0;

    @(posedge CLK)
    INPUT_VALID = 1'b1;
    INPUT_ADDR = `ADDR_SIZE'd110;
    INPUT_CNT = `CNT_SIZE'd55;
    @(posedge CLK)
    INPUT_VALID = 1'b0;

    @(posedge CLK)
    INPUT_VALID = 1'b1;
    INPUT_ADDR = `ADDR_SIZE'd117;
    INPUT_CNT = `CNT_SIZE'd70;
    @(posedge CLK)
    INPUT_VALID = 1'b0;

    @(posedge CLK)
    INPUT_VALID = 1'b1;
    INPUT_ADDR = `ADDR_SIZE'd118;
    INPUT_CNT = `CNT_SIZE'd102;
    @(posedge CLK)
    INPUT_VALID = 1'b0;

    @(posedge CLK)
    INPUT_VALID = 1'b1;
    INPUT_ADDR = `ADDR_SIZE'd102;
    INPUT_CNT = `CNT_SIZE'd88;
    @(posedge CLK)
    INPUT_VALID = 1'b0;

    @(posedge CLK)
    INPUT_VALID = 1'b1;
    INPUT_ADDR = `ADDR_SIZE'd112;
    INPUT_CNT = `CNT_SIZE'd8;
    @(posedge CLK)
    INPUT_VALID = 1'b0;

    @(posedge CLK)
    INPUT_VALID = 1'b1;
    INPUT_ADDR = `ADDR_SIZE'd128;
    INPUT_CNT = `CNT_SIZE'd59;
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