`timescale 1ns/1ps
module Hazard4_raw_gap2_tb;
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

    microprocessor dut(
        .clk(clk),
        .rst(rst)    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 0;
        instruction = 32'b0;
        errors = 0;

        for (i = 0; i < 32; i = i + 1) begin
            dut.u_instruction_memory.u_memory.mem[i] = NOP;
        end

        // RAW gap-2 scenario:
        // i1: addi x1, x0, 10        (producer)
        // i2: addi x3, x0, 1         (independent)
        // i3: addi x3, x3, 1         (independent)
        // i4: add  x4, x1, x2        (consumer)
        //
        // In a 5-stage pipeline, i1 reaches WB when i4 is in Decode.
        // This checks same-cycle regfile write (x1) + decode read (x1).
        dut.u_instruction_memory.u_memory.mem[0] = enc_i(12'd10, 5'd0, 3'b000, 5'd1, OP_I);
        dut.u_instruction_memory.u_memory.mem[1] = enc_i(12'd1,  5'd0, 3'b000, 5'd3, OP_I);
        dut.u_instruction_memory.u_memory.mem[2] = enc_i(12'd1,  5'd3, 3'b000, 5'd3, OP_I);
        dut.u_instruction_memory.u_memory.mem[3] = enc_r(7'b0000000, 5'd2, 5'd1, 3'b000, 5'd4, OP_R);

        repeat (2) @(posedge clk);
        rst = 1;

        // x2 is the other operand for i4
        dut.u_core.u_decodestage.u_regfile0.register[2] = 32'd7;

        repeat (70) @(posedge clk);

        if (dut.u_core.u_decodestage.u_regfile0.register[1] !== 32'd10) begin
            errors = errors + 1;
            $display("FAIL: producer writeback x1 wrong, x1=%h", dut.u_core.u_decodestage.u_regfile0.register[1]);
        end else begin
            $display("PASS: producer writeback x1=10");
        end

        if (dut.u_core.u_decodestage.u_regfile0.register[4] !== 32'd17) begin
            errors = errors + 1;
            $display("FAIL: RAW gap2 consumer wrong, x4=%h (expected 17)", dut.u_core.u_decodestage.u_regfile0.register[4]);
        end else begin
            $display("PASS: RAW gap2 same-cycle read/write handled (x4=17)");
        end

        if (errors == 0) begin
            $display("RESULT: PASS");
        end else begin
            $display("RESULT: FAIL (%0d checks failed)", errors);
        end

        $finish;
    end
endmodule
/*
Hazard Documentation:
Instructions:
- i1: addi x1, x0, 10
- i2: addi x3, x0, 1
- i3: addi x3, x3, 1
- i4: add  x4, x1, x2
Expected Result:
- x1 = 10
- x4 = 17 (x1 + x2, where x2 = 7)
Hazard Covered:
- RAW gap-2 with same-cycle WB write and Decode read of x1.
Without Hazard Handling:
- i4 may read old x1 (0) and x4 could become 7 instead of 17.
*/
