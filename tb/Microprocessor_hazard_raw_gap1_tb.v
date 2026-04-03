`timescale 1ns/1ps
module Microprocessor_hazard_raw_gap1_tb();

    reg clk;
    reg rst;
    reg [31:0] instruction;
    integer i;
    integer errors;

    localparam [6:0] OP_R = 7'b0110011;
    localparam [6:0] OP_I = 7'b0010011;
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

    microprocessor u_microprocessor0 (
        .clk(clk),
        .rst(rst)    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 0;
        instruction = 32'b0;
        errors = 0;

        for (i = 0; i < 16; i = i + 1) begin
            u_microprocessor0.u_instruction_memory.u_memory.mem[i] = NOP;
        end

        // RAW with 1 instruction gap:
        // addi x2, x0, 9
        // addi x3, x0, 4
        // add  x4, x2, x3
        // nop
        // xor  x5, x4, x2   <- RAW with one-gap
        u_microprocessor0.u_instruction_memory.u_memory.mem[0] = enc_i(12'd9, 5'd0, 3'b000, 5'd2, OP_I);
        u_microprocessor0.u_instruction_memory.u_memory.mem[1] = enc_i(12'd4, 5'd0, 3'b000, 5'd3, OP_I);
        u_microprocessor0.u_instruction_memory.u_memory.mem[2] = enc_r(7'b0000000, 5'd3, 5'd2, 3'b000, 5'd4, OP_R);
        u_microprocessor0.u_instruction_memory.u_memory.mem[3] = NOP;
        u_microprocessor0.u_instruction_memory.u_memory.mem[4] = enc_r(7'b0000000, 5'd2, 5'd4, 3'b100, 5'd5, OP_R);

        #20;
        rst = 1;

        #140;

        if (u_microprocessor0.u_core.u_decodestage.u_regfile0.register[5] !== 32'd4) begin
            $display("FAIL: RAW gap1 x5 wrong, x5=%h", u_microprocessor0.u_core.u_decodestage.u_regfile0.register[5]);
            errors = errors + 1;
        end else begin
            $display("PASS: RAW gap1 x5");
        end

        if (errors == 0) $display("RESULT: PASS");
        else $display("RESULT: FAIL (%0d checks failed)", errors);

        $finish;
    end

endmodule

