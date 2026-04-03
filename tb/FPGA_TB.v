`timescale 1ns/1ps
module FPGA_TB;
    reg CLK100MHZ = 0;
    reg rst = 0;
    wire [15:0] LED;
    localparam INSTR_FILE = "C:/Users/Eshwar/Desktop/RV/RV/program.hex";
    localparam [31:0] NOP = 32'h00000013;
    reg [1023:0] runtime_imem_file;
    integer i;

    integer pass_count = 0;
    integer fail_count = 0;

    // Keep instruction file name only; Vivado resolves this from simulation sources.
    basys3_top #(
        .USE_SIMULATION_CLOCK(1),
        .IMPLEMENTATION_TOGGLE_COUNT(2),
        .INSTR_MEM_FILE(INSTR_FILE)
    ) uut (
        .CLK100MHZ(CLK100MHZ),
        .rst(rst),
        .LED(LED)
    );

    always #5 CLK100MHZ = ~CLK100MHZ;

    task automatic check_true;
        input cond;
        input [1023:0] msg;
        begin
            if (cond) begin
                pass_count = pass_count + 1;
                $display("PASS: %0s", msg);
            end
            else begin
                fail_count = fail_count + 1;
                $display("FAIL: %0s", msg);
            end
        end
    endtask

    initial begin
        // Optional runtime override (Vivado xsim supports plusargs).
        // Example: xsim FPGA_TB_behav -runall -testplusarg IMEM=instr_max5.mem
        if ($value$plusargs("IMEM=%s", runtime_imem_file)) begin
            for (i = 0; i < 256; i = i + 1) begin
                uut.u_microprocessor0.u_instruction_memory.u_memory.mem[i] = NOP;
            end
            $readmemh(runtime_imem_file, uut.u_microprocessor0.u_instruction_memory.u_memory.mem);
            $display("INFO: IMEM override loaded from %0s", runtime_imem_file);
        end

        // Hold reset
        rst = 0;
        repeat (3) @(posedge CLK100MHZ);

        // Release reset
        rst = 1;

         // Allow program.hex generated from max5 C program to execute fully.
        repeat (260) @(posedge CLK100MHZ);

         // C program writes final max to byte address 0x100 => word index 64.
         check_true(uut.u_microprocessor0.u_data_memory.u_memory.mem[64] == 32'd31,
             "mem[64] should store final max value 31");

         // a0 (x10) carries the value written to memory in this compiled program.
         check_true(uut.u_microprocessor0.u_core.u_decodestage.u_regfile0.register[10] == 32'd31,
             "x10 should hold final max value 31");

         // Keep one generic LED sanity check (no X/Z).
         check_true((LED ^ LED) == 16'h0000, "LED bus should not contain X/Z");

        if (fail_count == 0) begin
            $display("RESULT: PASS (%0d checks)", pass_count);
        end
        else begin
            $display("RESULT: FAIL (%0d pass, %0d fail)", pass_count, fail_count);
        end

        $finish;
    end

endmodule
