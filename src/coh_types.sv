package coh_types;
  parameter int LINE_BYTES = 32;
  parameter int CORES      = 4;

  typedef enum logic [3:0] {
    GETS, GETM, UPG, PUTM,
    INV, INV_ACK,
    DATA, DATA_EXCL
  } coh_cmd_e;

  typedef struct packed {
    coh_cmd_e cmd;
    logic [1:0] src;
    logic [31:0] addr;
  } coh_req_t;

  typedef struct packed {
    coh_cmd_e cmd;
    logic [1:0] dst;
    logic [31:0] addr;
    logic [LINE_BYTES*8-1:0] line;
  } coh_resp_t;
endpackage
