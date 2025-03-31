package ctrl_signal_types;

    parameter MC_CHANNEL                = 1;
    parameter MC_HA_DP_ADDR_WIDTH       = 46;
    parameter MC_HA_DP_DATA_WIDTH       = 512;
    parameter MC_HA_DP_SYMBOL_WIDTH     = 8;
    parameter MC_HA_DP_BE_WIDTH         = MC_HA_DP_DATA_WIDTH / MC_HA_DP_SYMBOL_WIDTH;
    parameter EMIF_AMM_ADDR_WIDTH       = 27;
    parameter EMIF_AMM_DATA_WIDTH       = 576;
    parameter EMIF_AMM_BURST_WIDTH      = 7;
    parameter EMIF_AMM_BE_WIDTH         = 72;
    parameter REQFIFO_DATA_WIDTH        = 640;

    parameter SRAM_DATA_WIDTH           = 512;
    parameter SRAM_ADDR_WIDTH           = 14; // 8GB, 4KB, 4bit 
    parameter COUNTER_WIDTH             = 4; // unit: bit
	parameter COUNTER_PER_ENTRY         = SRAM_DATA_WIDTH / COUNTER_WIDTH; // 512/8=64=2^6
	parameter COUNTER_GRAN              = 6; // 0 means per cacheline granularity, 6 means page granularity
    parameter MONITOR_REGION_WIDTH      = 33-(SRAM_ADDR_WIDTH+$clog2(COUNTER_PER_ENTRY)+COUNTER_GRAN+6); // 2^33 is 8GB. Use 8MB sram to monitor 256MB region. 8GB/256MB=2^5

    typedef enum bit[1:0] { FIFO, ISSUER } request_sel_t;
    typedef enum bit [1:0] { IDLE_S, COUNTING_S, WRITE_BACK_COUNTER_S, ZERO_OUT_COUNTER_S } ctrl_state_t;

    // These parameters are defined in mc_top.sv
    typedef struct packed {
        logic [MC_HA_DP_DATA_WIDTH-1:0]   writedata;
        logic [MC_HA_DP_BE_WIDTH-1:0]     byteenable;
        logic                             write_ras_sbe;
        logic                             write_ras_dbe;
        logic [EMIF_AMM_ADDR_WIDTH-1:0]   address;
        logic                             read;
        logic                             write;
        logic                             write_poison;  
    } mem_request_t;

    typedef enum bit[1:0] { UPDATER_A, USER_A } arbiter_sel_t;

    typedef enum bit[1:0] { UPDATER_B, USER_B, CAFU_B } buf_port_sel_t;

    typedef enum bit[2:0] { ZERO_OUT_COUNTER, WRITE_BACK_COUNTER } updater_mode_t;

endpackage



/*
interface mem_request_itf;
    logic                            write;
    logic                            partial_write;
    logic                            read;
    logic [MC_HA_DP_DATA_WIDTH-1:0]  writedata;
    logic                            write_poison;
    logic [MC_HA_DP_BE_WIDTH-1:0]    byteenable;
    logic [EMIF_AMM_ADDR_WIDTH-1:0]  address;
    logic [MC_MDATA_WIDTH-1:0]       req_mdata;
    logic                            write_ras_sbe;
    logic                            write_ras_dbe;  

    modport SENDER (
    output write, partial_write, read, writedata, write_poison,
        byteenable, address, req_mdata, write_ras_dbe, write_ras_dbe;
    );
    modport RECEIVER (
    input write, partial_write, read, writedata, write_poison,
        byteenable, address, req_mdata, write_ras_dbe, write_ras_dbe;
    );
endinterface //mem_request_itf*/
