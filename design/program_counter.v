module pc (
    input wire clk,
    input wire rst,
    input wire stall,
    input wire redirect,
    input wire [31:0]next_address,

    output reg [31:0]address_out,
    output wire [31:0] pre_address_pc
);

    always @(posedge clk or negedge rst) begin
    if(!rst)begin
        address_out <= 0;
    end
    else begin
        if (redirect)begin
            address_out <= next_address;
        end
        else if (stall)begin
            address_out <= address_out;
        end
        else begin
            address_out <= address_out + 32'd4;
        end
    end
end

assign pre_address_pc = address_out;
endmodule

// MODULE_BRIEF: Program counter register with reset, stall, and redirect handling.
