module fetch_pipe(
  input wire clk,
  input wire rst,
  input wire [31:0] pre_address_pc,
  input wire [31:0] instruction_fetch,
  input wire next_select,
  input wire branch_result,
  input wire jalr,
  input wire load_use_stall,

  output wire [31:0] pre_address_out,
  output wire [31:0] instruction
);

  reg [31:0] pre_address, instruc;
  wire hazard_stall;
  wire hazard_flush;

  assign hazard_stall = load_use_stall;
  assign hazard_flush = next_select || branch_result || jalr;

  always @ (posedge clk or negedge rst) begin
    if (!rst) begin
      pre_address     <= 32'b0;
      instruc         <= 32'h00000013;
    end
    else begin
      if (hazard_flush) begin
        // Flush the wrong-path instruction already fetched into IF/ID.
        pre_address     <= 32'b0;
        instruc         <= 32'h00000013;
      end
      else if (hazard_stall) begin
    pre_address     <= pre_address;
    instruc         <= instruc;
end
      else begin
        // For other instructions, proceed normally
        pre_address     <= pre_address_pc;
        instruc         <= instruction_fetch;
      end
    end
  end

  assign pre_address_out = pre_address;
  assign instruction     = instruc;
endmodule

//load here means a load instruction like lw,lh,lb is taking place and we cannot
//execute a new instruction until we know the data mem is valid and read is done
// MODULE_BRIEF: Pipeline register between Fetch and Decode with stall/flush behavior.
