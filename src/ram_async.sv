// Asynchronous single port ram
module ram_async #(
    parameter SIZE  = 256,      // size of memory 
    parameter WORD = 32         // word size
) (
    input  logic                        we, re,              // write enable, read enable
    input  logic [$clog2(SIZE)-1:0]     addr,  // write/read address
    input  logic [N-1:0]                wdata,
    output logic [N-1:0]                rdata
);
    
    reg [WORD-1:0] data_out;
    reg [WORD-1:0] mem [0:SIZE-1];

    // Mem write
    always @(we, addr) begin
        if (we) begin
            mem[addr] <= wdata;
        end
    end

    // Mem read
    always @(re, addr) begin
        if (re) begin
            rdata = mem[addr];
        end else begin
            rdata = 'bz;
        end
    end


endmodule
