`timescale 1ns/1ps
module Microprocessor_btype_single_inst_tb();

    reg clk;
    reg rst;
    reg [31:0] instruction;
    integer i;
    integer errors;

    localparam [6:0] OP_B = 7'b1100011;
    localparam [6:0] OP_I = 7'b0010011;
    localparam [31:0] NOP = 32'h00000013; // addi x0, x0, 0

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

        // Fill instruction memory with NOPs first.
        for (i = 0; i < 16; i = i + 1) begin
            u_microprocessor0.u_instruction_memory.u_memory.mem[i] = NOP;
        end

        // --------------------------------------------------------------------
        // B-TYPE SINGLE-INSTRUCTION SELECTOR
        // Keep exactly one line active at mem[0].
        // Comment the one you already checked and uncomment the next one.
        // --------------------------------------------------------------------

        // ACTIVE TEST (default): beq x2, x3, +8 (taken when x2==x3)
        // Branch target is mem[2], so EXPECT x4=2.
        u_microprocessor0.u_instruction_memory.u_memory.mem[0] = enc_b(13'd8, 5'd3, 5'd2, 3'b000, OP_B);

        // u_microprocessor0.u_instruction_memory.u_memory.mem[0] = enc_b(13'd8, 5'd3, 5'd2, 3'b001, OP_B); // bne x2,x3,+8
        // u_microprocessor0.u_instruction_memory.u_memory.mem[0] = enc_b(13'd8, 5'd3, 5'd2, 3'b100, OP_B); // blt x2,x3,+8
        // u_microprocessor0.u_instruction_memory.u_memory.mem[0] = enc_b(13'd8, 5'd3, 5'd2, 3'b101, OP_B); // bge x2,x3,+8
        // u_microprocessor0.u_instruction_memory.u_memory.mem[0] = enc_b(13'd8, 5'd3, 5'd2, 3'b110, OP_B); // bltu x2,x3,+8
        // u_microprocessor0.u_instruction_memory.u_memory.mem[0] = enc_b(13'd8, 5'd3, 5'd2, 3'b111, OP_B); // bgeu x2,x3,+8

        // Marker instructions for branch behavior.
        u_microprocessor0.u_instruction_memory.u_memory.mem[1] = enc_i(12'd1, 5'd0, 3'b000, 5'd4, OP_I); // addi x4, x0, 1
        u_microprocessor0.u_instruction_memory.u_memory.mem[2] = enc_i(12'd2, 5'd0, 3'b000, 5'd4, OP_I); // addi x4, x0, 2

        #20;
        rst = 1;

        #1;
        u_microprocessor0.u_core.u_decodestage.u_regfile0.register[2] = 32'd10;
        u_microprocessor0.u_core.u_decodestage.u_regfile0.register[3] = 32'd10;
        u_microprocessor0.u_core.u_decodestage.u_regfile0.register[4] = 32'd0;

        // Alternative init suggestions for other branch variants:
        // bne not-taken check: keep x2=x3=10 -> EXPECT x4=1
        // blt taken check: set x2=10, x3=20 -> EXPECT x4=2
        // bge taken check: set x2=20, x3=10 -> EXPECT x4=2
        // bltu/bgeu: use positive values similarly

        #220;

        // --------------------------------------------------------------------
        // RESULT CHECKS
        // Keep one check active matching the selected instruction above.
        // --------------------------------------------------------------------

        // ACTIVE CHECK (default beq taken): EXPECT x4 = 2
        if (u_microprocessor0.u_core.u_decodestage.u_regfile0.register[4] !== 32'd2) begin
            $display("FAIL: beq x2,x3,+8 wrong, x4=%h", u_microprocessor0.u_core.u_decodestage.u_regfile0.register[4]);
            errors = errors + 1;
        end else begin
            $display("PASS: beq x2,x3,+8");
        end

        // if (u_microprocessor0.u_core.u_decodestage.u_regfile0.register[4] !== 32'd1) begin
        //     $display("FAIL: bne x2,x3,+8 wrong, x4=%h", u_microprocessor0.u_core.u_decodestage.u_regfile0.register[4]);
        //     errors = errors + 1;
        // end else begin
        //     $display("PASS: bne x2,x3,+8");
        // end

        // if (u_microprocessor0.u_core.u_decodestage.u_regfile0.register[4] !== 32'd2) begin
        //     $display("FAIL: blt x2,x3,+8 wrong, x4=%h", u_microprocessor0.u_core.u_decodestage.u_regfile0.register[4]);
        //     errors = errors + 1;
        // end else begin
        //     $display("PASS: blt x2,x3,+8");
        // end

        // if (u_microprocessor0.u_core.u_decodestage.u_regfile0.register[4] !== 32'd2) begin
        //     $display("FAIL: bge x2,x3,+8 wrong, x4=%h", u_microprocessor0.u_core.u_decodestage.u_regfile0.register[4]);
        //     errors = errors + 1;
        // end else begin
        //     $display("PASS: bge x2,x3,+8");
        // end

        // if (u_microprocessor0.u_core.u_decodestage.u_regfile0.register[4] !== 32'd2) begin
        //     $display("FAIL: bltu x2,x3,+8 wrong, x4=%h", u_microprocessor0.u_core.u_decodestage.u_regfile0.register[4]);
        //     errors = errors + 1;
        // end else begin
        //     $display("PASS: bltu x2,x3,+8");
        // end

        // if (u_microprocessor0.u_core.u_decodestage.u_regfile0.register[4] !== 32'd2) begin
        //     $display("FAIL: bgeu x2,x3,+8 wrong, x4=%h", u_microprocessor0.u_core.u_decodestage.u_regfile0.register[4]);
        //     errors = errors + 1;
        // end else begin
        //     $display("PASS: bgeu x2,x3,+8");
        // end

        if (errors == 0) begin
            $display("RESULT: PASS");
        end else begin
            $display("RESULT: FAIL (%0d checks failed)", errors);
        end

        $finish;
    end

endmodule

