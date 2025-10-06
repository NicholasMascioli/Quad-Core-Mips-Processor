module n_adder #(
    parameter WIDTH = 32
) (
    input  logic [WIDTH-1:0]    a,        // Operand A
    input  logic [WIDTH-1:0]    b,        // Operand B
    input  logic                c_in,     // Carry in
    output logic [WIDTH-1:0]    result,   // Result
    output logic                c_out     // Carry out
);

    alwasy @(a, b, c_in) begin
        {c_out, result} = a + b + c_in;
    end

endmodule
