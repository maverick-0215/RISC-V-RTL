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

        // ACTIVE TEST (default):
        //add x4, x2, x3
        //add x5, x5, x6
        //add x6, x8, x9
        //add x7, x31, x30
        //add x8, x8, x30
        
//        u_microprocessor0.u_instruction_memory.u_memory.mem[0] = enc_r(7'b0000000, 5'd3, 5'd2, 3'b000, 5'd4, OP_R);  // add x4, x2, x3
//        u_microprocessor0.u_instruction_memory.u_memory.mem[1] = enc_r(7'b0000000, 5'd6, 5'd5, 3'b000, 5'd5, OP_R);  // add x5, x5, x6
//        u_microprocessor0.u_instruction_memory.u_memory.mem[2] = enc_r(7'b0000000, 5'd9, 5'd8, 3'b000, 5'd6, OP_R); // add x6, x8, x9
//        u_microprocessor0.u_instruction_memory.u_memory.mem[3] = enc_r(7'b0000000, 5'd30, 5'd31, 3'b000, 5'd7, OP_R);// add x7, x11, x12
//        u_microprocessor0.u_instruction_memory.u_memory.mem[4] = enc_r(7'b0000000, 5'd30, 5'd8, 3'b000, 5'd8, OP_R);// add x8, x14, x15

//// ================= SUB =================
// sub x4, x2, x3 
// sub x5, x2, x6  
// sub x6, x11, x7 
// sub x7, x31, x7
// sub x8, x30, x31

//u_microprocessor0.u_instruction_memory.u_memory.mem[0] = enc_r(7'b0100000, 5'd3, 5'd2, 3'b000, 5'd4, OP_R);
//u_microprocessor0.u_instruction_memory.u_memory.mem[1] = enc_r(7'b0100000, 5'd2, 5'd6, 3'b000, 5'd5, OP_R); 
//u_microprocessor0.u_instruction_memory.u_memory.mem[2] = enc_r(7'b0100000, 5'd11, 5'd7, 3'b000, 5'd6, OP_R);
//u_microprocessor0.u_instruction_memory.u_memory.mem[3] = enc_r(7'b0100000, 5'd31, 5'd7, 3'b000, 5'd7, OP_R);
//u_microprocessor0.u_instruction_memory.u_memory.mem[4] = enc_r(7'b0100000, 5'd30, 5'd31, 3'b000, 5'd8, OP_R);


//// ================= SLL =================
// sll x4, x2, x3[4:0]
// sll x7, x5, x6[4:0]
// sll x10, x8, x9[4:0]
// sll x13, x11, x12[4:0]
// sll x16, x14, x15[4:0]

//u_microprocessor0.u_instruction_memory.u_memory.mem[0] = enc_r(7'b0000000, 5'd3, 5'd2, 3'b001, 5'd4, OP_R);
//u_microprocessor0.u_instruction_memory.u_memory.mem[1] = enc_r(7'b0000000, 5'd6, 5'd5, 3'b001, 5'd5, OP_R);
//u_microprocessor0.u_instruction_memory.u_memory.mem[2] = enc_r(7'b0000000, 5'd9, 5'd8, 3'b001, 5'd6, OP_R);
//u_microprocessor0.u_instruction_memory.u_memory.mem[3] = enc_r(7'b0000000, 5'd12, 5'd11, 3'b001, 5'd7, OP_R);
//u_microprocessor0.u_instruction_memory.u_memory.mem[4] = enc_r(7'b0000000, 5'd15, 5'd14, 3'b001, 5'd8, OP_R);


//// ================= SLT =================
// slt x4, x4, x3
// slt x7, x5, x6
// slt x10, x10, x9
// slt x13, x11, x12
// slt x16, x31, x30

//u_microprocessor0.u_instruction_memory.u_memory.mem[0] = enc_r(7'b0000000, 5'd3, 5'd4, 3'b010, 5'd4, OP_R);
//u_microprocessor0.u_instruction_memory.u_memory.mem[1] = enc_r(7'b0000000, 5'd6, 5'd5, 3'b010, 5'd5, OP_R);
//u_microprocessor0.u_instruction_memory.u_memory.mem[2] = enc_r(7'b0000000, 5'd9, 5'd10, 3'b010, 5'd6, OP_R);
//u_microprocessor0.u_instruction_memory.u_memory.mem[3] = enc_r(7'b0000000, 5'd12, 5'd11, 3'b010, 5'd7, OP_R);
//u_microprocessor0.u_instruction_memory.u_memory.mem[4] = enc_r(7'b0000000, 5'd30, 5'd31, 3'b010, 5'd8, OP_R);


//// ================= SLTU =================
// sltu x4, x4, x3
// sltu x5, x5, x6
// sltu x6, x10, x9
// sltu x7, x31, x30
// sltu x8, x31, x8

