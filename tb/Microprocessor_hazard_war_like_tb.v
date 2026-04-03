`timescale 1ns/1ps
module Microprocessor_hazard_war_like_tb();

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

        // WAR-like ordering check (in-order core should keep correctness):
        // addi x5, x0, 9
        // add  x6, x5, x2   <- should read old x5=9
        // addi x5, x0, 1    <- younger write to x5
        u_microprocessor0.u_instruction_memory.u_memory.mem[0] = enc_i(12'd9, 5'd0, 3'b000, 5'd5, OP_I);
        u_microprocessor0.u_instruction_memory.u_memory.mem[1] = enc_r(7'b0000000, 5'd2, 5'd5, 3'b000, 5'd6, OP_R);
        u_microprocessor0.u_instruction_memory.u_memory.mem[2] = enc_i(12'd1, 5'd0, 3'b000, 5'd5, OP_I);

        #20;
        rst = 1;

        #1;
        u_microprocessor0.u_core.u_decodestage.u_regfile0.register[2] = 32'd3;

        #240;

        if (u_microprocessor0.u_core.u_decodestage.u_regfile0.register[6] !== 32'd12) begin
            $display("FAIL: WAR-like read ordering wrong, x6=%h", u_microprocessor0.u_core.u_decodestage.u_regfile0.register[6]);
            errors = errors + 1;
        end else begin
            $display("PASS: WAR-like read ordering x6");
        end

        if (u_microprocessor0.u_core.u_decodestage.u_regfile0.register[5] !== 32'd1) begin
            $display("FAIL: WAR-like final writer wrong, x5=%h", u_microprocessor0.u_core.u_decodestage.u_regfile0.register[5]);
            errors = errors + 1;
        end else begin
            $display("PASS: WAR-like final writer x5");
        end

        if (errors == 0) $display("RESULT: PASS");
        else $display("RESULT: FAIL (%0d checks failed)", errors);

        $finish;
    end

endmodule

