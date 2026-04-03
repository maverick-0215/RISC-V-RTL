`timescale 1ns/1ps
module Microprocessor_rtype_single_inst_tb();

    reg clk;
    reg rst;
    reg [31:0] instruction;
    integer i;
    integer errors;

    localparam [6:0] OP_R = 7'b0110011;
    localparam [31:0] NOP = 32'h00000013; // addi x0, x0, 0

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
        // R-TYPE SINGLE-INSTRUCTION SELECTOR
        // Keep exactly one line active at mem[0].
        // Comment the one you already checked and uncomment the next one.
        // --------------------------------------------------------------------

        // ACTIVE TEST (default): add x4, x2, x3  => EXPECT x4 = 30
        u_microprocessor0.u_instruction_memory.u_memory.mem[0] = enc_r(7'b0000000, 5'd3, 5'd2, 3'b000, 5'd4, OP_R);

        // u_microprocessor0.u_instruction_memory.u_memory.mem[0] = enc_r(7'b0100000, 5'd3, 5'd2, 3'b000, 5'd4, OP_R); // sub  x4, x2, x3
        // u_microprocessor0.u_instruction_memory.u_memory.mem[0] = enc_r(7'b0000000, 5'd3, 5'd2, 3'b001, 5'd4, OP_R); // sll  x4, x2, x3[4:0]
        // u_microprocessor0.u_instruction_memory.u_memory.mem[0] = enc_r(7'b0000000, 5'd3, 5'd2, 3'b010, 5'd4, OP_R); // slt  x4, x2, x3
        // u_microprocessor0.u_instruction_memory.u_memory.mem[0] = enc_r(7'b0000000, 5'd3, 5'd2, 3'b011, 5'd4, OP_R); // sltu x4, x2, x3
        // u_microprocessor0.u_instruction_memory.u_memory.mem[0] = enc_r(7'b0000000, 5'd3, 5'd2, 3'b100, 5'd4, OP_R); // xor  x4, x2, x3
        // u_microprocessor0.u_instruction_memory.u_memory.mem[0] = enc_r(7'b0000000, 5'd3, 5'd2, 3'b101, 5'd4, OP_R); // srl  x4, x2, x3[4:0]
        // u_microprocessor0.u_instruction_memory.u_memory.mem[0] = enc_r(7'b0100000, 5'd3, 5'd2, 3'b101, 5'd4, OP_R); // sra  x4, x2, x3[4:0]
        // u_microprocessor0.u_instruction_memory.u_memory.mem[0] = enc_r(7'b0000000, 5'd3, 5'd2, 3'b110, 5'd4, OP_R); // or   x4, x2, x3
        // u_microprocessor0.u_instruction_memory.u_memory.mem[0] = enc_r(7'b0000000, 5'd3, 5'd2, 3'b111, 5'd4, OP_R); // and  x4, x2, x3

        #20;
        rst = 1;

        // Register init after reset release.
        #1;
        u_microprocessor0.u_core.u_decodestage.u_regfile0.register[2] = 32'd10;
        u_microprocessor0.u_core.u_decodestage.u_regfile0.register[3] = 32'd20;
        u_microprocessor0.u_core.u_decodestage.u_regfile0.register[4] = 32'd0;

        #200;

        // --------------------------------------------------------------------
        // RESULT CHECKS
        // Keep one check active matching the selected instruction above.
        // --------------------------------------------------------------------

        // ACTIVE CHECK (default add): EXPECT x4 = 30
        if (u_microprocessor0.u_core.u_decodestage.u_regfile0.register[4] !== 32'd30) begin
            $display("FAIL: add x4,x2,x3 wrong, x4=%h", u_microprocessor0.u_core.u_decodestage.u_regfile0.register[4]);
            errors = errors + 1;
        end else begin
            $display("PASS: add x4,x2,x3 (x4=30)");
        end

        // if (u_microprocessor0.u_core.u_decodestage.u_regfile0.register[4] !== 32'hFFFFFFF6) begin // sub: 10-20=-10
        //     $display("FAIL: sub x4,x2,x3 wrong, x4=%h", u_microprocessor0.u_core.u_decodestage.u_regfile0.register[4]);
        //     errors = errors + 1;
        // end else begin
        //     $display("PASS: sub x4,x2,x3");
        // end

        // if (u_microprocessor0.u_core.u_decodestage.u_regfile0.register[4] !== (32'd10 << 20)) begin // sll by x3[4:0]=20
        //     $display("FAIL: sll x4,x2,x3 wrong, x4=%h", u_microprocessor0.u_core.u_decodestage.u_regfile0.register[4]);
        //     errors = errors + 1;
        // end else begin
        //     $display("PASS: sll x4,x2,x3");
        // end

        // if (u_microprocessor0.u_core.u_decodestage.u_regfile0.register[4] !== 32'd1) begin // slt: 10<20
        //     $display("FAIL: slt x4,x2,x3 wrong, x4=%h", u_microprocessor0.u_core.u_decodestage.u_regfile0.register[4]);
        //     errors = errors + 1;
        // end else begin
        //     $display("PASS: slt x4,x2,x3");
        // end

        // if (u_microprocessor0.u_core.u_decodestage.u_regfile0.register[4] !== 32'd1) begin // sltu: 10<20
        //     $display("FAIL: sltu x4,x2,x3 wrong, x4=%h", u_microprocessor0.u_core.u_decodestage.u_regfile0.register[4]);
        //     errors = errors + 1;
        // end else begin
        //     $display("PASS: sltu x4,x2,x3");
        // end

        // if (u_microprocessor0.u_core.u_decodestage.u_regfile0.register[4] !== (32'd10 ^ 32'd20)) begin
        //     $display("FAIL: xor x4,x2,x3 wrong, x4=%h", u_microprocessor0.u_core.u_decodestage.u_regfile0.register[4]);
        //     errors = errors + 1;
        // end else begin
        //     $display("PASS: xor x4,x2,x3");
        // end

        // if (u_microprocessor0.u_core.u_decodestage.u_regfile0.register[4] !== (32'd10 >> 20)) begin // srl by x3[4:0]=20
        //     $display("FAIL: srl x4,x2,x3 wrong, x4=%h", u_microprocessor0.u_core.u_decodestage.u_regfile0.register[4]);
        //     errors = errors + 1;
        // end else begin
        //     $display("PASS: srl x4,x2,x3");
        // end

        // if (u_microprocessor0.u_core.u_decodestage.u_regfile0.register[4] !== ($signed(32'd10) >>> 20)) begin
        //     $display("FAIL: sra x4,x2,x3 wrong, x4=%h", u_microprocessor0.u_core.u_decodestage.u_regfile0.register[4]);
        //     errors = errors + 1;
        // end else begin
        //     $display("PASS: sra x4,x2,x3");
        // end

        // if (u_microprocessor0.u_core.u_decodestage.u_regfile0.register[4] !== (32'd10 | 32'd20)) begin
        //     $display("FAIL: or x4,x2,x3 wrong, x4=%h", u_microprocessor0.u_core.u_decodestage.u_regfile0.register[4]);
        //     errors = errors + 1;
        // end else begin
        //     $display("PASS: or x4,x2,x3");
        // end

        // if (u_microprocessor0.u_core.u_decodestage.u_regfile0.register[4] !== (32'd10 & 32'd20)) begin
        //     $display("FAIL: and x4,x2,x3 wrong, x4=%h", u_microprocessor0.u_core.u_decodestage.u_regfile0.register[4]);
        //     errors = errors + 1;
        // end else begin
        //     $display("PASS: and x4,x2,x3");
        // end

        if (errors == 0) begin
            $display("RESULT: PASS");
        end else begin
            $display("RESULT: FAIL (%0d checks failed)", errors);
        end

        $finish;
    end

endmodule

