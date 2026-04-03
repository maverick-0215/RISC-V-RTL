`timescale 1ns/1ps
module Microprocessor_utype_single_inst_tb();

    reg clk;
    reg rst;
    reg [31:0] instruction;
    integer i;
    integer errors;

    localparam [6:0] OP_LUI   = 7'b0110111;
    localparam [6:0] OP_AUIPC = 7'b0010111;
    localparam [31:0] NOP = 32'h00000013; // addi x0, x0, 0

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

        for (i = 0; i < 16; i = i + 1) begin
            u_microprocessor0.u_instruction_memory.u_memory.mem[i] = NOP;
        end

        // --------------------------------------------------------------------
        // U-TYPE SINGLE-INSTRUCTION SELECTOR
        // Keep exactly one line active at mem[0].
        // --------------------------------------------------------------------

        // ACTIVE TEST (default): lui x4, 0x12345 => EXPECT x4=0x12345000
        u_microprocessor0.u_instruction_memory.u_memory.mem[0] = enc_u(20'h12345, 5'd4, OP_LUI);

        // u_microprocessor0.u_instruction_memory.u_memory.mem[0] = enc_u(20'h12345, 5'd4, OP_AUIPC); // auipc x4,0x12345
        // u_microprocessor0.u_instruction_memory.u_memory.mem[0] = enc_u(20'h00001, 5'd4, OP_LUI);   // lui x4,0x00001

        #20;
        rst = 1;

        #1;
        u_microprocessor0.u_core.u_decodestage.u_regfile0.register[4] = 32'd0;

        #220;

        // ACTIVE CHECK (default LUI)
        if (u_microprocessor0.u_core.u_decodestage.u_regfile0.register[4] !== 32'h12345000) begin
            $display("FAIL: lui x4,0x12345 wrong, x4=%h", u_microprocessor0.u_core.u_decodestage.u_regfile0.register[4]);
            errors = errors + 1;
        end else begin
            $display("PASS: lui x4,0x12345");
        end

        // if (u_microprocessor0.u_core.u_decodestage.u_regfile0.register[4] !== 32'h12345000) begin
        //     $display("FAIL: auipc x4,0x12345 wrong, x4=%h", u_microprocessor0.u_core.u_decodestage.u_regfile0.register[4]);
        //     errors = errors + 1;
        // end else begin
        //     $display("PASS: auipc x4,0x12345");
        // end

        // if (u_microprocessor0.u_core.u_decodestage.u_regfile0.register[4] !== 32'h00001000) begin
        //     $display("FAIL: lui x4,0x00001 wrong, x4=%h", u_microprocessor0.u_core.u_decodestage.u_regfile0.register[4]);
        //     errors = errors + 1;
        // end else begin
        //     $display("PASS: lui x4,0x00001");
        // end

        if (errors == 0) begin
            $display("RESULT: PASS");
        end else begin
            $display("RESULT: FAIL (%0d checks failed)", errors);
        end

        $finish;
    end

endmodule

