module immediategen (
    input  wire [31:0] instr,
    input  wire [2:0]  imm_sel,
    output reg  signed [31:0] imm_out
);
    always @(*) begin
        case (imm_sel)
            3'b000: imm_out = $signed({{20{instr[31]}}, instr[31:20]});
            3'b001: imm_out = $signed({{20{instr[31]}}, instr[31:25], instr[11:7]});
            3'b010: imm_out = $signed({{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0});
            3'b011: imm_out = $signed({{11{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0});
            3'b100: imm_out = $signed({instr[31:12], 12'b0});
            default: imm_out = 32'sd0;
        endcase
    end
endmodule
// MODULE_BRIEF: Generates only the selected RV32I immediate type based on imm_sel.
