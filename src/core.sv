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


  logic [XLEN-1:0] branch_target =  ifid_d.pc_plus4 + (imm_sext << 2);
  logic branch_taken = branch & (rs_data == rt_data);
  logic [XLEN-1:0] jump_target = {ifid_q.pc_plus4[31:28],ifid_q.instr[25:0], 2'b00};

  always_comb begin
    if (jump)
        pc_n = jump_target;
    else if (branch_taken)
        pc_n = branch_target;
    else
        pc_n = pc_plus4;
  end

  typedef struct packed {
    logic [XLEN-1:0] rs_data, rt_data, imm_sext;
    logic [REG_ADDR_W-1:0] rs, rt, rd;
    logic [5:0] funct;
    logic       regDst, aluSrc;
    logic [1:0] aluOP;       
    logic       memRead, memWrite;
    logic       memToReg, regWrite;
    logic       valid; 
  } idex_t;

  idex_t idex_q, idex_d;
  logic  controlMux;  

    always_comb begin
    idex_d = idex_q;

    idex_d.pc_plus4 = ifid_q.pc_plus4;
    idex_d.rs_data  = rs_data;
    idex_d.rt_data  = rt_data;
    idex_d.imm_sext = imm_sext;
    idex_d.rs       = rs;
    idex_d.rt       = rt;
    idex_d.rd       = rd;
    idex_d.funct    = funct;
    idex_d.valid    = ifid_q.valid;

    // pack ALUop from control
    logic [1:0] aluOP = {aluOP1, aluOP0};

    if (controlMux) begin
      idex_d.regDst   = regDst;
      idex_d.aluSrc   = aluSrc;
      idex_d.aluOP    = aluOP;
      idex_d.memRead  = memRead;
      idex_d.memWrite = memWrite;
      idex_d.branch   = branch;
      idex_d.memToReg = memToReg;
      idex_d.regWrite = regWrite;
    end else begin
      // bubble (zero EX/M/WB controls)
      idex_d.regDst   = 1'b0;
      idex_d.aluSrc   = 1'b0;
      idex_d.aluOP    = 2'b00;
      idex_d.memRead  = 1'b0;
      idex_d.memWrite = 1'b0;
      idex_d.branch   = 1'b0;
      idex_d.memToReg = 1'b0;
      idex_d.regWrite = 1'b0;
    end
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        idex_q <= '0;
    else
        idex_q <= idex_d;
  end

    logic ifIdW_int, controlMux_int;

  hazard u_hzd (
    .idExRt     (idex_q.rt),
    .ifIdRs     (rs),
    .ifIdRt     (rt),
    .idExMW     (idex_q.memRead),
    .pcWrite    (pcWrite),
    .ifIdW      (ifIdW_int),
    .controlMux (controlMux_int)
  );

  // If high control mux passes bubble through ID/EX control signals
  assign controlMux = controlMux_int;

  assign pc_en = pcWrite;

  // IF/ID write enable: stall on hazard
  assign ifIdW = ifIdW_int;


  // EX stage: Forwarding Unit, ALU

  logic [1:0] forwardA, forwardB;

  logic [XLEN-1:0] exmem_aluResult;
  logic [XLEN-1:0] memwb_wbData;

  forward u_fwd (
    .exMemRegW (/* Assigned below */),
    .exMemRegRd(/* Assigned below */),
    .memWbRegW (/* Assigned below */),
    .memWbRd   (/* Assigned below */),
    .idExRs    (idex_q.rs),
    .idExRt    (idex_q.rt),
    .forwardA  (forwardA),
    .forwardB  (forwardB)
  );

  logic [XLEN-1:0] alu_srcA_raw, alu_srcB_raw;

  // ALU feeding muxes (from forwarding unit)
  always_comb begin
    
    // Default
    alu_srcA_raw = idex_q.rs_data;
    alu_srcB_raw = idex_q.rt_data;

    unique case (forwardA)
      2'b10: alu_srcA_raw = exmem_aluResult;
      2'b01: alu_srcA_raw = memwb_wbData;
      default: // Do nothing
    endcase

    unique case (forwardB)
      2'b10: alu_srcB_raw = exmem_aluResult;
      2'b01: alu_srcB_raw = memwb_wbData;
      default: // Do nothing
    endcase
  end

 
  logic [2:0] alu_op_sel;

  alu_control u_aluctl (
    .aluOP (idex_q.aluOP),
    .funct (idex_q.funct),
    .op    (alu_op_sel)
  );

    // ALU
  logic [XLEN-1:0] alu_result;
  logic alu_zero;

  n_alu #(.WIDTH(XLEN)) u_alu (
    .op     (alu_op_sel),
    .a      (alu_srcA_raw),
    .b      (alu_srcB_raw),
    .result (alu_result),
    .zero   (alu_zero)
  );

  logic [REG_ADDR_W-1:0] ex_dest = (idex_q.regDst) ? idex_q.rd : idex_q.rt;

  typedef struct packed {
    logic [XLEN-1:0] alu_result;
    logic [XLEN-1:0] rt_forwarded;  // Rt data for Store-Word commands
    logic [REG_ADDR_W-1:0] rd;

    logic memRead, memWrite;
    logic memToReg, regWrite;

    logic valid;
  } exmem_t;

  exmem_t exmem_q, exmem_d;

  always_comb begin
    exmem_d = exmem_q;

    exmem_d.alu_result   = alu_result;
    exmem_d.rt_forwarded = alu_srcB_raw;
    exmem_d.rd           = ex_dest;

    exmem_d.memRead      = idex_q.memRead;
    exmem_d.memWrite     = idex_q.memWrite;
    exmem_d.memToReg     = idex_q.memToReg;
    exmem_d.regWrite     = idex_q.regWrite;

    exmem_d.valid        = idex_q.valid;
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) 
        exmem_q <= '0;
    else
        exmem_q <= exmem_d;
  end


  // MEM Stage: Single port memory unit

  // Signals sent to external memory unit
  assign dmem_memRead  = exmem_q.valid && exmem_q.memRead;
  assign dmem_memWrite = exmem_q.valid && exmem_q.memWrite;
  assign dmem_addr     = exmem_q.alu_result;
  assign dmem_wdata    = exmem_q.rt_forwarded;
  assign dmem_be       = 4'b1111; 

  typedef struct packed {
    logic [XLEN-1:0] alu_result;
    logic [XLEN-1:0] load_data;
    logic [REG_ADDR_W-1:0] rd;

    // WB
    logic memToReg, regWrite;

    logic valid;
  } memwb_t;

  memwb_t memwb_q, memwb_d;

  always_comb begin
    memwb_d = memwb_q;

    memwb_d.alu_result = exmem_q.alu_result;
    memwb_d.load_data  = dmem_rdata;
    memwb_d.rd         = exmem_q.rd;

    memwb_d.memToReg   = exmem_q.memToReg;
    memwb_d.regWrite   = exmem_q.regWrite;

    memwb_d.valid      = exmem_q.valid;
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) memwb_q <= '0;
    else        memwb_q <= memwb_d;
  end


  // WB Stage: Writeback to reg file
  logic [XLEN-1:0] wbData = (memwb_q.memToReg) ? memwb_q.load_data : memwb_q.alu_result;

  // Set regfile write port
  assign u_rf.we    = memwb_q.valid && memwb_q.regWrite;
  assign u_rf.waddr = memwb_q.rd;
  assign u_rf.wdata = wbData;

  // Assigns forward data
  assign memwb_wbData   = wbData;
  assign exmem_aluResult= exmem_q.alu_result;


endmodule
