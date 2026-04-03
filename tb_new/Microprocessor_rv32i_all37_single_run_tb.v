`timescale 1ns/1ps
module Microprocessor_rv32i_all37_single_run_tb();

    reg clk;
    reg rst;
    reg [31:0] instruction;
    integer errors;
    integer i;

    localparam [6:0] OP_R     = 7'b0110011;
    localparam [6:0] OP_I     = 7'b0010011;
    localparam [6:0] OP_LOAD  = 7'b0000011;
    localparam [6:0] OP_S     = 7'b0100011;
    localparam [6:0] OP_B     = 7'b1100011;
    localparam [6:0] OP_JAL   = 7'b1101111;
    localparam [6:0] OP_JALR  = 7'b1100111;
    localparam [6:0] OP_LUI   = 7'b0110111;
    localparam [6:0] OP_AUIPC = 7'b0010111;
    localparam [31:0] NOP     = 32'h00000013;

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

    function [31:0] enc_u;
        input [19:0] imm;
        input [4:0] rd;
        input [6:0] opcode;
        begin
            enc_u = {imm, rd, opcode};
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

    task check_reg;
        input [4:0] reg_id;
        input [31:0] expected;
        input [8*48:1] tag;
        reg [31:0] actual;
        begin
            actual = u_microprocessor0.u_core.u_decodestage.u_regfile0.register[reg_id];
            if (actual !== expected) begin
                $display("FAIL: %0s expected=%h actual=%h", tag, expected, actual);
                errors = errors + 1;
            end else begin
                $display("PASS: %0s", tag);
            end
        end
    endtask

    task check_mem;
        input [7:0] mem_id;
        input [31:0] expected;
        input [8*48:1] tag;
        reg [31:0] actual;
        begin
            actual = u_microprocessor0.u_data_memory.u_memory.mem[mem_id];
            if (actual !== expected) begin
                $display("FAIL: %0s expected=%h actual=%h", tag, expected, actual);
                errors = errors + 1;
            end else begin
                $display("PASS: %0s", tag);
            end
        end
    endtask

    microprocessor u_microprocessor0 (
        .clk(clk),
        .rst(rst)    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 0;
        instruction = 32'b0;
        errors = 0;

        // No reset between cases: single continuous program covering all 37 RV32I instructions.
        for (i = 0; i < 256; i = i + 1) begin
            u_microprocessor0.u_instruction_memory.u_memory.mem[i] = NOP;
            u_microprocessor0.u_data_memory.u_memory.mem[i] = 32'b0;
        end

        // Program start
        u_microprocessor0.u_instruction_memory.u_memory.mem[0]  = enc_i(12'd16, 5'd0, 3'b000, 5'd1, OP_I);                // addi x1, x0, 16
        u_microprocessor0.u_instruction_memory.u_memory.mem[1]  = enc_i(12'd5,  5'd0, 3'b000, 5'd2, OP_I);                // addi x2, x0, 5
        u_microprocessor0.u_instruction_memory.u_memory.mem[2]  = enc_i(12'd9,  5'd0, 3'b000, 5'd3, OP_I);                // addi x3, x0, 9

        // R-type (10)
        u_microprocessor0.u_instruction_memory.u_memory.mem[3]  = enc_r(7'b0000000, 5'd3,  5'd2,  3'b000, 5'd4,  OP_R);   // add
        u_microprocessor0.u_instruction_memory.u_memory.mem[4]  = enc_r(7'b0100000, 5'd2,  5'd4,  3'b000, 5'd5,  OP_R);   // sub
        u_microprocessor0.u_instruction_memory.u_memory.mem[5]  = enc_r(7'b0000000, 5'd2,  5'd2,  3'b001, 5'd6,  OP_R);   // sll
        u_microprocessor0.u_instruction_memory.u_memory.mem[6]  = enc_r(7'b0000000, 5'd3,  5'd2,  3'b010, 5'd7,  OP_R);   // slt
        u_microprocessor0.u_instruction_memory.u_memory.mem[7]  = enc_r(7'b0000000, 5'd3,  5'd2,  3'b011, 5'd8,  OP_R);   // sltu
        u_microprocessor0.u_instruction_memory.u_memory.mem[8]  = enc_r(7'b0000000, 5'd3,  5'd2,  3'b100, 5'd9,  OP_R);   // xor
        u_microprocessor0.u_instruction_memory.u_memory.mem[9]  = enc_r(7'b0000000, 5'd2,  5'd6,  3'b101, 5'd10, OP_R);   // srl
        u_microprocessor0.u_instruction_memory.u_memory.mem[10] = enc_i(12'hFF0, 5'd0, 3'b000, 5'd14, OP_I);              // addi x14, x0, -16
        u_microprocessor0.u_instruction_memory.u_memory.mem[11] = enc_r(7'b0100000, 5'd2,  5'd14, 3'b101, 5'd11, OP_R);   // sra
        u_microprocessor0.u_instruction_memory.u_memory.mem[12] = enc_r(7'b0000000, 5'd3,  5'd2,  3'b110, 5'd12, OP_R);   // or
        u_microprocessor0.u_instruction_memory.u_memory.mem[13] = enc_r(7'b0000000, 5'd3,  5'd2,  3'b111, 5'd13, OP_R);   // and

        // I-type ALU (9)
        u_microprocessor0.u_instruction_memory.u_memory.mem[14] = enc_i(12'd7,   5'd2, 3'b000, 5'd15, OP_I);              // addi
        u_microprocessor0.u_instruction_memory.u_memory.mem[15] = enc_i(12'h002, 5'd2, 3'b001, 5'd16, OP_I);              // slli
        u_microprocessor0.u_instruction_memory.u_memory.mem[16] = enc_i(12'd6,   5'd2, 3'b010, 5'd17, OP_I);              // slti
        u_microprocessor0.u_instruction_memory.u_memory.mem[17] = enc_i(12'd6,   5'd2, 3'b011, 5'd18, OP_I);              // sltiu
        u_microprocessor0.u_instruction_memory.u_memory.mem[18] = enc_i(12'd3,   5'd2, 3'b100, 5'd19, OP_I);              // xori
        u_microprocessor0.u_instruction_memory.u_memory.mem[19] = enc_i(12'd2,   5'd6, 3'b101, 5'd20, OP_I);              // srli
        u_microprocessor0.u_instruction_memory.u_memory.mem[20] = enc_i(12'h402, 5'd14,3'b101, 5'd21, OP_I);              // srai
        u_microprocessor0.u_instruction_memory.u_memory.mem[21] = enc_i(12'd8,   5'd2, 3'b110, 5'd22, OP_I);              // ori
        u_microprocessor0.u_instruction_memory.u_memory.mem[22] = enc_i(12'd8,   5'd3, 3'b111, 5'd23, OP_I);              // andi

        // U-type (2)
        u_microprocessor0.u_instruction_memory.u_memory.mem[23] = enc_u(20'h12345, 5'd24, OP_LUI);                        // lui
        u_microprocessor0.u_instruction_memory.u_memory.mem[24] = enc_u(20'h00001, 5'd25, OP_AUIPC);                      // auipc

        // Stores (3)
        u_microprocessor0.u_instruction_memory.u_memory.mem[25] = enc_s(12'd0, 5'd4, 5'd1, 3'b010, OP_S);                 // sw x4,0(x1)
        u_microprocessor0.u_instruction_memory.u_memory.mem[26] = enc_s(12'd4, 5'd5, 5'd1, 3'b001, OP_S);                 // sh x5,4(x1)
        u_microprocessor0.u_instruction_memory.u_memory.mem[27] = enc_s(12'd8, 5'd3, 5'd1, 3'b000, OP_S);                 // sb x3,8(x1)

        // Loads (5)
        u_microprocessor0.u_instruction_memory.u_memory.mem[28] = enc_i(12'd8, 5'd1, 3'b000, 5'd26, OP_LOAD);             // lb
        u_microprocessor0.u_instruction_memory.u_memory.mem[29] = enc_i(12'd4, 5'd1, 3'b001, 5'd28, OP_LOAD);             // lh
        u_microprocessor0.u_instruction_memory.u_memory.mem[30] = enc_i(12'd0, 5'd1, 3'b010, 5'd30, OP_LOAD);             // lw
        u_microprocessor0.u_instruction_memory.u_memory.mem[31] = enc_i(12'd8, 5'd1, 3'b100, 5'd27, OP_LOAD);             // lbu
        u_microprocessor0.u_instruction_memory.u_memory.mem[32] = enc_i(12'd4, 5'd1, 3'b101, 5'd29, OP_LOAD);             // lhu

        // Branch and jump witness register
        u_microprocessor0.u_instruction_memory.u_memory.mem[33] = enc_i(12'd0, 5'd0, 3'b000, 5'd31, OP_I);                // addi x31, x0, 0

        // Branches (6) with offset 12 (as requested)
        u_microprocessor0.u_instruction_memory.u_memory.mem[34] = enc_b(13'd12, 5'd2, 5'd2, 3'b000, OP_B);                // beq (taken)
        u_microprocessor0.u_instruction_memory.u_memory.mem[35] = enc_i(12'd1, 5'd31, 3'b000, 5'd31, OP_I);               // skipped
        u_microprocessor0.u_instruction_memory.u_memory.mem[36] = enc_i(12'd1, 5'd31, 3'b000, 5'd31, OP_I);               // skipped

        u_microprocessor0.u_instruction_memory.u_memory.mem[37] = enc_b(13'd12, 5'd3, 5'd2, 3'b001, OP_B);                // bne (taken)
        u_microprocessor0.u_instruction_memory.u_memory.mem[38] = enc_i(12'd1, 5'd31, 3'b000, 5'd31, OP_I);               // skipped
        u_microprocessor0.u_instruction_memory.u_memory.mem[39] = enc_i(12'd1, 5'd31, 3'b000, 5'd31, OP_I);               // skipped

        u_microprocessor0.u_instruction_memory.u_memory.mem[40] = enc_b(13'd12, 5'd3, 5'd2, 3'b100, OP_B);                // blt (taken)
        u_microprocessor0.u_instruction_memory.u_memory.mem[41] = enc_i(12'd1, 5'd31, 3'b000, 5'd31, OP_I);               // skipped
        u_microprocessor0.u_instruction_memory.u_memory.mem[42] = enc_i(12'd1, 5'd31, 3'b000, 5'd31, OP_I);               // skipped

        u_microprocessor0.u_instruction_memory.u_memory.mem[43] = enc_b(13'd12, 5'd2, 5'd3, 3'b101, OP_B);                // bge (taken)
        u_microprocessor0.u_instruction_memory.u_memory.mem[44] = enc_i(12'd1, 5'd31, 3'b000, 5'd31, OP_I);               // skipped
        u_microprocessor0.u_instruction_memory.u_memory.mem[45] = enc_i(12'd1, 5'd31, 3'b000, 5'd31, OP_I);               // skipped

        u_microprocessor0.u_instruction_memory.u_memory.mem[46] = enc_b(13'd12, 5'd3, 5'd2, 3'b110, OP_B);                // bltu (taken)
        u_microprocessor0.u_instruction_memory.u_memory.mem[47] = enc_i(12'd1, 5'd31, 3'b000, 5'd31, OP_I);               // skipped
        u_microprocessor0.u_instruction_memory.u_memory.mem[48] = enc_i(12'd1, 5'd31, 3'b000, 5'd31, OP_I);               // skipped

        u_microprocessor0.u_instruction_memory.u_memory.mem[49] = enc_b(13'd12, 5'd2, 5'd3, 3'b111, OP_B);                // bgeu (taken)
        u_microprocessor0.u_instruction_memory.u_memory.mem[50] = enc_i(12'd1, 5'd31, 3'b000, 5'd31, OP_I);               // skipped
        u_microprocessor0.u_instruction_memory.u_memory.mem[51] = enc_i(12'd1, 5'd31, 3'b000, 5'd31, OP_I);               // skipped

        // Jumps with offset 16 (as requested)
        u_microprocessor0.u_instruction_memory.u_memory.mem[52] = enc_j(21'd16, 5'd6, OP_JAL);                            // jal x6, +16 (to mem[56])
        u_microprocessor0.u_instruction_memory.u_memory.mem[53] = enc_i(12'd1, 5'd31, 3'b000, 5'd31, OP_I);               // skipped
        u_microprocessor0.u_instruction_memory.u_memory.mem[54] = enc_i(12'd1, 5'd31, 3'b000, 5'd31, OP_I);               // skipped
        u_microprocessor0.u_instruction_memory.u_memory.mem[55] = enc_i(12'd1, 5'd31, 3'b000, 5'd31, OP_I);               // skipped

        u_microprocessor0.u_instruction_memory.u_memory.mem[56] = enc_u(20'h00000, 5'd10, OP_AUIPC);                      // auipc x10,0 (for jalr base)
        u_microprocessor0.u_instruction_memory.u_memory.mem[57] = enc_i(12'd16, 5'd10, 3'b000, 5'd7, OP_JALR);            // jalr x7, x10, 16 (to mem[60])
        u_microprocessor0.u_instruction_memory.u_memory.mem[58] = enc_i(12'd1, 5'd31, 3'b000, 5'd31, OP_I);               // skipped
        u_microprocessor0.u_instruction_memory.u_memory.mem[59] = enc_i(12'd1, 5'd31, 3'b000, 5'd31, OP_I);               // skipped

        // Single startup reset only
        repeat (2) @(posedge clk);
        rst = 1;

        // Run once without any reset in between
        repeat (220) @(posedge clk);

        // Key checks (functional + control-flow)
        check_reg(5'd4,  32'd14,        "R add result x4");
        check_reg(5'd5,  32'd9,         "R sub result x5");
        check_reg(5'd11, 32'hFFFF_FFFF, "R sra result x11");
        check_reg(5'd15, 32'd12,        "I addi result x15");
        check_reg(5'd16, 32'd20,        "I slli result x16");
        check_reg(5'd21, 32'hFFFF_FFFC, "I srai result x21");
        check_reg(5'd24, 32'h1234_5000, "U lui result x24");
        check_reg(5'd25, 32'h0000_1060, "U auipc result x25");

        check_mem(8'd4, 32'd14,         "S sw wrote mem[4]");
        check_mem(8'd5, 32'd9,          "S sh wrote mem[5]");
        check_mem(8'd6, 32'd9,          "S sb wrote mem[6]");

        check_reg(5'd26, 32'd9,         "L lb result x26");
        check_reg(5'd27, 32'd9,         "L lbu result x27");
        check_reg(5'd28, 32'd9,         "L lh result x28");
        check_reg(5'd29, 32'd9,         "L lhu result x29");
        check_reg(5'd30, 32'd14,        "L lw result x30");

        check_reg(5'd31, 32'd0,         "All branch/jump skipped fillers");
        check_reg(5'd6,  32'd212,       "J jal link x6");
        check_reg(5'd7,  32'd232,       "J jalr link x7");

        if (errors == 0) begin
            $display("RESULT: PASS (single-run RV32I 37-instruction TB)");
        end else begin
            $display("RESULT: FAIL (%0d checks failed)", errors);
        end

        $finish;
    end

endmodule
