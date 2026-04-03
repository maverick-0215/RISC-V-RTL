`timescale 1ns/1ps
module Hazard4_load_use_tb;
    reg clk, rst; reg [31:0] instruction; integer i, errors;
    localparam [6:0] OP_R=7'b0110011, OP_I=7'b0010011, OP_L=7'b0000011; localparam [31:0] NOP=32'h00000013;

    function [31:0] enc_r; input [6:0] f7; input [4:0] r2,r1; input [2:0] f3; input [4:0] rd; input [6:0] op; begin enc_r={f7,r2,r1,f3,rd,op}; end endfunction
    function [31:0] enc_i; input [11:0] imm; input [4:0] r1; input [2:0] f3; input [4:0] rd; input [6:0] op; begin enc_i={imm,r1,f3,rd,op}; end endfunction

    microprocessor dut(.clk(clk), .rst(rst));
    always #5 clk = ~clk;

    initial begin
        clk=0; rst=0; instruction=0; errors=0;
        for(i=0;i<32;i=i+1) begin dut.u_instruction_memory.u_memory.mem[i]=NOP; dut.u_data_memory.u_memory.mem[i]=0; end

        // x1 base, lw x2,0(x1); add x3,x2,x4 (load-use hazard)
        dut.u_instruction_memory.u_memory.mem[0]=enc_i(12'd0,5'd0,3'b000,5'd1,OP_I);
        dut.u_instruction_memory.u_memory.mem[1]=enc_i(12'd0,5'd1,3'b010,5'd2,OP_L);
        dut.u_instruction_memory.u_memory.mem[2]=enc_r(7'b0000000,5'd4,5'd2,3'b000,5'd3,OP_R);
        dut.u_data_memory.u_memory.mem[0]=32'd21;

        repeat(2) @(posedge clk); rst=1;
        dut.u_core.u_decodestage.u_regfile0.register[4]=32'd4;
        repeat(60) @(posedge clk);

        if (dut.u_core.u_decodestage.u_regfile0.register[2] !== 32'd21) begin errors=errors+1; $display("FAIL: x2"); end
        if (dut.u_core.u_decodestage.u_regfile0.register[3] !== 32'd25) begin errors=errors+1; $display("FAIL: x3"); end
        if (errors==0) $display("RESULT: PASS"); else $display("RESULT: FAIL (%0d)", errors);
        $finish;
    end
endmodule
/*
Hazard Documentation:
Instructions:
- addi x1, x0, 0
- lw   x2, 0(x1)
- add  x3, x2, x4
Expected Result:
- x2 = 21
- x3 = 25 (x2 + x4, where x4 = 4)
Hazard Covered:
- Load-use hazard requiring stall/forward.
Without Hazard Handling:
- x3 can use stale x2 and evaluate to 4 or another incorrect value.
*/
