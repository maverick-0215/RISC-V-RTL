`timescale 1ns/1ps
module Hazard4_load_branch_tb;
    reg clk, rst; reg [31:0] instruction; integer i, errors;
    localparam [6:0] OP_I=7'b0010011, OP_L=7'b0000011, OP_B=7'b1100011; localparam [31:0] NOP=32'h00000013;

    function [31:0] enc_i; input [11:0] imm; input [4:0] r1; input [2:0] f3; input [4:0] rd; input [6:0] op; begin enc_i={imm,r1,f3,rd,op}; end endfunction
    function [31:0] enc_b; input [12:0] imm; input [4:0] r2,r1; input [2:0] f3; input [6:0] op; begin enc_b={imm[12],imm[10:5],r2,r1,f3,imm[4:1],imm[11],op}; end endfunction

    microprocessor dut(.clk(clk), .rst(rst));
    always #5 clk = ~clk;

    initial begin
        clk=0; rst=0; instruction=0; errors=0;
        for(i=0;i<32;i=i+1) begin dut.u_instruction_memory.u_memory.mem[i]=NOP; dut.u_data_memory.u_memory.mem[i]=0; end

        // lw x2,0(x1); beq x2,x3,+8; addi x4,1(flush); addi x3,2(target)
        dut.u_instruction_memory.u_memory.mem[0]=enc_i(12'd0,5'd0,3'b000,5'd1,OP_I);
        dut.u_instruction_memory.u_memory.mem[1]=enc_i(12'd0,5'd1,3'b010,5'd2,OP_L);
        dut.u_instruction_memory.u_memory.mem[2]=enc_b(13'd8,5'd3,5'd2,3'b000,OP_B);
        dut.u_instruction_memory.u_memory.mem[3]=enc_i(12'd1,5'd0,3'b000,5'd4,OP_I);
        dut.u_instruction_memory.u_memory.mem[4]=enc_i(12'd2,5'd0,3'b000,5'd3,OP_I);

        dut.u_data_memory.u_memory.mem[0]=32'd9;
        repeat(2) @(posedge clk); rst=1;
        dut.u_core.u_decodestage.u_regfile0.register[3]=32'd9;
        repeat(80) @(posedge clk);

        if (dut.u_core.u_decodestage.u_regfile0.register[3] !== 32'd2) begin errors=errors+1; $display("FAIL: x3 target"); end
        if (dut.u_core.u_decodestage.u_regfile0.register[4] !== 32'd0) begin errors=errors+1; $display("FAIL: x4 wrong-path committed"); end
        if (errors==0) $display("RESULT: PASS"); else $display("RESULT: FAIL (%0d)", errors);
        $finish;
    end
endmodule
/*
Hazard Documentation:
Instructions:
- addi x1, x0, 0
- lw   x2, 0(x1)
- beq  x2, x3, +8
- addi x4, x0, 1 (wrong-path)
- addi x3, x0, 2 (target)
Expected Result:
- x3 = 2
- x4 = 0 (must remain unchanged if flush is correct)
Hazard Covered:
- Load-to-branch dependency hazard with branch compare after load.
Without Hazard Handling:
- wrong-path addi may commit and x4 becomes 1.
*/
