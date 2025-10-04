module n_reg #(
    parameter integer WIDTH = 32
) (
    input  logic                  clk,
    input  logic                  reset_n, // active-low reset
    input  logic                  en,   // write enable
    input  logic [WIDTH-1:0]      d,
    output logic [WIDTH-1:0]      q
);

    always_ff @(posedge clk or posedge reset_n) begin
        if (!reset_n)
            q <= '0;
        else if (en)
            q <= d;
    end

endmodule
