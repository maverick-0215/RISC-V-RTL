`timescale 1ns/1ps
module Hazard4_store_load_order_tb;
    reg clk, rst; reg [31:0] instruction; integer i, errors;
    localparam [6:0] OP_I=7'b0010011, OP_S=7'b0100011, OP_L=7'b0000011; localparam [31:0] NOP=32'h00000013;

    function [31:0] enc_i; input [11:0] imm; input [4:0] r1; input [2:0] f3; input [4:0] rd; input [6:0] op; begin enc_i={imm,r1,f3,rd,op}; end endfunction
    function [31:0] enc_s; input [11:0] imm; input [4:0] r2,r1; input [2:0] f3; input [6:0] op; begin enc_s={imm[11:5],r2,r1,f3,imm[4:0],op}; end endfunction

    microprocessor dut(.clk(clk), .rst(rst));
    always #5 clk = ~clk;

    initial begin
        clk=0; rst=0; instruction=0; errors=0;
        for(i=0;i<32;i=i+1) begin dut.u_instruction_memory.u_memory.mem[i]=NOP; dut.u_data_memory.u_memory.mem[i]=0; end

        // addi x1,0 ; addi x2,77 ; sw x2,0(x1) ; lw x3,0(x1)
        dut.u_instruction_memory.u_memory.mem[0]=enc_i(12'd0,5'd0,3'b000,5'd1,OP_I);
        dut.u_instruction_memory.u_memory.mem[1]=enc_i(12'd77,5'd0,3'b000,5'd2,OP_I);
        dut.u_instruction_memory.u_memory.mem[2]=enc_s(12'd0,5'd2,5'd1,3'b010,OP_S);
        dut.u_instruction_memory.u_memory.mem[3]=enc_i(12'd0,5'd1,3'b010,5'd3,OP_L);

        repeat(2) @(posedge clk); rst=1;
        repeat(80) @(posedge clk);

        if (dut.u_data_memory.u_memory.mem[0] !== 32'd77) begin errors=errors+1; $display("FAIL: mem[0]"); end
        if (dut.u_core.u_decodestage.u_regfile0.register[3] !== 32'd77) begin errors=errors+1; $display("FAIL: x3"); end
        if (errors==0) $display("RESULT: PASS"); else $display("RESULT: FAIL (%0d)", errors);
        $finish;
    end
endmodule
/*
Hazard Documentation:
Instructions:
- addi x1, x0, 0
- addi x2, x0, 77
- sw   x2, 0(x1)
- lw   x3, 0(x1)
Expected Result:
- mem[0] = 77
- x3 = 77
Hazard Covered:
- Store-to-load ordering/data visibility hazard at same address.
Without Hazard Handling:
- load may see old memory value and x3 would be stale.
*/
