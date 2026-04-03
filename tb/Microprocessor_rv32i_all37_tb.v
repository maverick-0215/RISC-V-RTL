`timescale 1ns/1ps
module Microprocessor_rv32i_all37_tb();

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

    task clear_case;
        integer j;
        begin
            rst = 0;
            instruction = 32'b0;
            for (j = 0; j < 64; j = j + 1) begin
                u_microprocessor0.u_instruction_memory.u_memory.mem[j] = NOP;
                u_microprocessor0.u_data_memory.u_memory.mem[j] = 32'b0;
            end
            repeat (2) @(posedge clk);
        end
    endtask

    task start_case;
        begin
            @(negedge clk);
            rst = 1;
        end
    endtask

    task check_reg;
        input [4:0] reg_id;
        input [31:0] expected;
        input [8*40:1] tag;
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
        input [8*40:1] tag;
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

        // ---------------- R-type (10) ----------------
        clear_case(); u_microprocessor0.u_instruction_memory.u_memory.mem[0] = enc_r(7'b0000000,5'd3,5'd2,3'b000,5'd10,OP_R); start_case(); u_microprocessor0.u_core.u_decodestage.u_regfile0.register[2]=32'd7; u_microprocessor0.u_core.u_decodestage.u_regfile0.register[3]=32'd5; repeat(26) @(posedge clk); check_reg(5'd10,32'd12,"R add");
        clear_case(); u_microprocessor0.u_instruction_memory.u_memory.mem[0] = enc_r(7'b0100000,5'd3,5'd2,3'b000,5'd10,OP_R); start_case(); u_microprocessor0.u_core.u_decodestage.u_regfile0.register[2]=32'd7; u_microprocessor0.u_core.u_decodestage.u_regfile0.register[3]=32'd5; repeat(26) @(posedge clk); check_reg(5'd10,32'd2,"R sub");
        clear_case(); u_microprocessor0.u_instruction_memory.u_memory.mem[0] = enc_r(7'b0000000,5'd3,5'd2,3'b001,5'd10,OP_R); start_case(); u_microprocessor0.u_core.u_decodestage.u_regfile0.register[2]=32'h0000_0003; u_microprocessor0.u_core.u_decodestage.u_regfile0.register[3]=32'd4; repeat(26) @(posedge clk); check_reg(5'd10,32'h0000_0030,"R sll");
        clear_case(); u_microprocessor0.u_instruction_memory.u_memory.mem[0] = enc_r(7'b0000000,5'd3,5'd2,3'b010,5'd10,OP_R); start_case(); u_microprocessor0.u_core.u_decodestage.u_regfile0.register[2]=32'hFFFF_FFFF; u_microprocessor0.u_core.u_decodestage.u_regfile0.register[3]=32'd1; repeat(26) @(posedge clk); check_reg(5'd10,32'd1,"R slt");
        clear_case(); u_microprocessor0.u_instruction_memory.u_memory.mem[0] = enc_r(7'b0000000,5'd3,5'd2,3'b011,5'd10,OP_R); start_case(); u_microprocessor0.u_core.u_decodestage.u_regfile0.register[2]=32'd1; u_microprocessor0.u_core.u_decodestage.u_regfile0.register[3]=32'd2; repeat(26) @(posedge clk); check_reg(5'd10,32'd1,"R sltu");
        clear_case(); u_microprocessor0.u_instruction_memory.u_memory.mem[0] = enc_r(7'b0000000,5'd3,5'd2,3'b100,5'd10,OP_R); start_case(); u_microprocessor0.u_core.u_decodestage.u_regfile0.register[2]=32'hAAAA_0000; u_microprocessor0.u_core.u_decodestage.u_regfile0.register[3]=32'h00FF_00FF; repeat(26) @(posedge clk); check_reg(5'd10,32'hAA55_00FF,"R xor");
        clear_case(); u_microprocessor0.u_instruction_memory.u_memory.mem[0] = enc_r(7'b0000000,5'd3,5'd2,3'b101,5'd10,OP_R); start_case(); u_microprocessor0.u_core.u_decodestage.u_regfile0.register[2]=32'h8000_0000; u_microprocessor0.u_core.u_decodestage.u_regfile0.register[3]=32'd4; repeat(26) @(posedge clk); check_reg(5'd10,32'h0800_0000,"R srl");
        clear_case(); u_microprocessor0.u_instruction_memory.u_memory.mem[0] = enc_r(7'b0100000,5'd3,5'd2,3'b101,5'd10,OP_R); start_case(); u_microprocessor0.u_core.u_decodestage.u_regfile0.register[2]=32'h8000_0000; u_microprocessor0.u_core.u_decodestage.u_regfile0.register[3]=32'd4; repeat(26) @(posedge clk); check_reg(5'd10,32'hF800_0000,"R sra");
        clear_case(); u_microprocessor0.u_instruction_memory.u_memory.mem[0] = enc_r(7'b0000000,5'd3,5'd2,3'b110,5'd10,OP_R); start_case(); u_microprocessor0.u_core.u_decodestage.u_regfile0.register[2]=32'hF000_00F0; u_microprocessor0.u_core.u_decodestage.u_regfile0.register[3]=32'h00FF_0F00; repeat(26) @(posedge clk); check_reg(5'd10,32'hF0FF_0FF0,"R or");
        clear_case(); u_microprocessor0.u_instruction_memory.u_memory.mem[0] = enc_r(7'b0000000,5'd3,5'd2,3'b111,5'd10,OP_R); start_case(); u_microprocessor0.u_core.u_decodestage.u_regfile0.register[2]=32'hF0F0_00FF; u_microprocessor0.u_core.u_decodestage.u_regfile0.register[3]=32'h0FF0_0FF0; repeat(26) @(posedge clk); check_reg(5'd10,32'h00F0_00F0,"R and");

        // ---------------- I-type ALU (9) ----------------
        clear_case(); u_microprocessor0.u_instruction_memory.u_memory.mem[0] = enc_i(12'd9,5'd2,3'b000,5'd10,OP_I); start_case(); u_microprocessor0.u_core.u_decodestage.u_regfile0.register[2]=32'd7; repeat(26) @(posedge clk); check_reg(5'd10,32'd16,"I addi");
        clear_case(); u_microprocessor0.u_instruction_memory.u_memory.mem[0] = enc_i(12'h004,5'd2,3'b001,5'd10,OP_I); start_case(); u_microprocessor0.u_core.u_decodestage.u_regfile0.register[2]=32'h0000_0003; repeat(26) @(posedge clk); check_reg(5'd10,32'h0000_0030,"I slli");
        clear_case(); u_microprocessor0.u_instruction_memory.u_memory.mem[0] = enc_i(12'd1,5'd2,3'b010,5'd10,OP_I); start_case(); u_microprocessor0.u_core.u_decodestage.u_regfile0.register[2]=32'hFFFF_FFFF; repeat(26) @(posedge clk); check_reg(5'd10,32'd1,"I slti");
        clear_case(); u_microprocessor0.u_instruction_memory.u_memory.mem[0] = enc_i(12'd10,5'd2,3'b011,5'd10,OP_I); start_case(); u_microprocessor0.u_core.u_decodestage.u_regfile0.register[2]=32'd5; repeat(26) @(posedge clk); check_reg(5'd10,32'd1,"I sltiu");
        clear_case(); u_microprocessor0.u_instruction_memory.u_memory.mem[0] = enc_i(12'h0F0,5'd2,3'b100,5'd10,OP_I); start_case(); u_microprocessor0.u_core.u_decodestage.u_regfile0.register[2]=32'h0000_00AA; repeat(26) @(posedge clk); check_reg(5'd10,32'h0000_005A,"I xori");
        clear_case(); u_microprocessor0.u_instruction_memory.u_memory.mem[0] = enc_i(12'h004,5'd2,3'b101,5'd10,OP_I); start_case(); u_microprocessor0.u_core.u_decodestage.u_regfile0.register[2]=32'h8000_0000; repeat(26) @(posedge clk); check_reg(5'd10,32'h0800_0000,"I srli");
        clear_case(); u_microprocessor0.u_instruction_memory.u_memory.mem[0] = enc_i(12'h404,5'd2,3'b101,5'd10,OP_I); start_case(); u_microprocessor0.u_core.u_decodestage.u_regfile0.register[2]=32'h8000_0000; repeat(26) @(posedge clk); check_reg(5'd10,32'hF800_0000,"I srai");
        clear_case(); u_microprocessor0.u_instruction_memory.u_memory.mem[0] = enc_i(12'h0F0,5'd2,3'b110,5'd10,OP_I); start_case(); u_microprocessor0.u_core.u_decodestage.u_regfile0.register[2]=32'h0000_000A; repeat(26) @(posedge clk); check_reg(5'd10,32'h0000_00FA,"I ori");
        clear_case(); u_microprocessor0.u_instruction_memory.u_memory.mem[0] = enc_i(12'h0F0,5'd2,3'b111,5'd10,OP_I); start_case(); u_microprocessor0.u_core.u_decodestage.u_regfile0.register[2]=32'h0000_00AA; repeat(26) @(posedge clk); check_reg(5'd10,32'h0000_00A0,"I andi");

        // ---------------- Loads (5) ----------------
        clear_case(); u_microprocessor0.u_instruction_memory.u_memory.mem[0] = enc_i(12'd0,5'd1,3'b000,5'd10,OP_LOAD); u_microprocessor0.u_data_memory.u_memory.mem[0]=32'h80FF_7F01; start_case(); u_microprocessor0.u_core.u_decodestage.u_regfile0.register[1]=32'd0; repeat(28) @(posedge clk); check_reg(5'd10,32'h0000_0001,"L lb");
        clear_case(); u_microprocessor0.u_instruction_memory.u_memory.mem[0] = enc_i(12'd0,5'd1,3'b001,5'd10,OP_LOAD); u_microprocessor0.u_data_memory.u_memory.mem[0]=32'h1234_8001; start_case(); u_microprocessor0.u_core.u_decodestage.u_regfile0.register[1]=32'd0; repeat(28) @(posedge clk); check_reg(5'd10,32'hFFFF_8001,"L lh");
        clear_case(); u_microprocessor0.u_instruction_memory.u_memory.mem[0] = enc_i(12'd0,5'd1,3'b010,5'd10,OP_LOAD); u_microprocessor0.u_data_memory.u_memory.mem[0]=32'hCAFE_BABE; start_case(); u_microprocessor0.u_core.u_decodestage.u_regfile0.register[1]=32'd0; repeat(28) @(posedge clk); check_reg(5'd10,32'hCAFE_BABE,"L lw");
        clear_case(); u_microprocessor0.u_instruction_memory.u_memory.mem[0] = enc_i(12'd3,5'd1,3'b100,5'd10,OP_LOAD); u_microprocessor0.u_data_memory.u_memory.mem[0]=32'h80FF_7F01; start_case(); u_microprocessor0.u_core.u_decodestage.u_regfile0.register[1]=32'd0; repeat(28) @(posedge clk); check_reg(5'd10,32'h0000_0080,"L lbu");
        clear_case(); u_microprocessor0.u_instruction_memory.u_memory.mem[0] = enc_i(12'd2,5'd1,3'b101,5'd10,OP_LOAD); u_microprocessor0.u_data_memory.u_memory.mem[0]=32'h80FF_7F01; start_case(); u_microprocessor0.u_core.u_decodestage.u_regfile0.register[1]=32'd0; repeat(28) @(posedge clk); check_reg(5'd10,32'h0000_80FF,"L lhu");

        // ---------------- Stores (3) ----------------
        clear_case(); u_microprocessor0.u_instruction_memory.u_memory.mem[0] = enc_s(12'd0,5'd2,5'd1,3'b000,OP_S); u_microprocessor0.u_data_memory.u_memory.mem[0]=32'h1122_3344; start_case(); u_microprocessor0.u_core.u_decodestage.u_regfile0.register[1]=32'd0; u_microprocessor0.u_core.u_decodestage.u_regfile0.register[2]=32'hAABB_CCDD; repeat(28) @(posedge clk); check_mem(8'd0,32'h1122_33DD,"S sb");
        clear_case(); u_microprocessor0.u_instruction_memory.u_memory.mem[0] = enc_s(12'd0,5'd2,5'd1,3'b001,OP_S); u_microprocessor0.u_data_memory.u_memory.mem[0]=32'h1122_3344; start_case(); u_microprocessor0.u_core.u_decodestage.u_regfile0.register[1]=32'd0; u_microprocessor0.u_core.u_decodestage.u_regfile0.register[2]=32'hAABB_CCDD; repeat(28) @(posedge clk); check_mem(8'd0,32'h1122_CCDD,"S sh");
        clear_case(); u_microprocessor0.u_instruction_memory.u_memory.mem[0] = enc_s(12'd0,5'd2,5'd1,3'b010,OP_S); u_microprocessor0.u_data_memory.u_memory.mem[0]=32'h1122_3344; start_case(); u_microprocessor0.u_core.u_decodestage.u_regfile0.register[1]=32'd0; u_microprocessor0.u_core.u_decodestage.u_regfile0.register[2]=32'hAABB_CCDD; repeat(28) @(posedge clk); check_mem(8'd0,32'hAABB_CCDD,"S sw");

        // ---------------- Branches (6) ----------------
        clear_case(); u_microprocessor0.u_instruction_memory.u_memory.mem[0]=enc_b(13'd8,5'd3,5'd2,3'b000,OP_B); u_microprocessor0.u_instruction_memory.u_memory.mem[1]=enc_i(12'd1,5'd0,3'b000,5'd20,OP_I); u_microprocessor0.u_instruction_memory.u_memory.mem[2]=enc_i(12'd2,5'd0,3'b000,5'd20,OP_I); start_case(); u_microprocessor0.u_core.u_decodestage.u_regfile0.register[2]=32'd5; u_microprocessor0.u_core.u_decodestage.u_regfile0.register[3]=32'd5; repeat(30) @(posedge clk); check_reg(5'd20,32'd2,"B beq");
        clear_case(); u_microprocessor0.u_instruction_memory.u_memory.mem[0]=enc_b(13'd8,5'd3,5'd2,3'b001,OP_B); u_microprocessor0.u_instruction_memory.u_memory.mem[1]=enc_i(12'd1,5'd0,3'b000,5'd20,OP_I); u_microprocessor0.u_instruction_memory.u_memory.mem[2]=enc_i(12'd2,5'd0,3'b000,5'd20,OP_I); start_case(); u_microprocessor0.u_core.u_decodestage.u_regfile0.register[2]=32'd5; u_microprocessor0.u_core.u_decodestage.u_regfile0.register[3]=32'd6; repeat(30) @(posedge clk); check_reg(5'd20,32'd2,"B bne");
        clear_case(); u_microprocessor0.u_instruction_memory.u_memory.mem[0]=enc_b(13'd8,5'd3,5'd2,3'b100,OP_B); u_microprocessor0.u_instruction_memory.u_memory.mem[1]=enc_i(12'd1,5'd0,3'b000,5'd20,OP_I); u_microprocessor0.u_instruction_memory.u_memory.mem[2]=enc_i(12'd2,5'd0,3'b000,5'd20,OP_I); start_case(); u_microprocessor0.u_core.u_decodestage.u_regfile0.register[2]=32'hFFFF_FFFF; u_microprocessor0.u_core.u_decodestage.u_regfile0.register[3]=32'd1; repeat(30) @(posedge clk); check_reg(5'd20,32'd2,"B blt");
        clear_case(); u_microprocessor0.u_instruction_memory.u_memory.mem[0]=enc_b(13'd8,5'd3,5'd2,3'b101,OP_B); u_microprocessor0.u_instruction_memory.u_memory.mem[1]=enc_i(12'd1,5'd0,3'b000,5'd20,OP_I); u_microprocessor0.u_instruction_memory.u_memory.mem[2]=enc_i(12'd2,5'd0,3'b000,5'd20,OP_I); start_case(); u_microprocessor0.u_core.u_decodestage.u_regfile0.register[2]=32'd5; u_microprocessor0.u_core.u_decodestage.u_regfile0.register[3]=32'd5; repeat(30) @(posedge clk); check_reg(5'd20,32'd2,"B bge");
        clear_case(); u_microprocessor0.u_instruction_memory.u_memory.mem[0]=enc_b(13'd8,5'd3,5'd2,3'b110,OP_B); u_microprocessor0.u_instruction_memory.u_memory.mem[1]=enc_i(12'd1,5'd0,3'b000,5'd20,OP_I); u_microprocessor0.u_instruction_memory.u_memory.mem[2]=enc_i(12'd2,5'd0,3'b000,5'd20,OP_I); start_case(); u_microprocessor0.u_core.u_decodestage.u_regfile0.register[2]=32'd1; u_microprocessor0.u_core.u_decodestage.u_regfile0.register[3]=32'd2; repeat(30) @(posedge clk); check_reg(5'd20,32'd2,"B bltu");
        clear_case(); u_microprocessor0.u_instruction_memory.u_memory.mem[0]=enc_b(13'd8,5'd3,5'd2,3'b111,OP_B); u_microprocessor0.u_instruction_memory.u_memory.mem[1]=enc_i(12'd1,5'd0,3'b000,5'd20,OP_I); u_microprocessor0.u_instruction_memory.u_memory.mem[2]=enc_i(12'd2,5'd0,3'b000,5'd20,OP_I); start_case(); u_microprocessor0.u_core.u_decodestage.u_regfile0.register[2]=32'd2; u_microprocessor0.u_core.u_decodestage.u_regfile0.register[3]=32'd1; repeat(30) @(posedge clk); check_reg(5'd20,32'd2,"B bgeu");

        // ---------------- Jumps (2) ----------------
        clear_case(); u_microprocessor0.u_instruction_memory.u_memory.mem[0]=enc_j(21'd8,5'd5,OP_JAL); u_microprocessor0.u_instruction_memory.u_memory.mem[1]=enc_i(12'd1,5'd0,3'b000,5'd21,OP_I); u_microprocessor0.u_instruction_memory.u_memory.mem[2]=enc_i(12'd2,5'd0,3'b000,5'd21,OP_I); start_case(); repeat(30) @(posedge clk); check_reg(5'd5,32'd4,"J jal link"); check_reg(5'd21,32'd2,"J jal flow");
        clear_case(); u_microprocessor0.u_instruction_memory.u_memory.mem[0]=enc_i(12'd0,5'd1,3'b000,5'd6,OP_JALR); u_microprocessor0.u_instruction_memory.u_memory.mem[1]=enc_i(12'd1,5'd0,3'b000,5'd22,OP_I); u_microprocessor0.u_instruction_memory.u_memory.mem[2]=enc_i(12'd2,5'd0,3'b000,5'd22,OP_I); start_case(); u_microprocessor0.u_core.u_decodestage.u_regfile0.register[1]=32'd8; repeat(30) @(posedge clk); check_reg(5'd6,32'd4,"J jalr link"); check_reg(5'd22,32'd2,"J jalr flow");

        // ---------------- U-type (2) ----------------
        clear_case(); u_microprocessor0.u_instruction_memory.u_memory.mem[0]=enc_u(20'h12345,5'd7,OP_LUI); start_case(); repeat(26) @(posedge clk); check_reg(5'd7,32'h1234_5000,"U lui");
        clear_case(); u_microprocessor0.u_instruction_memory.u_memory.mem[0]=enc_u(20'h12345,5'd7,OP_AUIPC); start_case(); repeat(26) @(posedge clk); check_reg(5'd7,32'h1234_5000,"U auipc");

        if (errors == 0) begin
            $display("RESULT: PASS (RV32I all-37 checks passed)");
        end else begin
            $display("RESULT: FAIL (%0d checks failed)", errors);
        end

        $finish;
    end

endmodule

