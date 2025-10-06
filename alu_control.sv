module alu_control #(
    input  logic [1:0] aluOP,
    input  logic [5:0] funct,
    output logic [2:0] op
);

    always @(aluOP, funct) begin
        if (!aluOP[0] && !aluOP[1]) begin
            op = 3'b010;
        end else if (aluOP[1]) begin
            op = 3'b110;
        end else if (aluOP[0]) begin
            if (funct == 6'bXX0000 ) begin
                op = 3'b010;
            end else if (funct == 6'bXX0010 ) begin
                op = 3'b110;
            end else if (funct == 6'bXX0100 ) begin
                op = 3'b000;
            end else if (funct == 6'bXX0101 ) begin
                op = 3'b001;
            end else if (funct == 6'bXX1010 ) begin
                op = 3'b111;
            end
        end
    end

endmodule