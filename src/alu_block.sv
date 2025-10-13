module alu_block (
    input  logic a,
    input  logic b,
    input  logic Ainvert,
    input  logic Binvert,
    input  logic CarryIn,
    input  logic [1:0] Operation,  // 00=AND, 01=OR, 10=ADD, 11=SLT
    input  logic Less,             // Used for SLT
    output logic Result,
    output logic CarryOut
);

    logic a_in, b_in;      // possibly inverted inputs
    logic and_out, or_out;
    logic sum;

    // Input inversion logic
    assign a_in = Ainvert ? ~a : a;
    assign b_in = Binvert ? ~b : b;

    // Basic logic operations
    assign and_out = a_in & b_in;
    assign or_out  = a_in | b_in;

    // Full adder for arithmetic operations
    assign {CarryOut, sum} = a_in + b_in + CarryIn;

    // MUX for operation select
    always_comb begin
        case (Operation)
            2'b00: Result = and_out;     // AND
            2'b01: Result = or_out;      // OR
            2'b10: Result = sum;         // ADD
            2'b11: Result = Less;        // SLT (set less than)
            default: Result = 1'b0;
        endcase
    end

endmodule
