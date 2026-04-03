`timescale 1ns/1ps
module Microprocessor_itype_single_inst_tb();

    reg clk;
    reg rst;
    reg [31:0] instruction;
    integer i;
    integer errors;

    localparam [6:0] OP_I = 7'b0010011;
    localparam [31:0] NOP = 32'h00000013; // addi x0, x0, 0

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
        // I-TYPE SINGLE-INSTRUCTION SELECTOR
        // Keep exactly one line active at mem[0].
        // Comment the one you already checked and uncomment the next one.
        // --------------------------------------------------------------------

        // ACTIVE TEST (default): addi x4, x2, 5 => EXPECT x4 = 15
        u_microprocessor0.u_instruction_memory.u_memory.mem[0] = enc_i(12'd5, 5'd2, 3'b000, 5'd4, OP_I);

        // u_microprocessor0.u_instruction_memory.u_memory.mem[0] = enc_i({7'b0000000, 5'd3}, 5'd2, 3'b001, 5'd4, OP_I); // slli x4, x2, 3
        // u_microprocessor0.u_instruction_memory.u_memory.mem[0] = enc_i(12'd20, 5'd2, 3'b010, 5'd4, OP_I);              // slti x4, x2, 20
        // u_microprocessor0.u_instruction_memory.u_memory.mem[0] = enc_i(12'd20, 5'd2, 3'b011, 5'd4, OP_I);              // sltiu x4, x2, 20
        // u_microprocessor0.u_instruction_memory.u_memory.mem[0] = enc_i(12'd6, 5'd2, 3'b100, 5'd4, OP_I);               // xori x4, x2, 6
        // u_microprocessor0.u_instruction_memory.u_memory.mem[0] = enc_i({7'b0000000, 5'd1}, 5'd2, 3'b101, 5'd4, OP_I); // srli x4, x2, 1
        // u_microprocessor0.u_instruction_memory.u_memory.mem[0] = enc_i({7'b0100000, 5'd1}, 5'd2, 3'b101, 5'd4, OP_I); // srai x4, x2, 1
        // u_microprocessor0.u_instruction_memory.u_memory.mem[0] = enc_i(12'd12, 5'd2, 3'b110, 5'd4, OP_I);              // ori  x4, x2, 12
        // u_microprocessor0.u_instruction_memory.u_memory.mem[0] = enc_i(12'd12, 5'd2, 3'b111, 5'd4, OP_I);              // andi x4, x2, 12

        #20;
        rst = 1;

        // Register init after reset release.
        #1;
        u_microprocessor0.u_core.u_decodestage.u_regfile0.register[2] = 32'd10;
        u_microprocessor0.u_core.u_decodestage.u_regfile0.register[4] = 32'd0;

        #200;

        // --------------------------------------------------------------------
        // RESULT CHECKS
        // Keep one check active matching the selected instruction above.
        // --------------------------------------------------------------------

        // ACTIVE CHECK (default addi): EXPECT x4 = 15
        if (u_microprocessor0.u_core.u_decodestage.u_regfile0.register[4] !== 32'd15) begin
            $display("FAIL: addi x4,x2,5 wrong, x4=%h", u_microprocessor0.u_core.u_decodestage.u_regfile0.register[4]);
            errors = errors + 1;
        end else begin
            $display("PASS: addi x4,x2,5 (x4=15)");
        end

        // if (u_microprocessor0.u_core.u_decodestage.u_regfile0.register[4] !== (32'd10 << 3)) begin
        //     $display("FAIL: slli x4,x2,3 wrong, x4=%h", u_microprocessor0.u_core.u_decodestage.u_regfile0.register[4]);
        //     errors = errors + 1;
        // end else begin
        //     $display("PASS: slli x4,x2,3");
        // end

        // if (u_microprocessor0.u_core.u_decodestage.u_regfile0.register[4] !== 32'd1) begin
        //     $display("FAIL: slti x4,x2,20 wrong, x4=%h", u_microprocessor0.u_core.u_decodestage.u_regfile0.register[4]);
        //     errors = errors + 1;
        // end else begin
        //     $display("PASS: slti x4,x2,20");
        // end

        // if (u_microprocessor0.u_core.u_decodestage.u_regfile0.register[4] !== 32'd1) begin
        //     $display("FAIL: sltiu x4,x2,20 wrong, x4=%h", u_microprocessor0.u_core.u_decodestage.u_regfile0.register[4]);
        //     errors = errors + 1;
        // end else begin
        //     $display("PASS: sltiu x4,x2,20");
        // end

        // if (u_microprocessor0.u_core.u_decodestage.u_regfile0.register[4] !== (32'd10 ^ 32'd6)) begin
        //     $display("FAIL: xori x4,x2,6 wrong, x4=%h", u_microprocessor0.u_core.u_decodestage.u_regfile0.register[4]);
        //     errors = errors + 1;
        // end else begin
        //     $display("PASS: xori x4,x2,6");
        // end

        // if (u_microprocessor0.u_core.u_decodestage.u_regfile0.register[4] !== (32'd10 >> 1)) begin
        //     $display("FAIL: srli x4,x2,1 wrong, x4=%h", u_microprocessor0.u_core.u_decodestage.u_regfile0.register[4]);
        //     errors = errors + 1;
        // end else begin
        //     $display("PASS: srli x4,x2,1");
        // end

        // if (u_microprocessor0.u_core.u_decodestage.u_regfile0.register[4] !== ($signed(32'd10) >>> 1)) begin
        //     $display("FAIL: srai x4,x2,1 wrong, x4=%h", u_microprocessor0.u_core.u_decodestage.u_regfile0.register[4]);
        //     errors = errors + 1;
        // end else begin
        //     $display("PASS: srai x4,x2,1");
        // end

        // if (u_microprocessor0.u_core.u_decodestage.u_regfile0.register[4] !== (32'd10 | 32'd12)) begin
        //     $display("FAIL: ori x4,x2,12 wrong, x4=%h", u_microprocessor0.u_core.u_decodestage.u_regfile0.register[4]);
        //     errors = errors + 1;
        // end else begin
        //     $display("PASS: ori x4,x2,12");
        // end

        // if (u_microprocessor0.u_core.u_decodestage.u_regfile0.register[4] !== (32'd10 & 32'd12)) begin
        //     $display("FAIL: andi x4,x2,12 wrong, x4=%h", u_microprocessor0.u_core.u_decodestage.u_regfile0.register[4]);
        //     errors = errors + 1;
        // end else begin
        //     $display("PASS: andi x4,x2,12");
        // end

        if (errors == 0) begin
            $display("RESULT: PASS");
        end else begin
            $display("RESULT: FAIL (%0d checks failed)", errors);
        end

        $finish;
    end

endmodule

