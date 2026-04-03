`timescale 1ns/1ps
module Microprocessor_hazard_stress_tb();

    reg clk;
    reg rst;
    reg [31:0] instruction;
    integer errors;

    localparam [6:0] OP_R   = 7'b0110011;
    localparam [6:0] OP_I   = 7'b0010011;
    localparam [6:0] OP_S   = 7'b0100011;
    localparam [6:0] OP_B   = 7'b1100011;
    localparam [6:0] OP_JAL = 7'b1101111;

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

    function [31:0] enc_s;
        input [11:0] imm;
        input [4:0] rs2;
        input [4:0] rs1;
        input [2:0] funct3;
        input [6:0] opcode;
        begin
            enc_s = {imm[11:5], rs2, rs1, funct3, imm[4:0], opcode};
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

    function [31:0] enc_j;
        input [20:0] imm;
        input [4:0] rd;
        input [6:0] opcode;
        begin
            enc_j = {imm[20], imm[10:1], imm[11], imm[19:12], rd, opcode};
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

        // Hazard stress program: no NOPs, intentional RAW and control hazards.
        u_microprocessor0.u_instruction_memory.u_memory.mem[0]  = enc_i(12'd10, 5'd0, 3'b000, 5'd2, OP_I);              // addi x2, x0, 10
        u_microprocessor0.u_instruction_memory.u_memory.mem[1]  = enc_i(12'd20, 5'd0, 3'b000, 5'd3, OP_I);              // addi x3, x0, 20
        u_microprocessor0.u_instruction_memory.u_memory.mem[2]  = enc_r(7'b0000000, 5'd3, 5'd2, 3'b000, 5'd4, OP_R);    // add  x4, x2, x3 (RAW) X4 = 30
        u_microprocessor0.u_instruction_memory.u_memory.mem[3]  = enc_r(7'b0000000, 5'd2, 5'd4, 3'b000, 5'd5, OP_R);    // add  x5, x4, x2 (RAW) X5 = 40
        u_microprocessor0.u_instruction_memory.u_memory.mem[4]  = enc_s(12'd0, 5'd5, 5'd1, 3'b010, OP_S);               // sw   x5, 0(x1)
        u_microprocessor0.u_instruction_memory.u_memory.mem[5]  = enc_b(13'd8, 5'd2, 5'd2, 3'b000, OP_B);               // beq  x2, x2, +8 (taken)
        u_microprocessor0.u_instruction_memory.u_memory.mem[6]  = enc_i(12'd0, 5'd0, 3'b000, 5'd6, OP_I);               // addi x6, x0, 0 (flush)
        u_microprocessor0.u_instruction_memory.u_memory.mem[7]  = enc_i(12'd1, 5'd0, 3'b000, 5'd6, OP_I);               // addi x6, x0, 1 (target)
        u_microprocessor0.u_instruction_memory.u_memory.mem[8]  = enc_j(21'd8, 5'd9, OP_JAL);                           // jal  x9, +8
        u_microprocessor0.u_instruction_memory.u_memory.mem[9]  = enc_i(12'd0, 5'd0, 3'b000, 5'd7, OP_I);               // addi x7, x0, 0 (flush)
        u_microprocessor0.u_instruction_memory.u_memory.mem[10] = enc_i(12'd2, 5'd0, 3'b000, 5'd7, OP_I);               // addi x7, x0, 2 (target)
        u_microprocessor0.u_instruction_memory.u_memory.mem[11] = enc_i(12'd1, 5'd0, 3'b000, 5'd10, OP_I);              // addi x10, x0, 1
        u_microprocessor0.u_instruction_memory.u_memory.mem[12] = enc_i(12'd2, 5'd0, 3'b000, 5'd11, OP_I);              // addi x11, x0, 2
        u_microprocessor0.u_instruction_memory.u_memory.mem[13] = enc_r(7'b0000000, 5'd11, 5'd10, 3'b000, 5'd12, OP_R); // add  x12, x10, x11 = 3

        u_microprocessor0.u_data_memory.u_memory.mem[0] = 32'hDEADBEEF;

        #20;
        rst = 1;

        #1;
        u_microprocessor0.u_core.u_decodestage.u_regfile0.register[1] = 32'h00000000; // base for stores

        #620;

        if (u_microprocessor0.u_core.u_decodestage.u_regfile0.register[4] !== 32'd30) begin
            $display("FAIL: RAW add result wrong, x4=%h", u_microprocessor0.u_core.u_decodestage.u_regfile0.register[4]);
            errors = errors + 1;
        end else begin
            $display("PASS: RAW #1 handled (x4=30)");
        end

        if (u_microprocessor0.u_core.u_decodestage.u_regfile0.register[5] !== 32'd40) begin
            $display("FAIL: RAW chained add result wrong, x5=%h", u_microprocessor0.u_core.u_decodestage.u_regfile0.register[5]);
            errors = errors + 1;
        end else begin
            $display("PASS: RAW #2 handled (x5=40)");
        end

        if (u_microprocessor0.u_data_memory.u_memory.mem[0] !== 32'd40) begin
            $display("FAIL: Store after RAW wrong, mem[0]=%h", u_microprocessor0.u_data_memory.u_memory.mem[0]);
            errors = errors + 1;
        end else begin
            $display("PASS: Store flow correct after RAW");
        end

        if (u_microprocessor0.u_core.u_decodestage.u_regfile0.register[6] !== 32'd1) begin
            $display("FAIL: Branch control hazard handling wrong, x6=%h", u_microprocessor0.u_core.u_decodestage.u_regfile0.register[6]);
            errors = errors + 1;
        end else begin
            $display("PASS: Branch flush handled");
        end

        if (u_microprocessor0.u_core.u_decodestage.u_regfile0.register[7] !== 32'd2) begin
            $display("FAIL: Jump control hazard handling wrong, x7=%h", u_microprocessor0.u_core.u_decodestage.u_regfile0.register[7]);
            errors = errors + 1;
        end else begin
            $display("PASS: Jump flush handled");
        end

        if (u_microprocessor0.u_core.u_decodestage.u_regfile0.register[12] !== 32'd3) begin
            $display("FAIL: Post-control RAW result wrong, x12=%h", u_microprocessor0.u_core.u_decodestage.u_regfile0.register[12]);
            errors = errors + 1;
        end else begin
            $display("PASS: Post-control RAW handled (x12=3)");
        end

        if (errors == 0) begin
            $display("RESULT: PASS (hazard stress checks passed)");
        end else begin
            $display("RESULT: FAIL (%0d checks failed)", errors);
        end

        $finish;
    end

endmodule
