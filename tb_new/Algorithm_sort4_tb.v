`timescale 1ns/1ps
module Algorithm_sort4_tb;
    reg clk, rst;
    integer i, errors;

    localparam [6:0] OP_R = 7'b0110011;
    localparam [6:0] OP_I = 7'b0010011;
    localparam [6:0] OP_S = 7'b0100011;
    localparam [6:0] OP_B = 7'b1100011;
    localparam [6:0] OP_J = 7'b1101111;
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

    task check_reg;
        input [4:0] reg_id;
        input [31:0] expected;
        input [8*48:1] tag;
        reg [31:0] actual;
        begin
            actual = dut.u_core.u_decodestage.u_regfile0.register[reg_id];
            if (actual !== expected) begin
                errors = errors + 1;
                $display("FAIL: %0s expected=%0d actual=%0d", tag, expected, actual);
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
            actual = dut.u_data_memory.u_memory.mem[mem_id];
            if (actual !== expected) begin
                errors = errors + 1;
                $display("FAIL: %0s expected=%0d actual=%0d", tag, expected, actual);
            end else begin
                $display("PASS: %0s", tag);
            end
        end
    endtask

    microprocessor dut(
        .clk(clk),
        .rst(rst)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 0;
        errors = 0;

        for (i = 0; i < 256; i = i + 1) begin
            dut.u_instruction_memory.u_memory.mem[i] = NOP;
            dut.u_data_memory.u_memory.mem[i] = 32'b0;
        end

        // Sort 4 integers [9,3,7,1] ascending using compare-swap passes.
        // Data registers: x10,x11,x12,x13  Temp/flags: x14,x15
        dut.u_instruction_memory.u_memory.mem[0]  = enc_i(12'd9, 5'd0, 3'b000, 5'd10, OP_I);
        dut.u_instruction_memory.u_memory.mem[1]  = enc_i(12'd3, 5'd0, 3'b000, 5'd11, OP_I);
        dut.u_instruction_memory.u_memory.mem[2]  = enc_i(12'd7, 5'd0, 3'b000, 5'd12, OP_I);
        dut.u_instruction_memory.u_memory.mem[3]  = enc_i(12'd1, 5'd0, 3'b000, 5'd13, OP_I);

        // pass1: compare-swap (x10,x11)
        dut.u_instruction_memory.u_memory.mem[4]  = enc_r(7'b0000000, 5'd10, 5'd11, 3'b010, 5'd14, OP_R); // slt x14,x11,x10
        dut.u_instruction_memory.u_memory.mem[5]  = enc_b(13'd16, 5'd0, 5'd14, 3'b000, OP_B);             // beq x14,x0,skip
        dut.u_instruction_memory.u_memory.mem[6]  = enc_i(12'd0,  5'd10, 3'b000, 5'd15, OP_I);            // addi x15,x10,0
        dut.u_instruction_memory.u_memory.mem[7]  = enc_i(12'd0,  5'd11, 3'b000, 5'd10, OP_I);            // addi x10,x11,0
        dut.u_instruction_memory.u_memory.mem[8]  = enc_i(12'd0,  5'd15, 3'b000, 5'd11, OP_I);            // addi x11,x15,0

        // pass1: compare-swap (x11,x12)
        dut.u_instruction_memory.u_memory.mem[9]  = enc_r(7'b0000000, 5'd11, 5'd12, 3'b010, 5'd14, OP_R); // slt x14,x12,x11
        dut.u_instruction_memory.u_memory.mem[10] = enc_b(13'd16, 5'd0, 5'd14, 3'b000, OP_B);
        dut.u_instruction_memory.u_memory.mem[11] = enc_i(12'd0,  5'd11, 3'b000, 5'd15, OP_I);
        dut.u_instruction_memory.u_memory.mem[12] = enc_i(12'd0,  5'd12, 3'b000, 5'd11, OP_I);
        dut.u_instruction_memory.u_memory.mem[13] = enc_i(12'd0,  5'd15, 3'b000, 5'd12, OP_I);

        // pass1: compare-swap (x12,x13)
        dut.u_instruction_memory.u_memory.mem[14] = enc_r(7'b0000000, 5'd12, 5'd13, 3'b010, 5'd14, OP_R); // slt x14,x13,x12
        dut.u_instruction_memory.u_memory.mem[15] = enc_b(13'd16, 5'd0, 5'd14, 3'b000, OP_B);
        dut.u_instruction_memory.u_memory.mem[16] = enc_i(12'd0,  5'd12, 3'b000, 5'd15, OP_I);
        dut.u_instruction_memory.u_memory.mem[17] = enc_i(12'd0,  5'd13, 3'b000, 5'd12, OP_I);
        dut.u_instruction_memory.u_memory.mem[18] = enc_i(12'd0,  5'd15, 3'b000, 5'd13, OP_I);

        // pass2: compare-swap (x10,x11)
        dut.u_instruction_memory.u_memory.mem[19] = enc_r(7'b0000000, 5'd10, 5'd11, 3'b010, 5'd14, OP_R);
        dut.u_instruction_memory.u_memory.mem[20] = enc_b(13'd16, 5'd0, 5'd14, 3'b000, OP_B);
        dut.u_instruction_memory.u_memory.mem[21] = enc_i(12'd0,  5'd10, 3'b000, 5'd15, OP_I);
        dut.u_instruction_memory.u_memory.mem[22] = enc_i(12'd0,  5'd11, 3'b000, 5'd10, OP_I);
        dut.u_instruction_memory.u_memory.mem[23] = enc_i(12'd0,  5'd15, 3'b000, 5'd11, OP_I);

        // pass2: compare-swap (x11,x12)
        dut.u_instruction_memory.u_memory.mem[24] = enc_r(7'b0000000, 5'd11, 5'd12, 3'b010, 5'd14, OP_R);
        dut.u_instruction_memory.u_memory.mem[25] = enc_b(13'd16, 5'd0, 5'd14, 3'b000, OP_B);
        dut.u_instruction_memory.u_memory.mem[26] = enc_i(12'd0,  5'd11, 3'b000, 5'd15, OP_I);
        dut.u_instruction_memory.u_memory.mem[27] = enc_i(12'd0,  5'd12, 3'b000, 5'd11, OP_I);
        dut.u_instruction_memory.u_memory.mem[28] = enc_i(12'd0,  5'd15, 3'b000, 5'd12, OP_I);

        // pass3: compare-swap (x10,x11)
        dut.u_instruction_memory.u_memory.mem[29] = enc_r(7'b0000000, 5'd10, 5'd11, 3'b010, 5'd14, OP_R);
        dut.u_instruction_memory.u_memory.mem[30] = enc_b(13'd16, 5'd0, 5'd14, 3'b000, OP_B);
        dut.u_instruction_memory.u_memory.mem[31] = enc_i(12'd0,  5'd10, 3'b000, 5'd15, OP_I);
        dut.u_instruction_memory.u_memory.mem[32] = enc_i(12'd0,  5'd11, 3'b000, 5'd10, OP_I);
        dut.u_instruction_memory.u_memory.mem[33] = enc_i(12'd0,  5'd15, 3'b000, 5'd11, OP_I);

        // store sorted results to memory
        dut.u_instruction_memory.u_memory.mem[34] = enc_s(12'd0,  5'd10, 5'd0, 3'b010, OP_S);
        dut.u_instruction_memory.u_memory.mem[35] = enc_s(12'd4,  5'd11, 5'd0, 3'b010, OP_S);
        dut.u_instruction_memory.u_memory.mem[36] = enc_s(12'd8,  5'd12, 5'd0, 3'b010, OP_S);
        dut.u_instruction_memory.u_memory.mem[37] = enc_s(12'd12, 5'd13, 5'd0, 3'b010, OP_S);
        dut.u_instruction_memory.u_memory.mem[38] = enc_j(21'd0,  5'd0, OP_J); // halt

        repeat (2) @(posedge clk);
        rst = 1;

        repeat (420) @(posedge clk);

        check_reg(5'd10, 32'd1, "sorted x10");
        check_reg(5'd11, 32'd3, "sorted x11");
        check_reg(5'd12, 32'd7, "sorted x12");
        check_reg(5'd13, 32'd9, "sorted x13");

        check_mem(8'd0, 32'd1, "mem[0] sorted value");
        check_mem(8'd1, 32'd3, "mem[1] sorted value");
        check_mem(8'd2, 32'd7, "mem[2] sorted value");
        check_mem(8'd3, 32'd9, "mem[3] sorted value");

        if (errors == 0) begin
            $display("RESULT: PASS");
        end else begin
            $display("RESULT: FAIL (%0d)", errors);
        end

        $finish;
    end
endmodule
/*
Algorithm Documentation:
- Algorithm: 4-element ascending sort via compare-swap passes (bubble-sort style).
- Input: [9,3,7,1] in x10..x13
- Instruction Sequence:
    1) addi x10, x0, 9
    2) addi x11, x0, 3
    3) addi x12, x0, 7
    4) addi x13, x0, 1
    5) Repeated compare-swap blocks using:
         - slt x14, right, left
         - beq x14, x0, skip_swap
         - addi moves through x15 temp
    6) Pass order:
         - pass1: (x10,x11), (x11,x12), (x12,x13)
         - pass2: (x10,x11), (x11,x12)
         - pass3: (x10,x11)
    7) sw x10,0(x0), sw x11,4(x0), sw x12,8(x0), sw x13,12(x0)
    8) jal x0,0 ; halt
- Expected Results:
    - Registers: x10=1, x11=3, x12=7, x13=9
    - Memory words: mem[0]=1, mem[1]=3, mem[2]=7, mem[3]=9
*/
