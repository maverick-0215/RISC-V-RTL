`timescale 1ns/1ps
module Microprocessor_stype_single_inst_tb();

    reg clk;
    reg rst;
    reg [31:0] instruction;
    integer i;
    integer errors;

    localparam [6:0] OP_S = 7'b0100011;
    localparam [31:0] NOP = 32'h00000013; // addi x0, x0, 0

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

        // Fill instruction memory with NOPs first.
        for (i = 0; i < 16; i = i + 1) begin
            u_microprocessor0.u_instruction_memory.u_memory.mem[i] = NOP;
        end

        // --------------------------------------------------------------------
        // S-TYPE SINGLE-INSTRUCTION SELECTOR
        // Keep exactly one line active at mem[0].
        // Comment the one you already checked and uncomment the next one.
        // --------------------------------------------------------------------

        // ACTIVE TEST (default): sw x3, 0(x1) => EXPECT mem[0] = 0x11223344
        u_microprocessor0.u_instruction_memory.u_memory.mem[0] = enc_s(12'd0, 5'd3, 5'd1, 3'b010, OP_S);

        // u_microprocessor0.u_instruction_memory.u_memory.mem[0] = enc_s(12'd0, 5'd3, 5'd1, 3'b000, OP_S); // sb x3, 0(x1)
        // u_microprocessor0.u_instruction_memory.u_memory.mem[0] = enc_s(12'd1, 5'd3, 5'd1, 3'b000, OP_S); // sb x3, 1(x1)
        // u_microprocessor0.u_instruction_memory.u_memory.mem[0] = enc_s(12'd2, 5'd3, 5'd1, 3'b000, OP_S); // sb x3, 2(x1)
        // u_microprocessor0.u_instruction_memory.u_memory.mem[0] = enc_s(12'd3, 5'd3, 5'd1, 3'b000, OP_S); // sb x3, 3(x1)
        // u_microprocessor0.u_instruction_memory.u_memory.mem[0] = enc_s(12'd0, 5'd3, 5'd1, 3'b001, OP_S); // sh x3, 0(x1)
        // u_microprocessor0.u_instruction_memory.u_memory.mem[0] = enc_s(12'd1, 5'd3, 5'd1, 3'b001, OP_S); // sh x3, 1(x1)
        // u_microprocessor0.u_instruction_memory.u_memory.mem[0] = enc_s(12'd2, 5'd3, 5'd1, 3'b001, OP_S); // sh x3, 2(x1)

        #20;
        rst = 1;

        #1;
        u_microprocessor0.u_core.u_decodestage.u_regfile0.register[1] = 32'd0;         // base address
        u_microprocessor0.u_core.u_decodestage.u_regfile0.register[3] = 32'h11223344;   // store data

        // Initialize data memory word to observe partial-byte/halfword updates.
        u_microprocessor0.u_data_memory.u_memory.mem[0] = 32'hAABBCCDD;

        #220;

        // --------------------------------------------------------------------
        // RESULT CHECKS
        // Keep one check active matching the selected instruction above.
        // --------------------------------------------------------------------

        // ACTIVE CHECK (default sw): EXPECT mem[0] = 0x11223344
        if (u_microprocessor0.u_data_memory.u_memory.mem[0] !== 32'h11223344) begin
            $display("FAIL: sw x3,0(x1) wrong, mem[0]=%h", u_microprocessor0.u_data_memory.u_memory.mem[0]);
            errors = errors + 1;
        end else begin
            $display("PASS: sw x3,0(x1)");
        end

        // if (u_microprocessor0.u_data_memory.u_memory.mem[0] !== 32'hAABBCC44) begin
        //     $display("FAIL: sb x3,0(x1) wrong, mem[0]=%h", u_microprocessor0.u_data_memory.u_memory.mem[0]);
        //     errors = errors + 1;
        // end else begin
        //     $display("PASS: sb x3,0(x1)");
        // end

        // if (u_microprocessor0.u_data_memory.u_memory.mem[0] !== 32'hAABB44DD) begin
        //     $display("FAIL: sb x3,1(x1) wrong, mem[0]=%h", u_microprocessor0.u_data_memory.u_memory.mem[0]);
        //     errors = errors + 1;
        // end else begin
        //     $display("PASS: sb x3,1(x1)");
        // end

        // if (u_microprocessor0.u_data_memory.u_memory.mem[0] !== 32'hAA33CCDD) begin
        //     $display("FAIL: sb x3,2(x1) wrong, mem[0]=%h", u_microprocessor0.u_data_memory.u_memory.mem[0]);
        //     errors = errors + 1;
        // end else begin
        //     $display("PASS: sb x3,2(x1)");
        // end

        // if (u_microprocessor0.u_data_memory.u_memory.mem[0] !== 32'h44BBCCDD) begin
        //     $display("FAIL: sb x3,3(x1) wrong, mem[0]=%h", u_microprocessor0.u_data_memory.u_memory.mem[0]);
        //     errors = errors + 1;
        // end else begin
        //     $display("PASS: sb x3,3(x1)");
        // end

        // if (u_microprocessor0.u_data_memory.u_memory.mem[0] !== 32'hAABB3344) begin
        //     $display("FAIL: sh x3,0(x1) wrong, mem[0]=%h", u_microprocessor0.u_data_memory.u_memory.mem[0]);
        //     errors = errors + 1;
        // end else begin
        //     $display("PASS: sh x3,0(x1)");
        // end

        // if (u_microprocessor0.u_data_memory.u_memory.mem[0] !== 32'hAA3344DD) begin
        //     $display("FAIL: sh x3,1(x1) wrong, mem[0]=%h", u_microprocessor0.u_data_memory.u_memory.mem[0]);
        //     errors = errors + 1;
        // end else begin
        //     $display("PASS: sh x3,1(x1)");
        // end

        // if (u_microprocessor0.u_data_memory.u_memory.mem[0] !== 32'h3344CCDD) begin
        //     $display("FAIL: sh x3,2(x1) wrong, mem[0]=%h", u_microprocessor0.u_data_memory.u_memory.mem[0]);
        //     errors = errors + 1;
        // end else begin
        //     $display("PASS: sh x3,2(x1)");
        // end

        if (errors == 0) begin
            $display("RESULT: PASS");
        end else begin
            $display("RESULT: FAIL (%0d checks failed)", errors);
        end

        $finish;
    end

endmodule

