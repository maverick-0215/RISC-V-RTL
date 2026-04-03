`timescale 1ns/1ps
module Algorithm_gcd_tb;
    reg clk, rst;
    integer i, errors;

    localparam [6:0] OP_R = 7'b0110011;
    localparam [6:0] OP_I = 7'b0010011;
    localparam [6:0] OP_S = 7'b0100011;
    localparam [6:0] OP_B = 7'b1100011;
    localparam [6:0] OP_J = 7'b1101111;
    localparam [31:0] NOP = 32'h00000013;

    function [31:0] enc_r;
        input [6:0] funct7; input [4:0] rs2; input [4:0] rs1; input [2:0] funct3; input [4:0] rd; input [6:0] opcode;
        begin enc_r = {funct7, rs2, rs1, funct3, rd, opcode}; end
    endfunction

    function [31:0] enc_i;
        input [11:0] imm; input [4:0] rs1; input [2:0] funct3; input [4:0] rd; input [6:0] opcode;
        begin enc_i = {imm, rs1, funct3, rd, opcode}; end
    endfunction

    function [31:0] enc_s;
        input [11:0] imm; input [4:0] rs2; input [4:0] rs1; input [2:0] funct3; input [6:0] opcode;
        begin enc_s = {imm[11:5], rs2, rs1, funct3, imm[4:0], opcode}; end
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

        // Euclidean GCD by repeated subtraction: gcd(48,18)=6
        // x1=a, x2=b
        dut.u_instruction_memory.u_memory.mem[0] = enc_i(12'd48, 5'd0, 3'b000, 5'd1, OP_I);
        dut.u_instruction_memory.u_memory.mem[1] = enc_i(12'd18, 5'd0, 3'b000, 5'd2, OP_I);
        dut.u_instruction_memory.u_memory.mem[2] = enc_b(13'd24, 5'd2, 5'd1, 3'b000, OP_B);      // if a==b -> done
        dut.u_instruction_memory.u_memory.mem[3] = enc_b(13'd12, 5'd2, 5'd1, 3'b100, OP_B);      // if a<b -> less
        dut.u_instruction_memory.u_memory.mem[4] = enc_r(7'b0100000, 5'd2, 5'd1, 3'b000, 5'd1, OP_R); // a=a-b
        dut.u_instruction_memory.u_memory.mem[5] = enc_j(21'h1FFFF4, 5'd0, OP_J);                // jump to mem[2]
        dut.u_instruction_memory.u_memory.mem[6] = enc_r(7'b0100000, 5'd1, 5'd2, 3'b000, 5'd2, OP_R); // b=b-a
        dut.u_instruction_memory.u_memory.mem[7] = enc_j(21'h1FFFEC, 5'd0, OP_J);                // jump to mem[2]
        dut.u_instruction_memory.u_memory.mem[8] = enc_s(12'd0, 5'd1, 5'd0, 3'b010, OP_S);       // sw a,0(x0)
        dut.u_instruction_memory.u_memory.mem[9] = enc_j(21'd0, 5'd0, OP_J);                     // halt

        repeat (2) @(posedge clk); rst = 1;
        repeat (240) @(posedge clk);

        check_reg(5'd1, 32'd6, "gcd result in x1");
        check_reg(5'd2, 32'd6, "gcd convergence x2");
        check_mem(8'd0, 32'd6, "stored gcd in mem[0]");

        if (errors == 0) $display("RESULT: PASS");
        else $display("RESULT: FAIL (%0d)", errors);
        $finish;
    end
endmodule
/*
Algorithm Documentation:
- Algorithm: Euclidean GCD using subtraction
- Input: 48 and 18
- Instruction Sequence:
    1) addi x1, x0, 48      ; a
    2) addi x2, x0, 18      ; b
    3) beq  x1, x2, done
    4) blt  x1, x2, less
    5) sub  x1, x1, x2      ; a = a-b
    6) jal  x0, loop
    7) sub  x2, x2, x1      ; b = b-a (less branch target)
    8) jal  x0, loop
    9) sw   x1, 0(x0)       ; done: store gcd
 10) jal  x0, 0           ; halt
- Expected Results:
    - x1 = 6
    - x2 = 6
    - mem[0] = 6
*/
