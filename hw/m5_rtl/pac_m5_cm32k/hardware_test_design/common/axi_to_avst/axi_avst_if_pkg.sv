// (C) 2001-2023 Intel Corporation. All rights reserved.
// Your use of Intel Corporation's design tools, logic functions and other 
// software and tools, and its AMPP partner logic functions, and any output 
// files from any of the foregoing (including device programming or simulation 
// files), and any associated documentation or information are expressly subject 
// to the terms and conditions of the Intel Program License Subscription 
// Agreement, Intel FPGA IP License Agreement, or other applicable 
// license agreement, including, without limitation, that your use is for the 
// sole purpose of programming logic devices manufactured by Intel and sold by 
// Intel or its authorized distributors.  Please refer to the applicable 
// agreement for further details.


//------------------------------------------------------------
// Copyright 2023 Intel Corporation.
//
// THIS SOFTWARE MAY CONTAIN PREPRODUCTION CODE AND IS PROVIDED BY THE
// COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED
// WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
// MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
// BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
// WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
// OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
// EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
//------------------------------------------------------------

package axi_avst_if_pkg;
    //pulled from verif/unit/amba_axi4/include/sverilog/svt_axi_port_defines.svi
    localparam AFU_AXI_BURST_WIDTH            = 2;
    localparam AFU_AXI_CACHE_WIDTH            = 4;
    localparam AFU_AXI_LOCK_WIDTH             = 2;
    localparam AFU_AXI_MAX_ADDR_USER_WIDTH    = 5;
    localparam AFU_AXI_MAX_ADDR_WIDTH         = 64;
    localparam AFU_AXI_MAX_BRESP_USER_WIDTH   = 4;
    localparam AFU_AXI_MAX_BURST_LENGTH_WIDTH = 10;
    localparam AFU_AXI_MAX_DATA_USER_WIDTH    = 4;
    localparam AFU_AXI_MAX_DATA_WIDTH         = 512;
    localparam AFU_AXI_MAX_ID_WIDTH           = 12;
    localparam AFU_AXI_PROT_WIDTH             = 3;
    localparam AFU_AXI_QOS_WIDTH              = 4;
    localparam AFU_AXI_REGION_WIDTH           = 4;
    localparam AFU_AXI_RESP_WIDTH             = 2;
    localparam AFU_AXI_SIZE_WIDTH             = 3;
    localparam AFU_AXI_BUSER_WIDTH            = 4;
    
//------------------------------------------------------------------------ 
//  AMBA AXI and ACE Protocol Specitifcation, Issue 4, 2013
//  page 73, A4.7, Access Permissions
//  Table A4-6 Protection Encoding    
//------------------------------------------------------------------------   
    typedef enum logic [AFU_AXI_PROT_WIDTH-1:0] {
        eprot_UNPRIV_SECURE_DATA        = 3'b000,
        eprot_UNPRIV_SECURE_INST        = 3'b001,
        eprot_UNPRIV_NONSEC_DATA        = 3'b010,
        eprot_UNPRIV_NONSEC_INST        = 3'b011,
        eprot_PRIV_SECURE_DATA          = 3'b100,
        eprot_PRIV_SECURE_INST          = 3'b101,
        eprot_PRIV_NONSEC_DATA          = 3'b110,
        eprot_PRIV_NONSEC_INST          = 3'b111
    } t_axi4_prot_encoding;
    
//------------------------------------------------------------------------ 
//  AMBA AXI and ACE Protocol Specitifcation, Issue 4, 2013
//  page 48, A3.4.1, Access Permissions
//  Table A3-3 Burst type encoding    
//------------------------------------------------------------------------ 
    typedef enum logic [AFU_AXI_BURST_WIDTH-1:0] {
        eburst_FIXED     = 2'b00,
        eburst_INCR      = 2'b01,
        eburst_WRAP      = 2'b10,
        eburst_RSVD      = 2'b11
    } t_axi4_burst_encoding;

//------------------------------------------------------------------------ 
//  AMBA AXI and ACE Protocol Specitifcation, Issue 4, 2013
//  page 47, A3.4.1, Access Permissions
//  Table A3-2 Burst size encoding    
//------------------------------------------------------------------------ 
    typedef enum logic [AFU_AXI_SIZE_WIDTH-1:0] {
        //e_BURST_SIZE_1          = 3'b000,
        //e_BURST_SIZE_2          = 3'b001,
        //e_BURST_SIZE_4          = 3'b010,
        //e_BURST_SIZE_8          = 3'b011,
        //e_BURST_SIZE_16         = 3'b100,
        //e_BURST_SIZE_32         = 3'b101,
        //e_BURST_SIZE_64         = 3'b110,
        //e_BURST_SIZE_128        = 3'b111
        
        esize_128          = 3'b100,
        esize_256          = 3'b101,
        esize_512          = 3'b110,
        esize_1024         = 3'b111
    } t_axi4_burst_size_encoding;

