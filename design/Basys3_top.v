module basys3_top #(
    parameter USE_SIMULATION_CLOCK = 0,
    parameter integer IMPLEMENTATION_TOGGLE_COUNT = 50_000_000,
    parameter INSTR_MEM_FILE = ""
) (
    input  wire        CLK100MHZ,
    input  wire        rst, // R2 switch for reset
    output wire [15:0] LED
);
    wire rst_n;
    wire slow_clk;
    wire cpu_clk_prebuf;
    wire cpu_clk;
    wire [15:0] x1_to_x4_nibbles_debug;

    // Use external reset switch: rst=0 reset asserted, rst=1 run.
    assign rst_n = rst;

    // Divide onboard 100MHz clock to 1Hz for observable LED updates on FPGA.
    clock_divider #(
        .TOGGLE_COUNT(IMPLEMENTATION_TOGGLE_COUNT)
    ) u_clk_divider (
        .clk_in(CLK100MHZ),
        .rst_n(rst_n),
        .clk_out(slow_clk)
    );

    // Simulation mode: use direct input clock. Implementation mode: use divided clock.
    assign cpu_clk_prebuf = USE_SIMULATION_CLOCK ? CLK100MHZ : slow_clk;

    // Drive CPU clock on a global buffer for predictable clock routing.
`ifdef __ICARUS__
    // Icarus does not model Xilinx BUFG; use direct connection for RTL simulation.
    assign cpu_clk = cpu_clk_prebuf;
`else
    BUFG u_cpu_clk_bufg (
        .I(cpu_clk_prebuf),
        .O(cpu_clk)
    );
`endif

    microprocessor #(
        .INSTR_MEM_FILE(INSTR_MEM_FILE)
    ) u_microprocessor0 (
        .clk(cpu_clk),
        .rst(rst_n),
        .x1_to_x4_nibbles(x1_to_x4_nibbles_debug)
    );

    // LED[3:0]=x1[3:0], LED[7:4]=x2[3:0], LED[11:8]=x3[3:0], LED[15:12]=x4[3:0]
    assign LED = x1_to_x4_nibbles_debug;

endmodule

// MODULE_BRIEF: Board-level wrapper: handles clock/reset and exposes register nibble debug on LEDs.
