`timescale 1ns/1ps
module Algorithm_sum_n_tb;
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

        // Sum of first N numbers, N=10. Expected 55.
        // x1=n, x2=i, x3=sum
        dut.u_instruction_memory.u_memory.mem[0] = enc_i(12'd10, 5'd0, 3'b000, 5'd1, OP_I);
        dut.u_instruction_memory.u_memory.mem[1] = enc_i(12'd1,  5'd0, 3'b000, 5'd2, OP_I);
        dut.u_instruction_memory.u_memory.mem[2] = enc_i(12'd0,  5'd0, 3'b000, 5'd3, OP_I);
        dut.u_instruction_memory.u_memory.mem[3] = enc_b(13'd20, 5'd2, 5'd1, 3'b100, OP_B);  // if n<i done
        dut.u_instruction_memory.u_memory.mem[4] = enc_r(7'b0000000, 5'd2, 5'd3, 3'b000, 5'd3, OP_R); // sum+=i
        dut.u_instruction_memory.u_memory.mem[5] = enc_i(12'd1,  5'd2, 3'b000, 5'd2, OP_I);  // i++
        dut.u_instruction_memory.u_memory.mem[6] = enc_j(21'h1FFFF4, 5'd0, OP_J);            // jump loop
        dut.u_instruction_memory.u_memory.mem[8] = enc_s(12'd4,  5'd3, 5'd0, 3'b010, OP_S);  // sw sum,4(x0)
        dut.u_instruction_memory.u_memory.mem[9] = enc_j(21'd0,  5'd0, OP_J);                // halt

        repeat (2) @(posedge clk); rst = 1;
        repeat (200) @(posedge clk);

        check_reg(5'd3, 32'd55, "sum(1..10) in x3");
        check_reg(5'd2, 32'd11, "loop index end x2");
        check_mem(8'd1, 32'd55, "stored sum in mem[1]");

        if (errors == 0) $display("RESULT: PASS");
        else $display("RESULT: FAIL (%0d)", errors);
        $finish;
    end
endmodule
/*
Algorithm Documentation:
- Algorithm: Sum of first N natural numbers
- Input: N=10
- Instruction Sequence:
    1) addi x1, x0, 10      ; n
    2) addi x2, x0, 1       ; i
    3) addi x3, x0, 0       ; sum
    4) blt  x1, x2, done    ; if n<i stop
    5) add  x3, x3, x2      ; sum += i
    6) addi x2, x2, 1       ; i++
    7) jal  x0, loop
    8) sw   x3, 4(x0)       ; done: store sum
    9) jal  x0, 0           ; halt
- Expected Results:
    - x3 = 55  (1+2+...+10)
    - x2 = 11  (loop exit value)
    - mem[1] = 55
*/
