module clock_divider #(
    parameter integer TOGGLE_COUNT = 200_000_000
) (
    input  wire clk_in,
    input  wire rst_n,
    output reg  clk_out
);

    reg [27:0] count;

    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            count   <= 28'd0;
            clk_out <= 1'b0;
        end else if (count == TOGGLE_COUNT - 1) begin
            count   <= 28'd0;
            clk_out <= ~clk_out;
        end else begin
            count <= count + 28'd1;
        end
    end

endmodule

// MODULE_BRIEF: Divides the 100 MHz board clock for slow observable FPGA execution.
