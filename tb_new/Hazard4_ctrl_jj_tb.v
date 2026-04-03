`timescale 1ns/1ps
module Hazard4_ctrl_jj_tb;
    reg clk, rst;
    reg [31:0] instruction;
    integer i, errors;

    localparam [6:0] OP_I = 7'b0010011;
    localparam [6:0] OP_J = 7'b1101111;
    localparam [31:0] NOP = 32'h00000013;

    function [31:0] enc_i;
        input [11:0] imm; input [4:0] rs1; input [2:0] fun3; input [4:0] rd; input [6:0] op;
        begin enc_i = {imm, rs1, fun3, rd, op}; end
    endfunction

    function [31:0] enc_j;
        input [20:0] imm; input [4:0] rd; input [6:0] op;
        begin enc_j = {imm[20], imm[10:1], imm[11], imm[19:12], rd, op}; end
    endfunction

    microprocessor dut(.clk(clk), .rst(rst));
    always #5 clk = ~clk;

    initial begin
        clk = 0; rst = 0; instruction = 0; errors = 0;
        for (i = 0; i < 32; i = i + 1) dut.u_instruction_memory.u_memory.mem[i] = NOP;

        // jump-jump-addi sequence
        // 0: jal x4,+8      -> target mem[2]
        // 1: jal x2,+8      (wrong-path, must flush and NOT execute)
        // 2: addi x1,2      (correct target)
        dut.u_instruction_memory.u_memory.mem[0] = enc_j(21'd8, 5'd4, OP_J);
        dut.u_instruction_memory.u_memory.mem[1] = enc_j(21'd8, 5'd2, OP_J);
        dut.u_instruction_memory.u_memory.mem[2] = enc_i(12'd2, 5'd0, 3'b000, 5'd1, OP_I);

        repeat (2) @(posedge clk); rst = 1;
        repeat (100) @(posedge clk);

        if (dut.u_core.u_decodestage.u_regfile0.register[1] !== 32'd2) begin errors = errors + 1; $display("FAIL: x1 target"); end
        if (dut.u_core.u_decodestage.u_regfile0.register[4] !== 32'd4) begin errors = errors + 1; $display("FAIL: x4 first jal link"); end
        if (dut.u_core.u_decodestage.u_regfile0.register[2] !== 32'd0) begin errors = errors + 1; $display("FAIL: x2 wrong-path jump executed"); end

        if (errors == 0) $display("RESULT: PASS"); else $display("RESULT: FAIL (%0d)", errors);
        $finish;
    end
endmodule
/*
Hazard Documentation:
Instructions:
- jal  x4, +8
- jal  x2, +8 (wrong-path)
- addi x1, x0, 2 (final target)
Expected Result:
- x1 = 2
- x4 = 4 (first jal link)
- x2 = 0 (second wrong-path jump must not execute)
Hazard Covered:
- Control-after-control hazard: wrong-path jump right after jump.
Without Hazard Handling:
- wrong-path jump may execute and update x2 link (non-zero), proving flush failure.
*/
