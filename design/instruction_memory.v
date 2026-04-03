module instruction_memory #(
    parameter INIT_FILE = ""
) (
    input wire        clk,
    input wire        request,
    input wire [7:0]  address,
    output reg [31:0] data_out
);

    reg [31:0] mem [0:255];
    integer i;

    initial begin
        for (i = 0; i < 256; i = i + 1) begin
            mem[i] = 32'h00000013; // NOP default
        end

        if (INIT_FILE != "") begin
            $readmemh(INIT_FILE, mem);
        end
        else begin
            // Hardcoded instr_max5.mem (32 instructions from max5 algorithm)
            mem[0]  = 32'h00E00293;  // addi x5,x0,14
            mem[1]  = 32'h00502023;  // sw x5,0(x0)
            mem[2]  = 32'h01B00293;  // addi x5,x0,27
            mem[3]  = 32'h00502223;  // sw x5,4(x0)
            mem[4]  = 32'h00900293;  // addi x5,x0,9
            mem[5]  = 32'h00502423;  // sw x5,8(x0)
            mem[6]  = 32'h01F00293;  // addi x5,x0,31
            mem[7]  = 32'h00502623;  // sw x5,12(x0)
            mem[8]  = 32'h01200293;  // addi x5,x0,18
            mem[9]  = 32'h00502823;  // sw x5,16(x0)
            mem[10] = 32'h00002083;  // lw x1,0(x0)
            mem[11] = 32'h00402103;  // lw x2,4(x0)
            mem[12] = 32'h00802183;  // lw x3,8(x0)
            mem[13] = 32'h00C02203;  // lw x4,12(x0)
            mem[14] = 32'h01002283;  // lw x5,16(x0)
            mem[15] = 32'h00008513;  // addi x10,x1,0   # cur=max=v1
            mem[16] = 32'h00010593;  // addi x11,x2,0   # b=v2
            mem[17] = 32'h02800FEF;  // jal x31,max_fn
            mem[18] = 32'h00018593;  // addi x11,x3,0
            mem[19] = 32'h02000FEF;  // jal x31,max_fn
            mem[20] = 32'h00020593;  // addi x11,x4,0
            mem[21] = 32'h01800FEF;  // jal x31,max_fn
            mem[22] = 32'h00028593;  // addi x11,x5,0
            mem[23] = 32'h01000FEF;  // jal x31,max_fn
            mem[24] = 32'h00050093;  // addi x1,x10,0   # final max to x1
            mem[25] = 32'h00102A23;  // sw x1,20(x0)    # mem[5] = max
            mem[26] = 32'h0180006F;  // jal x0,halt
            mem[27] = 32'h00B52633;  // slt x12,x10,x11 (max_fn)
            mem[28] = 32'h00060463;  // beq x12,x0,ret
            mem[29] = 32'h00058513;  // addi x10,x11,0
            mem[30] = 32'h000F8067;  // jalr x0,x31,0   (ret)
            mem[31] = 32'h0000006F;  // jal x0,0        (halt)
        end
    end

    always @(*) begin
        if (request) begin
            data_out = mem[address];
        end
        else begin
            data_out = 32'b0;
        end
    end

endmodule