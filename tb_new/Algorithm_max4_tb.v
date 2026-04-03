`timescale 1ns/1ps
module Algorithm_max4_tb;
    reg clk, rst;
    integer i, errors;

    localparam [6:0] OP_I = 7'b0010011;
    localparam [6:0] OP_S = 7'b0100011;
    localparam [6:0] OP_R = 7'b0110011;
    localparam [6:0] OP_B = 7'b1100011;
    localparam [6:0] OP_J = 7'b1101111;
    localparam [31:0] NOP = 32'h00000013;

    function [31:0] enc_i;
        input [11:0] imm; input [4:0] rs1; input [2:0] funct3; input [4:0] rd; input [6:0] opcode;
        begin enc_i = {imm, rs1, funct3, rd, opcode}; end
    endfunction
    function [31:0] enc_s;
        input [11:0] imm; input [4:0] rs2; input [4:0] rs1; input [2:0] funct3; input [6:0] opcode;
        begin enc_s = {imm[11:5], rs2, rs1, funct3, imm[4:0], opcode}; end
    endfunction
    function [31:0] enc_r;
        input [6:0] funct7; input [4:0] rs2; input [4:0] rs1; input [2:0] funct3; input [4:0] rd; input [6:0] opcode;
        begin enc_r = {funct7, rs2, rs1, funct3, rd, opcode}; end
    endfunction
    function [31:0] enc_b;
        input [12:0] imm; input [4:0] rs2; input [4:0] rs1; input [2:0] funct3; input [6:0] opcode;
        begin enc_b = {imm[12], imm[10:5], rs2, rs1, funct3, imm[4:1], imm[11], opcode}; end
    endfunction
    function [31:0] enc_j;
        input [20:0] imm; input [4:0] rd; input [6:0] opcode;
        begin enc_j = {imm[20], imm[10:1], imm[11], imm[19:12], rd, opcode}; end
    endfunction

    task check_reg;
        input [4:0] reg_id; input [31:0] expected; input [8*48:1] tag;
        reg [31:0] actual;
        begin
            actual = dut.u_core.u_decodestage.u_regfile0.register[reg_id];
            if (actual !== expected) begin errors = errors + 1; $display("FAIL: %0s expected=%0d actual=%0d", tag, expected, actual); end
            else $display("PASS: %0s", tag);
        end
    endtask

    task check_mem;
        input [7:0] mem_id; input [31:0] expected; input [8*48:1] tag;
        reg [31:0] actual;
        begin
            actual = dut.u_data_memory.u_memory.mem[mem_id];
            if (actual !== expected) begin errors = errors + 1; $display("FAIL: %0s expected=%0d actual=%0d", tag, expected, actual); end
            else $display("PASS: %0s", tag);
        end
    endtask

    microprocessor dut(.clk(clk), .rst(rst));
    always #5 clk = ~clk;

    initial begin
        clk = 0; rst = 0; errors = 0;
        for (i = 0; i < 256; i = i + 1) begin
            dut.u_instruction_memory.u_memory.mem[i] = NOP;
            dut.u_data_memory.u_memory.mem[i] = 32'b0;
        end

        // Find max of four values [14,27,9,31] -> 31
        // x10..x13 data, x14=max, x15=temp
        dut.u_instruction_memory.u_memory.mem[0]  = enc_i(12'd14, 5'd0, 3'b000, 5'd10, OP_I);
        dut.u_instruction_memory.u_memory.mem[1]  = enc_i(12'd27, 5'd0, 3'b000, 5'd11, OP_I);
        dut.u_instruction_memory.u_memory.mem[2]  = enc_i(12'd9,  5'd0, 3'b000, 5'd12, OP_I);
        dut.u_instruction_memory.u_memory.mem[3]  = enc_i(12'd31, 5'd0, 3'b000, 5'd13, OP_I);
        dut.u_instruction_memory.u_memory.mem[4]  = enc_i(12'd0,  5'd10,3'b000, 5'd14, OP_I); // max=x10

        // if max < x11 then max=x11
        dut.u_instruction_memory.u_memory.mem[5]  = enc_b(13'd8, 5'd11, 5'd14, 3'b100, OP_B);
        dut.u_instruction_memory.u_memory.mem[6]  = enc_j(21'd8, 5'd0, OP_J);
        dut.u_instruction_memory.u_memory.mem[7]  = enc_i(12'd0, 5'd11,3'b000, 5'd14, OP_I);

        // if max < x12 then max=x12
        dut.u_instruction_memory.u_memory.mem[8]  = enc_b(13'd8, 5'd12, 5'd14, 3'b100, OP_B);
        dut.u_instruction_memory.u_memory.mem[9]  = enc_j(21'd8, 5'd0, OP_J);
        dut.u_instruction_memory.u_memory.mem[10] = enc_i(12'd0, 5'd12,3'b000, 5'd14, OP_I);

        // if max < x13 then max=x13
        dut.u_instruction_memory.u_memory.mem[11] = enc_b(13'd8, 5'd13, 5'd14, 3'b100, OP_B);
        dut.u_instruction_memory.u_memory.mem[12] = enc_j(21'd8, 5'd0, OP_J);
        dut.u_instruction_memory.u_memory.mem[13] = enc_i(12'd0, 5'd13,3'b000, 5'd14, OP_I);

        dut.u_instruction_memory.u_memory.mem[14] = enc_s(12'd8, 5'd14,5'd0, 3'b010, OP_S); // sw max,8(x0)
        dut.u_instruction_memory.u_memory.mem[15] = enc_j(21'd0, 5'd0, OP_J);               // halt

        repeat (2) @(posedge clk); rst = 1;
        repeat (180) @(posedge clk);

        check_reg(5'd14, 32'd31, "max in x14");
        check_mem(8'd2, 32'd31, "stored max in mem[2]");

        if (errors == 0) $display("RESULT: PASS");
        else $display("RESULT: FAIL (%0d)", errors);
        $finish;
    end
endmodule
/*
Algorithm Documentation:
- Algorithm: Maximum of 4 values
- Input: [14,27,9,31] in x10..x13
- Instruction Sequence:
    1) addi x10, x0, 14
    2) addi x11, x0, 27
    3) addi x12, x0, 9
    4) addi x13, x0, 31
    5) addi x14, x10, 0     ; max = first element
    6) For each candidate (x11, x12, x13):
         - blt  x14, candidate, update
         - jal  x0, next
         - addi x14, candidate, 0
    7) sw x14, 8(x0)
    8) jal x0, 0 ; halt
- Expected Results:
    - x14 = 31
    - mem[2] = 31
*/
