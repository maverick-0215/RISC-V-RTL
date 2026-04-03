`timescale 1ns/1ps
module Microprocessor_4reg_tb;
    reg CLK100MHZ = 0;
        reg rst = 0; // Reset (active high)
    wire [15:0] LED;

    // Instantiate the top module
    basys3_top #(
        .USE_SIMULATION_CLOCK(1)
    ) uut (
        .CLK100MHZ(CLK100MHZ),
            .rst(rst),
        .LED(LED)
    );

    // Clock generation (10ns period = 100MHz input clock)
    always #5 CLK100MHZ = ~CLK100MHZ;

    initial begin
        // Initialize reset
            rst = 0;
        #100;
        // Release reset
            rst = 1;
        // Run for enough cycles to execute all instructions
        #1_000_000;
        $finish;
    end
endmodule