//------------------------------------------------------------------------ 
//  AXI AFU HAS, page 32
//------------------------------------------------------------------------ 
    typedef enum logic [AFU_AXI_QOS_WIDTH-1:0] {
        eqos_BEST_EFFORT           = 4'h0,
        eqos_USER_LOW              = 4'h4,
        eqos_USER_HIGH             = 4'h8,
        eqos_LOW_LATENCY           = 4'hC
    } t_axi4_qos_encoding;

//------------------------------------------------------------------------ 
//  AMBA AXI and ACE Protocol Specitifcation, Issue 4, 2013
//  page 67
//  Table A4-5 MEMORY TYPE ENCODING
//------------------------------------------------------------------------ 
    typedef enum logic [AFU_AXI_CACHE_WIDTH-1:0] {
        ecache_ar_DEVICE_NON_BUFFERABLE                 = 4'b0000,
        ecache_ar_DEVICE_BUFFERABLE                     = 4'b0001,
        ecache_ar_NORMAL_NON_CACHEABLE_NON_BUFFERABLE   = 4'b0010,
        ecache_ar_NORMAL_NON_CACHEABLE_BUFFERABLE       = 4'b0011,
        ecache_ar_WRITE_THROUGH_NO_ALLOCATE             = 4'b1010,
        ecache_ar_WRITE_BACK_NO_ALLOCATE                = 4'b1011,
        ecache_ar_WRITE_THROUGH_READ_ALLOCATE           = 4'b1110,
        ecache_ar_WRITE_BACK_READ_ALLOCATE              = 4'b1111
    } t_axi4_arcache_encoding;
    
//------------------------------------------------------------------------ 
//  AMBA AXI and ACE Protocol Specitifcation, Issue 4, 2013
//  page 67
//  Table A4-5 MEMORY TYPE ENCODING
//------------------------------------------------------------------------ 
    typedef enum logic [AFU_AXI_CACHE_WIDTH-1:0] {
        ecache_aw_DEVICE_NON_BUFFERABLE                 = 4'b0000,
        ecache_aw_DEVICE_BUFFERABLE                     = 4'b0001,
        ecache_aw_NORMAL_NON_CACHEABLE_NON_BUFFERABLE   = 4'b0010,
        ecache_aw_NORMAL_NON_CACHEABLE_BUFFERABLE       = 4'b0011,
        ecache_aw_WRITE_THROUGH_NO_ALLOCATE             = 4'b0110,
        ecache_aw_WRITE_BACK_NO_ALLOCATE                = 4'b0111,
        ecache_aw_WRITE_THROUGH_WRITE_ALLOCATE          = 4'b1110,
        ecache_aw_WRITE_BACK_WRITE_ALLOCATE             = 4'b1111
    } t_axi4_awcache_encoding;

//------------------------------------------------------------------------ 
//  AMBA AXI and ACE Protocol Specitifcation, Issue 4, 2013
//  page 100, A7.4
//  Table A7-1 AXI3 atomic access encoding    
//------------------------------------------------------------------------ 
    typedef enum logic [AFU_AXI_LOCK_WIDTH-1:0] {
        elock_NORMAL            = 2'b00,
        elock_EXECLUSIVE        = 2'b01,
        elock_LOCKED            = 2'b10,
        elock_RSVD              = 2'b11
    } t_axi4_lock_encoding;

//------------------------------------------------------------------------ 
//  AMBA AXI and ACE Protocol Specitifcation, Issue 4, 2013
//  page 57, A3.4.4
//  Table A3-4 RRESP and BRESP encoding   
//------------------------------------------------------------------------ 
    typedef enum logic [AFU_AXI_RESP_WIDTH-1:0] {
        eresp_OKAY              = 2'b00,
        eresp_EXOKAY            = 2'b01,
        eresp_SLVERR            = 2'b10,
        eresp_DECERR            = 2'b11
    } t_axi4_resp_encoding;


    typedef enum logic [3:0] {
       eWR_I_WO              = 4'h0,  // WRLINEI or WRPARTI (weadly ordered version)
       eWR_M                 = 4'h1,  // WRLINEEM or WRPARTM
       eWR_I_SO              = 4'h2,  // WRPUSHI or WRINV (strongly ordered version)
       eWR_BARRIER           = 4'h3,
       eWR_EVICT             = 4'h4,
       eWR_FLUSHHOSTCACHE    = 4'h5,
       eWR_FLUSHDEVCACHE     = 4'h6
    } t_axi4_awuser_opcode;

    typedef struct packed {
      logic                  do_not_send_d2hreq;
      t_axi4_awuser_opcode   opcode;
    } t_axi4_awuser;

    localparam AFU_AXI_AWUSER_WIDTH = $bits(t_axi4_awuser);

