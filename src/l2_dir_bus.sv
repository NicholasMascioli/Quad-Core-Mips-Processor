import coh_types::*;
`include "coh_if.sv"

module l2_dir_bus #(
  parameter int CORES=4,
  parameter int LINE_BYTES=32,
  parameter int SETS=128
)(
  input  logic clk, rst_n,
  coh_if link [CORES]
);

  typedef struct packed {
    logic [31:0] tag;
    logic [CORES-1:0] sharers;
    logic [1:0] owner;
    logic valid;
  } dir_entry_t;

  dir_entry_t dir [SETS];
  logic [LINE_BYTES*8-1:0] data_store [SETS];

  localparam int OFFSET_W=$clog2(LINE_BYTES);
  localparam int INDEX_W =$clog2(SETS);

  // Simple Arbiter
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      for (int i=0;i<SETS;i++) dir[i].valid<=0;
    end else begin
      for (int c=0;c<CORES;c++) begin
        if (link[c].req_valid) begin
          logic [INDEX_W-1:0] idx = link[c].req.addr[OFFSET_W +: INDEX_W];
          case (link[c].req.cmd)
            GETS: begin
              dir[idx].valid   <= 1;
              dir[idx].sharers[c]<=1;
              link[c].resp_valid <= 1;
              link[c].resp.cmd    <= DATA;
              link[c].resp.line   <= data_store[idx];
              link[c].resp.dst    <= c;
            end
            GETM: begin
              dir[idx].valid   <= 1;
              dir[idx].owner   <= c;
              dir[idx].sharers <= '0;
              dir[idx].sharers[c]<=1;
              link[c].resp_valid <= 1;
              link[c].resp.cmd    <= DATA_EXCL;
              link[c].resp.line   <= data_store[idx];
              link[c].resp.dst    <= c;
            end
            PUTM: begin
              data_store[idx] <= link[c].resp.line;
            end
          endcase
        end
      end
    end
  end
endmodule
