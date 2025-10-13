module alu_INVALID #(
    parameter WIDTH = 32
) (
    input  logic [WIDTH-1:0]   a,        // Operand A
    input  logic [WIDTH-1:0]   b,        // Operand B
    input  logic [3:0]         alu_ctrl, // ALU control signal
    output logic [WIDTH-1:0]   result,   // Result
    output logic               zero      // Zero flag
);

    // ALU control encoding (example MIPS-like)
    localparam ALU_ADD = 4'b0000;
    localparam ALU_SUB = 4'b0001;
    localparam ALU_AND = 4'b0010;
    localparam ALU_OR  = 4'b0011;
    localparam ALU_XOR = 4'b0100;
    localparam ALU_SLT = 4'b0101;  // set-less-than
    localparam ALU_SLL = 4'b0110;  // shift left logical
    localparam ALU_SRL = 4'b0111;  // shift right logical
    localparam ALU_SRA = 4'b1000;  // shift right arithmetic
 
    // Combinational logic
    always_comb begin
        // Default
        result = '0;

        unique case (alu_ctrl)
            ALU_ADD: result = a + b;
            ALU_SUB: result = a - b;
            ALU_AND: result = a & b;
            ALU_OR : result = a | b;
            ALU_XOR: result = a ^ b;
            ALU_SLT: result = ($signed(a) < $signed(b)) ? 1 : 0;
            ALU_SLL: result = a << b[4:0]; // use lower bits as shift amt
            ALU_SRL: result = a >> b[4:0];
            ALU_SRA: result = $signed(a) >>> b[4:0];
            default: result = '0;
        endcase
    end

    // Zero flag (true if result is all zeros)
    assign zero = (result == '0);

endmodule
