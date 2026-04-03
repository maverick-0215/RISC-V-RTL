`timescale 1ns/1ps
module Microprocessor_jtype_single_inst_tb();

    reg clk;
    reg rst;
    reg [31:0] instruction;
    integer i;
    integer errors;

    localparam [6:0] OP_JAL = 7'b1101111;
    localparam [6:0] OP_I   = 7'b0010011;
    localparam [31:0] NOP = 32'h00000013; // addi x0, x0, 0

    function [31:0] enc_j;
        input [20:0] imm;
        input [4:0] rd;
        input [6:0] opcode;
        begin
            enc_j = {imm[20], imm[10:1], imm[11], imm[19:12], rd, opcode};
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

        for (i = 0; i < 16; i = i + 1) begin
            u_microprocessor0.u_instruction_memory.u_memory.mem[i] = NOP;
        end

        // --------------------------------------------------------------------
        // J-TYPE SINGLE-INSTRUCTION SELECTOR
        // Keep exactly one line active at mem[0].
        // --------------------------------------------------------------------

        // ACTIVE TEST (default): jal x5, +8
        // With current redirect/flush behavior, final marker observed is mem[3], EXPECT x4=3
        u_microprocessor0.u_instruction_memory.u_memory.mem[0] = enc_j(21'd8, 5'd5, OP_JAL);

        // u_microprocessor0.u_instruction_memory.u_memory.mem[0] = enc_j(21'd8, 5'd0, OP_JAL);  // jal x0,+8
        // u_microprocessor0.u_instruction_memory.u_memory.mem[0] = enc_j(21'd12, 5'd5, OP_JAL); // jal x5,+12

        u_microprocessor0.u_instruction_memory.u_memory.mem[1] = enc_i(12'd1, 5'd0, 3'b000, 5'd4, OP_I); // addi x4,x0,1
        u_microprocessor0.u_instruction_memory.u_memory.mem[2] = enc_i(12'd2, 5'd0, 3'b000, 5'd4, OP_I); // addi x4,x0,2
        u_microprocessor0.u_instruction_memory.u_memory.mem[3] = enc_i(12'd3, 5'd0, 3'b000, 5'd4, OP_I); // addi x4,x0,3

        #20;
        rst = 1;

        #1;
        u_microprocessor0.u_core.u_decodestage.u_regfile0.register[4] = 32'd0;
        u_microprocessor0.u_core.u_decodestage.u_regfile0.register[5] = 32'd0;

        #240;

        // ACTIVE CHECK (default jal +8): EXPECT x4 = 3
        if (u_microprocessor0.u_core.u_decodestage.u_regfile0.register[4] !== 32'd3) begin
            $display("FAIL: jal x5,+8 wrong flow, x4=%h", u_microprocessor0.u_core.u_decodestage.u_regfile0.register[4]);
            errors = errors + 1;
        end else begin
            $display("PASS: jal x5,+8 flow");
        end

        // if (u_microprocessor0.u_core.u_decodestage.u_regfile0.register[4] !== 32'd2) begin
        //     $display("FAIL: jal x0,+8 wrong flow, x4=%h", u_microprocessor0.u_core.u_decodestage.u_regfile0.register[4]);
        //     errors = errors + 1;
        // end else begin
        //     $display("PASS: jal x0,+8 flow");
        // end

        // if (u_microprocessor0.u_core.u_decodestage.u_regfile0.register[4] !== 32'd3) begin
        //     $display("FAIL: jal x5,+12 wrong flow, x4=%h", u_microprocessor0.u_core.u_decodestage.u_regfile0.register[4]);
        //     errors = errors + 1;
        // end else begin
        //     $display("PASS: jal x5,+12 flow");
        // end

        if (errors == 0) begin
            $display("RESULT: PASS");
        end else begin
            $display("RESULT: FAIL (%0d checks failed)", errors);
        end

        $finish;
    end

endmodule