//------------------------------------------------------------------------
// Opcode mapping on WUSER
//------------------------------------------------------------------------
    typedef struct packed {
      logic        poison;
    } t_axi4_wuser;

    localparam AFU_AXI_WUSER_WIDTH = $bits(t_axi4_wuser);


    typedef enum logic [3:0] {
       eRD_I     = 4'h0,  // RDLINEI_RDCURR
       eRD_S     = 4'h1,  // RDLINES_RDSHARED
       eRD_EM    = 4'h2   // RDLINEEM_RDOWN
    } t_axi4_aruser_opcode;

    typedef struct packed {
      logic                  do_not_send_d2hreq;
      t_axi4_aruser_opcode   opcode;
    } t_axi4_aruser;

    localparam AFU_AXI_ARUSER_WIDTH = $bits(t_axi4_aruser);

//------------------------------------------------------------------------
// Opcode mapping on RUSER
//------------------------------------------------------------------------
    typedef struct packed {
      logic        poison;
    } t_axi4_ruser;

    localparam AFU_AXI_RUSER_WIDTH = $bits(t_axi4_ruser);

//------------------------------------------------------------------------
// Opcode mapping on user bits
// Section 2.4 of AFU AXI IF HAS r0.1.a
// enumerations are formed from 4 inputs: 1) AXI opcode, 2) Cache Hint, 3) CCIP Opcode, 4) CXL Opcode
// AXI_CacheHint_CCIP_CXL
//------------------------------------------------------------------------
/*    typedef enum logic [AFU_AXI_MAX_ADDR_USER_WIDTH-1:0] {
        eRD_N_RDLINEI_RDCURR    = 4'h0,
        eRD_S_RDLINES_RDSHARED  = 4'h1,
        eRD_EM_RDLINEEM_RDOWN   = 4'h2
    } t_axi4_aruser_opcode;

    typedef enum logic [AFU_AXI_MAX_ADDR_USER_WIDTH-1:0] {
        eWR_N_WRLINEI_WOWRINV       = 4'h3,
        eWR_N_WRPARTI_WOWRINV       = 4'h4,
        eWR_M_WRLINEM_RDOWNNODATA   = 4'h5,
        eWR_M_WRPARTM_RDOWN         = 4'h6,
        eWR_I_WRPUSHI_ITOMWR        = 4'h7,
        eWR_B_WRFENCE_NONE          = 4'h8, //B for Barrier
        eWR_F_EVICT_EVICT           = 4'h9  //F for Flush
    } t_axi4_awuser_opcode;

    typedef enum logic [AFU_AXI_MAX_ADDR_USER_WIDTH-1:0] {
        eOK_N_RDLINE_NONE   = 4'hA,
        eOK_N_RDND_NONE     = 4'hB
    } t_axi4_ruser_opcode;

    typedef enum logic [AFU_AXI_MAX_ADDR_USER_WIDTH-1:0] {
        eOK_N_WRLINE_NONE    = 4'hC,
        eOK_N_WRFENCE_NONE   = 4'hD
    } t_axi4_buser_opcode;
*/
//------------------------------------------------------------------------
// AXI input & output buses.
// AXI3 + AXI4, no ACE IO
//------------------------------------------------------------------------
    typedef logic t_axi4_wr_addr_ready;
    
    typedef struct packed {
        logic [AFU_AXI_MAX_ID_WIDTH-1:0]            awid;
        logic [AFU_AXI_MAX_ADDR_WIDTH-1:0]          awaddr; 
        logic [AFU_AXI_MAX_BURST_LENGTH_WIDTH-1:0]  awlen;
        t_axi4_burst_size_encoding                  awsize;
        t_axi4_burst_encoding                       awburst;
        t_axi4_prot_encoding                        awprot;
        t_axi4_qos_encoding                         awqos;
        logic                                       awvalid;
        t_axi4_awcache_encoding                     awcache;
        t_axi4_lock_encoding                        awlock;
        logic [AFU_AXI_REGION_WIDTH-1:0]            awregion;

       // t_axi4_awuser_opcode                        awuser;
        t_axi4_awuser                               awuser;

        //logic [AFU_AXI_SIZE_WIDTH-1:0]                awsize;
        //logic [AFU_AXI_BURST_WIDTH-1:0]               awburst;
        //logic [AFU_AXI_PROT_WIDTH-1:0]                awprot;
        //logic                                         awready;
        // AXI4 Extension
        //logic [AFU_AXI_MAX_ADDR_USER_WIDTH-1:0]       awuser;
        //logic [AFU_AXI_QOS_WIDTH-1:0]                 awqos;
        //logic [AFU_AXI_CACHE_WIDTH-1:0]               awcache;
        //logic [AFU_AXI_LOCK_WIDTH-1:0]                awlock;
    } t_axi4_wr_addr_ch;

    typedef logic t_axi4_wr_data_ready;
    
    typedef struct packed {
        logic [AFU_AXI_MAX_DATA_WIDTH-1:0]              wdata;
        logic [AFU_AXI_MAX_DATA_WIDTH/8-1:0]            wstrb;
        logic                                           wlast;
        logic                                           wvalid;

        //t_axi4_awuser_opcode                            wuser;
        t_axi4_wuser             		 	wuser;

        //logic [AFU_AXI_MAX_ID_WIDTH-1:0]                wid;        
        //logic                                             wready;
        //logic [AFU_AXI_MAX_DATA_USER_WIDTH-1:0]           wuser;  
    } t_axi4_wr_data_ch;

    typedef logic t_axi4_wr_resp_ready;
    
    typedef struct packed {
        logic [AFU_AXI_MAX_ID_WIDTH-1:0]                bid;
        t_axi4_resp_encoding                            bresp;
        logic                                           bvalid;

        //t_axi4_buser_opcode                             buser;
        logic [AFU_AXI_BUSER_WIDTH-1:0] 	       	buser;

        //logic                                             bready;
        //AXi$ Extension
        //logic [AFU_AXI_MAX_BRESP_USER_WIDTH-1:0]          buser;
        //logic [AFU_AXI_RESP_WIDTH-1:0]                    bresp;
    } t_axi4_wr_resp_ch;

    typedef logic t_axi4_rd_addr_ready;
    
    typedef struct packed {
        logic [AFU_AXI_MAX_ID_WIDTH-1:0]            arid;
        logic [AFU_AXI_MAX_ADDR_WIDTH-1:0]          araddr;
        logic [AFU_AXI_MAX_BURST_LENGTH_WIDTH-1:0]  arlen;
        t_axi4_burst_size_encoding                  arsize;
        t_axi4_burst_encoding                       arburst;
        t_axi4_prot_encoding                        arprot;
        t_axi4_qos_encoding                         arqos;
        logic                                       arvalid;
        t_axi4_arcache_encoding                     arcache;
        t_axi4_lock_encoding                        arlock;
        logic [AFU_AXI_REGION_WIDTH-1:0]            arregion;

        //t_axi4_aruser_opcode                        aruser;
        t_axi4_aruser                               aruser;
        
        //logic [AFU_AXI_SIZE_WIDTH-1:0]                arsize;
        //logic [AFU_AXI_BURST_WIDTH-1:0]               arburst;
        //logic [AFU_AXI_PROT_WIDTH-1:0]                arprot;
        //logic                                         arready;
        // AXI4 Extension
        //logic [AFU_AXI_MAX_ADDR_USER_WIDTH-1:0]       aruser;
        //logic [AFU_AXI_QOS_WIDTH-1:0]                 arqos;
        //logic [AFU_AXI_CACHE_WIDTH-1:0]               arcache;
        //logic [AFU_AXI_LOCK_WIDTH-1:0]                arlock;
    } t_axi4_rd_addr_ch;

    typedef logic t_axi4_rd_resp_ready;
    
    typedef struct packed {
        logic [AFU_AXI_MAX_ID_WIDTH-1:0]        rid;
        logic [AFU_AXI_MAX_DATA_WIDTH-1:0]      rdata;
        t_axi4_resp_encoding                    rresp;
        logic                                   rlast;
        logic                                   rvalid;

        //t_axi4_ruser_opcode                     ruser;
        t_axi4_ruser                            ruser;

        //logic                                     rready;
        // AXI4 Extension
        //t_axi4_ruser_opcode                       ruser;
        //logic [AFU_AXI_RESP_WIDTH-1:0]            rresp;
    } t_axi4_rd_resp_ch;
    
    localparam AFU_AXI_WR_ADDR_CH_WIDTH = $bits(t_axi4_wr_addr_ch);
    localparam AFU_AXI_WR_DATA_CH_WIDTH = $bits(t_axi4_wr_data_ch);
    localparam AFU_AXI_WR_RESP_CH_WIDTH = $bits(t_axi4_wr_resp_ch);
    localparam AFU_AXI_RD_ADDR_CH_WIDTH = $bits(t_axi4_rd_addr_ch);
    localparam AFU_AXI_RD_RESP_CH_WIDTH = $bits(t_axi4_rd_resp_ch);
    
    

endpackage
