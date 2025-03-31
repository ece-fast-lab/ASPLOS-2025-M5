module cust_afu_tb ();


    logic clk, reset_n;
    always #5 clk = (clk === 1'b0);
    default clocking tb_clk @(negedge clk); endclocking

    /*
        AXI-MM interface - write address channel
    */
    logic [11:0]               awid;
    logic [63:0]               awaddr; 
    logic [9:0]                awlen;
    logic [2:0]                awsize;
    logic [1:0]                awburst;
    logic [2:0]                awprot;
    logic [3:0]                awqos;
    logic [5:0]                awuser;
    logic                      awvalid;
    logic [3:0]                awcache;
    logic [1:0]                awlock;
    logic [3:0]                awregion;
    logic [5:0]                awatop;
    logic                      awready;
  
    /*
        AXI-MM interface - write data channel
    */
    logic [511:0]               wdata;
    logic [(512/8)-1:0]         wstrb;
    logic                       wlast;
    logic                       wuser;
    logic                       wvalid;
    // logic [7:0]                wid;
    logic                       wready;
  
    /*
        AXI-MM interface - write response channel
    */ 
    logic [11:0]                bid;
    logic [1:0]                 bresp;
    logic [3:0]                 buser;
    logic                       bvalid;
    logic                       bready;
  
    /*
        AXI-MM interface - read address channel
    */
    logic [11:0]               arid;
    logic [63:0]               araddr;
    logic [9:0]                arlen;
    logic [2:0]                arsize;
    logic [1:0]                arburst;
    logic [2:0]                arprot;
    logic [3:0]                arqos;
    logic [4:0]                aruser;
    logic                      arvalid;
    logic [3:0]                arcache;
    logic [1:0]                arlock;
    logic [3:0]                arregion;
    logic                      arready;

    /*
        AXI-MM interface - read response channel
    */ 
    logic [11:0]                     rid;
    logic [511:0]                    rdata;
    logic [1:0]                      rresp;
    logic                            rlast;
    logic                            ruser;
    logic                            rvalid;
    logic                            rready;
  
    /* From CSR */
    logic  [63:0]               write_back_base_addr;
    logic                       write_back_start;
    logic                       write_back_done;

    logic [SRAM_ADDR_WIDTH-1:0]  cafu2buf_rdaddress;
    logic [SRAM_DATA_WIDTH-1:0]  buf2cafu_q;
    logic                        buf2cafu_q_valid; // for synchronization purpose
    logic                        cafu2buf_q_resp;


    my_cust_afu dut(
        .axi4_mm_clk(clk),
        .axi4_mm_rst_n(reset_n),
        .*
    );


    /* Stimulus */
    initial begin

        $timeformat(-9, 1, "ns");
        
        reset_n <= 1'b0;
        write_back_start <= 1'b0;
        repeat(2)@(tb_clk);
        reset_n <= 1'b1;

        /* set signals */
        @(tb_clk);
        awready <= 1'b1;
        wready  <= 1'b1;
        write_back_base_addr <= 'hA0000;
        bvalid  <= 1'b0;
        bresp   <= 4'b0000;

        fork
            stimulus();
            write_response();
        join

    end

    task automatic stimulus();
        /* start the writeback */
        $display("[INFO] Start writeback.");
        @(tb_clk);
        write_back_start <= 1'b1;
        @(tb_clk);
        write_back_start <= 1'b0;

        forever begin
            @(tb_clk);
            if (dut.state == 3'b0) begin
                $display("[RESULT] State returned to IDLE.");
                if (awaddr != 0) begin
                   $display("[ERROR] The awaddr should be 0 when in IDLE state!"); 
                end else begin
                   $display("[RESULT] Checks PASSED."); 
                end
                $finish;
            end
        end
        

    endtask //automatic


    int timeout_counter;

    task automatic write_response();
        forever begin
            $display("[Monitor] Waiting for awvalid...");
            while (awvalid == 1'b0) begin
                @(tb_clk);
            end
            @(tb_clk);
            awready <= 1'b1;

            $display("[Monitor] Waiting for wvalid...");
            while (wvalid == 1'b0) begin
                @(tb_clk);
                awready <= 1'b0;
                timeout_counter++;
                timeout();
            end
            @(tb_clk);
            awready <= 1'b0;
            wready <= 1'b1;
            timeout_counter = 0;

            $display("[Monitor] Waiting for bready...");
            @(tb_clk);
            bvalid  <= 1'b1;
            wready  <= 1'b0;
            while (bready == 1'b0) begin
                @(tb_clk);
                wready  <= 1'b0;
                timeout_counter++;
                timeout();
            end
            @(tb_clk);
            bvalid <= 1'b0;
            timeout_counter = 0;

        end
    endtask //automatic

    task automatic timeout();
        if (timeout_counter >= 100) begin
            $display("[ERROR] Timeout!");
            $finish;
        end
    endtask //automatic


    initial begin
        $fsdbDumpfile("cust_afu.fsdb");
        $fsdbDumpvars;
    end

endmodule