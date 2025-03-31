interface pac_itf (input logic clk, input logic eclk, input logic reset_n);

    localparam ALTECC_DATAWORD_WIDTH   = 64;
    localparam ALTECC_WIDTH_CODEWORD   = 72;
    localparam ALTECC_INST_NUMBER      = MC_HA_DP_DATA_WIDTH / ALTECC_DATAWORD_WIDTH;

    default clocking tb_clk @(negedge clk); endclocking

    /* to/from EMIF */
    logic [MC_CHANNEL-1:0]             emif_amm_read;                        //  width = 1
    logic [MC_CHANNEL-1:0]             emif_amm_write;                       //  width = 1
    logic [EMIF_AMM_ADDR_WIDTH-1:0]    emif_amm_address    [MC_CHANNEL-1:0]; //  width = 27
    logic [EMIF_AMM_DATA_WIDTH-1:0]    emif_amm_writedata  [MC_CHANNEL-1:0]; //  width = 576
    logic [EMIF_AMM_BURST_WIDTH-1:0]   emif_amm_burstcount [MC_CHANNEL-1:0]; //  width = 7
    logic [EMIF_AMM_BE_WIDTH-1:0]      emif_amm_byteenable [MC_CHANNEL-1:0]; //  width = 72
    logic [MC_CHANNEL-1:0]             emif_amm_readdatavalid;               //  width = 1
    logic [MC_CHANNEL-1:0]             emif_amm_ready;                       //  width = 1
    logic [EMIF_AMM_DATA_WIDTH-1:0]    emif_amm_readdata [MC_CHANNEL-1:0];   //  width = 576

    /* to/from channel_adaptor */
    logic [MC_CHANNEL-1:0]             mem_read_rmw_mclk;
    logic [MC_CHANNEL-1:0]             mem_write_rmw_mclk;
    logic [EMIF_AMM_ADDR_WIDTH-1:0]    mem_address_rmw_mclk     [MC_CHANNEL-1:0];
    logic [MC_HA_DP_DATA_WIDTH-1:0]    mem_readdata_rmw_mclk    [MC_CHANNEL-1:0];
    logic [MC_HA_DP_DATA_WIDTH-1:0]    mem_writedata_rmw_mclk   [MC_CHANNEL-1:0];
    logic [MC_HA_DP_BE_WIDTH-1:0]      mem_byteenable_rmw_mclk  [MC_CHANNEL-1:0];
    logic [MC_CHANNEL-1:0]             mem_readdatavalid_rmw_mclk;
    logic [MC_CHANNEL-1:0]             mem_ready_rmw_mclk;
    
    logic [MC_CHANNEL-1:0]             mem_write_ras_sbe_mclk;
    logic [MC_CHANNEL-1:0]             mem_write_ras_dbe_mclk;
    logic [MC_CHANNEL-1:0]             mem_read_poison_rmw_mclk;
    logic [MC_CHANNEL-1:0]             mem_write_poison_rmw_mclk;

    logic [ALTECC_INST_NUMBER-1:0]     mem_ecc_err_corrected_rmw_mclk [MC_CHANNEL-1:0];
    logic [ALTECC_INST_NUMBER-1:0]     mem_ecc_err_detected_rmw_mclk  [MC_CHANNEL-1:0];
    logic [ALTECC_INST_NUMBER-1:0]     mem_ecc_err_fatal_rmw_mclk     [MC_CHANNEL-1:0];
    logic [ALTECC_INST_NUMBER-1:0]     mem_ecc_err_syn_e_rmw_mclk     [MC_CHANNEL-1:0];

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
    logic [511:0]              wdata;
    logic [(512/8)-1:0]        wstrb;
    logic                      wlast;
    logic                      wuser;
    logic                      wvalid;
    // output logic [7:0]                wid;
    logic                      wready;
  
    /*
        AXI-MM interface - write response channel
    */ 
    logic [11:0]                    bid;
    logic [1:0]                     bresp;
    logic [3:0]                     buser;
    logic                           bvalid;
    logic                           bready;
  
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
    logic [11:0]               rid;
    logic [511:0]              rdata;
    logic [1:0]                rresp;
    logic                      rlast;
    logic                      ruser;
    logic                      rvalid;
    logic                      rready;

    logic                               csr_zero_out;
    logic                               csr_write_back;
    logic [63:0]                        write_back_addr;
    logic [MONITOR_REGION_WIDTH-1:0]    csr_monitor_region;
    logic                               is_writing_back;
    
    clocking ckb @(posedge clk);
        output #2 mem_address_rmw_mclk, mem_read_rmw_mclk, mem_write_rmw_mclk, mem_byteenable_rmw_mclk, mem_writedata_rmw_mclk,
                    csr_zero_out, csr_write_back, write_back_addr;
    endclocking

    /* The following are the internal signals of the dut */
    logic                               counter_buf_wren;
    logic [SRAM_ADDR_WIDTH-1:0]         counter_buf_wraddress;
    logic [SRAM_DATA_WIDTH-1:0]         counter_buf_wdata;

    ctrl_state_t state;


endinterface //pac_itf
