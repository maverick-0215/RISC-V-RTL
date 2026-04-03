module fetch (
    input wire clk,
    input wire rst,
    input wire next_sel,
    input wire load_use_stall,
    input wire jalr_execute,
    input wire branch_result,
    input wire [31:0] next_address,
    input wire [31:0] instruction_fetch,

    output reg  request,
    output wire [31:0] address_out,
    output reg  [31:0] instruction,
    output wire [31:0] pre_address_pc
);

    wire hazard_stall;
    wire hazard_redirect;

    assign hazard_stall = load_use_stall;
    assign hazard_redirect = next_sel || branch_result || jalr_execute;

    pc u_pc0 (
        .clk(clk),
        .rst(rst),
        .stall(hazard_stall),
        .redirect(hazard_redirect),
        .next_address(next_address),
        .address_out(address_out),
        .pre_address_pc(pre_address_pc)
    );

    always @ (*) begin
        if (hazard_stall) begin
            request = 1'b0;
        end
        else begin
            request = 1'b1;
        end
    end

    always @ (*) begin
        instruction = instruction_fetch;
    end

endmodule
// MODULE_BRIEF: Fetch stage: program counter progression and instruction request control.
