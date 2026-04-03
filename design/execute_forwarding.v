module execute_forwarding (
    input wire reg_write_memstage,
    input wire reg_write_wb,
    input wire [4:0] rd_memstage,
    input wire [4:0] rd_wb,
    input wire [4:0] rs1_execute,
    input wire [4:0] rs2_execute,
    input wire [31:0] instruction_execute,
    input wire [31:0] alu_res_out_memstage,
    input wire [31:0] rd_wb_data,
    input wire [31:0] op_a_raw_execute,
    input wire [31:0] opa_mux_out_execute,
    input wire [31:0] opb_mux_out_execute,
    input wire [31:0] op_b_execute,
    input wire load_memstage,
    input wire [31:0] wrap_load_memstage,
    input wire [1:0]  mem_to_reg_memstage,
    input wire [31:0] next_sel_addr_memstage,

    output wire [31:0] alu_in_a,
    output wire [31:0] alu_in_b,
    output wire [31:0] store_data_forward_execute,
    output wire [31:0] branch_op_a,
    output wire [31:0] branch_op_b
);

wire [31:0] memstage_forward_data;

    assign memstage_forward_data = load_memstage                    ? wrap_load_memstage :
                                   (mem_to_reg_memstage == 2'b10)   ? next_sel_addr_memstage :
                                   alu_res_out_memstage;

    wire is_pc_based = (instruction_execute[6:0] == 7'b1100011) ||
                       (instruction_execute[6:0] == 7'b1101111) ||
                       (instruction_execute[6:0] == 7'b0010111);

    assign alu_in_a =
        is_pc_based ? opa_mux_out_execute :
        (reg_write_memstage && (rd_memstage != 0) && (rs1_execute == rd_memstage)) ? memstage_forward_data :
        (reg_write_wb && (rd_wb != 0) && (rs1_execute == rd_wb)) ? rd_wb_data :
        opa_mux_out_execute;

    assign alu_in_b =
        (instruction_execute[6:0] == 7'b0110011) ?
            ((reg_write_memstage && (rd_memstage != 0) && (rs2_execute == rd_memstage)) ? memstage_forward_data :
             (reg_write_wb && (rd_wb != 0) && (rs2_execute == rd_wb)) ? rd_wb_data :
             opb_mux_out_execute)
        : opb_mux_out_execute;

    assign store_data_forward_execute =
        (reg_write_memstage && (rd_memstage != 0) && (rs2_execute == rd_memstage)) ? memstage_forward_data :
        (reg_write_wb && (rd_wb != 0) && (rs2_execute == rd_wb)) ? rd_wb_data :
        op_b_execute;

    // Branch compare also needs freshest rs1/rs2 values in execute stage.
    assign branch_op_a =
        (reg_write_memstage && (rd_memstage != 0) && (rs1_execute == rd_memstage)) ? memstage_forward_data :
        (reg_write_wb && (rd_wb != 0) && (rs1_execute == rd_wb)) ? rd_wb_data :
        op_a_raw_execute;

    assign branch_op_b =
        (reg_write_memstage && (rd_memstage != 0) && (rs2_execute == rd_memstage)) ? memstage_forward_data :
        (reg_write_wb && (rd_wb != 0) && (rs2_execute == rd_wb)) ? rd_wb_data :
        op_b_execute;
        
endmodule
// MODULE_BRIEF: Computes forwarding paths for ALU/store/branch operands to resolve RAW hazards.
