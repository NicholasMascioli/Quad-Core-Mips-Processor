import coh_types::*;

interface coh_if;
  logic        req_valid;
  coh_req_t    req;
  logic        req_ready;

  logic        resp_valid;
  coh_resp_t   resp;
  logic        resp_ready;
endinterface
