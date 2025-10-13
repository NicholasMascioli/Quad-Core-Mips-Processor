module forward #(
    parameter WIDTH = 32
) (
    input  logic          exMemRegW,    // EX/MEM.RegWrite
    input  logic [4:0]    exMemRegRd,   // EX/MEM.RegisterRd
    input  logic          memWbRegW,    // MEM/WB.RegWrite
    input  logic [4:0]    memWbRd,      // MEM/WB.RegisterRd
    input  logic [4:0]    idExRs,       // ID/EX.RegisterRs
    input  logic [4:0]    idExRt,       // ID/EX.RegisterRt
    output logic [1:0]    forwardA,     
    output logic [1:0]    forwardB
);

    always_comb begin
        // Default values (no forwarding)
        forwardA = 2'b00;
        forwardB = 2'b00;

        // Rule 1: EX hazard on Rs
        if (exMemRegW && (exMemRegRd != 0) && (exMemRegRd == idExRs))
            forwardA = 2'b10;

        // Rule 2: EX hazard on Rt
        if (exMemRegW && (exMemRegRd != 0) && (exMemRegRd == idExRt))
            forwardB = 2'b10;

        // Rule 3: MEM hazard on Rs (only if EX hazard didn’t apply)
        if (memWbRegW && (memWbRd != 0) && 
            !(exMemRegW && (exMemRegRd != 0) && (exMemRegRd == idExRs)) &&
            (memWbRd == idExRs))
            forwardA = 2'b01;

        // Rule 4: MEM hazard on Rt (only if EX hazard didn’t apply)
        if (memWbRegW && (memWbRd != 0) && 
            !(exMemRegW && (exMemRegRd != 0) && (exMemRegRd == idExRt)) &&
            (memWbRd == idExRt))
            forwardB = 2'b01;
    end

endmodule
