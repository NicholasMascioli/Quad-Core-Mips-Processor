// regfile.sv
module regfile #(
    parameter N = 8,      // register width
    parameter M = 4       // number of registers
) (
    input  logic               clk,
    input  logic               rst,
    input  logic               we,              // write enable
    input  logic [$clog2(M)-1:0] waddr, raddr1, raddr2,  // write/read address
    input  logic [N-1:0]       wdata,
    output logic [N-1:0]       rdata1,
    output logic [N-1:0]       rdata2
);

    // Array of M N-bit registers
    logic [N-1:0] reg_array [M-1:0];

    // Instantiate N-bit registers
    genvar i;
    generate
        for (i = 0; i < M; i++) begin : reg_instances
            n_reg #(.WIDTH(N)) u_reg (
                .clk (clk),
                .rst (rst),
                .en  (we && (waddr == $clog2(M)'(i))),
                .d   (wdata),
                .q   (reg_array[i])
            );
        end
    endgenerate

    // Read port
    assign rdata1 = reg_array[raddr1];
    assign rdata2 = reg_array[raddr2];

endmodule
