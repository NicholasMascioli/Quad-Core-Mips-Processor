module control (
    input  logic [5:0] op,
    output logic regDst, aluSrc, memToReg, regWrite, memRead, memWrite, branch, aluOP1, aluOP0
);

    logic r, lw, sw, beq;

    always @(op) begin
        r   = !op[0] & !op[1] & !op[2] & !op[3] & !op[4] & !op[5];
        lw  = op[0] & op[1] & !op[2] & !op[3] & !op[4] & op[5];
        sw  = op[0] & op[1] & !op[2] & op[3] & !op[4] & op[5];
        beq = !op[0] & !op[1] & op[2] & !op[3] & !op[4] & !op[5];

        regDst = r;
        aluSrc = lw | sw;
        memToReg = lw;
        regWrite = r | lw;
        memRead = lw;
        memWrite = sw;
        branch = beq;
        aluOP1 = r;
        aluOP0 = beq;
    end

endmodule