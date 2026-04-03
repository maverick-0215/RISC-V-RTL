module decode (
    input wire clk,
    input wire rst,
    input wire valid,
    input wire reg_write_en_in,//feedback from execute/writeback stage
    input wire load_control_signal,//feedback
    input wire [31:0] instruction,
    input wire [31:0] pc_address,//for jal,.. instructions
    input wire [31:0] rd_wb_data, //if we have to writeback, the data for it
    input wire [31:0] instruction_rd,//writeback instruction(for rd address)


    //flags/control signals for curr instruction
    output wire load,    
    output wire store,                      
    output wire jalr,
    output wire next_sel,
    output wire branch_result,
    output wire reg_write_en_out,
    output wire [4:0]  alu_control,
    output wire [1:0]  mem_to_reg,//select what writes back to register (ALU result, memory data, PC+4, etc.)
    output wire [4:0]  rs1 , rs2,
    output wire [31:0] opb_data,    //rs2 value
    output wire [31:0] opa_mux_out, //either rs1 or pc
    output wire [31:0] opb_mux_out, //rs2 or immediate
    output wire [31:0] op_a_raw,    //raw rs1 value for branch comparator
    output wire [15:0] x1_to_x4_nibbles_out
    );

    wire branch;
    wire operand_a;//0 for rs1, 1 for pc
    wire operand_b;//0 for rs2 and 1 for imm
    wire mem_en_unused;
    wire [2:0]  imm_sel; //type of imm 
    wire [31:0] op_a , op_b;
    wire [31:0] imm_mux_out;

    // CONTROL UNIT
    controlunit u_cu0 
    (
        .opcode(instruction[6:0]),
        .fun3(instruction[14:12]),
        .fun7(instruction[31:25]),
        .valid(valid),
        .reg_write(reg_write_en_out),
        .imm_sel(imm_sel),
        .next_sel(next_sel),
        .operand_b(operand_b),
        .operand_a(operand_a),
        .mem_to_reg(mem_to_reg),
        .Load(load),
        .Store(store),
        .jalr_out(jalr),
        .Branch(branch),
        .mem_en(mem_en_unused),
        .load_control(load_control_signal),
        .alu_control(alu_control)
    );

    // IMMEDIATE GENERATION
    immediategen u_imm_gen0 (
        .instr(instruction),
        .imm_sel(imm_sel),
        .imm_out(imm_mux_out)
    );

    // REGISTER FILE
    registerfile u_regfile0 
    (
        .clk(clk),
        .rst(rst),
        .en(reg_write_en_in), //for writing to registers
        .rs1(instruction[19:15]),
        .rs2(instruction[24:20]),
        .rd(instruction_rd[11:7]),
        .data(rd_wb_data),
        .op_a(op_a),
        .op_b(op_b),
        .x1_to_x4_nibbles(x1_to_x4_nibbles_out)
    );

    assign rs1 = instruction[19:15];
    assign rs2 = instruction[24:20];
    assign opb_data = op_b ;

    //SELECTION OF PROGRAM COUNTER OR OPERAND A
    mux u_mux1 
    (
        .a(op_a),
        .b(pc_address),
        .sel(operand_a),
        .out(opa_mux_out)
    );
    
    //SELECTION OF OPERAND B OR IMMEDIATE     
    mux u_mux2(
        .a(op_b),
        .b(imm_mux_out),
        .sel(operand_b),
        .out(opb_mux_out)
    );

    //BRANCH
   // Branch enable and fun3 passed to Execute stage for forwarded evaluation
    assign branch_result = branch;   // repurpose output to carry branch ENABLE flag
    assign op_a_raw = op_a;

endmodule
// MODULE_BRIEF: Decode stage: register read, immediate generation, and control signal setup.
