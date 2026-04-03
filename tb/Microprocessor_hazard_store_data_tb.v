`timescale 1ns/1ps
module Microprocessor_hazard_store_data_tb();

    reg clk;
    reg rst;
    reg [31:0] instruction;
    integer i;
    integer errors;

    localparam [6:0] OP_R = 7'b0110011;
    localparam [6:0] OP_S = 7'b0100011;
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

        // STORE data hazard:
        // add x4, x2, x3
        // sw  x4, 0(x1)   <- needs freshly produced x4
        u_microprocessor0.u_instruction_memory.u_memory.mem[0] = enc_r(7'b0000000, 5'd3, 5'd2, 3'b000, 5'd4, OP_R);
        u_microprocessor0.u_instruction_memory.u_memory.mem[1] = enc_s(12'd0, 5'd4, 5'd1, 3'b010, OP_S);

        #20;
        rst = 1;

        #1;
        u_microprocessor0.u_core.u_decodestage.u_regfile0.register[1] = 32'd0;
        u_microprocessor0.u_core.u_decodestage.u_regfile0.register[2] = 32'd5;
        u_microprocessor0.u_core.u_decodestage.u_regfile0.register[3] = 32'd6;
        u_microprocessor0.u_data_memory.u_memory.mem[0] = 32'hDEADBEEF;

        #240;

        if (u_microprocessor0.u_data_memory.u_memory.mem[0] !== 32'd11) begin
            $display("FAIL: STORE data hazard wrong, mem[0]=%h", u_microprocessor0.u_data_memory.u_memory.mem[0]);
            errors = errors + 1;
        end else begin
            $display("PASS: STORE data hazard");
        end

        if (errors == 0) $display("RESULT: PASS");
        else $display("RESULT: FAIL (%0d checks failed)", errors);

        $finish;
    end

endmodule

