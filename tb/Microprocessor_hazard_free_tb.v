`timescale 1ns/1ps
module Microprocessor_hazard_free_tb();

    reg clk;
    reg rst;
    reg [31:0] instruction;
    integer errors;

    localparam [6:0] OP_R      = 7'b0110011;
    localparam [6:0] OP_I      = 7'b0010011;
    localparam [6:0] OP_S      = 7'b0100011;
    localparam [6:0] OP_B      = 7'b1100011;
    localparam [6:0] OP_JAL    = 7'b1101111;
    localparam [6:0] OP_LUI    = 7'b0110111;

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

    function [31:0] enc_u;
        input [19:0] imm;
        input [4:0] rd;
        input [6:0] opcode;
        begin
            enc_u = {imm, rd, opcode};
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

        // Program with instruction types R, I, S, B, J, U and inserted spacing to avoid hazards.
        u_microprocessor0.u_instruction_memory.u_memory.mem[0]  = enc_r(7'b0000000, 5'd3, 5'd2, 3'b000, 5'd4, OP_R);      // add  x4, x2, x3
        u_microprocessor0.u_instruction_memory.u_memory.mem[2]  = 32'h00000013;                                            // nop
        u_microprocessor0.u_instruction_memory.u_memory.mem[1]  = enc_i(12'h00F, 5'd3, 3'b111, 5'd6, OP_I);               // andi x6, x3, 15
        u_microprocessor0.u_instruction_memory.u_memory.mem[3]  = enc_i(12'h001, 5'd2, 3'b000, 5'd10, OP_I);              // addi x10, x2, 1
        u_microprocessor0.u_instruction_memory.u_memory.mem[4]  = 32'h00000013;                                            // nop
        u_microprocessor0.u_instruction_memory.u_memory.mem[5]  = enc_s(12'h000, 5'd4, 5'd1, 3'b010, OP_S);               // sw   x4, 0(x1)
        u_microprocessor0.u_instruction_memory.u_memory.mem[6]  = enc_u(20'h12345, 5'd9, OP_LUI);                         // lui  x9, 0x12345
        u_microprocessor0.u_instruction_memory.u_memory.mem[7]  = 32'h00000013;                                            // nop
        u_microprocessor0.u_instruction_memory.u_memory.mem[8]  = 32'h00000013;                                            // nop
        u_microprocessor0.u_instruction_memory.u_memory.mem[9]  = 32'h00000013;                                            // nop
        u_microprocessor0.u_instruction_memory.u_memory.mem[10] = enc_s(12'd4, 5'd9, 5'd1, 3'b010, OP_S);                 // sw   x9, 4(x1)
        u_microprocessor0.u_instruction_memory.u_memory.mem[11] = enc_b(13'd8, 5'd2, 5'd2, 3'b000, OP_B);                 // beq  x2, x2, +8
        u_microprocessor0.u_instruction_memory.u_memory.mem[12] = enc_i(12'd99, 5'd0, 3'b000, 5'd7, OP_I);                // addi x7, x0, 99 (skip)
        u_microprocessor0.u_instruction_memory.u_memory.mem[13] = enc_j(21'd8, 5'd0, OP_JAL);                             // jal  x0, +8
        u_microprocessor0.u_instruction_memory.u_memory.mem[14] = enc_i(12'd55, 5'd0, 3'b000, 5'd8, OP_I);                // addi x8, x0, 55 (skip)
        u_microprocessor0.u_instruction_memory.u_memory.mem[15] = 32'h00000013;                                            // nop

        // Data memory init values to observe writes clearly.
        u_microprocessor0.u_data_memory.u_memory.mem[0] = 32'hAAAAAAAA;
        u_microprocessor0.u_data_memory.u_memory.mem[1] = 32'hBBBBBBBB;

        #20;
        rst = 1;

        // Register init after reset release to keep sequence hazard-free.
        #1;
        u_microprocessor0.u_core.u_decodestage.u_regfile0.register[1] = 32'h00000000; // base address
        u_microprocessor0.u_core.u_decodestage.u_regfile0.register[2] = 32'd10;
        u_microprocessor0.u_core.u_decodestage.u_regfile0.register[3] = 32'd20;

        #420;

        if (u_microprocessor0.u_data_memory.u_memory.mem[0] !== 32'd30) begin
            $display("FAIL: store from R-type result wrong, mem[0]=%h", u_microprocessor0.u_data_memory.u_memory.mem[0]);
            errors = errors + 1;
        end else begin
            $display("PASS: R->S flow (mem[0]=30)");
        end

        if (u_microprocessor0.u_core.u_decodestage.u_regfile0.register[6] !== 32'd4) begin
            $display("FAIL: I-type ANDI result wrong, x6=%h", u_microprocessor0.u_core.u_decodestage.u_regfile0.register[6]);
            errors = errors + 1;
        end else begin
            $display("PASS: I-type ANDI flow (x6=4)");
        end

        if (u_microprocessor0.u_core.u_decodestage.u_regfile0.register[10] !== 32'd11) begin
            $display("FAIL: I-type ADDI result wrong, x10=%h", u_microprocessor0.u_core.u_decodestage.u_regfile0.register[10]);
            errors = errors + 1;
        end else begin
            $display("PASS: I-type ADDI flow (x10=11)");
        end

        if (u_microprocessor0.u_core.u_decodestage.u_regfile0.register[7] !== 32'd0) begin
            $display("FAIL: B-type BEQ did not skip instruction, x7=%h", u_microprocessor0.u_core.u_decodestage.u_regfile0.register[7]);
            errors = errors + 1;
        end else begin
            $display("PASS: B-type BEQ skip flow");
        end

        if (u_microprocessor0.u_core.u_decodestage.u_regfile0.register[8] !== 32'd0) begin
            $display("FAIL: J-type JAL did not skip instruction, x8=%h", u_microprocessor0.u_core.u_decodestage.u_regfile0.register[8]);
            errors = errors + 1;
        end else begin
            $display("PASS: J-type JAL skip flow");
        end

        if (u_microprocessor0.u_core.u_decodestage.u_regfile0.register[9] !== 32'h12345000) begin
            $display("FAIL: U-type LUI register write wrong, x9=%h", u_microprocessor0.u_core.u_decodestage.u_regfile0.register[9]);
            errors = errors + 1;
        end else begin
            $display("PASS: U-type LUI register flow (x9=0x12345000)");
        end

        if (u_microprocessor0.u_data_memory.u_memory.mem[1] !== 32'h12345000) begin
            $display("FAIL: U-type LUI -> S-type store wrong, mem[1]=%h", u_microprocessor0.u_data_memory.u_memory.mem[1]);
            errors = errors + 1;
        end else begin
            $display("PASS: U->S flow (mem[1]=0x12345000)");
        end

        if (errors == 0) begin
            $display("RESULT: PASS (hazard-free mixed-type flow checks passed)");
        end else begin
            $display("RESULT: FAIL (%0d checks failed)", errors);
        end

        $finish;
    end

endmodule