//u_microprocessor0.u_instruction_memory.u_memory.mem[0] = enc_r(7'b0000000, 5'd3, 5'd4, 3'b011, 5'd4, OP_R);
//u_microprocessor0.u_instruction_memory.u_memory.mem[1] = enc_r(7'b0000000, 5'd6, 5'd5, 3'b011, 5'd5, OP_R);
//u_microprocessor0.u_instruction_memory.u_memory.mem[2] = enc_r(7'b0000000, 5'd9, 5'd10, 3'b011, 5'd6, OP_R);
//u_microprocessor0.u_instruction_memory.u_memory.mem[3] = enc_r(7'b0000000, 5'd30, 5'd31, 3'b011, 5'd7, OP_R);
//u_microprocessor0.u_instruction_memory.u_memory.mem[4] = enc_r(7'b0000000, 5'd8, 5'd31, 3'b011, 5'd8, OP_R);


//// ================= XOR =================
// xor x4, x2, x3
// xor x5, x5, x6
// xor x6, x8, x8
// xor x7, x11, x12
// xor x8, x31, x0

//u_microprocessor0.u_instruction_memory.u_memory.mem[0] = enc_r(7'b0000000, 5'd3, 5'd2, 3'b100, 5'd4, OP_R);
//u_microprocessor0.u_instruction_memory.u_memory.mem[1] = enc_r(7'b0000000, 5'd6, 5'd5, 3'b100, 5'd5, OP_R);
//u_microprocessor0.u_instruction_memory.u_memory.mem[2] = enc_r(7'b0000000, 5'd8, 5'd8, 3'b100, 5'd6, OP_R);
//u_microprocessor0.u_instruction_memory.u_memory.mem[3] = enc_r(7'b0000000, 5'd12, 5'd11, 3'b100, 5'd7, OP_R);
//u_microprocessor0.u_instruction_memory.u_memory.mem[4] = enc_r(7'b0000000, 5'd0, 5'd31, 3'b100, 5'd8, OP_R);


//// ================= SRL =================
// srl x4, x18, x3[4:0]
// srl x5, x5, x6[4:0]
// srl x6, x8, x0[4:0]
// srl x7, x11, x12[4:0]
// srl x8, x14, x15[4:0]

//u_microprocessor0.u_instruction_memory.u_memory.mem[0] = enc_r(7'b0000000, 5'd3, 5'd18, 3'b101, 5'd4, OP_R);
//u_microprocessor0.u_instruction_memory.u_memory.mem[1] = enc_r(7'b0000000, 5'd6, 5'd5, 3'b101, 5'd5, OP_R);
//u_microprocessor0.u_instruction_memory.u_memory.mem[2] = enc_r(7'b0000000, 5'd0, 5'd8, 3'b101, 5'd6, OP_R);
//u_microprocessor0.u_instruction_memory.u_memory.mem[3] = enc_r(7'b0000000, 5'd12, 5'd11, 3'b101, 5'd7, OP_R);
//u_microprocessor0.u_instruction_memory.u_memory.mem[4] = enc_r(7'b0000000, 5'd15, 5'd14, 3'b101, 5'd8, OP_R);


//// ================= SRA =================
// sra x4, x4, x3[4:0]
// sra x5, x16, x6[4:0]
// sra x6, x8, x33[4:0]
// sra x7, x11, x32[4:0]
// sra x8, x30, x33[4:0]

//u_microprocessor0.u_instruction_memory.u_memory.mem[0] = enc_r(7'b0100000, 5'd3, 5'd4, 3'b101, 5'd4, OP_R);
//u_microprocessor0.u_instruction_memory.u_memory.mem[1] = enc_r(7'b0100000, 5'd6, 5'd16, 3'b101, 5'd5, OP_R);
//u_microprocessor0.u_instruction_memory.u_memory.mem[2] = enc_r(7'b0100000, 5'd33, 5'd8, 3'b101, 5'd6, OP_R);
//u_microprocessor0.u_instruction_memory.u_memory.mem[3] = enc_r(7'b0100000, 5'd32, 5'd11, 3'b101, 5'd7, OP_R);
//u_microprocessor0.u_instruction_memory.u_memory.mem[4] = enc_r(7'b0100000, 5'd33, 5'd30, 3'b101, 5'd8, OP_R);


//// ================= OR =================
// or x4, x2, x3
// or x7, x5, x6
// or x10, x8, x9
// or x13, x11, x12
// or x16, x14, x15

