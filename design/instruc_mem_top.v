module instruc_mem_top #(
    parameter INIT_FILE = ""
) (
    input wire clk,
    input wire rst,
    input wire request,
    input wire [7:0]  address,

    output reg valid,
    output wire [31:0] data_out
    );

    always @(posedge clk or negedge rst ) begin
        if(!rst)begin
            valid <= 0;
        end
        else begin
            valid <= request;
        end
    end

    instruction_memory #(
        .INIT_FILE(INIT_FILE)
    ) u_memory(
        .clk(clk),
        .request(request),
        .address(address),
        .data_out(data_out)
    );
endmodule
// MODULE_BRIEF: Instruction memory wrapper with request/valid handshake behavior.
