`timescale 1ns/1ps
module Microprocessor_hazard_lw_add_tb();

    reg clk;
    reg rst;
    reg [31:0] instruction;
    integer i;
    integer errors;

    localparam [6:0] OP_R    = 7'b0110011;
    localparam [6:0] OP_LOAD = 7'b0000011;
    localparam [31:0] NOP    = 32'h00000013;

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

    microprocessor u_microprocessor0 (
        .clk(clk),
        .rst(rst)    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 0;
        instruction = 32'b0;
        errors = 0;

        for (i = 0; i < 32; i = i + 1) begin
            u_microprocessor0.u_instruction_memory.u_memory.mem[i] = NOP;
        end

        // Hazard under test:
        //   lw  x2, 0(x1)
        //   add x1, x2, x3
        u_microprocessor0.u_instruction_memory.u_memory.mem[0] = enc_i(12'd0, 5'd1, 3'b010, 5'd2, OP_LOAD);
        u_microprocessor0.u_instruction_memory.u_memory.mem[1] = enc_r(7'b0000000, 5'd3, 5'd2, 3'b000, 5'd1, OP_R);

        // Data at address 0 for lw.
        u_microprocessor0.u_data_memory.u_memory.mem[0] = 32'd21;

        #20;
        rst = 1;

        #1;
        u_microprocessor0.u_core.u_decodestage.u_regfile0.register[1] = 32'd0;  // base address
        u_microprocessor0.u_core.u_decodestage.u_regfile0.register[3] = 32'd4;  // addend

        #220;

        if (u_microprocessor0.u_core.u_decodestage.u_regfile0.register[2] !== 32'd21) begin
            $display("FAIL: lw result wrong, x2=%h", u_microprocessor0.u_core.u_decodestage.u_regfile0.register[2]);
            errors = errors + 1;
        end else begin
            $display("PASS: lw produced x2=21");
        end

        if (u_microprocessor0.u_core.u_decodestage.u_regfile0.register[1] !== 32'd25) begin
            $display("FAIL: load-use add wrong, x1=%h", u_microprocessor0.u_core.u_decodestage.u_regfile0.register[1]);
            errors = errors + 1;
        end else begin
            $display("PASS: lw->add hazard handled x1=25");
        end

        if (errors == 0) begin
            $display("RESULT: PASS");
        end else begin
            $display("RESULT: FAIL (%0d checks failed)", errors);
        end

        $finish;
    end

endmodule

