// tb_n_reg.sv - simple testbench for n_reg
`timescale 1ns/1ps

module tb_n_reg;
    parameter WIDTH = 8;

    logic clk;
    logic reset_n;
    logic wr_en;
    logic [WIDTH-1:0] d;
    logic [WIDTH-1:0] q;

    // Instantiate the DUT
    n_reg #(.WIDTH(WIDTH)) dut (
        .clk(clk),
        .reset_n(reset_n),
        .wr_en(wr_en),
        .d(d),
        .q(q)
    );

    // Clock generator: 10ns period
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        // Initialize
        reset_n = 0; wr_en = 0; d = '0;
        #20;
        // Release reset
        reset_n = 1;
        #10;

        // Write value 0xA5
        d = 8'hA5; wr_en = 1;
        #10; // capture on next rising edge
        wr_en = 0;

        #20;
        // Write another value
        d = 8'h3C; wr_en = 1;
        #10; wr_en = 0;

        #20;
        // Assert reset again
        reset_n = 0;
        #10; reset_n = 1;

        #20;
        $display("Final q = 0x%0h", q);
        $finish;
    end

    // Optional waveform dump for VCD viewers
    initial begin
        $dumpfile("tb_n_reg.vcd");
        $dumpvars(0, tb_n_reg);
    end

endmodule
