import coh_types::*;
`include "coh_if.sv"

module quad_core_top (
  input  logic clk, rst_n
);
  localparam int CORES = 4;

  coh_if link [CORES]();

  // Per-core instruction/data ports
  logic [31:0] imem_addr [CORES], imem_rdata [CORES];
  logic [31:0] dmem_addr [CORES], dmem_wdata [CORES], dmem_rdata [CORES];
  logic        dmem_read [CORES], dmem_write [CORES];
  logic [3:0]  dmem_be   [CORES];

  // ------------------------------
  // Cores + L1D caches
  // ------------------------------
  for (genvar i=0; i<CORES; ++i) begin : G
    core u_core (
      .clk(clk), .rst_n(rst_n),
      .imem_addr(imem_addr[i]),
      .imem_rdata(imem_rdata[i]),
      .dmem_memRead(dmem_read[i]),
      .dmem_memWrite(dmem_write[i]),
      .dmem_be(dmem_be[i]),
      .dmem_addr(dmem_addr[i]),
      .dmem_wdata(dmem_wdata[i]),
      .dmem_rdata(dmem_rdata[i])
    );

    l1d_mesi #(.COREID(i)) u_l1d (
      .clk(clk), .rst_n(rst_n),
      .cpu_valid (dmem_read[i] || dmem_write[i]),
      .cpu_we    (dmem_write[i]),
      .cpu_be    (dmem_be[i]),
      .cpu_addr  (dmem_addr[i]),
      .cpu_wdata (dmem_wdata[i]),
      .cpu_rdata (dmem_rdata[i]),
      .cpu_ready (), .cpu_rvalid(),
      .coh(link[i])
    );

    // simple instruction memory stub (shared or per-core, add complex instructions later)
    assign imem_rdata[i] = 32'h0000_0000;
  end

  // Shared L2 memory and MESI arbiter
  l2_dir_bus #(.CORES(CORES)) u_l2 (
    .clk(clk), .rst_n(rst_n),
    .link(link)
  );
endmodule
