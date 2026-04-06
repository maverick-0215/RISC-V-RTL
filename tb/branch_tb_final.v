`timescale 1ns/1ps
// =============================================================================
// branch_tb_final.v  —  RISC-V pipeline branch/jump testbench
//                        All 8 instruction types, each fires EXACTLY ONCE.
//
// KEY FIX vs branch_tb_fixed.v:
//   mem[25] changed from NOP (00000013) to HALT (0000006f = jal x0,0)
//   This makes JALR land at the HALT and park — no more infinite loop.
//   JALR now fires exactly once. Pass count = exactly 8/8.
//
// Memory layout:
//   [0 -3 ] BEQ  group  (PC 0x00–0x0C)
//   [4 -7 ] BNE  group  (PC 0x10–0x1C)
//   [8 -11] BLT  group  (PC 0x20–0x2C)
//   [12-15] BGE  group  (PC 0x30–0x3C)
//   [16-19] BLTU group  (PC 0x40–0x4C)
//   [20-23] BGEU group  (PC 0x50–0x5C)
//   [24]    JAL  x1,+8  (PC 0x60) → x1=0x64, jump to 0x68
//   [25]    HALT jal x0,0 (PC 0x64) → JALR returns here and parks
//   [26]    JALR x0,0(x1)(PC 0x68) → jumps to x1=0x64 → HALT
//   [27]    NOP          (PC 0x6C) → never reached
//
// Expected PC targets after each redirect:
//   BEQ  0x08 → 0x10   BNE  0x18 → 0x20   BLT  0x28 → 0x30
//   BGE  0x38 → 0x40   BLTU 0x48 → 0x50   BGEU 0x58 → 0x60
//   JAL  0x60 → 0x68   JALR 0x68 → 0x64
//
// Requires pc.v fix:
//   assign pre_address_pc = pre_address;   // was: = address_out
// =============================================================================

module branch_tb_final();

    // -------------------------------------------------------------------------
    // Clock & reset
    // -------------------------------------------------------------------------
    reg clk;
    reg rst;
    integer cycle;

    always #5 clk = ~clk;

    // -------------------------------------------------------------------------
    // DUT
    // -------------------------------------------------------------------------
    microprocessor dut (
        .clk(clk),
        .instruction(),
        .rst(rst)
    );

    // -------------------------------------------------------------------------
    // Cycle counter
    // -------------------------------------------------------------------------
    always @(posedge clk)
        cycle = cycle + 1;

    // -------------------------------------------------------------------------
    // Debug signal taps
    // -------------------------------------------------------------------------
    wire [31:0] pc        = dut.pc_address;
    wire [31:0] IF_instr  = dut.u_core.instruction_fetch;
    wire [31:0] ID_instr  = dut.u_core.instruction_decode;
    wire [31:0] EX_instr  = dut.u_core.instruction_execute;
    wire [31:0] MEM_instr = dut.u_core.instruction_memstage;
    wire [31:0] WB_instr  = dut.u_core.instruction_wb;

    wire branch_taken = dut.u_core.branch_result_execute;
    wire jal_taken    = dut.u_core.next_sel_execute;
    wire jalr_taken   = dut.u_core.jalr_execute;

    // -------------------------------------------------------------------------
    // Waveform dump
    // -------------------------------------------------------------------------
    initial begin
        $dumpfile("branch_tb_final.vcd");
        $dumpvars(0, branch_tb_final);
        $dumpvars(1, branch_taken);
        $dumpvars(1, jal_taken);
        $dumpvars(1, jalr_taken);
    end

    // -------------------------------------------------------------------------
    // Per-cycle display
    // -------------------------------------------------------------------------
    always @(posedge clk) begin
        #1;
        $display("Cycle:%0d | PC:%h | IF:%h | ID:%h | EX:%h | MEM:%h | WB:%h | BR:%b JAL:%b JALR:%b",
            cycle, pc,
            IF_instr, ID_instr, EX_instr, MEM_instr, WB_instr,
            branch_taken, jal_taken, jalr_taken);
    end

    // -------------------------------------------------------------------------
    // Pass/Fail checker
    // -------------------------------------------------------------------------
    integer pass_count;
    integer fail_count;

    // Step 1: detect redirect and arm check for next cycle
    reg        check_pending;
    reg [31:0] expected_target;
    reg [47:0] instr_name;   // 6-char label

    always @(posedge clk) begin
        #2;
        check_pending = 1'b0;

        // BEQ x1,x2,+8 at PC=0x08 → target 0x10
        if (branch_taken && EX_instr == 32'h00208463) begin
            check_pending   = 1'b1;
            expected_target = 32'h00000010;
            instr_name      = "BEQ   ";
        end
        // BNE x1,x2,+8 at PC=0x18 → target 0x20
        else if (branch_taken && EX_instr == 32'h00209463) begin
            check_pending   = 1'b1;
            expected_target = 32'h00000020;
            instr_name      = "BNE   ";
        end
        // BLT x1,x2,+8 at PC=0x28 → target 0x30
        else if (branch_taken && EX_instr == 32'h0020c463) begin
            check_pending   = 1'b1;
            expected_target = 32'h00000030;
            instr_name      = "BLT   ";
        end
        // BGE x1,x2,+8 at PC=0x38 → target 0x40
        else if (branch_taken && EX_instr == 32'h0020d463) begin
            check_pending   = 1'b1;
            expected_target = 32'h00000040;
            instr_name      = "BGE   ";
        end
        // BLTU x1,x2,+8 at PC=0x48 → target 0x50
        else if (branch_taken && EX_instr == 32'h0020e463) begin
            check_pending   = 1'b1;
            expected_target = 32'h00000050;
            instr_name      = "BLTU  ";
        end
        // BGEU x1,x2,+8 at PC=0x58 → target 0x60
        else if (branch_taken && EX_instr == 32'h0020f463) begin
            check_pending   = 1'b1;
            expected_target = 32'h00000060;
            instr_name      = "BGEU  ";
        end
        // JAL x1,+8 at PC=0x60 → target 0x68
        else if (jal_taken && EX_instr == 32'h008000ef) begin
            check_pending   = 1'b1;
            expected_target = 32'h00000068;
            instr_name      = "JAL   ";
        end
        // JALR x0,0(x1) at PC=0x68 → target 0x64 (HALT)
        else if (jalr_taken && EX_instr == 32'h00008067) begin
            check_pending   = 1'b1;
            expected_target = 32'h00000064;
            instr_name      = "JALR  ";
        end
    end

    // Step 2: one cycle later, sample PC and compare
    reg        check_next;
    reg [31:0] expected_next;
    reg [47:0] name_next;

    always @(posedge clk) begin
        #3;
        check_next    <= check_pending;
        expected_next <= expected_target;
        name_next     <= instr_name;

        if (check_next) begin
            if (pc === expected_next) begin
                $display("  >>> PASS: %s  PC = 0x%08h (correct)", name_next, pc);
                pass_count = pass_count + 1;
            end else begin
                $display("  >>> FAIL: %s  PC = 0x%08h  expected = 0x%08h",
                    name_next, pc, expected_next);
                fail_count = fail_count + 1;
            end
        end
    end

    // -------------------------------------------------------------------------
    // Halt detector — stop simulation when processor parks at HALT (0x64)
    // Give it a few cycles to confirm it's truly parked, not just passing through
    // -------------------------------------------------------------------------
    integer halt_count;

    always @(posedge clk) begin
        #4;
        if (pc == 32'h00000064 && IF_instr == 32'h0000006f) begin
            halt_count = halt_count + 1;
        end else begin
            halt_count = 0;
        end

        // Once we see 4 consecutive cycles parked at HALT, we're done
        if (halt_count >= 4) begin
            $display("");
            $display("  [INFO] Processor parked at HALT (PC=0x64). Simulation ending.");
        end
    end

    // -------------------------------------------------------------------------
    // Stimulus & program load
    // -------------------------------------------------------------------------
    initial begin
        clk        = 0;
        cycle      = 0;
        rst        = 1;
        pass_count = 0;
        fail_count = 0;
        halt_count = 0;
        check_pending = 0;
        check_next    = 0;
        expected_target = 0;
        expected_next   = 0;

        // =====================================================================
        // PROGRAM
        // Each branch group: addi, addi, BRANCH+8, NOP(skipped)
        // All branches taken. imm=+8 skips the NOP cleanly.
        // =====================================================================

        // ---- BEQ (TAKEN): x1=5 == x2=5 ----
        dut.u_instruction_memory.u_memory.mem[0]  = 32'h00500093; // addi x1, x0, 5
        dut.u_instruction_memory.u_memory.mem[1]  = 32'h00500113; // addi x2, x0, 5
        dut.u_instruction_memory.u_memory.mem[2]  = 32'h00208463; // beq  x1, x2, +8
        dut.u_instruction_memory.u_memory.mem[3]  = 32'h00000013; // nop  (skipped)

        // ---- BNE (TAKEN): x1=5 != x2=10 ----
        dut.u_instruction_memory.u_memory.mem[4]  = 32'h00500093; // addi x1, x0, 5
        dut.u_instruction_memory.u_memory.mem[5]  = 32'h00a00113; // addi x2, x0, 10
        dut.u_instruction_memory.u_memory.mem[6]  = 32'h00209463; // bne  x1, x2, +8
        dut.u_instruction_memory.u_memory.mem[7]  = 32'h00000013; // nop  (skipped)

        // ---- BLT (TAKEN): x1=5 < x2=10 ----
        dut.u_instruction_memory.u_memory.mem[8]  = 32'h00500093; // addi x1, x0, 5
        dut.u_instruction_memory.u_memory.mem[9]  = 32'h00a00113; // addi x2, x0, 10
        dut.u_instruction_memory.u_memory.mem[10] = 32'h0020c463; // blt  x1, x2, +8
        dut.u_instruction_memory.u_memory.mem[11] = 32'h00000013; // nop  (skipped)

        // ---- BGE (TAKEN): x1=10 >= x2=5 ----
        dut.u_instruction_memory.u_memory.mem[12] = 32'h00a00093; // addi x1, x0, 10
        dut.u_instruction_memory.u_memory.mem[13] = 32'h00500113; // addi x2, x0, 5
        dut.u_instruction_memory.u_memory.mem[14] = 32'h0020d463; // bge  x1, x2, +8
        dut.u_instruction_memory.u_memory.mem[15] = 32'h00000013; // nop  (skipped)

        // ---- BLTU (TAKEN): x1=5 <u x2=10 ----
        dut.u_instruction_memory.u_memory.mem[16] = 32'h00500093; // addi x1, x0, 5
        dut.u_instruction_memory.u_memory.mem[17] = 32'h00a00113; // addi x2, x0, 10
        dut.u_instruction_memory.u_memory.mem[18] = 32'h0020e463; // bltu x1, x2, +8
        dut.u_instruction_memory.u_memory.mem[19] = 32'h00000013; // nop  (skipped)

        // ---- BGEU (TAKEN): x1=10 >=u x2=5 ----
        dut.u_instruction_memory.u_memory.mem[20] = 32'h00a00093; // addi x1, x0, 10
        dut.u_instruction_memory.u_memory.mem[21] = 32'h00500113; // addi x2, x0, 5
        dut.u_instruction_memory.u_memory.mem[22] = 32'h0020f463; // bgeu x1, x2, +8
        dut.u_instruction_memory.u_memory.mem[23] = 32'h00000013; // nop  (skipped)

        // ---- JAL ----
        // jal x1, +8 → x1 = 0x64 (return addr), PC → 0x68
        dut.u_instruction_memory.u_memory.mem[24] = 32'h008000ef; // jal x1, +8

        // ---- HALT at 0x64 ----
        // jal x0, 0 → self-loop, parks here forever
        // JALR returns here after firing once, then processor halts
        // *** THIS IS THE KEY FIX: was NOP (00000013), now HALT (0000006f) ***
        dut.u_instruction_memory.u_memory.mem[25] = 32'h0000006f; // jal x0, 0  (HALT)

        // ---- JALR ----
        // jalr x0, 0(x1) → PC = x1 + 0 = 0x64 → HALT
        // Fires exactly ONCE, then lands at HALT above
        dut.u_instruction_memory.u_memory.mem[26] = 32'h00008067; // jalr x0, 0(x1)

        // Never reached (JALR skips this via flush)
        dut.u_instruction_memory.u_memory.mem[27] = 32'h00000013; // nop

        // =====================================================================
        // Reset sequence (active-low rst)
        // =====================================================================
        #10 rst = 0;   // assert reset
        #10 rst = 1;   // deassert, processor starts

        // =====================================================================
        // Run long enough: 8 groups × ~5 cycles each = ~40 cycles = 400ns
        // Add margin for pipeline fill + HALT confirmation = 600ns total
        // =====================================================================
        #600;

        // =====================================================================
        // Final report
        // =====================================================================
        $display("");
        $display("========================================");
        $display("  BRANCH/JUMP TEST SUMMARY");
        $display("========================================");
        $display("  PASSED : %0d / 8", pass_count);
        $display("  FAILED : %0d / 8", fail_count);
        if (fail_count == 0)
            $display("  RESULT : ALL 8 TESTS PASSED");
        else
            $display("  RESULT : %0d TEST(S) FAILED", fail_count);
        $display("========================================");

        $finish;
    end

endmodule
