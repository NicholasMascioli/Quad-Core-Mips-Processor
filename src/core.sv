module core #(
    parameter int XLEN = 32,
    parameter int REG_ADDR_W = 5,
    parameter int RESET_PC = 'h0000_0000
)(
    input logic clk,
    output logic rst_n,

    // ---------------- Instruction memory (simple Harvard I-port) ---------------
    output logic [XLEN-1:0]      imem_addr,   // PC
    input  logic [XLEN-1:0]      imem_rdata,  // fetched instruction

    // ---------------- Data memory (simple Harvard D-port) ----------------------
    output logic                 dmem_memRead,
    output logic                 dmem_memWrite,
    output logic [3:0]           dmem_be,     // byte-enables (word ops -> 4'b1111)
    output logic [XLEN-1:0]      dmem_addr,
    output logic [XLEN-1:0]      dmem_wdata,
    input  logic [XLEN-1:0]      dmem_rdata


);

// IF stage: PC, PC+4 and Branch

    logic [XLEN], pc_q, pc_n;
    logic pcWrite;
    logic pc_en;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) pc_q <= RESET_PC;
        else if (pc_en) pc_q <= pc_n
    end

    assign imem_addr = pc_q;

    logic [XLEN-1:0] pc_plus4 = pc_q + 32'd4;

   typedef struct packed {
        logic [XLEN-1:0] pc_plus4;
        logic [XLEN-1:0] instr;
        logic valid;
   } ifid_t;

   ifid_t ifid_q, ifid_d;

   logic ifIdW;

   always_comb begin
    ifid_d = ifid_q;
    if (ifIdW) begin
        ifid_d.pc_plus4 = pc_plus4;
        ifid_d.instr =  imem_addr;
        ifid_d.valid = 1'b1;
    end
   end

   always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) ifid_q <= '0;
    else ifid_q <=  ifid_d;
   end


// ID Stage: Decode regfile, sign-extend

    logic [5:0]             op    = ifid_q.instr[31:26];
    logic [REG_ADDR_W-1:0]  rs    = ifid_q.instr[25:21];
    logic [REG_ADDR_W-1:0]  rt    = ifid_q.instr[20:16];
    logic [REG_ADDR_W-1:0]  rd    = ifid_q.instr[15:11];
    logic [15:0]            imm16 = ifid_q.instr[15:0];
    logic [5:0]             funct = ifid_q.instr[5:0];

    logic [XLEN-1:0] imm_sext = {{16{imm16[15]}}, imm16};

    logic regDst, aluSrc, memToReg, regWrite, memRead, memWrite, branch;
    logic aluOP1, aluOP0;

    control u_ctl (
        .op       (op),
        .regDst   (regDst),
        .aluSrc   (aluSrc),
        .memToReg (memToReg),
        .regWrite (regWrite),
        .memRead  (memRead),
        .memWrite (memWrite),
        .branch   (branch),
        .aluOP1   (aluOP1),
        .aluOP0   (aluOP0)
    );

    logic [XLEN-1:0] rs_data, rt_data;

    regfile #(.N(XLEN), .M(32)) u_rf (
        .clk    (clk),
        .rst    (~rst_n),
        .we     (/* driven in WB */),
        .waddr  (/* driven in WB */),
        .raddr1 (rs),
        .raddr2 (rt),
        .wdata  (/* driven in WB */),
        .rdata1 (rs_data),
        .rdata2 (rt_data)
  );


endmodule