import ctrl_signal_types::*;

module counter_ctrl (
    input logic clk,
    input logic reset_n,

    /* from datapath */
    input logic                     mem_updater_done,
    input logic [MC_CHANNEL-1:0]    emif_amm_ready,

    /* to datapath */
    output logic                    mem_updater_start,
    output updater_mode_t           mem_updater_mode,
    // output logic cnt_buf_wren, // this should be controlled by the request
    output buf_port_sel_t           buf_port_sel,
    output arbiter_sel_t            arbiter_sel,
    output logic  [MC_CHANNEL-1:0]  eac2mc_ready,
    output logic                    cafu_start,
    input  logic                    cafu_done,

    // from CSR
    input logic zero_out,
    input logic write_back,
    input logic [MC_HA_DP_ADDR_WIDTH-1:0] dram_buf_base_addr, // not used
    // to CSR
    output logic is_writing_back

);
    logic  [MC_CHANNEL-1:0]  hold_request_fifo;
    ctrl_state_t state;

	for( genvar chanCount = 0; chanCount < MC_CHANNEL; chanCount=chanCount+1 ) begin : HOLD_TO_READY
        always_comb begin
            eac2mc_ready[chanCount] = emif_amm_ready[chanCount] & ~hold_request_fifo[chanCount];
        end
    end

    always_ff @( posedge clk ) begin : state_machine_transition
        
        if (~reset_n) begin
            state <= IDLE_S;
        end else begin
            case (state)
                IDLE_S: 
                    state <= COUNTING_S;

                COUNTING_S: begin
                    if (write_back)
                        state <= WRITE_BACK_COUNTER_S;
                    else if (zero_out)
                        state <= ZERO_OUT_COUNTER_S; 
                end

                WRITE_BACK_COUNTER_S: begin
                    if (cafu_done)
                        state <= IDLE_S;
                end

                ZERO_OUT_COUNTER_S: begin
                    if (mem_updater_done)
                        state <= IDLE_S;
                end

                default: ;
            endcase
        end
    end

    always_comb begin : state_machine_output

        mem_updater_start = 1'b0;
        hold_request_fifo[0] = 1'b0; // XXX ASSUME 1 channel
        is_writing_back = 1'b0;
        mem_updater_mode = ZERO_OUT_COUNTER;
        arbiter_sel = USER_A;
        buf_port_sel = USER_B;

        case (state)
            IDLE_S: ;

            COUNTING_S: begin
                arbiter_sel = USER_A;
                buf_port_sel = USER_B;
            end

            WRITE_BACK_COUNTER_S: begin
                buf_port_sel = CAFU_B;
                // arbiter_sel = UPDATER_A;
                mem_updater_mode = WRITE_BACK_COUNTER;
                // mem_updater_start = 1'b1; // commented out for cafu test
                // hold_request_fifo[0] = 1'b1;
                cafu_start = 1'b1;
                is_writing_back = 1'b1;
            end

            ZERO_OUT_COUNTER_S: begin
                buf_port_sel = UPDATER_B;
                //arbiter_sel = UPDATER_A;
                mem_updater_mode = ZERO_OUT_COUNTER;
                mem_updater_start = 1'b1;
            end

            default: ;
        endcase
    end
    
endmodule
