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
///////////////////////////////////////////////////////////////////////


package cafu_mem_target_pkg;
    
    localparam  CL_ADDR_MSB = 51;
    localparam  CL_ADDR_LSB = 6;    
    
    typedef logic [CL_ADDR_MSB:CL_ADDR_LSB]        Cl_Addr_t;
    
    typedef struct packed {
        logic [CL_ADDR_MSB:28]  Addr;
        logic [CL_ADDR_MSB:28]  Size;
        logic [3:0]             IW;
        logic [3:0]             IG;
    }  hdm_mem_base_t;  //used for address decode in fabric_slice 
    
    typedef enum logic {
       TARGET_HOST_MEM     = 1'b0,
       TARGET_DEV_MEM      = 1'b1
    } fabric_target_dcd_e;    
    
    function automatic fabric_target_dcd_e fabric_target_dcd_f;
        input Cl_Addr_t        Addr;
        input hdm_mem_base_t   Base;
    
        localparam ADDRMATCH1  = 'h0_0000_0004;
        localparam ADDRMATCH2  = 'h0_0000_0005;
    
        logic [CL_ADDR_MSB:28]      shifted_addr;
    
        //shifted_addr = Addr << 22; //since CL Addr, shift 22 instead of 28
        shifted_addr = Addr[CL_ADDR_MSB:28];
    
        if ( (shifted_addr[CL_ADDR_MSB:28] <   Base.Addr + Base.Size)
           & (shifted_addr[CL_ADDR_MSB:28] >=  Base.Addr))
            fabric_target_dcd_f = TARGET_DEV_MEM;
        else
            fabric_target_dcd_f = TARGET_HOST_MEM;  
    
    endfunction    
    

endpackage
