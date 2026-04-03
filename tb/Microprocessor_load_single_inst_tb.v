`timescale 1ns/1ps
module Microprocessor_load_single_inst_tb();

    reg clk;
    reg rst;
    reg [31:0] instruction;
    integer i;
    integer errors;

    localparam [6:0] OP_LOAD = 7'b0000011;
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
        // LOAD SINGLE-INSTRUCTION SELECTOR
        // Keep exactly one line active at mem[0].
        // Comment the one you already checked and uncomment the next one.
        // --------------------------------------------------------------------

        // ACTIVE TEST (default): lw x4, 0(x1) => EXPECT x4 = 0x80FF7F01
        u_microprocessor0.u_instruction_memory.u_memory.mem[0] = enc_i(12'd0, 5'd1, 3'b010, 5'd4, OP_LOAD);

        // u_microprocessor0.u_instruction_memory.u_memory.mem[0] = enc_i(12'd0, 5'd1, 3'b000, 5'd4, OP_LOAD); // lb  x4, 0(x1)
        // u_microprocessor0.u_instruction_memory.u_memory.mem[0] = enc_i(12'd1, 5'd1, 3'b000, 5'd4, OP_LOAD); // lb  x4, 1(x1)
        // u_microprocessor0.u_instruction_memory.u_memory.mem[0] = enc_i(12'd2, 5'd1, 3'b000, 5'd4, OP_LOAD); // lb  x4, 2(x1)
        // u_microprocessor0.u_instruction_memory.u_memory.mem[0] = enc_i(12'd3, 5'd1, 3'b000, 5'd4, OP_LOAD); // lb  x4, 3(x1)
        // u_microprocessor0.u_instruction_memory.u_memory.mem[0] = enc_i(12'd0, 5'd1, 3'b001, 5'd4, OP_LOAD); // lh  x4, 0(x1)
        // u_microprocessor0.u_instruction_memory.u_memory.mem[0] = enc_i(12'd2, 5'd1, 3'b001, 5'd4, OP_LOAD); // lh  x4, 2(x1)
        // u_microprocessor0.u_instruction_memory.u_memory.mem[0] = enc_i(12'd0, 5'd1, 3'b100, 5'd4, OP_LOAD); // lbu x4, 0(x1)
        // u_microprocessor0.u_instruction_memory.u_memory.mem[0] = enc_i(12'd1, 5'd1, 3'b100, 5'd4, OP_LOAD); // lbu x4, 1(x1)
        // u_microprocessor0.u_instruction_memory.u_memory.mem[0] = enc_i(12'd2, 5'd1, 3'b100, 5'd4, OP_LOAD); // lbu x4, 2(x1)
        // u_microprocessor0.u_instruction_memory.u_memory.mem[0] = enc_i(12'd3, 5'd1, 3'b100, 5'd4, OP_LOAD); // lbu x4, 3(x1)
        // u_microprocessor0.u_instruction_memory.u_memory.mem[0] = enc_i(12'd0, 5'd1, 3'b101, 5'd4, OP_LOAD); // lhu x4, 0(x1)
        // u_microprocessor0.u_instruction_memory.u_memory.mem[0] = enc_i(12'd2, 5'd1, 3'b101, 5'd4, OP_LOAD); // lhu x4, 2(x1)

        #20;
        rst = 1;

        // Data memory pattern:
        // mem[0] = 0x80FF7F01 -> byte0=01, byte1=7F, byte2=FF, byte3=80
        #1;
        u_microprocessor0.u_data_memory.u_memory.mem[0] = 32'h80FF7F01;
        u_microprocessor0.u_core.u_decodestage.u_regfile0.register[1] = 32'd0; // base address
        u_microprocessor0.u_core.u_decodestage.u_regfile0.register[4] = 32'd0;

        #220;

        // --------------------------------------------------------------------
        // RESULT CHECKS
        // Keep one check active matching the selected instruction above.
        // --------------------------------------------------------------------

        // ACTIVE CHECK (default lw): EXPECT x4 = 0x80FF7F01
        if (u_microprocessor0.u_core.u_decodestage.u_regfile0.register[4] !== 32'h80FF7F01) begin
            $display("FAIL: lw x4,0(x1) wrong, x4=%h", u_microprocessor0.u_core.u_decodestage.u_regfile0.register[4]);
            errors = errors + 1;
        end else begin
            $display("PASS: lw x4,0(x1)");
        end

        // if (u_microprocessor0.u_core.u_decodestage.u_regfile0.register[4] !== 32'h00000001) begin
        //     $display("FAIL: lb x4,0(x1) wrong, x4=%h", u_microprocessor0.u_core.u_decodestage.u_regfile0.register[4]);
        //     errors = errors + 1;
        // end else begin
        //     $display("PASS: lb x4,0(x1)");
        // end

        // if (u_microprocessor0.u_core.u_decodestage.u_regfile0.register[4] !== 32'h0000007F) begin
        //     $display("FAIL: lb x4,1(x1) wrong, x4=%h", u_microprocessor0.u_core.u_decodestage.u_regfile0.register[4]);
        //     errors = errors + 1;
        // end else begin
        //     $display("PASS: lb x4,1(x1)");
        // end

        // if (u_microprocessor0.u_core.u_decodestage.u_regfile0.register[4] !== 32'hFFFFFFFF) begin
        //     $display("FAIL: lb x4,2(x1) wrong, x4=%h", u_microprocessor0.u_core.u_decodestage.u_regfile0.register[4]);
        //     errors = errors + 1;
        // end else begin
        //     $display("PASS: lb x4,2(x1)");
        // end

        // if (u_microprocessor0.u_core.u_decodestage.u_regfile0.register[4] !== 32'hFFFFFF80) begin
        //     $display("FAIL: lb x4,3(x1) wrong, x4=%h", u_microprocessor0.u_core.u_decodestage.u_regfile0.register[4]);
        //     errors = errors + 1;
        // end else begin
        //     $display("PASS: lb x4,3(x1)");
        // end

        // if (u_microprocessor0.u_core.u_decodestage.u_regfile0.register[4] !== 32'h00007F01) begin
        //     $display("FAIL: lh x4,0(x1) wrong, x4=%h", u_microprocessor0.u_core.u_decodestage.u_regfile0.register[4]);
        //     errors = errors + 1;
        // end else begin
        //     $display("PASS: lh x4,0(x1)");
        // end

        // if (u_microprocessor0.u_core.u_decodestage.u_regfile0.register[4] !== 32'hFFFF80FF) begin
        //     $display("FAIL: lh x4,2(x1) wrong, x4=%h", u_microprocessor0.u_core.u_decodestage.u_regfile0.register[4]);
        //     errors = errors + 1;
        // end else begin
        //     $display("PASS: lh x4,2(x1)");
        // end

        // if (u_microprocessor0.u_core.u_decodestage.u_regfile0.register[4] !== 32'h00000001) begin
        //     $display("FAIL: lbu x4,0(x1) wrong, x4=%h", u_microprocessor0.u_core.u_decodestage.u_regfile0.register[4]);
        //     errors = errors + 1;
        // end else begin
        //     $display("PASS: lbu x4,0(x1)");
        // end

        // if (u_microprocessor0.u_core.u_decodestage.u_regfile0.register[4] !== 32'h0000007F) begin
        //     $display("FAIL: lbu x4,1(x1) wrong, x4=%h", u_microprocessor0.u_core.u_decodestage.u_regfile0.register[4]);
        //     errors = errors + 1;
        // end else begin
        //     $display("PASS: lbu x4,1(x1)");
        // end

        // if (u_microprocessor0.u_core.u_decodestage.u_regfile0.register[4] !== 32'h000000FF) begin
        //     $display("FAIL: lbu x4,2(x1) wrong, x4=%h", u_microprocessor0.u_core.u_decodestage.u_regfile0.register[4]);
        //     errors = errors + 1;
        // end else begin
        //     $display("PASS: lbu x4,2(x1)");
        // end

        // if (u_microprocessor0.u_core.u_decodestage.u_regfile0.register[4] !== 32'h00000080) begin
        //     $display("FAIL: lbu x4,3(x1) wrong, x4=%h", u_microprocessor0.u_core.u_decodestage.u_regfile0.register[4]);
        //     errors = errors + 1;
        // end else begin
        //     $display("PASS: lbu x4,3(x1)");
        // end

        // if (u_microprocessor0.u_core.u_decodestage.u_regfile0.register[4] !== 32'h00007F01) begin
        //     $display("FAIL: lhu x4,0(x1) wrong, x4=%h", u_microprocessor0.u_core.u_decodestage.u_regfile0.register[4]);
        //     errors = errors + 1;
        // end else begin
        //     $display("PASS: lhu x4,0(x1)");
        // end

        // if (u_microprocessor0.u_core.u_decodestage.u_regfile0.register[4] !== 32'h000080FF) begin
        //     $display("FAIL: lhu x4,2(x1) wrong, x4=%h", u_microprocessor0.u_core.u_decodestage.u_regfile0.register[4]);
        //     errors = errors + 1;
        // end else begin
        //     $display("PASS: lhu x4,2(x1)");
        // end

        if (errors == 0) begin
            $display("RESULT: PASS");
        end else begin
            $display("RESULT: FAIL (%0d checks failed)", errors);
        end

        $finish;
    end

endmodule

