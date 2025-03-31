import ctrl_signal_types::*;
import cxlip_top_pkg::*;

module csr_updater #(
    CSR_REGFILE_SIZE = 16,
    CSR_ADDRESS_WIDTH = $clog2(CSR_REGFILE_SIZE) + 1 // make sure that address doesn't overflow
)(

    input logic afu_clk,
    input logic afu_rstn,

    output logic                            csr_update,
    output logic [63:0]                     csr_update_data,
    output logic [CSR_ADDRESS_WIDTH-1:0]    csr_update_addr,

    input  logic [cxlip_top_pkg::MC_CHANNEL-1:0]             mc2iafu_ready_eclk,
    input  logic [cxlip_top_pkg::MC_CHANNEL-1:0]             mc2iafu_read_poison_eclk,
    input  logic [cxlip_top_pkg::MC_CHANNEL-1:0]             mc2iafu_readdatavalid_eclk,

    // Error Correction Code (ECC)
    // Note *ecc_err_* are valid when mc2iafu_readdatavalid_eclk is active
    input  logic [cxlip_top_pkg::ALTECC_INST_NUMBER-1:0]     mc2iafu_ecc_err_corrected_eclk  [cxlip_top_pkg::MC_CHANNEL-1:0],
    input  logic [cxlip_top_pkg::ALTECC_INST_NUMBER-1:0]     mc2iafu_ecc_err_detected_eclk   [cxlip_top_pkg::MC_CHANNEL-1:0],
    input  logic [cxlip_top_pkg::ALTECC_INST_NUMBER-1:0]     mc2iafu_ecc_err_fatal_eclk      [cxlip_top_pkg::MC_CHANNEL-1:0],
    input  logic [cxlip_top_pkg::ALTECC_INST_NUMBER-1:0]     mc2iafu_ecc_err_syn_e_eclk      [cxlip_top_pkg::MC_CHANNEL-1:0],
    input  logic [cxlip_top_pkg::MC_CHANNEL-1:0]             mc2iafu_ecc_err_valid_eclk,
    input  logic [cxlip_top_pkg::MC_CHANNEL-1:0]             mc2iafu_cxlmem_ready,
    input  logic [cxlip_top_pkg::MC_HA_DP_DATA_WIDTH-1:0]    mc2iafu_readdata_eclk           [cxlip_top_pkg::MC_CHANNEL-1:0],
    input  logic [cxlip_top_pkg::MC_MDATA_WIDTH-1:0]         mc2iafu_rsp_mdata_eclk          [cxlip_top_pkg::MC_CHANNEL-1:0],

    input logic [cxlip_top_pkg::MC_HA_DP_DATA_WIDTH-1:0]      cxlip2iafu_writedata_eclk          [cxlip_top_pkg::MC_CHANNEL-1:0],
    input logic [cxlip_top_pkg::MC_HA_DP_BE_WIDTH-1:0]        cxlip2iafu_byteenable_eclk         [cxlip_top_pkg::MC_CHANNEL-1:0],
    input logic [cxlip_top_pkg::MC_CHANNEL-1:0]               cxlip2iafu_read_eclk,
    input logic [cxlip_top_pkg::MC_CHANNEL-1:0]               cxlip2iafu_write_eclk,
    input logic [cxlip_top_pkg::MC_CHANNEL-1:0]               cxlip2iafu_write_poison_eclk,
    input logic [cxlip_top_pkg::MC_CHANNEL-1:0]               cxlip2iafu_write_ras_sbe_eclk,    
    input logic [cxlip_top_pkg::MC_CHANNEL-1:0]               cxlip2iafu_write_ras_dbe_eclk,    
    input logic [51:0]                                        cxlip2iafu_address_eclk,  // FIXME: this need to be change for more than 2 channels
    input logic [cxlip_top_pkg::MC_MDATA_WIDTH-1:0]           cxlip2iafu_req_mdata_eclk          [cxlip_top_pkg::MC_CHANNEL-1:0],


    input logic csr_avmm_read,
    input logic csr_avmm_write,
    input  logic [21:0] csr_avmm_address
); 
    /* Yan: taken from cop, afu_top.sv*/
    /* Douglas: Added counters here */
    logic [63:0] csr_data [CSR_REGFILE_SIZE];

    /* flags for detecting rising edge */
    logic read_flag;
    logic write_flag;
    logic [63:0] update_counter; /* this register controls the interval between CSR regfile updates */

    /* counter definitions */
    /* ============================================================= */
    /*              Update ONLY counters (Host Read only)            */
    /* ============================================================= */
    // csr_avmm_read
    // csr_data[0] : read counter       -- increment when reading CSR 
    //
    // csr_avmm_write
    // csr_data[1] : write counter      -- increment when writing CSR 
    //
    // csr_avmm_address
    // csr_data[2] : debug register     -- indicate the last read/write address received.
    //
    // csr_data[3] : debug register     -- increment every 10000 afu_clk cycle
    //
    // cxlip2iafu_read_eclk
    // csr_data[4] : memory read counter [63:0]  -- increment when there is a read request from cxlip to memory
    //
    // cxlip2iafu_write_eclk 
    // csr_data[5] : memory write counter[63:0]  -- increment when there is a write request from cxlip to memory
    //
    //
    // csr_data[6] : memory rmw counter[63:0]  -- increment when the write is asserted and the byteenable is not all '1 
    //
    // csr_data[7]: debug register     -- count the memory write assuming each read signal will last for more than 1 cycle (have to wait until the signal is deasserted)
    // Reset: write 0xace0beef to address 0x0
    //
    // csr_data[8]: debug register     -- Record the read address of the last request
    //
    // csr_data[16]: zero out command    -- write any non-zero value to send the zero out command
    //
    // csr_data[17]: write back command  -- write any non-zero value to send the write back command
    //
    // csr_data[18]: write back address     -- set up by the host. The counter values will be written back to this address.
    

    /* ============================================================= */
    /*    counter_increment_logic and other csr_data update logic    */
    /* ============================================================= */

    
    enum bit [2:0] { IDLE_2, WRITING }           write_counter_state [cxlip_top_pkg::MC_CHANNEL];
    logic [63:0] write_re_counter     [cxlip_top_pkg::MC_CHANNEL]; // 2 for two memory channels
    logic [63:0] memRead_counter;
    logic [63:0] memWrite_counter;
    logic [63:0] memRMW_counter;


    // =====================================================
    //                    registers 
    // =====================================================

    task set_reg_0();
            // if (csr_avmm_read) csr_data[0] <= csr_data[0] + 1; // FIXED: read signal may be raised for multiple cycles intrinsically -- see Avalon Doc Page 21
        if (read_flag == 1'b0 && csr_avmm_read == 1'b1) begin
            read_flag   <= 1'b1;
            csr_data[0] <= csr_data[0] + 1;
        end else if (read_flag == 1'b1 && csr_avmm_read == 1'b0) begin
            read_flag   <= 1'b0;
        end
    endtask 

    task set_reg_1();
        if (write_flag == 1'b0 && csr_avmm_write == 1'b1) begin
            write_flag  <= 1'b1; // FIXED: was read_flag
            csr_data[1] <= csr_data[1] + 1;
        end else if (write_flag == 1'b1 && csr_avmm_write == 1'b0) begin
            write_flag  <= 1'b0;
        end
    endtask

    task set_reg_2();
        if (csr_avmm_write | csr_avmm_read) begin
            csr_data[2] <= csr_avmm_address;
        end
    endtask

    task set_reg_3();
        if (update_counter >= 10000) begin
            csr_data[3] <= csr_data[3] + 1;
        end
    endtask

    task set_reg_4();
        if (cxlip2iafu_read_eclk != 0) begin
            if (cxlip2iafu_read_eclk == 2'b11) begin
                memRead_counter <= memRead_counter + 2;
            end else begin
                memRead_counter <= memRead_counter + 1;
            end
        end
        csr_data[4] <= memRead_counter;
    endtask

    task set_reg_5();
        if (cxlip2iafu_write_eclk != 0) begin
            if (cxlip2iafu_write_eclk == 2'b11) begin
                memWrite_counter <= memWrite_counter + 2; // FIXED : index was 5
            end else begin
                memWrite_counter <= memWrite_counter + 1;
            end
        end 
        csr_data[5] <= memWrite_counter;
    endtask


    task set_reg_6();
        // counter for rising edge of write signal
        for (int i = 0; i < cxlip_top_pkg::MC_CHANNEL; i++) begin
            if (~afu_rstn) begin
                write_counter_state[i] <= IDLE_2;
            end else begin
                case (write_counter_state[i])
                    IDLE_2: begin
                        if (cxlip2iafu_write_eclk[i]) begin
                            write_re_counter[i] <= write_re_counter[i] + 1;
                            write_counter_state[i]   <= WRITING;
                        end
                    end

                    WRITING: begin
                        if (~cxlip2iafu_write_eclk[i]) begin
                            write_counter_state[i]   <= IDLE_2;
                        end
                    end
                    default: ;
                endcase
            end
        end
        csr_data[6] <= write_re_counter[0];
    endtask

    task set_reg_7();
        for (int i = 0; i < cxlip_top_pkg::MC_CHANNEL; i++) begin
            if (cxlip2iafu_write_eclk[i] && cxlip2iafu_byteenable_eclk[i] != '1) begin
                memRMW_counter <= memRMW_counter + 1; 
            end
        end
        csr_data[7] <= memRMW_counter;
    endtask

    task set_reg_8();
        if (cxlip2iafu_read_eclk) begin
            csr_data[8] <= cxlip2iafu_address_eclk;
        end
    endtask


    always_ff @( posedge afu_clk ) begin  // FIXED: wrong clock domain (fixed but changed back because we use afu_clk for the real purpose)

        if (!afu_rstn) begin
            for (int i = 0; i < CSR_REGFILE_SIZE; i++) begin
                csr_data[i] <= '0;
            end
            read_flag               <= 1'b0;
            write_flag              <= 1'b0;
            write_re_counter        <= '{default:'b0};
            memRead_counter         <= '0;
            memWrite_counter        <= '0;
            memRMW_counter          <= '0;

        end else begin
            
            /* csr read and write counters */
            set_reg_0();

            set_reg_1();
            
            /* debug registers */
            set_reg_2();

            set_reg_3();

            /* memory read/write counters */

            set_reg_4();

            set_reg_5();

            set_reg_6();

            set_reg_7();

            set_reg_8();
        end
    end


    // ==================================================
    /* regfile update logic */
    // ==================================================

    logic [CSR_ADDRESS_WIDTH-1:0] regfile_idx; /* used for looping through regfile */
    enum bit [3:0] {IDLE, UPDATE} state;

    always_ff @( posedge afu_clk ) begin : update_regfile_logic

        if (!afu_rstn) begin
            state           <= IDLE;
            update_counter  <= '0;
            regfile_idx     <= '0;
            csr_update      <= 1'b0;
            csr_update_addr <= '0;
            csr_update_data <= '0;
        end else begin
            update_counter  <= update_counter + 1;
            case (state)
                IDLE: begin
                    if (update_counter >= 10000) begin  /* update the regfile every 10000 cycles */
                        state           <= UPDATE;
                        csr_update      <= 1'b1;
                        csr_update_addr <= '0;
                        csr_update_data <= csr_data[0];
                        regfile_idx     <= 1;
                    end
                end

                UPDATE: begin
                    if (regfile_idx >= CSR_REGFILE_SIZE) begin
                        state           <= IDLE;
                        regfile_idx     <= '0;
                        csr_update      <= 1'b0;
                        update_counter  <= '0;
                    end else begin
                        csr_update      <= 1'b1;
                        csr_update_addr <= regfile_idx;
                        csr_update_data <= csr_data[regfile_idx];
                        regfile_idx     <= regfile_idx + 1;
                    end
                end

                default: ;
            endcase
        end
    end
endmodule

/*
custom_csr_top #(CSR_REGFILE_SIZE, CSR_ADDRESS_WIDTH) custom_csr_top_inst (
    .clk          (csr_avmm_clk),
    .afu_clk      (afu_clk),
    .reset_n      (csr_avmm_rstn),
    .writedata    (csr_avmm_writedata),
    .read         (csr_avmm_read),
    .write        (csr_avmm_write),
    .byteenable   (csr_avmm_byteenable),
    .readdata     (csr_avmm_readdata),
    .readdatavalid(csr_avmm_readdatavalid),
    .address      (csr_avmm_address),
    .waitrequest  (csr_avmm_waitrequest),
    .update       (csr_update),
    .update_data  (csr_update_data),
    .update_address(csr_update_addr),
); 

*/