//u_microprocessor0.u_instruction_memory.u_memory.mem[0] = enc_r(7'b0000000, 5'd3, 5'd2, 3'b110, 5'd4, OP_R);
//u_microprocessor0.u_instruction_memory.u_memory.mem[1] = enc_r(7'b0000000, 5'd6, 5'd5, 3'b110, 5'd5, OP_R);
//u_microprocessor0.u_instruction_memory.u_memory.mem[2] = enc_r(7'b0000000, 5'd9, 5'd8, 3'b110, 5'd6, OP_R);
//u_microprocessor0.u_instruction_memory.u_memory.mem[3] = enc_r(7'b0000000, 5'd12, 5'd11, 3'b110, 5'd7, OP_R);
//u_microprocessor0.u_instruction_memory.u_memory.mem[4] = enc_r(7'b0000000, 5'd15, 5'd14, 3'b110, 5'd8, OP_R);


//// ================= AND =================
// and x4, x2, x3
// and x7, x5, x6
// and x10, x8, x9
// and x13, x11, x12
// and x16, x14, x15

u_microprocessor0.u_instruction_memory.u_memory.mem[0] = enc_r(7'b0000000, 5'd3, 5'd2, 3'b111, 5'd4, OP_R);
u_microprocessor0.u_instruction_memory.u_memory.mem[1] = enc_r(7'b0000000, 5'd6, 5'd5, 3'b111, 5'd5, OP_R);
u_microprocessor0.u_instruction_memory.u_memory.mem[2] = enc_r(7'b0000000, 5'd9, 5'd8, 3'b111, 5'd6, OP_R);
u_microprocessor0.u_instruction_memory.u_memory.mem[3] = enc_r(7'b0000000, 5'd12, 5'd11, 3'b111, 5'd7, OP_R);
u_microprocessor0.u_instruction_memory.u_memory.mem[4] = enc_r(7'b0000000, 5'd15, 5'd14, 3'b111, 5'd8, OP_R);

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
        u_microprocessor0.u_core.u_decodestage.u_regfile0.register[0]  = 32'd0;
        u_microprocessor0.u_core.u_decodestage.u_regfile0.register[1]  = 32'd1;
        u_microprocessor0.u_core.u_decodestage.u_regfile0.register[2]  = 32'd2;
        u_microprocessor0.u_core.u_decodestage.u_regfile0.register[3]  = 32'd3;
        u_microprocessor0.u_core.u_decodestage.u_regfile0.register[4]  = 32'd4;
        u_microprocessor0.u_core.u_decodestage.u_regfile0.register[5]  = 32'd5;
        u_microprocessor0.u_core.u_decodestage.u_regfile0.register[6]  = 32'd6;
        u_microprocessor0.u_core.u_decodestage.u_regfile0.register[7]  = 32'd7;
        u_microprocessor0.u_core.u_decodestage.u_regfile0.register[8]  = 32'd8;
        u_microprocessor0.u_core.u_decodestage.u_regfile0.register[9]  = 32'd9;
        u_microprocessor0.u_core.u_decodestage.u_regfile0.register[10] = 32'd10;
        u_microprocessor0.u_core.u_decodestage.u_regfile0.register[11] = 32'd11;
        u_microprocessor0.u_core.u_decodestage.u_regfile0.register[12] = 32'd12;
        u_microprocessor0.u_core.u_decodestage.u_regfile0.register[13] = 32'd13;
        u_microprocessor0.u_core.u_decodestage.u_regfile0.register[14] = 32'd14;
        u_microprocessor0.u_core.u_decodestage.u_regfile0.register[15] = 32'd15;
        u_microprocessor0.u_core.u_decodestage.u_regfile0.register[16] = 32'd16;
        u_microprocessor0.u_core.u_decodestage.u_regfile0.register[17] = 32'd17;
        u_microprocessor0.u_core.u_decodestage.u_regfile0.register[18] = 32'd18;
        u_microprocessor0.u_core.u_decodestage.u_regfile0.register[19] = 32'd19;
        u_microprocessor0.u_core.u_decodestage.u_regfile0.register[20] = 32'd20;
        u_microprocessor0.u_core.u_decodestage.u_regfile0.register[21] = 32'd21;
        u_microprocessor0.u_core.u_decodestage.u_regfile0.register[22] = 32'd22;
        u_microprocessor0.u_core.u_decodestage.u_regfile0.register[23] = 32'd23;
        u_microprocessor0.u_core.u_decodestage.u_regfile0.register[24] = 32'd24;
        u_microprocessor0.u_core.u_decodestage.u_regfile0.register[25] = 32'd25;
        u_microprocessor0.u_core.u_decodestage.u_regfile0.register[26] = 32'd26;
        u_microprocessor0.u_core.u_decodestage.u_regfile0.register[27] = 32'd27;
        u_microprocessor0.u_core.u_decodestage.u_regfile0.register[28] = 32'd28;
        u_microprocessor0.u_core.u_decodestage.u_regfile0.register[29] = 32'd29;
        u_microprocessor0.u_core.u_decodestage.u_regfile0.register[30] = -8;
        u_microprocessor0.u_core.u_decodestage.u_regfile0.register[31] = -10;

        #110;

        $finish;
    end

endmodule

