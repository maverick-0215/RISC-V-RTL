`timescale 1ns/1ps
module Hazard4_raw_gap1_tb;
    reg clk, rst; reg [31:0] instruction; integer i, errors;
    localparam [6:0] OP_R = 7'b0110011, OP_I = 7'b0010011; localparam [31:0] NOP = 32'h00000013;

    function [31:0] enc_r; input [6:0] f7; input [4:0] r2,r1; input [2:0] f3; input [4:0] rd; input [6:0] op; begin enc_r={f7,r2,r1,f3,rd,op}; end endfunction
    function [31:0] enc_i; input [11:0] imm; input [4:0] r1; input [2:0] f3; input [4:0] rd; input [6:0] op; begin enc_i={imm,r1,f3,rd,op}; end endfunction

    microprocessor dut(.clk(clk), .rst(rst));
    always #5 clk = ~clk;

    initial begin
        clk=0; rst=0; instruction=0; errors=0;
        for (i=0;i<32;i=i+1) dut.u_instruction_memory.u_memory.mem[i]=NOP;

        // gap1 RAW on x3 with one independent instruction between producer and consumer
        dut.u_instruction_memory.u_memory.mem[0]=enc_i(12'd5,5'd0,3'b000,5'd1,OP_I);
        dut.u_instruction_memory.u_memory.mem[1]=enc_i(12'd4,5'd0,3'b000,5'd2,OP_I);
        dut.u_instruction_memory.u_memory.mem[2]=enc_r(7'b0000000,5'd2,5'd1,3'b000,5'd3,OP_R);
        dut.u_instruction_memory.u_memory.mem[3]=enc_i(12'd1,5'd0,3'b000,5'd2,OP_I);
        dut.u_instruction_memory.u_memory.mem[4]=enc_r(7'b0000000,5'd1,5'd3,3'b000,5'd4,OP_R);

        repeat (2) @(posedge clk); rst=1;
        repeat (50) @(posedge clk);

        if (dut.u_core.u_decodestage.u_regfile0.register[4] !== 32'd14) begin errors=errors+1; $display("FAIL: x4"); end
        if (errors==0) $display("RESULT: PASS"); else $display("RESULT: FAIL (%0d)", errors);
        $finish;
    end
endmodule
/*
Hazard Documentation:
Instructions:
- addi x1, x0, 5
- addi x2, x0, 4
- add  x3, x1, x2
- addi x2, x0, 1 (gap)
- add  x4, x3, x1
Expected Result:
- x4 = 14
Hazard Covered:
- RAW gap-1 dependency (one instruction separation).
Without Hazard Handling:
- x4 may read old x3 and produce a lower incorrect sum.
*/
