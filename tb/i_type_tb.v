`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/19/2026 12:10:44 AM
// Design Name: 
// Module Name: i_type_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


`timescale 1ns / 1ps

module i_type_tb;

    reg clk;
    reg rst;
    wire [15:0] test_output; 

    // Instantiate the microprocessor and pass the memory file parameter
    // change the machine codes in instr.mem as needed(we have provided the machine codes in phase2 report)
    microprocessor #(
        .INSTR_MEM_FILE("C:/Users/Sia/Vivado/FPGAA/tb/instr.mem") // change the file path as required
    ) uut (
        .clk(clk),
        .rst(rst),
        .x1_to_x4_nibbles(test_output) 
    );

    // Generate the clock
    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 0;

        #20 rst = 1;

        #500 $stop;
    end

endmodule

