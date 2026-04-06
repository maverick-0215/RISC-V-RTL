`timescale 1ns/1ps
module microprocessor_tb();

reg clk;
reg [31:0] instruction;
reg rst;

////////////////////////////////////////////////////
// OPCODES
////////////////////////////////////////////////////
parameter OP_RTYPE = 7'b0110011;
parameter OP_LOAD  = 7'b0000011;
parameter OP_STORE = 7'b0100011;

////////////////////////////////////////////////////
// FUNCT3
////////////////////////////////////////////////////
parameter F3_ADD_SUB = 3'b000;

// ALU
parameter F3_ADD = 3'b000;
parameter F3_AND = 3'b111;

// LOAD
parameter F3_LB  = 3'b000;
parameter F3_LH  = 3'b001;
parameter F3_LW  = 3'b010;
parameter F3_LBU = 3'b100;
parameter F3_LHU = 3'b101;

// STORE
parameter F3_SB  = 3'b000;
parameter F3_SH  = 3'b001;
parameter F3_SW  = 3'b010;

////////////////////////////////////////////////////
// FUNCT7
////////////////////////////////////////////////////
parameter F7_ADD = 7'b0000000;

////////////////////////////////////////////////////
// REGISTERS
////////////////////////////////////////////////////
parameter R0  = 5'd0;
parameter R1  = 5'd1;
parameter R5  = 5'd5;
parameter R6  = 5'd6;
parameter R7  = 5'd7;
parameter R8  = 5'd8;
parameter R9  = 5'd9;
parameter R10 = 5'd10;
parameter R11 = 5'd11;
parameter R12 = 5'd12;
parameter R13 = 5'd13;
parameter R14 = 5'd14;
parameter R20 = 5'd20;
parameter R21 = 5'd21;
parameter R22 = 5'd22;

////////////////////////////////////////////////////
// CLOCK
////////////////////////////////////////////////////
always #5 clk = ~clk;

////////////////////////////////////////////////////
// DUT
////////////////////////////////////////////////////
microprocessor u_microprocessor0
(
    .clk(clk),
    .instruction(instruction),
    .rst(rst)
);

////////////////////////////////////////////////////
// TEST PROGRAM
////////////////////////////////////////////////////
initial begin
clk = 0;

////////////////////////////////////////////////////
// DATA MEMORY INIT
////////////////////////////////////////////////////
// mem[0] = 32'hFF0077AA
u_microprocessor0.u_data_memory.u_memory.mem[0] <= 32'hFF0077AA;

////////////////////////////////////////////////////
// PROGRAM
// All loads: load INTO x5 FROM mem[0]
// All stores: store FROM x5 TO mem[0]
// Address always = 0 using x0 as base for easy wave cheaking 
//comment out  or remove comment for cheaking instruction simulation
////////////////////////////////////////////////////

// lb x5,0(x0)   -> load signed byte from mem[0] into x5
//u_microprocessor0.u_instruction_memory.u_memory.mem[0]
//<= {12'd0, R0, F3_LB, R5, OP_LOAD};

// lh x5,0(x0)   -> load signed halfword from mem[0] into x5
//u_microprocessor0.u_instruction_memory.u_memory.mem[0]
//<= {12'd0, R0, F3_LH, R5, OP_LOAD};

// lw x5,0(x0)   -> load word from mem[0] into x5
//u_microprocessor0.u_instruction_memory.u_memory.mem[0]
//<= {12'd0, R0, F3_LW, R5, OP_LOAD};

// lbu x5,0(x0)  -> load unsigned byte from mem[0] into x5
//u_microprocessor0.u_instruction_memory.u_memory.mem[0]
//<= {12'd0, R0, F3_LBU, R5, OP_LOAD};

// lhu x5,0(x0)  -> load unsigned halfword from mem[0] into x5
//u_microprocessor0.u_instruction_memory.u_memory.mem[0]
//<= {12'd0, R0, F3_LHU, R5, OP_LOAD};

////////////////////////////////////////////////////
// STORES
////////////////////////////////////////////////////
//u_microprocessor0.u_core.u_decodestage.u_regfile0.register[5]<= 32'hAABB77FF;

// sb x5,0(x0)   -> store low byte of x5 into mem[0]
//u_microprocessor0.u_instruction_memory.u_memory.mem[0]
//<= {7'd0, R5, R0, F3_SB, 5'd0, OP_STORE};

// sh x5,0(x0)   -> store low halfword of x5 into mem[0]
//u_microprocessor0.u_instruction_memory.u_memory.mem[0]
//<= {7'd0, R5, R0, F3_SH, 5'd0, OP_STORE};

// sw x5,0(x0)   -> store full word of x5 into mem[0]
u_microprocessor0.u_instruction_memory.u_memory.mem[0]
<= {7'd0, R5, R0, F3_SW, 5'd0, OP_STORE};

////////////////////////////////////////////////////

rst = 0;
#20 rst = 1;
u_microprocessor0.u_core.u_decodestage.u_regfile0.register[5]<= 32'hAABB44FF;


#100;
$finish;
end

endmodule