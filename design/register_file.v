module registerfile (
    input wire clk,
    input wire rst,
    input wire en,
    input wire [4:0]rs1,
    input wire [4:0]rs2,
    input wire [4:0]rd,
    input wire [31:0]data,

    output wire [31:0]op_a,
    output wire [31:0]op_b,
    output wire [15:0] x1_to_x4_nibbles
);

    reg [31:0] register[31:0];
    integer i;

    always @(posedge clk or negedge rst) begin
        if(!rst)begin
            for (i=0; i<32; i=i+1) begin
                register[i] <= 32'b0;
            end
        end
        else begin
            if (en && (rd != 0)) begin
                register[rd] <= data;
            end
            register[0] <= 32'b0;
        end
    end

    assign op_a = (rs1 != 0) ? ((en && (rd == rs1) && (rd != 0)) ? data : register[rs1]) : 0;
    assign op_b = (rs2 != 0) ? ((en && (rd == rs2) && (rd != 0)) ? data : register[rs2]) : 0;
    assign x1_to_x4_nibbles = {register[4][3:0], register[3][3:0], register[2][3:0], register[1][3:0]};
endmodule
// MODULE_BRIEF: 32x32 register file with dual read ports and single write port.
