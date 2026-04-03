`timescale 1ns/1ps
module Microprocessor_hazard_add_beq_tb();

    reg clk;
    reg rst;
    reg [31:0] instruction;
    integer i;
    integer errors;

    localparam [6:0] OP_R = 7'b0110011;
    localparam [6:0] OP_I = 7'b0010011;
    localparam [6:0] OP_B = 7'b1100011;
    localparam [31:0] NOP = 32'h00000013;

    function [31:0] enc_r;
        input [6:0] funct7;
        input [4:0] rs2;
        input [4:0] rs1;
        input [2:0] funct3;
        input [4:0] rd;
        input [6:0] opcode;
        begin
            enc_r = {funct7, rs2, rs1, funct3, rd, opcode};
        end
    endfunction

    function [31:0] enc_i;
        input [11:0] imm;
        input [4:0] rs1;
        input [2:0] funct3;
        input [4:0] rd;
        input [6:0] opcode;
        begin
            enc_i = {imm, rs1, funct3, rd, opcode};
        end
    endfunction

    function [31:0] enc_b;
        input [12:0] imm;
        input [4:0] rs2;
        input [4:0] rs1;
        input [2:0] funct3;
        input [6:0] opcode;
        begin
            enc_b = {imm[12], imm[10:5], rs2, rs1, funct3, imm[4:1], imm[11], opcode};
        end
    endfunction

    microprocessor u_microprocessor0 (
        .clk(clk),
        .rst(rst)    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 0;
        instruction = 32'b0;
        errors = 0;

        for (i = 0; i < 32; i = i + 1) begin
            u_microprocessor0.u_instruction_memory.u_memory.mem[i] = NOP;
        end

        // Hazard under test:
        //   add x1, x2, x3
        //   beq x1, x2, +8
        //   addi x5, x0, 1   (must be flushed if branch is taken)
        //   addi x6, x0, 2   (branch target)
        u_microprocessor0.u_instruction_memory.u_memory.mem[0] = enc_r(7'b0000000, 5'd3, 5'd2, 3'b000, 5'd1, OP_R);
        u_microprocessor0.u_instruction_memory.u_memory.mem[1] = enc_b(13'd8, 5'd2, 5'd1, 3'b000, OP_B);
        u_microprocessor0.u_instruction_memory.u_memory.mem[2] = enc_i(12'd1, 5'd0, 3'b000, 5'd5, OP_I);
        u_microprocessor0.u_instruction_memory.u_memory.mem[3] = enc_i(12'd2, 5'd0, 3'b000, 5'd6, OP_I);

        #20;
        rst = 1;

        #1;
        u_microprocessor0.u_core.u_decodestage.u_regfile0.register[2] = 32'd10;
        u_microprocessor0.u_core.u_decodestage.u_regfile0.register[3] = 32'd0;

        #220;

        if (u_microprocessor0.u_core.u_decodestage.u_regfile0.register[1] !== 32'd10) begin
            $display("FAIL: add producer wrong, x1=%h", u_microprocessor0.u_core.u_decodestage.u_regfile0.register[1]);
            errors = errors + 1;
        end else begin
            $display("PASS: add producer x1=10");
        end

        if (u_microprocessor0.u_core.u_decodestage.u_regfile0.register[5] !== 32'd0) begin
            $display("FAIL: branch flush failed, x5=%h", u_microprocessor0.u_core.u_decodestage.u_regfile0.register[5]);
            errors = errors + 1;
        end else begin
            $display("PASS: beq taken flushed next instruction");
        end

        if (u_microprocessor0.u_core.u_decodestage.u_regfile0.register[6] !== 32'd2) begin
            $display("FAIL: branch target wrong, x6=%h", u_microprocessor0.u_core.u_decodestage.u_regfile0.register[6]);
            errors = errors + 1;
        end else begin
            $display("PASS: branch target executed x6=2");
        end

        if (errors == 0) begin
            $display("RESULT: PASS");
        end else begin
            $display("RESULT: FAIL (%0d checks failed)", errors);
        end

        $finish;
    end

endmodule

