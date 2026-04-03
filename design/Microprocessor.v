`timescale 1ns/1ps
module microprocessor #(
    parameter INSTR_MEM_FILE = ""
) (
    input wire clk,
    input wire rst,

    output wire [15:0] x1_to_x4_nibbles
    );

    wire [31:0] instruction_data;
    wire [31:0] pc_address;
    wire [31:0] load_data_out;
    wire [31:0] alu_out_address;
    wire [31:0] store_data;
    wire [3:0]  mask;
    wire instruction_mem_request;
    wire instruc_mem_valid;
    wire data_mem_valid;
    wire data_mem_we_re;
    wire data_mem_request;
    wire load_signal;

    // INSTRUCTION MEMORY
    instruc_mem_top #(
        .INIT_FILE(INSTR_MEM_FILE)
    )u_instruction_memory(
        .clk(clk),
        .rst(rst),
        .request(instruction_mem_request),
        .address(pc_address[9:2]),
        .valid(instruc_mem_valid),
        .data_out(instruction_data)
    );

    //CORE
    core u_core(
        .clk(clk),
        .rst(rst),
        .instruction(instruction_data),
        .load_data_in(load_data_out),
        .mask_singal(mask),
        .load_signal(load_signal),
        .instruction_mem_request(instruction_mem_request),
        .data_mem_we_re(data_mem_we_re),
        .data_mem_request(data_mem_request),
        .instruc_mem_valid(instruc_mem_valid),
        .data_mem_valid(data_mem_valid),
        .store_data_out(store_data),
        .pc_address(pc_address),
        .alu_out_address(alu_out_address),
        .x1_to_x4_nibbles_out(x1_to_x4_nibbles)
    );

    // DATA MEMORY
    data_memory_top u_data_memory(
        .clk(clk),
        .rst(rst),
        .we_re(data_mem_we_re),
        .request(data_mem_request),
        .address(alu_out_address[9:2]),
        .data_in(store_data),
        .mask(mask),
        .load(load_signal),
        .valid(data_mem_valid),
        .data_out(load_data_out)
    );
endmodule
// MODULE_BRIEF: Chip-level integration of core, instruction memory, and data memory blocks.
