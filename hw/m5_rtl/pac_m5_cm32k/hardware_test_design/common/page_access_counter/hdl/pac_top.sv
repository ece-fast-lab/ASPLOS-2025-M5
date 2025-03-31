import ctrl_signal_types::*;

module pac_top #(
   parameter ALTECC_DATAWORD_WIDTH   = 64,
   parameter ALTECC_WIDTH_CODEWORD   = 72,
   parameter ALTECC_INST_NUMBER      = MC_HA_DP_DATA_WIDTH / ALTECC_DATAWORD_WIDTH
) (
    input logic mclk,
    input logic reset_n,

    /* to/from EMIF */
    output  logic [MC_CHANNEL-1:0]             emif_amm_read,                        //  width = 1,
    output  logic [MC_CHANNEL-1:0]             emif_amm_write,                       //  width = 1,
    output  logic [EMIF_AMM_ADDR_WIDTH-1:0]    emif_amm_address    [MC_CHANNEL-1:0], //  width = 27,
    output  logic [EMIF_AMM_DATA_WIDTH-1:0]    emif_amm_writedata  [MC_CHANNEL-1:0], //  width = 576,
    output  logic [EMIF_AMM_BURST_WIDTH-1:0]   emif_amm_burstcount [MC_CHANNEL-1:0], //  width = 7,
    output  logic [EMIF_AMM_BE_WIDTH-1:0]      emif_amm_byteenable [MC_CHANNEL-1:0], //  width = 72,
    input   logic [MC_CHANNEL-1:0]             emif_amm_readdatavalid,               //  width = 1,
    input   logic [MC_CHANNEL-1:0]             emif_amm_ready,                       //  width = 1,
    input   logic [EMIF_AMM_DATA_WIDTH-1:0]    emif_amm_readdata [MC_CHANNEL-1:0],   //  width = 576

    /* to/from channel_adaptor */
	input   logic [MC_CHANNEL-1:0]             mem_read_rmw_mclk,
    input   logic [MC_CHANNEL-1:0]             mem_write_rmw_mclk,
	input   logic [EMIF_AMM_ADDR_WIDTH-1:0]    mem_address_rmw_mclk     [MC_CHANNEL-1:0],
    input   logic [MC_HA_DP_DATA_WIDTH-1:0]    mem_writedata_rmw_mclk   [MC_CHANNEL-1:0],
    input   logic [MC_HA_DP_BE_WIDTH-1:0]      mem_byteenable_rmw_mclk  [MC_CHANNEL-1:0],
    output  logic [MC_HA_DP_DATA_WIDTH-1:0]    mem_readdata_rmw_mclk    [MC_CHANNEL-1:0],
    output  logic [MC_CHANNEL-1:0]             mem_readdatavalid_rmw_mclk,
    output  logic [MC_CHANNEL-1:0]             mem_ready_rmw_mclk,
	output	logic [ALTECC_INST_NUMBER-1:0]     mem_ecc_err_corrected_rmw_mclk [MC_CHANNEL-1:0],
	output	logic [ALTECC_INST_NUMBER-1:0]     mem_ecc_err_detected_rmw_mclk  [MC_CHANNEL-1:0],
	output	logic [ALTECC_INST_NUMBER-1:0]     mem_ecc_err_fatal_rmw_mclk     [MC_CHANNEL-1:0],
	output	logic [ALTECC_INST_NUMBER-1:0]     mem_ecc_err_syn_e_rmw_mclk     [MC_CHANNEL-1:0],

    input logic [MC_CHANNEL-1:0]             mem_write_ras_sbe_mclk,
    input logic [MC_CHANNEL-1:0]             mem_write_ras_dbe_mclk,
    input logic [MC_CHANNEL-1:0]             mem_write_poison_rmw_mclk,
    output logic [MC_CHANNEL-1:0]            mem_read_poison_rmw_mclk,


	/* ================== */
	/* To/From Custom AFU */
	/* ================== */

	// Clocks
    input logic  axi4_mm_clk, 

    // Resets
    input logic  axi4_mm_rst_n,

    /*
        AXI-MM interface - write address channel
    */
    output logic [11:0]               awid,
    output logic [63:0]               awaddr, 
    output logic [9:0]                awlen,
    output logic [2:0]                awsize,
    output logic [1:0]                awburst,
    output logic [2:0]                awprot,
    output logic [3:0]                awqos,
    output logic [5:0]                awuser,
    output logic                      awvalid,
    output logic [3:0]                awcache,
    output logic [1:0]                awlock,
    output logic [3:0]                awregion,
    output logic [5:0]                awatop,
    input  logic                      awready,
  
    /*
        AXI-MM interface - write data channel
    */
    output logic [511:0]              wdata,
    output logic [(512/8)-1:0]        wstrb,
    output logic                      wlast,
    output logic                      wuser,
    output logic                      wvalid,
    // output logic [7:0]                wid,
    input  logic                      wready,
  
    /*
        AXI-MM interface - write response channel
    */ 
    input logic [11:0]               bid,
    input logic [1:0]                bresp,
    input logic [3:0]                buser,
    input logic                      bvalid,
    output logic                     bready,
  
    /*
        AXI-MM interface - read address channel
    */
    output logic [11:0]               arid,
    output logic [63:0]               araddr,
    output logic [9:0]                arlen,
    output logic [2:0]                arsize,
    output logic [1:0]                arburst,
    output logic [2:0]                arprot,
    output logic [3:0]                arqos,
    output logic [4:0]                aruser,
    output logic                      arvalid,
    output logic [3:0]                arcache,
    output logic [1:0]                arlock,
    output logic [3:0]                arregion,
    input  logic                      arready,

    /*
        AXI-MM interface - read response channel
    */ 
    input logic [11:0]               rid,
    input logic [511:0]              rdata,
    input logic [1:0]                rresp,
    input logic                      rlast,
    input logic                      ruser,
    input logic                      rvalid,
    output logic                     rready,


	/* =========== */
	/* To/From CSR */
	/* =========== */

    // from csr
    input   logic csr_zero_out_aclk,
    input   logic csr_write_back_aclk,
	input 	logic [63:0] write_back_addr,
	input 	logic [31:0] csr_write_back_cnt_aclk,
	input	logic [MONITOR_REGION_WIDTH-1:0] csr_monitor_region, // in unit of 1GB
    input   logic [63:0] csr_ofw_buf_tail_max,

	input	logic [5:0]  csr_awuser_aclk,
	input	logic [63:0] csr_ofw_buf_head_aclk,
	// to csr
	output	logic is_writing_back,

	output	logic [63:0] csr_ofw_buf_vld_cnt
);

	// Moved to ctrl_signal_types.sv
	// localparam COUNTER_WIDTH = 8; // unit: bit
	// localparam COUNTER_PER_ENTRY = SRAM_DATA_WIDTH / COUNTER_WIDTH; // 512/8=64
	// localparam COUNTER_GRAN = 0; // 0 means per cacheline granularity

	logic 			mem_updater_done;
	logic 			mem_updater_start;
	logic 			mem_updater_hold_reqfifo;
	(* preserve_for_debug *) logic 			eac2mc_ready;
	updater_mode_t  mem_updater_mode;
    buf_port_sel_t  buf_port_sel;
    arbiter_sel_t   arbiter_sel;

	mem_request_t   request_user;
    mem_request_t   request_updater;
	mem_request_t	request_out;
	mem_request_t   request_arbiter_out;

    logic [SRAM_ADDR_WIDTH-1:0] request_addr_2_sram_addr;

	logic [SRAM_DATA_WIDTH-1:0] buf_data;    
    logic [SRAM_DATA_WIDTH-1:0] buf_q;       
    logic [SRAM_ADDR_WIDTH-1:0] buf_wraddress;
    logic [SRAM_ADDR_WIDTH-1:0] buf_rdaddress;
    logic        				buf_wren;

	logic 			csr_write_back_mclk;
	logic 			csr_zero_out_mclk;
	logic [31:0]	csr_write_back_cnt_mclk;

	logic [31:0] 	csr_write_back_cnt_sync1;
	logic [31:0] 	csr_write_back_cnt_sync2;

	logic [SRAM_DATA_WIDTH-1:0] updater2buf_data;      
    logic [SRAM_ADDR_WIDTH-1:0] updater2buf_wraddress;
    logic [SRAM_ADDR_WIDTH-1:0] updater2buf_rdaddress;
    logic        				updater2buf_wren;
	
	// Counter update signals
	logic 									valid_buf_1; // valid means this buffered data is a request
	logic 									valid_buf_2; //   introduced to solve the edge case of 4 consecutive accesses to the same addr
	logic 									wren_buf_1;	// wren means whether this request should be written to the counter_buf
	logic 									wren_buf_2;
	logic [SRAM_ADDR_WIDTH-1:0] 			addr_buf_1;
	logic [SRAM_ADDR_WIDTH-1:0] 			addr_buf_2;
	logic [SRAM_DATA_WIDTH-1:0] 			counter_incremented; 
	logic [$clog2(COUNTER_PER_ENTRY)-1:0] 	subcounter_buf_1;
	logic [$clog2(COUNTER_PER_ENTRY)-1:0] 	subcounter_buf_2;
	logic 									buf1_same_as_req;
	logic 									buf2_same_as_req;
	logic									buf2_same_as_buf1;
	logic 									is_monitor_region; // asserted when the request falls in the region we are monitoring (for cacheline granularity counting)
	logic 									is_monitor_region_reg;
	// logic [4:0] 				subcounter_sel; // determines which of the 32 counters in one word is being written to

	logic [MC_HA_DP_DATA_WIDTH-1:0] emif_amm_readdata_chopped [MC_CHANNEL-1:0];
	assign emif_amm_readdata_chopped[0] = emif_amm_readdata[0][MC_HA_DP_DATA_WIDTH-1:0];

	// Arbiter signals
	logic grant_updater;
	(* preserve_for_debug *) logic grant_user;
	logic req_updater;
	logic req_user;
	mem_request_t in_requests [2];

	assign req_updater = request_updater.read || request_updater.write;
	assign req_user = request_user.read || request_user.write;
	assign in_requests[0] = request_updater;
	assign in_requests[1] = request_user;

	// assign request_out = request_user; // Pass-through
	// assign mem_ready_rmw_mclk = emif_amm_ready;
	// assign request_out = request_arbiter_out; // Arbiter in route
	// assign mem_ready_rmw_mclk[0] = grant_user;
	assign mem_ready_rmw_mclk = emif_amm_ready[0] & (~mem_updater_hold_reqfifo); // let mem_updater decide if ready or not

	// Overflow logic signals
	logic 						ofw_detected;
	logic [31:0]				ofw_address;

	logic [511:0] 				ofw_q_wrdata;
	logic 						ofw_q_wrreq;
	logic 						ofw_q_full;
	logic [$clog2(512/32)-1:0] 	ofw_q_wrdata_ptr;
	logic 						ofw_q_wrdata_valid;

	logic 						ofw_q_rdreq;
	logic [511:0] 				ofw_q_rddata;
	logic 						ofw_q_empty;

	logic [5:0]                 csr_awuser_eclk;
	logic [63:0]                csr_ofw_buf_head_eclk;

	//buf_512w_65536d counter_buf_inst (
	//buf_512w_32768d counter_buf_inst (
	buf_512w_16384d counter_buf_inst (
		.data(buf_data),
		.q(buf_q),
		.wraddress(buf_wraddress),
		.rdaddress(buf_rdaddress),
		.wren(buf_wren),
		.clock(mclk)
    );

	// buf_512w_131072d counter_buf_inst (
	// 	.data(buf_data),
	// 	.q(buf_q),
	// 	.wraddress(buf_wraddress),
	// 	.rdaddress(buf_rdaddress),
	// 	.wren(buf_wren),
	// 	.clock(mclk)
    // );

	counter_ctrl counter_ctrl_inst (
		.clk				(mclk),
		.reset_n			(reset_n),
		.mem_updater_done	(mem_updater_done),
		.mem_updater_start	(mem_updater_start),
		.mem_updater_mode	(mem_updater_mode),
		.cafu_start			(cafu_start_mclk),
		.cafu_done			('0),		// not used anymore
		.buf_port_sel		(buf_port_sel),
		.arbiter_sel		(arbiter_sel),
		.eac2mc_ready       (eac2mc_ready), // only monitor channel 0 for now
		.emif_amm_ready		(emif_amm_ready),
		.zero_out			(csr_zero_out_mclk),
		.write_back			(csr_write_back_mclk),
		.dram_buf_base_addr	('0), // not used
		.is_writing_back	(is_writing_back)
	);


	mem_updater mem_updater_inst (
		.mclk				(mclk),
		.reset_n			(reset_n),
		.start				(mem_updater_start),
		.mode				(mem_updater_mode),
		.buffer_addr		(write_back_addr),
		.done				(mem_updater_done), 
		.hold_reqfifo		(mem_updater_hold_reqfifo),
		// .mem_ready_mclk		(grant_updater),
		.mem_ready_mclk		(emif_amm_ready),
		.mem_readdata_mclk	(emif_amm_readdata_chopped),
		.mem_readdatavalid_mclk(emif_amm_readdatavalid),
		.buf_data			(updater2buf_data),
		.buf_q				(buf_q),
		.buf_wraddress		(updater2buf_wraddress),
		.buf_rdaddress		(updater2buf_rdaddress),
		.buf_wren			(updater2buf_wren),
		.mem_request		(request_updater),
        .write_back_cnt     (csr_write_back_cnt_mclk)
	); 


	
	(* preserve_for_debug *) logic awvalid_debug;
	(* preserve_for_debug *) logic wvalid_debug;
	// assign awvalid = 1'b0;
	// assign wvalid = 1'b0;

	ofw_buf_afu ofw_buf_afu_inst (
		// Clocks
		.axi4_mm_clk                           (axi4_mm_clk), 
		// Resets
		.axi4_mm_rst_n                         (axi4_mm_rst_n),

		// AXI-MM interface - write address channel
		.awid                                  (awid),
		.awaddr                                (awaddr), 
		.awlen                                 (awlen),
		.awsize                                (awsize),
		.awburst                               (awburst),
		.awprot                                (awprot),
		.awqos                                 (awqos),
		.awuser                                (awuser),
		.awvalid                               (awvalid),
		.awcache                               (awcache),
		.awlock                                (awlock),
		.awregion                              (awregion),
		.awatop                                (awatop),
		.awready                               (awready),
		
		// AXI-MM interface - write data channel
		.wdata                                 (wdata),
		.wstrb                                 (wstrb),
		.wlast                                 (wlast),
		.wuser                                 (wuser),
		.wvalid                                (wvalid),
		.wready                                (wready),
		
		//  AXI-MM interface - write response channel
		.bid                                  (bid),
		.bresp                                (bresp),
		.buser                                (buser),
		.bvalid                               (bvalid),
		.bready                               (bready),
		
		// AXI-MM interface - read address channel
		.arid                                  (arid),
		.araddr                                (araddr),
		.arlen                                 (arlen),
		.arsize                                (arsize),
		.arburst                               (arburst),
		.arprot                                (arprot),
		.arqos                                 (arqos),
		.aruser                                (aruser),
		.arvalid                               (arvalid),
		.arcache                               (arcache),
		.arlock                                (arlock),
		.arregion                              (arregion),
		.arready                               (arready),

		// AXI-MM interface - read response channel
		.rid                                   (rid),
		.rdata                                 (rdata),
		.rresp                                 (rresp),
		.rlast                                 (rlast),
		.ruser                                 (ruser),
		.rvalid                                (rvalid),
		.rready                                (rready),

		// CSR Control signals
		.csr_awuser							   (csr_awuser_eclk),
		.ofw_buf_head						   (csr_ofw_buf_head_eclk),
		.ofw_buf_vld_cnt					   (csr_ofw_buf_vld_cnt),
        .csr_ofw_buf_tail_max                  (csr_ofw_buf_tail_max),

		// Overflow Queue control signals
		.ofw_q_empty						   (ofw_q_empty),
		.ofw_q_rdreq						   (ofw_q_rdreq),
		.ofw_q_rddata						   (ofw_q_rddata)
	);


	altera_std_synchronizer_nocut #(
        .depth(3)
	) synchronizer_inst_1 (
		.clk            (mclk),
		.reset_n        (1'b1),
		.din            (csr_write_back_aclk),
		.dout           (csr_write_back_mclk)
	);

	altera_std_synchronizer_nocut #(
        .depth(3)
	) synchronizer_inst_2 (
		.clk            (mclk),
		.reset_n        (1'b1),
		.din            (csr_zero_out_aclk),
		.dout           (csr_zero_out_mclk)
	);

	bus_synchronizer #(
		.SIGNAL_WIDTH(6)
	) bus_synchronizer_inst_awuser (
		.clk            (axi4_mm_clk),
		.data_in        (csr_awuser_aclk),
		.data_out       (csr_awuser_eclk)
	);


	bus_synchronizer #(
		.SIGNAL_WIDTH(64)
	) bus_synchronizer_inst_ofw_buf_head (
		.clk      (axi4_mm_clk),
		.data_in  (csr_ofw_buf_head_aclk),
		.data_out (csr_ofw_buf_head_eclk)
	);

	/* Bus synchronization */
	always_ff @( posedge mclk ) begin : naive_sync_for_bus_writeback_cnt
		csr_write_back_cnt_mclk 	<= csr_write_back_cnt_sync2;
		csr_write_back_cnt_sync2 	<= csr_write_back_cnt_sync1;
		csr_write_back_cnt_sync1 	<= csr_write_back_cnt_aclk;
	end


	/* fill in the request struct */
    // XXX -- assume single channel
	assign request_user.read			= mem_read_rmw_mclk[0];
	assign request_user.write 			= mem_write_rmw_mclk[0];
	assign request_user.address 		= mem_address_rmw_mclk[0];
	assign request_user.byteenable 		= mem_byteenable_rmw_mclk[0];
	assign request_user.write_ras_sbe 	= mem_write_ras_sbe_mclk[0];
	assign request_user.write_ras_dbe 	= mem_write_ras_dbe_mclk[0];
	assign request_user.write_poison 	= mem_write_poison_rmw_mclk[0];
	assign request_user.writedata       = mem_writedata_rmw_mclk[0];


	/* For signalTap debug */
    logic [15:0] 												check_deadbeef_arr;
	(* preserve_for_debug *) logic 								check_deadbeef;
	// (* preserve_for_debug *) logic 								arbiter_out_read;
	// (* preserve_for_debug *) logic 								arbiter_out_write;
	// (* preserve_for_debug *) logic [EMIF_AMM_ADDR_WIDTH-1:0] 	arbiter_out_address;
	(* preserve_for_debug *) logic 								updater_out_read;
	(* preserve_for_debug *) logic 								updater_out_write;
	(* preserve_for_debug *) logic [EMIF_AMM_ADDR_WIDTH-1:0] 	updater_out_address;
	(* preserve_for_debug *) logic [EMIF_AMM_ADDR_WIDTH-1:0] 	user_request_address;
	(* preserve_for_debug *) logic [EMIF_AMM_ADDR_WIDTH-1:0] 	emif_address;
	(* preserve_for_debug *) logic [MC_CHANNEL-1:0]             mem_ready_debug;
	(* preserve_for_debug *) logic [MONITOR_REGION_WIDTH-1:0]	monitor_region_debug;
	(* preserve_for_debug *) logic 								is_monitor_region_debug;

	always_comb begin : for_signal_tap_debug_preserved
		
        // for (int i = 0; i < 16; i++) begin
        //     check_deadbeef_arr[i] = request_out.writedata[32*i +: 32] == 32'hDEADBEEF;
        // end
		// check_deadbeef = | check_deadbeef_arr;

		// arbiter_out_read = request_arbiter_out.read;
		// arbiter_out_write = request_arbiter_out.write;
		// arbiter_out_address = request_arbiter_out.address;

		updater_out_read = request_updater.read;
		updater_out_write = request_updater.write;
		updater_out_address = request_updater.address;

		user_request_address = mem_address_rmw_mclk[0]; // to check if the dimension will cause the signalTap to catch wrong signal
		emif_address = emif_amm_address[0];

		mem_ready_debug = eac2mc_ready; // This can be assign 1 even through they are in different dimension

		//monitor_region_debug = request_user.address[(SRAM_ADDR_WIDTH+$clog2(COUNTER_PER_ENTRY)+COUNTER_GRAN+MONITOR_REGION_WIDTH-1):(SRAM_ADDR_WIDTH+$clog2(COUNTER_PER_ENTRY)+COUNTER_GRAN)];
        monitor_region_debug = 1'b1;
	end
	

    assign request_addr_2_sram_addr = request_user.address[($clog2(COUNTER_PER_ENTRY)+COUNTER_GRAN+SRAM_ADDR_WIDTH-1):($clog2(COUNTER_PER_ENTRY)+COUNTER_GRAN)]; // 2^7 counters in a sram entry. Granularity is per cacheline.
	//assign is_monitor_region = (monitor_region_debug == csr_monitor_region) ? 1'b1 : 1'b0;
	assign is_monitor_region = 1'b1;
	assign is_monitor_region_debug = (monitor_region_debug == csr_monitor_region) ? 1'b0 : 1'b1;
	assign buf1_same_as_req = (request_user.read || request_user.write) && (addr_buf_1 == request_addr_2_sram_addr) && valid_buf_1; // Buf 1's sram address is the same as current request
	assign buf2_same_as_req = (request_user.read || request_user.write) && (addr_buf_2 == request_addr_2_sram_addr) && valid_buf_2; // Buf 2's sram address is the same as current request
	assign buf2_same_as_buf1 = valid_buf_2 && valid_buf_1 && (addr_buf_2 == addr_buf_1); // Buf 2's sram address is the same as buf 1

	always_comb begin
        ofw_detected = 1'b0;
		ofw_address = '0;
		/* counter increment combinational logic */
		for (int i = 0; i < COUNTER_PER_ENTRY; i++) begin

			if ((valid_buf_2 && i == subcounter_buf_2) && 
				(buf2_same_as_buf1 && i == subcounter_buf_1) && 
				(buf2_same_as_req && i == request_user.address[(COUNTER_GRAN+$clog2(COUNTER_PER_ENTRY)-1):COUNTER_GRAN])) begin
				
				counter_incremented[i*COUNTER_WIDTH +: COUNTER_WIDTH] = buf_q[i*COUNTER_WIDTH +: COUNTER_WIDTH] + 3;
				if (16'(buf_q[i*COUNTER_WIDTH +: COUNTER_WIDTH]) + 16'd3 >= 16'(2**COUNTER_WIDTH - 1)) begin
					counter_incremented[i*COUNTER_WIDTH +: COUNTER_WIDTH] = '0;
					ofw_detected = '1;
					ofw_address = request_user.address;			// TODO ofw_address == 32 bits, request_user.address == 27 bits
				end
			
			end else if (((valid_buf_2 && i == subcounter_buf_2) && (buf2_same_as_buf1 && i == subcounter_buf_1)) ||
						 ((valid_buf_2 && i == subcounter_buf_2) && (buf2_same_as_req && i == request_user.address[(COUNTER_GRAN+$clog2(COUNTER_PER_ENTRY)-1):COUNTER_GRAN])) ||
						 ((buf2_same_as_buf1 && i == subcounter_buf_1) && (buf2_same_as_req && i == request_user.address[(COUNTER_GRAN+$clog2(COUNTER_PER_ENTRY)-1):COUNTER_GRAN]))) begin
				// The third condition means that buf_1 and request are aiming at the currect subcounter, while buf_2 is not (otherwise falls in +3 case).
				
				counter_incremented[i*COUNTER_WIDTH +: COUNTER_WIDTH] = buf_q[i*COUNTER_WIDTH +: COUNTER_WIDTH] + 2;
				if (16'(buf_q[i*COUNTER_WIDTH +: COUNTER_WIDTH]) + 16'd2 >= 16'(2**COUNTER_WIDTH - 1)) begin
					counter_incremented[i*COUNTER_WIDTH +: COUNTER_WIDTH] = '0;
					ofw_detected = '1;
					ofw_address = request_user.address;
				end

			end else if ((valid_buf_2 && i == subcounter_buf_2) ||
			 			 (buf2_same_as_buf1 && i == subcounter_buf_1) ||
						 (buf2_same_as_req && i == request_user.address[(COUNTER_GRAN+$clog2(COUNTER_PER_ENTRY)-1):COUNTER_GRAN])) begin

				counter_incremented[i*COUNTER_WIDTH +: COUNTER_WIDTH] = buf_q[i*COUNTER_WIDTH +: COUNTER_WIDTH] + 1;
				if (16'(buf_q[i*COUNTER_WIDTH +: COUNTER_WIDTH]) + 16'd1 >= 16'(2**COUNTER_WIDTH - 1)) begin
					counter_incremented[i*COUNTER_WIDTH +: COUNTER_WIDTH] = '0;
					ofw_detected = '1;
					ofw_address = request_user.address;	
				end

			end else begin

				counter_incremented[i*COUNTER_WIDTH +: COUNTER_WIDTH] = buf_q[i*COUNTER_WIDTH +: COUNTER_WIDTH];

			end
		end


		/* rquest_out is always connected to request_user */
		request_out = request_user;


		/* buffer ports mux */
		if (buf_port_sel == USER_B) begin
			buf_rdaddress 	= request_addr_2_sram_addr;
			buf_wraddress 	= addr_buf_2;
			buf_wren 		= valid_buf_2; // Try to get rid of wren buffers (since they are identical to valid buffers)
			buf_data 		= counter_incremented;
		end else if (buf_port_sel == UPDATER_B) begin
			buf_rdaddress 	= updater2buf_rdaddress;
			buf_wraddress 	= updater2buf_wraddress;
			buf_wren 		= updater2buf_wren;
			buf_data 		= updater2buf_data;
		end else begin
			buf_rdaddress 	= '0;
			buf_wraddress 	= '0;
			buf_wren 		= 1'b0;
			buf_data 		= '0;
		end

	end

	fifo_pac_overflow fifo_pac_overflow (
		.data    (ofw_q_wrdata),    //   input,  width = 512,  fifo_input.datain
		.wrreq   (ofw_q_wrreq),   //   input,    width = 1,            .wrreq
		.rdreq   (ofw_q_rdreq),   //   input,    width = 1,            .rdreq
		.wrclk   (mclk),   //   input,    width = 1,            .wrclk
		.rdclk   (axi4_mm_clk),   //   input,    width = 1,            .rdclk
		.aclr    (~reset_n),    //   input,    width = 1,            .aclr
		.q       (ofw_q_rddata),       //  output,  width = 512, fifo_output.dataout
		.rdempty (ofw_q_empty), //  output,    width = 1,            .rdempty		
		.wrfull  (ofw_q_full)   //  output,    width = 1,            .wrfull
	);

	always_ff @( posedge mclk ) begin
		if (~reset_n) begin
			ofw_q_wrdata <= '0;
			ofw_q_wrdata_ptr <= '0;
			ofw_q_wrdata_valid <= '0;
		end else begin
			if (ofw_q_wrreq & ~ofw_q_full) begin
				ofw_q_wrdata_valid <= '0;
			end
			if (ofw_detected & (~ofw_q_wrreq | (ofw_q_wrreq & ~ofw_q_full))) begin		// We lose ofw detections if: ofw queue is full (want to avoid losing if it's not) 
				ofw_q_wrdata[ofw_q_wrdata_ptr*32 +: 32] <= ofw_address;
				ofw_q_wrdata_ptr <= ofw_q_wrdata_ptr + 1'b1;
				ofw_q_wrdata_valid <= '1;
			end
		end
	end

	always_comb begin
		ofw_q_wrreq = ofw_q_wrdata_valid & (ofw_q_wrdata_ptr == '0);
	end

	/* Counter Increment Logic */
	always_ff @ (posedge mclk) begin
		if (~reset_n) begin
			addr_buf_1 <= '0;
			addr_buf_2 <= '0;
			valid_buf_1 <= 1'b0;
			valid_buf_2 <= 1'b0;
			wren_buf_1 <= 1'b0;
			wren_buf_2 <= 1'b0;
			subcounter_buf_1 <= '0;
			subcounter_buf_2 <= '0;
		end else begin

			is_monitor_region_reg <= is_monitor_region;
			
			/* Valid logic */
			if ((request_user.read || request_user.write) && ~buf2_same_as_req) begin 	// if consumed by buf2, invalidate the current request
				valid_buf_1 <= 1'b1;																		// if addr is the same as buf1, we do not consume the request
			end else begin
				valid_buf_1 <= 1'b0;
			end

			if (buf2_same_as_buf1 || ~is_monitor_region_reg) begin // if buf1 is consumed by buf2, invalidate buf1
				valid_buf_2 <= 1'b0;
			end else begin
				valid_buf_2 <= valid_buf_1;
			end

			addr_buf_1 <= request_addr_2_sram_addr;
			addr_buf_2 <= addr_buf_1;

			subcounter_buf_1 <= request_user.address[(COUNTER_GRAN+$clog2(COUNTER_PER_ENTRY)-1):COUNTER_GRAN];
			subcounter_buf_2 <= subcounter_buf_1;
		end
	end



	/* Wiring of request signals */

	for( genvar chanCount = 0; chanCount < MC_CHANNEL; chanCount=chanCount+1 ) /* assume only 1 channel */
	begin : GEN_CHAN_COUNT_pac_TOP_0

		always_comb 
		begin
			// == to emif ==
			emif_amm_read[ chanCount ]       = request_out.read;
			emif_amm_write[ chanCount ]      = request_out.write;
			emif_amm_address[ chanCount ]    = request_out.address;
			emif_amm_byteenable[ chanCount ] = '1;

			emif_amm_writedata[ chanCount ][MC_HA_DP_DATA_WIDTH-1:0]                     = request_out.writedata;
			emif_amm_writedata[ chanCount ][MC_HA_DP_DATA_WIDTH]                         = request_out.write_poison;
			emif_amm_writedata[ chanCount ][EMIF_AMM_DATA_WIDTH-1:MC_HA_DP_DATA_WIDTH+1] = '0;

			// == from emif ==
			//mem_ready_rmw_mclk[chanCount]              = emif_amm_ready[chanCount] ;

			// ==== releaded to read response ====
			mem_readdata_rmw_mclk[ chanCount ]       = emif_amm_readdata[ chanCount ][MC_HA_DP_DATA_WIDTH-1:0];
			mem_read_poison_rmw_mclk[ chanCount ]    = emif_amm_readdata[ chanCount ][MC_HA_DP_DATA_WIDTH];
			mem_readdatavalid_rmw_mclk[ chanCount ]  = emif_amm_readdatavalid[ chanCount ] ;

            emif_amm_burstcount[ chanCount ] = {{EMIF_AMM_BURST_WIDTH-1{1'b0}},1'b1};
		end
	end

	/* Wiring of ECC-related signals */

	for( genvar chanCount = 0; chanCount < MC_CHANNEL; chanCount=chanCount+1 ) /* Set chanCount to 1 for fast prototyping */
	begin : GEN_CHAN_COUNT_pac_TOP
		always_comb begin
			mem_ecc_err_corrected_rmw_mclk[ chanCount ] = '0;
			mem_ecc_err_detected_rmw_mclk[ chanCount ]  = '0;
			mem_ecc_err_fatal_rmw_mclk[ chanCount ]     = '0;
			mem_ecc_err_syn_e_rmw_mclk[ chanCount ]     = '0;
		end
	end


endmodule
