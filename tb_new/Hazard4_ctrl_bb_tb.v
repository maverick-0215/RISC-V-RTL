`timescale 1ns/1ps
module Hazard4_ctrl_bb_tb;
    reg clk, rst;
    reg [31:0] instruction;
    integer i, errors;

    localparam [6:0] OP_I = 7'b0010011;
    localparam [6:0] OP_B = 7'b1100011;
    localparam [31:0] NOP = 32'h00000013;

    function [31:0] enc_i;
        input [11:0] imm; input [4:0] rs1; input [2:0] fun3; input [4:0] rd; input [6:0] op;
        begin enc_i = {imm, rs1, fun3, rd, op}; end
    endfunction

    function [31:0] enc_b;
        input [12:0] imm; input [4:0] rs2; input [4:0] rs1; input [2:0] fun3; input [6:0] op;
        begin enc_b = {imm[12], imm[10:5], rs2, rs1, fun3, imm[4:1], imm[11], op}; end
    endfunction

    microprocessor dut(.clk(clk), .rst(rst));
    always #5 clk = ~clk;

    initial begin
        clk = 0; rst = 0; instruction = 0; errors = 0;
        for (i = 0; i < 32; i = i + 1) dut.u_instruction_memory.u_memory.mem[i] = NOP;

        // branch-branch-addi sequence
        // 0: addi x1,0
        // 1: beq x1,x0,+8   -> target mem[3]
        // 2: beq x0,x0,+8   (wrong-path, must flush and NOT execute)
        // 3: addi x4,2      (final target)
        // 4: nop
        dut.u_instruction_memory.u_memory.mem[0] = enc_i(12'd0, 5'd0, 3'b000, 5'd1, OP_I);
        dut.u_instruction_memory.u_memory.mem[1] = enc_b(13'd8, 5'd0, 5'd1, 3'b000, OP_B);
        dut.u_instruction_memory.u_memory.mem[2] = enc_b(13'd8, 5'd0, 5'd0, 3'b000, OP_B);
        dut.u_instruction_memory.u_memory.mem[3] = enc_i(12'd2, 5'd0, 3'b000, 5'd4, OP_I);
        dut.u_instruction_memory.u_memory.mem[4] = NOP;

        repeat (2) @(posedge clk); rst = 1;
        repeat (110) @(posedge clk);

        if (dut.u_core.u_decodestage.u_regfile0.register[4] !== 32'd2) begin errors = errors + 1; $display("FAIL: x4 final target not executed"); end

        if (errors == 0) $display("RESULT: PASS"); else $display("RESULT: FAIL (%0d)", errors);
        $finish;
    end
endmodule
/*
Hazard Documentation:
Instructions:
- addi x1, x0, 0
- beq  x1, x0, +8
- beq  x0, x0, +8 (wrong-path)
- addi x4, x0, 2 (final target)
Expected Result:
- x4 = 2
Hazard Covered:
- Control-after-control hazard: wrong-path branch right after branch.
Without Hazard Handling:
- wrong-path second branch may execute and skip final target, leaving x4 = 0.
*/
