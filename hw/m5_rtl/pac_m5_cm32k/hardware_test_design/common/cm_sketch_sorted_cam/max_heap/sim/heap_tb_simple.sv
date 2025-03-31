
`define TOP heap_tb
`define CNT_SIZE 20
`define ADDR_SIZE 28
`define TOTAL_LEVEL 6
module heap_tb();

  reg                     CLK, RST_N;
  reg [`CNT_SIZE-1:0]     INP_CNT;
  reg [`ADDR_SIZE-1:0]    INP_ADDR;
  reg                     VALID;

  heap 
  #(
    .CNT_SIZE(`CNT_SIZE),
    .ADDR_SIZE(`ADDR_SIZE),
    .TOTAL_LEVEL(`TOTAL_LEVEL)
  )
    heap_test 
  (
    .clk(CLK), 
    .rst_n(RST_N), 
    .input_valid(VALID), 
    .input_cnt(INP_CNT), 
    .input_addr(INP_ADDR),
    .input_query(1'b0)
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
    VALID = 1'b0;
    #110
    @(posedge CLK)
    VALID = 1'b1;
    INP_CNT = `CNT_SIZE'd7;
    INP_ADDR = `ADDR_SIZE'd107;
    @(posedge CLK)
    VALID = 1'b0;
    @(posedge CLK)
    VALID = 1'b1;
    INP_CNT = `CNT_SIZE'd6;
    INP_ADDR = `ADDR_SIZE'd106;
    @(posedge CLK)
    VALID = 1'b0;
    @(posedge CLK)
    VALID = 1'b1;
    INP_CNT = `CNT_SIZE'd11;
    INP_ADDR = `ADDR_SIZE'd111;
    @(posedge CLK)
    VALID = 1'b0;
    @(posedge CLK)
    VALID = 1'b1;
    INP_CNT = `CNT_SIZE'd5;
    INP_ADDR = `ADDR_SIZE'd105;
    @(posedge CLK)
    VALID = 1'b0;
    @(posedge CLK)
    VALID = 1'b1;
    INP_CNT = `CNT_SIZE'd8;
    INP_ADDR = `ADDR_SIZE'd108;
    @(posedge CLK)
    VALID = 1'b0;
    @(posedge CLK)
    VALID = 1'b1;
    INP_CNT = `CNT_SIZE'd3;
    INP_ADDR = `ADDR_SIZE'd103;
    @(posedge CLK)
    VALID = 1'b0;
    @(posedge CLK)
    VALID = 1'b1;
    INP_CNT = `CNT_SIZE'd10;
    INP_ADDR = `ADDR_SIZE'd110;
    @(posedge CLK)
    VALID = 1'b0;
    @(posedge CLK)
    VALID = 1'b1;
    INP_CNT = `CNT_SIZE'd17;
    INP_ADDR = `ADDR_SIZE'd117;
    @(posedge CLK)
    VALID = 1'b0;
    @(posedge CLK)
    VALID = 1'b1;
    INP_CNT = `CNT_SIZE'd18;
    INP_ADDR = `ADDR_SIZE'd118;
    @(posedge CLK)
    VALID = 1'b0;
    @(posedge CLK)
    VALID = 1'b1;
    INP_CNT = `CNT_SIZE'd2;
    INP_ADDR = `ADDR_SIZE'd102;
    @(posedge CLK)
    VALID = 1'b0;
    @(posedge CLK)
    VALID = 1'b1;
    INP_CNT = `CNT_SIZE'd12;
    INP_ADDR = `ADDR_SIZE'd112;
    @(posedge CLK)
    VALID = 1'b0;
    @(posedge CLK)
    VALID = 1'b1;
    INP_CNT = `CNT_SIZE'd28;
    INP_ADDR = `ADDR_SIZE'd128;
    @(posedge CLK)
    VALID = 1'b0;
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