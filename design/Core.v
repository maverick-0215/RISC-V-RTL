module core (
    input wire clk,
    input wire rst,
    input wire data_mem_valid,//flag from data memory
    input wire instruc_mem_valid,//flag from instruction memory
    input wire [31:0] instruction,//from instruction memory
    input wire [31:0] load_data_in,//from data memory

    output wire load_signal,
    output wire instruction_mem_request,
    output wire data_mem_we_re,
    output wire data_mem_request,
    output wire [3:0]  mask_singal,
    output wire [31:0] store_data_out,
    output wire [31:0] alu_out_address,
    output wire [31:0] pc_address,
    output wire [15:0] x1_to_x4_nibbles_out
    );

    wire [31:0] instruction_fetch , instruction_decode , instruction_execute;
    wire [31:0] instruction_memstage , instruction_wb;
    wire [31:0] pre_pc_addr_fetch , pre_pc_addr_decode , pre_pc_addr_execute;
    wire [31:0] pre_pc_addr_memstage;
    wire load_decode , load_execute , load_memstage;
    wire store_decode , store_execute , store_memstage;
    wire jalr_decode , jalr_execute;
    wire next_sel_decode , next_sel_execute;
    wire reg_write_decode , reg_write_execute , reg_write_memstage , reg_write_wb;
    wire branch_en_decode , branch_en_execute;
    wire branch_result_execute;
    wire [3:0]  mask;
    wire [4:0]  alu_control_decode , alu_control_execute;
    wire [1:0]  mem_to_reg_decode , mem_to_reg_execute;
    wire [1:0]  mem_to_reg_memstage , mem_to_reg_wb;
    wire [4:0]  rs1_decode , rs1_execute;
    wire [4:0]  rs2_decode , rs2_execute;
    wire [4:0]  rd_memstage , rd_wb;
    wire [31:0] op_b_decode , op_b_execute , op_b_memstage;
    wire [31:0] opa_mux_out_decode , opa_mux_out_execute;
    wire [31:0] opb_mux_out_decode , opb_mux_out_execute;
    wire [31:0] alu_res_out_execute , alu_res_out_memstage;
    wire [31:0] alu_res_out_wb;
    wire [31:0] next_sel_address_execute , next_sel_address_memstage;
    wire [31:0] next_sel_address_wb;
    wire [31:0] wrap_load_memstage , wrap_load_wb;
    wire [31:0] rd_wb_data;
    wire [31:0] alu_in_a , alu_in_b;
    wire [31:0] store_data_forward_execute;
    wire [31:0] branch_op_a , branch_op_b;
    wire [2:0] fun3_decode , fun3_execute; 
     wire [31:0] op_a_raw_decode , op_a_raw_execute; 
