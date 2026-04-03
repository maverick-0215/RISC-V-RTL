`timescale 1ns/1ps

module FPGA_simple_tb;
    reg CLK100MHZ = 0;
    reg rst = 0;
    wire [15:0] LED;

    // Simple FPGA-style top-level simulation.
    // Uses simulation clock and runs instructions from instruction memory.
    basys3_top #(
        .USE_SIMULATION_CLOCK(1),
        .IMPLEMENTATION_TOGGLE_COUNT(2)
    ) uut (
        .CLK100MHZ(CLK100MHZ),
        .rst(rst),
        .LED(LED)
    );

    // 100 MHz equivalent in sim: 10 ns period.
    always #5 CLK100MHZ = ~CLK100MHZ;

    initial begin
        $display("=== FPGA_simple_tb start ===");

        // Hold reset for a few cycles.
        rst = 0;
        repeat (3) @(posedge CLK100MHZ);

        // Release reset and run.
        rst = 1;
        repeat (300) @(posedge CLK100MHZ);

        // End-of-run snapshot (no pass/fail checks).
        $display("LED = 0x%04h", LED);
        $display("x1 = %0d", uut.u_microprocessor0.u_core.u_decodestage.u_regfile0.register[1]);
        $display("x2 = %0d", uut.u_microprocessor0.u_core.u_decodestage.u_regfile0.register[2]);
        $display("x3 = %0d", uut.u_microprocessor0.u_core.u_decodestage.u_regfile0.register[3]);
        $display("x4 = %0d", uut.u_microprocessor0.u_core.u_decodestage.u_regfile0.register[4]);
        $display("x5 = %0d", uut.u_microprocessor0.u_core.u_decodestage.u_regfile0.register[5]);
        $display("mem[0] = %0d", uut.u_microprocessor0.u_data_memory.u_memory.mem[0]);
        $display("mem[1] = %0d", uut.u_microprocessor0.u_data_memory.u_memory.mem[1]);
        $display("mem[2] = %0d", uut.u_microprocessor0.u_data_memory.u_memory.mem[2]);
        $display("mem[3] = %0d", uut.u_microprocessor0.u_data_memory.u_memory.mem[3]);
        $display("mem[4] = %0d", uut.u_microprocessor0.u_data_memory.u_memory.mem[4]);
        $display("mem[5] = %0d", uut.u_microprocessor0.u_data_memory.u_memory.mem[5]);

        $display("=== FPGA_simple_tb end ===");
        $finish;
    end

endmodule
