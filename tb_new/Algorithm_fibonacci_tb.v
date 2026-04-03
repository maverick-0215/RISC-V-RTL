`timescale 1ns/1ps
module Algorithm_fibonacci_tb;
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

        // Fibonacci iterative algorithm: compute fib(10) into x2, store to mem[0].
        // x1=n(10), x2=a(0), x3=b(1), x4=i(0), x5=temp
        dut.u_instruction_memory.u_memory.mem[0]  = enc_i(12'd10, 5'd0, 3'b000, 5'd1, OP_I); // addi x1,x0,10
        dut.u_instruction_memory.u_memory.mem[1]  = enc_i(12'd0,  5'd0, 3'b000, 5'd2, OP_I); // addi x2,x0,0
        dut.u_instruction_memory.u_memory.mem[2]  = enc_i(12'd1,  5'd0, 3'b000, 5'd3, OP_I); // addi x3,x0,1
        dut.u_instruction_memory.u_memory.mem[3]  = enc_i(12'd0,  5'd0, 3'b000, 5'd4, OP_I); // addi x4,x0,0
        dut.u_instruction_memory.u_memory.mem[4]  = enc_b(13'd24, 5'd1, 5'd4, 3'b000, OP_B); // beq  x4,x1,done
        dut.u_instruction_memory.u_memory.mem[5]  = enc_r(7'b0000000, 5'd3, 5'd2, 3'b000, 5'd5, OP_R); // add x5,x2,x3
        dut.u_instruction_memory.u_memory.mem[6]  = enc_i(12'd0,  5'd3, 3'b000, 5'd2, OP_I); // addi x2,x3,0
        dut.u_instruction_memory.u_memory.mem[7]  = enc_i(12'd0,  5'd5, 3'b000, 5'd3, OP_I); // addi x3,x5,0
        dut.u_instruction_memory.u_memory.mem[8]  = enc_i(12'd1,  5'd4, 3'b000, 5'd4, OP_I); // addi x4,x4,1
        dut.u_instruction_memory.u_memory.mem[9]  = enc_j(21'h1FFFEC, 5'd0, OP_J); // jal x0,loop (-20)
        dut.u_instruction_memory.u_memory.mem[10] = enc_s(12'd0,  5'd2, 5'd0, 3'b010, OP_S); // sw x2,0(x0)
        dut.u_instruction_memory.u_memory.mem[11] = enc_j(21'd0,  5'd0, OP_J); // halt

        repeat (2) @(posedge clk);
        rst = 1;

        repeat (260) @(posedge clk);

        check_reg(5'd2, 32'd55, "fib(10) in x2");
        check_reg(5'd3, 32'd89, "next fib in x3");
        check_reg(5'd4, 32'd10, "loop count i");
        check_mem(8'd0, 32'd55, "stored fib(10) mem[0]");

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
- Algorithm: Iterative Fibonacci (n=10)
- Instruction Sequence:
    1) addi x1, x0, 10      ; n
    2) addi x2, x0, 0       ; a
    3) addi x3, x0, 1       ; b
    4) addi x4, x0, 0       ; i
    5) beq  x4, x1, done
    6) add  x5, x2, x3      ; temp = a+b
    7) addi x2, x3, 0       ; a = b
    8) addi x3, x5, 0       ; b = temp
    9) addi x4, x4, 1       ; i++
 10) jal  x0, loop
 11) sw   x2, 0(x0)       ; store fib(n)
 12) jal  x0, 0           ; halt
- Expected Results:
    - x2 = 55   (fib(10))
    - x3 = 89   (fib(11))
    - x4 = 10   (loop iterations)
    - mem[0] = 55
*/