wire [31:0] jalr_aligned;
wire hazard_flush;
wire load_use_hazard;
wire [4:0] rd_execute;
assign jalr_aligned = alu_res_out_execute & 32'hFFFFFFFE;
assign rd_execute = instruction_execute[11:7];
assign load_use_hazard = load_execute && (rd_execute != 5'd0) &&
                        ((rd_execute == rs1_decode) || (rd_execute == rs2_decode));



    //FETCH STAGE
    fetch u_fetchstage(
        .clk(clk),
        .rst(rst),
        .load_use_stall(load_use_hazard),
        .jalr_execute(jalr_execute), 
        .next_sel(next_sel_execute),
        .branch_result(branch_result_execute),
        .next_address(jalr_execute ? jalr_aligned : alu_res_out_execute),
        .instruction_fetch(instruction),
        .instruction(instruction_fetch),
        .request(instruction_mem_request),
        .pre_address_pc(pre_pc_addr_fetch),
        .address_out(pc_address)
    );

   fetch_pipe u_fetchpipeline(
    .clk(clk),
    .rst(rst),
   .pre_address_pc(pre_pc_addr_fetch),
    .instruction_fetch(instruction_fetch),
    .pre_address_out(pre_pc_addr_decode),
    .instruction(instruction_decode),

    // ? CORRECT (EXECUTE STAGE)
    .next_select(next_sel_execute),
    .branch_result(branch_result_execute),
    .jalr(jalr_execute),

    .load_use_stall(load_use_hazard)
);

    //DECODE STAGE
    decode u_decodestage(
        .clk(clk),
        .rst(rst),
        .valid(data_mem_valid),
        .load_control_signal(load_execute),
        .reg_write_en_in(reg_write_wb),
        .instruction(instruction_decode),
        .pc_address(pre_pc_addr_decode),
        .rd_wb_data(rd_wb_data),
        .rs1(rs1_decode),
        .rs2(rs2_decode),
        .load(load_decode),
        .store(store_decode),
        .jalr(jalr_decode),
        .next_sel(next_sel_decode),
        .reg_write_en_out(reg_write_decode),
        .mem_to_reg(mem_to_reg_decode),
        .branch_result(branch_en_decode),
        .opb_data(op_b_decode),
        .instruction_rd(instruction_wb),
        .alu_control(alu_control_decode),
        .opa_mux_out(opa_mux_out_decode),
        .opb_mux_out(opb_mux_out_decode),
        .op_a_raw(op_a_raw_decode),
        .x1_to_x4_nibbles_out(x1_to_x4_nibbles_out)
    );

    //DECODE STAGE PIPELINE
    decode_pipe u_decodepipeline(
        .clk(clk),
        .rst(rst),
        .load_in(load_decode),
        .store_in(store_decode),
        .jalr_in(jalr_decode),
        .next_sel_in(next_sel_decode),
        .mem_to_reg_in(mem_to_reg_decode),
       .branch_result_in(branch_en_decode),
        .fun3_in(instruction_decode[14:12]),      // NEW
        .opb_data_in(op_b_decode),
        .alu_control_in(alu_control_decode),
        .opa_mux_in(opa_mux_out_decode),
        .opb_mux_in(opb_mux_out_decode),
        .pre_address_in(pre_pc_addr_decode),
        .instruction_in(instruction_decode),
        .reg_write_in(reg_write_decode),
        .rs1_in(rs1_decode),
        .rs2_in(rs2_decode),
        .op_a_raw_in(op_a_raw_decode),
        .reg_write_out(reg_write_execute),
        .jalr_out(jalr_execute),
        .load(load_execute),
        .store(store_execute),
        .next_sel(next_sel_execute),
        .mem_to_reg(mem_to_reg_execute),
        .branch_result(branch_en_execute),        // carries enable flag out of decode_pipe
        .fun3_out(fun3_execute),                  // NEW
        .opb_data_out(op_b_execute),
        .alu_control(alu_control_execute),
        .opa_mux_out(opa_mux_out_execute),
        .opb_mux_out(opb_mux_out_execute),
        .pre_address_out(pre_pc_addr_execute),
        .instruction_out(instruction_execute),
        .rs1_out(rs1_execute),
        .rs2_out(rs2_execute),
        .op_a_raw_out(op_a_raw_execute),
            .flush(hazard_flush | load_use_hazard)
    );

    execute_forwarding u_execute_forwarding(
        .reg_write_memstage(reg_write_memstage),
        .reg_write_wb(reg_write_wb),
        .rd_memstage(rd_memstage),
        .rd_wb(rd_wb),
        .rs1_execute(rs1_execute),
        .rs2_execute(rs2_execute),
        .instruction_execute(instruction_execute),
        .alu_res_out_memstage(alu_res_out_memstage),
        .rd_wb_data(rd_wb_data),
        .op_a_raw_execute(op_a_raw_execute),
        .opa_mux_out_execute(opa_mux_out_execute),
        .opb_mux_out_execute(opb_mux_out_execute),
        .op_b_execute(op_b_execute),
        .load_memstage(load_memstage),
        .wrap_load_memstage(wrap_load_memstage),
        .alu_in_a(alu_in_a),
        .alu_in_b(alu_in_b),
        .store_data_forward_execute(store_data_forward_execute),
        .branch_op_a(branch_op_a),
        .branch_op_b(branch_op_b),
        .mem_to_reg_memstage(mem_to_reg_memstage),
    .next_sel_addr_memstage(next_sel_address_memstage)
    );

// BRANCH EVALUATED IN EXECUTE with forwarded values
    branch u_branch_execute (
        .en(branch_en_execute),
        .op_a(branch_op_a),
        .op_b(branch_op_b),
        .fun3(fun3_execute),
        .result(branch_result_execute)
    );

    //EXECUTE STAGE
    execute u_executestage(
        .a_i(alu_in_a),
        .b_i(alu_in_b),
      .pc_address(pre_pc_addr_execute),  // ? FIX
        .alu_control(alu_control_execute),
        .alu_res_out(alu_res_out_execute),
        .next_sel_address(next_sel_address_execute)
    );

    //EXECUTE STAGE PIPELINE
    execute_pipe u_executepipeline(
        .clk(clk),
        .rst(rst),
        .load_in(load_execute),
        .store_in(store_execute),
        .opb_datain(store_data_forward_execute),
        .alu_res(alu_res_out_execute),
        .mem_reg_in(mem_to_reg_execute),
        .next_sel_addr(next_sel_address_execute),
        .pre_address_in(pre_pc_addr_execute),
        .instruction_in(instruction_execute),
        .reg_write_in(reg_write_execute),
        .reg_write_out(reg_write_memstage),
        .load_out(load_memstage),
        .store_out(store_memstage),
        .opb_dataout(op_b_memstage),
        .alu_res_out(alu_res_out_memstage),
        .mem_reg_out(mem_to_reg_memstage),
        .next_sel_address(next_sel_address_memstage),
        .pre_address_out(pre_pc_addr_memstage),
        .instruction_out(instruction_memstage)
    );

    //MEMORY STAGE
    memory_stage u_memorystage(
        .rst(rst),
        .load(load_memstage),
        .store(store_memstage),
        .op_b(op_b_memstage),
        .instruction(instruction_memstage),
        .alu_out_address(alu_res_out_memstage),
        .wrap_load_in(load_data_in),
        .mask(mask),
        .data_valid(data_mem_valid),
        .valid(instruc_mem_valid),
        .we_re(data_mem_we_re),
        .request(data_mem_request),
        .store_data_out(store_data_out),
        .wrap_load_out(wrap_load_memstage)
    );

    assign rd_memstage = instruction_memstage[11:7];
    assign rd_wb = instruction_wb[11:7];
    assign alu_out_address = alu_res_out_memstage;
    assign mask_singal = mask ;
    assign load_signal = load_memstage;
    assign hazard_flush = next_sel_execute | branch_result_execute | jalr_execute;
    //MEMORY STAGE PIPELINE
    memory_pipe u_memstagepipeline(
        .clk(clk),
        .rst(rst),
        .mem_reg_in(mem_to_reg_memstage),
        .wrap_load_in(wrap_load_memstage),
        .alu_res(alu_res_out_memstage),
        .next_sel_addr(next_sel_address_memstage),
        .pre_address_in(pre_pc_addr_memstage),
        .instruction_in(instruction_memstage),
        .reg_write_in(reg_write_memstage),
        .reg_write_out(reg_write_wb),
        .alu_res_out(alu_res_out_wb),
        .mem_reg_out(mem_to_reg_wb),
        .next_sel_address(next_sel_address_wb),
        .instruction_out(instruction_wb),
        .pre_address_out(),
        .wrap_load_out(wrap_load_wb)
    );

    //WRITE BACK STAGE
    write_back u_wbstage(
        .mem_to_reg(mem_to_reg_wb),
        .alu_out(alu_res_out_wb),
        .data_mem_out(wrap_load_wb),
        .next_sel_address(next_sel_address_wb),
        .rd_sel_mux_out(rd_wb_data)
    );
endmodule
// MODULE_BRIEF: Top pipeline core integrating fetch/decode/execute/memory/writeback with hazards.
