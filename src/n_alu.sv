module n_alu #(
    parameter WIDTH = 32
) (
    input  logic [2:0]          op,
    input  logic [WIDTH-1:0]    a,        // Operand A
    input  logic [WIDTH-1:0]    b,        // Operand B
    output logic [WIDTH-1:0]    result,   // Result
    output logic                zero     // Carry out
);

    logic [N:0] carry;        // internal carry chain (carry[0] is CarryIn)
    logic [N-1:0] less;       // for SLT (used only in LSB)
    
    assign carry[0] = op[2];

    genvar i;
    generate
        for (i = 0; i < N; i++) begin : alu_slice
            alu1 alu_block (
                .a        (A[i]),
                .b        (B[i]),
                .Ainvert  (1'b0),
                .Binvert  (op[2]),
                .CarryIn  (carry[i]),
                .Operation(op),
                .Less     ( (i == 0) ? less[N-1] : 1'b0 ), // SLT uses MSB result for LSB
                .Result   (result[i]),
                .CarryOut (carry[i+1])
            );
        end
    endgenerate

    // For SLT operation: use the sign bit from the subtract operation
    // SLT = 1 if (A - B) < 0
    assign less[N-1] = (A[N-1] ^ B[N-1]) ? 1'b1 : 1'b0; // simplified placeholder
    assign zero = (result == 0);

endmodule
