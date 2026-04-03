`timescale 1ns/1ps
module Basys3_top_tb;
    reg CLK100MHZ = 0;
    reg rst = 0; // Reset (active high)
    wire [15:0] LED;
    integer pass_count = 0;
    integer fail_count = 0;
    reg saw_clock_toggle = 0;
    reg [15:0] expected_led;

    // Instantiate the Basys3_top module
    basys3_top #(
        .USE_SIMULATION_CLOCK(1)
    ) uut (
        .CLK100MHZ(CLK100MHZ),
        .rst(rst),
        .LED(LED)
    );

    // Clock generation (10ns period = 100MHz input clock)
    always #5 CLK100MHZ = ~CLK100MHZ;

    always @(CLK100MHZ) begin
        saw_clock_toggle = 1'b1;
    end

    task automatic check_true;
        input cond;
        input [1023:0] msg;
        begin
            if (cond) begin
                pass_count = pass_count + 1;
                $display("PASS: %0s", msg);
            end else begin
                fail_count = fail_count + 1;
                $display("FAIL: %0s", msg);
            end
        end
    endtask

    initial begin
        expected_led = 16'b1001111010010101;

        // Assert reset
        rst = 0;

        // Basic sanity checks while in reset
        #1;
        check_true(uut.rst_n === 1'b0, "rst_n follows rst low during reset");
        check_true(uut.cpu_clk === CLK100MHZ, "cpu_clk follows input clock in simulation mode");

        #20;
        check_true(saw_clock_toggle, "CLK100MHZ toggles in testbench");

        #11;
        // Deassert reset
        rst = 1;

        #1;
        check_true(uut.rst_n === 1'b1, "rst_n follows rst high after reset release");
        check_true(uut.u_microprocessor0.clk === uut.cpu_clk, "clock is carried from basys3_top to microprocessor");
        check_true(uut.u_microprocessor0.rst === uut.rst_n, "reset is carried from basys3_top to microprocessor");
        check_true((LED ^ LED) === 16'h0000, "LED bus has no X/Z after reset release");
        check_true((uut.u_microprocessor0.u_core.pc_address ^ uut.u_microprocessor0.u_core.pc_address) === 32'h00000000,
                   "core pc_address has no X/Z");

        // Run long enough for the 4-instruction program to retire.
        repeat (20) @(posedge CLK100MHZ);

        check_true(LED === uut.x1_to_x4_nibbles_debug, "LED output equals internal x1..x4 nibble bus");
        check_true(LED === expected_led, "final LED value matches expected program result");

        if (fail_count == 0) begin
            $display("RESULT: PASS (%0d checks)", pass_count);
        end else begin
            $display("RESULT: FAIL (%0d pass, %0d fail)", pass_count, fail_count);
        end

        $finish;
    end
endmodule
