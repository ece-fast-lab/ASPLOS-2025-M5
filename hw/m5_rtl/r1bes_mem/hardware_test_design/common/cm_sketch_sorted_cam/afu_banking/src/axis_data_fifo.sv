`timescale 1ns / 1ps

module axis_data_fifo #(
  parameter DATA_WIDTH = 32
)
(
  input  logic                  s_axis_aclk,
  input  logic                  s_axis_aresetn,
  input  logic [DATA_WIDTH-1:0] s_axis_tdata,
  input  logic                  s_axis_tvalid,
  output logic                  s_axis_tready,
  output logic [DATA_WIDTH-1:0] m_axis_tdata,
  output logic                  m_axis_tvalid,
  input  logic                  m_axis_tready
);

localparam DEPTH = 10'd256;//10'd256;

logic [DATA_WIDTH-1:0]  data;
logic                   wrreq;
logic                   rdreq;
logic                   init_rdreq;
logic                   clk;
logic [DATA_WIDTH-1:0]  q;
logic [8:0]  usedw;
logic                   full;
logic                   afull;
logic                   empty;

logic                   rstn;
logic [9:0]             fifo_count;
logic [9:0]             axi_count;
logic                   axi_init;

assign clk            = s_axis_aclk;
assign rstn           = s_axis_aresetn;
assign m_axis_tdata   = q;
//assign data           = s_axis_tdata;


////////////////////////////
// AXI-stream interface
////////////////////////////
always_ff @ (posedge clk or negedge rstn) begin
  if (!rstn) begin
    data <= {DATA_WIDTH{1'b0}};
  end
  else begin
    data <= s_axis_tdata;
  end
end

always_comb begin
  if (!rstn) begin
    s_axis_tready = 1'b0;
  end
  else begin
    if (~full) begin
      s_axis_tready = 1'b1;
    end
    else begin
      s_axis_tready = 1'b0;
    end
  end
end

always_ff @ (posedge clk or negedge rstn) begin
  if (!rstn) begin
    m_axis_tvalid     <= 1'b0;
  end
  else begin
    //if ((axi_count > 0) | ((axi_count == 0) & rdreq)) begin
    if (((axi_count > 0) | ((axi_count == 0) & init_rdreq)) & ~((axi_count == 1) & m_axis_tready)) begin
      m_axis_tvalid     <= 1'b1;
    end
    else begin
      m_axis_tvalid     <= 1'b0;
    end
  end
end

assign axi_count = fifo_count + axi_init;
always_ff @ (posedge clk or negedge rstn) begin
  if (!rstn) begin
    axi_init <= 1'b0;
  end
  else begin
    // first input
    if (~axi_init & rdreq & (fifo_count > 10'h0)) begin
      axi_init <= 1'b1;
    end
    // turn off
    else if ((fifo_count == 0) & m_axis_tvalid & m_axis_tready) begin
      axi_init <= 1'b0;
    end
    else begin
      axi_init <= axi_init;
    end
  end
end

////////////////////////////
// fifo control
////////////////////////////

always_ff @ (posedge clk or negedge rstn) begin
  if (!rstn) begin
    wrreq <= 1'b0;
  end
  else begin
    if (s_axis_tvalid & s_axis_tready & ~full & ~afull) begin
      wrreq <= 1'b1;
    end
    else begin
      wrreq <= 1'b0;
    end
  end
end

always_ff @ (posedge clk or negedge rstn) begin
  if (!rstn) begin
    init_rdreq <= 1'b0;
  end
  else begin
    if (empty & wrreq & (axi_count == 10'd0)) begin
      init_rdreq <= 1'b1;
    end
    else if (empty & wrreq & (axi_count == 10'd1) & m_axis_tready) begin
      init_rdreq <= 1'b1;
    end
    else begin
      init_rdreq <= 1'b0;
    end
  end
end

assign rdreq = ~(empty) ? (m_axis_tvalid & m_axis_tready) | init_rdreq : 0;
assign afull = (fifo_count == 10'd255); 

always_ff @ (posedge clk or negedge rstn) begin
  if (!rstn) begin
    fifo_count <= 10'd0;
  end
  else begin
    if (wrreq & rdreq) begin
      fifo_count <= fifo_count;
    end
    else if (wrreq & ~rdreq) begin
      fifo_count <= fifo_count + 10'd1;
    end
    else if (~wrreq & rdreq) begin
      fifo_count <= fifo_count - 10'd1;
    end
    else begin
      fifo_count <= fifo_count;
    end
  end
end

fifo_w32_d256
  u_fifo_w32_d256
(
  .data  (data),    //   input,  width = 32,  fifo_input.datain
  .wrreq (wrreq),   //   input,   width = 1,            .wrreq
  .rdreq (rdreq),   //   input,   width = 1,            .rdreq
  .clock (clk),     //   input,   width = 1,            .clk
  .q     (q),       //  output,  width = 32, fifo_output.dataout
  .usedw (usedw),   //  output,   width = 8,            .usedw
  .full  (full),    //  output,   width = 1,            .full
  .empty (empty)    //  output,   width = 1,            .empty
);

endmodule