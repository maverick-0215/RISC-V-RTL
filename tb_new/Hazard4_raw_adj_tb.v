`timescale 1ns/1ps
module Hazard4_raw_adj_tb;
    reg clk, rst;
    reg [31:0] instruction;
    integer i, errors;

    localparam [6:0] OP_R = 7'b0110011;
    localparam [6:0] OP_I = 7'b0010011;
    localparam [31:0] NOP = 32'h00000013;

    function [31:0] enc_r;
        input [6:0] funct7; input [4:0] rs2; input [4:0] rs1; input [2:0] funct3; input [4:0] rd; input [6:0] opcode;
        begin enc_r = {funct7, rs2, rs1, funct3, rd, opcode}; end
    endfunction
    function [31:0] enc_i;
        input [11:0] imm; input [4:0] rs1; input [2:0] funct3; input [4:0] rd; input [6:0] opcode;
        begin enc_i = {imm, rs1, funct3, rd, opcode}; end
    endfunction

    microprocessor dut(.clk(clk), .rst(rst));
    always #5 clk = ~clk;

    initial begin
        clk = 0; rst = 0; instruction = 0; errors = 0;
        for (i=0; i<32; i=i+1) dut.u_instruction_memory.u_memory.mem[i] = NOP;

        // x1=7, x2=9, x3=x1+x2, x4=x3-x1 (adjacent RAW on x3)
        dut.u_instruction_memory.u_memory.mem[0] = enc_i(12'd7, 5'd0, 3'b000, 5'd1, OP_I);
        dut.u_instruction_memory.u_memory.mem[1] = enc_i(12'd9, 5'd0, 3'b000, 5'd2, OP_I);
        dut.u_instruction_memory.u_memory.mem[2] = enc_r(7'b0000000, 5'd2, 5'd1, 3'b000, 5'd3, OP_R);
        dut.u_instruction_memory.u_memory.mem[3] = enc_r(7'b0100000, 5'd1, 5'd3, 3'b000, 5'd4, OP_R);

        repeat (2) @(posedge clk); rst = 1;
        repeat (40) @(posedge clk);

        if (dut.u_core.u_decodestage.u_regfile0.register[3] !== 32'd16) begin errors=errors+1; $display("FAIL: x3"); end
        if (dut.u_core.u_decodestage.u_regfile0.register[4] !== 32'd9)  begin errors=errors+1; $display("FAIL: x4"); end

        if (errors==0) $display("RESULT: PASS"); else $display("RESULT: FAIL (%0d)", errors);
        $finish;
    end
endmodule
/*
Hazard Documentation:
Instructions:
- addi x1, x0, 7
- addi x2, x0, 9
- add  x3, x1, x2
- sub  x4, x3, x1
Expected Result:
- x3 = 16
- x4 = 9
Hazard Covered:
- RAW adjacent dependency (consumer immediately after producer).
Without Hazard Handling:
- x4 could use stale x3 and become 0 or incorrect.
*/
