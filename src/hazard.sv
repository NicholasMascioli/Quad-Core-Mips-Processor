module hazard #(
    parameter WIDTH = 32
) (
    input  logic [4:0]    idExRt,
    input  logic [4:0]    ifIdRs,
    input  logic [4:0]    ifIdRt,
    input  logic          idExMW,
    output logic          pcWrite,
    output logic          ifIdW,     
    output logic          controlMux,     

);

    always_comb begin
        // Default values (no stalling)
        pcWrite = 1'b1;
        ifIdW = 1'b1;
        controlMux = 1'b1;

        if (idExMW && ((idExRt == ifIdRs) || (idExRt == ifIdRt)))
            pcWrite = 1'b0;
            ifIdW = 1'b0;
            controlMux = 1'b0;
    end

endmodule
