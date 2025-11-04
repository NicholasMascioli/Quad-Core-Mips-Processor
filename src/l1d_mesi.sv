import coh_types::*;
`include "coh_if.sv"

module l1d_mesi #(
  parameter int LINE_BYTES = 32,
  parameter int SETS = 64,
  parameter int XLEN = 32,
  parameter int COREID = 0
)(
  input  logic clk, rst_n,

  // Core side 
  input  logic        cpu_valid,
  input  logic        cpu_we,
  input  logic [3:0]  cpu_be,
  input  logic [31:0] cpu_addr,
  input  logic [31:0] cpu_wdata,
  output logic [31:0] cpu_rdata,
  output logic        cpu_ready,
  output logic        cpu_rvalid,

  // Coherence link to L2
  coh_if coh
);

    typedef enum logic [2:0] {
        I,
        S,
        E,
        M
    } mesi_e;

    typedef enum logic [2:0] {
        IDLE, 
        LOOKUP, 
        MISS_GETS, 
        MISS_GETM, 
        WAIT_DATA
    } ctrl_e;

    localparam int OFFSET_W = $clog2(LINE_BYTES);
    localparam int INDEX_W  = $clog2(SETS);

    logic [INDEX_W-1:0] idx;
    logic [31:0] tag;
    assign idx = cpu_addr[OFFSET_W +: INDEX_W];
    assign tag = cpu_addr[31 -: (32-OFFSET_W-INDEX_W)];

    logic [31:0] tag_ram   [SETS];
    mesi_e state_ram [SETS];
    logic [LINE_BYTES*8-1:0] data_ram  [SETS];

    ctrl_e ctrl_q, ctrl_n;
    logic [31:0] latched_addr;
    logic latched_we;

    assign cpu_ready  = (ctrl_q==IDLE);
    assign coh.req_ready = 1'b1;
    assign coh.resp_ready= 1'b1;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ctrl_q <= IDLE;
            latched_addr <= '0;
            latched_we   <= 1'b0;
        end else begin
            ctrl_q <= ctrl_n;
            if (cpu_valid && cpu_ready) begin
                latched_addr <= cpu_addr;
                latched_we   <= cpu_we;
            end
        end
    end

  // Main FSM
  always_comb begin
    ctrl_n       = ctrl_q;
    coh.req_valid= 1'b0;
    coh.req      = '0;
    cpu_rdata    = '0;
    cpu_rvalid   = 1'b0;

    logic hit = (tag_ram[idx]==tag) && (state_ram[idx]!=I);

    unique case (ctrl_q)
      IDLE: if (cpu_valid) ctrl_n = LOOKUP;

      LOOKUP: begin
        if (hit) begin
          if (!cpu_we) begin
            cpu_rvalid = 1'b1;
            cpu_rdata  = data_ram[idx][31:0];
            ctrl_n     = IDLE;
          end else begin
            // write hit
            state_ram[idx] = M;
            ctrl_n = IDLE;
          end
        end else begin
          coh.req_valid = 1'b1;
          coh.req.src   = COREID[1:0];
          coh.req.addr  = {tag, idx, {OFFSET_W{1'b0}}};
          coh.req.cmd   = cpu_we ? GETM : GETS;
          ctrl_n        = WAIT_DATA;
        end
      end

      WAIT_DATA: if (coh.resp_valid) begin
        if (coh.resp.cmd inside {DATA, DATA_EXCL}) begin
          tag_ram[idx]   = tag;
          data_ram[idx]  = coh.resp.line;
          state_ram[idx] = (coh.resp.cmd==DATA) ? S : E;
          cpu_rdata      = coh.resp.line[31:0];
          cpu_rvalid     = !latched_we;
          ctrl_n         = IDLE;
        end
      end
    endcase
  end

endmodule