`timescale 1ns/1ps
module Microprocessor_hazards_all_tb();

    reg clk;
    reg rst;
    reg [31:0] instruction;
    integer errors;
    integer i;

    localparam [6:0] OP_R    = 7'b0110011;
    localparam [6:0] OP_I    = 7'b0010011;
    localparam [6:0] OP_LOAD = 7'b0000011;
    localparam [6:0] OP_S    = 7'b0100011;
    localparam [6:0] OP_B    = 7'b1100011;
    localparam [6:0] OP_JAL  = 7'b1101111;
    localparam [31:0] NOP    = 32'h00000013;

    function [31:0] enc_r;
        input [6:0] funct7;
        input [4:0] rs2;
        input [4:0] rs1;
        input [2:0] funct3;
        input [4:0] rd;
        input [6:0] opcode;
        begin
            enc_r = {funct7, rs2, rs1, funct3, rd, opcode};
        end
    endfunction

    function [31:0] enc_i;
        input [11:0] imm;
        input [4:0] rs1;
        input [2:0] funct3;
        input [4:0] rd;
        input [6:0] opcode;
        begin
            enc_i = {imm, rs1, funct3, rd, opcode};
        end
    endfunction

    function [31:0] enc_s;
        input [11:0] imm;
        input [4:0] rs2;
        input [4:0] rs1;
        input [2:0] funct3;
        input [6:0] opcode;
        begin
            enc_s = {imm[11:5], rs2, rs1, funct3, imm[4:0], opcode};
        end
    endfunction

    function [31:0] enc_b;
        input [12:0] imm;
        input [4:0] rs2;
        input [4:0] rs1;
        input [2:0] funct3;
        input [6:0] opcode;
        begin
            enc_b = {imm[12], imm[10:5], rs2, rs1, funct3, imm[4:1], imm[11], opcode};
        end
    endfunction

    function [31:0] enc_j;
        input [20:0] imm;
        input [4:0] rd;
        input [6:0] opcode;
        begin
            enc_j = {imm[20], imm[10:1], imm[11], imm[19:12], rd, opcode};
        end
    endfunction

    task clear_case;
        integer j;
        begin
            rst = 0;
            instruction = 32'b0;
            for (j = 0; j < 64; j = j + 1) begin
                u_microprocessor0.u_instruction_memory.u_memory.mem[j] = NOP;
                u_microprocessor0.u_data_memory.u_memory.mem[j] = 32'b0;
            end
            repeat (2) @(posedge clk);
        end
    endtask

    task start_case;
        begin
            @(negedge clk);
            rst = 1;
        end
    endtask

    task check_reg;
        input [4:0] reg_id;
        input [31:0] expected;
        input [8*48:1] tag;
        reg [31:0] actual;
        begin
            actual = u_microprocessor0.u_core.u_decodestage.u_regfile0.register[reg_id];
            if (actual !== expected) begin
                $display("FAIL: %0s expected=%h actual=%h", tag, expected, actual);
                errors = errors + 1;
            end else begin
                $display("PASS: %0s", tag);
            end
        end
    endtask

    task check_mem;
        input [7:0] mem_id;
        input [31:0] expected;
        input [8*48:1] tag;
        reg [31:0] actual;
        begin
            actual = u_microprocessor0.u_data_memory.u_memory.mem[mem_id];
            if (actual !== expected) begin
                $display("FAIL: %0s expected=%h actual=%h", tag, expected, actual);
                errors = errors + 1;
            end else begin
                $display("PASS: %0s", tag);
            end
        end
    endtask

    microprocessor u_microprocessor0 (
        .clk(clk),
        .rst(rst)    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 0;
        instruction = 32'b0;
        errors = 0;

        // Case 1: RAW adjacent forwarding chain
        clear_case();
        u_microprocessor0.u_instruction_memory.u_memory.mem[0] = enc_i(12'd7, 5'd0, 3'b000, 5'd2, OP_I);
        u_microprocessor0.u_instruction_memory.u_memory.mem[1] = enc_i(12'd9, 5'd0, 3'b000, 5'd3, OP_I);
        u_microprocessor0.u_instruction_memory.u_memory.mem[2] = enc_r(7'b0000000, 5'd3, 5'd2, 3'b000, 5'd4, OP_R);
        u_microprocessor0.u_instruction_memory.u_memory.mem[3] = enc_r(7'b0000000, 5'd2, 5'd4, 3'b000, 5'd5, OP_R);
        start_case();
        repeat (36) @(posedge clk);
        check_reg(5'd4, 32'd16, "Hazard RAW adjacent x4");
        check_reg(5'd5, 32'd23, "Hazard RAW adjacent x5");

        // Case 2: RAW with one instruction gap
        clear_case();
        u_microprocessor0.u_instruction_memory.u_memory.mem[0] = enc_i(12'd5, 5'd0, 3'b000, 5'd2, OP_I);
        u_microprocessor0.u_instruction_memory.u_memory.mem[1] = enc_i(12'd0, 5'd0, 3'b000, 5'd9, OP_I);
        u_microprocessor0.u_instruction_memory.u_memory.mem[2] = enc_r(7'b0000000, 5'd2, 5'd2, 3'b000, 5'd4, OP_R);
        start_case();
        repeat (32) @(posedge clk);
        check_reg(5'd4, 32'd10, "Hazard RAW gap1 x4");

        // Case 3: Load-use stall + forward
        clear_case();
        u_microprocessor0.u_instruction_memory.u_memory.mem[0] = enc_i(12'd0, 5'd1, 3'b010, 5'd2, OP_LOAD);
        u_microprocessor0.u_instruction_memory.u_memory.mem[1] = enc_r(7'b0000000, 5'd4, 5'd2, 3'b000, 5'd3, OP_R);
        u_microprocessor0.u_data_memory.u_memory.mem[0] = 32'd21;
        start_case();
        u_microprocessor0.u_core.u_decodestage.u_regfile0.register[1] = 32'd0;
        u_microprocessor0.u_core.u_decodestage.u_regfile0.register[4] = 32'd4;
        repeat (36) @(posedge clk);
        check_reg(5'd2, 32'd21, "Hazard lw result x2");
        check_reg(5'd3, 32'd25, "Hazard lw-use add x3");

        // Case 4: Producer to store-data forwarding
        clear_case();
        u_microprocessor0.u_instruction_memory.u_memory.mem[0] = enc_i(12'd0, 5'd0, 3'b000, 5'd1, OP_I);
        u_microprocessor0.u_instruction_memory.u_memory.mem[1] = enc_i(12'd11, 5'd0, 3'b000, 5'd2, OP_I);
        u_microprocessor0.u_instruction_memory.u_memory.mem[2] = enc_r(7'b0000000, 5'd2, 5'd2, 3'b000, 5'd5, OP_R);
        u_microprocessor0.u_instruction_memory.u_memory.mem[3] = enc_s(12'd0, 5'd5, 5'd1, 3'b010, OP_S);
        start_case();
        repeat (40) @(posedge clk);
        check_mem(8'd0, 32'd22, "Hazard producer-store mem0");

        // Case 5: Branch control hazard flush
        clear_case();
        u_microprocessor0.u_instruction_memory.u_memory.mem[0] = enc_r(7'b0000000, 5'd3, 5'd2, 3'b000, 5'd1, OP_R);
        u_microprocessor0.u_instruction_memory.u_memory.mem[1] = enc_b(13'd8, 5'd2, 5'd1, 3'b000, OP_B);
        u_microprocessor0.u_instruction_memory.u_memory.mem[2] = enc_i(12'd1, 5'd0, 3'b000, 5'd5, OP_I);
        u_microprocessor0.u_instruction_memory.u_memory.mem[3] = enc_i(12'd2, 5'd0, 3'b000, 5'd6, OP_I);
        start_case();
        u_microprocessor0.u_core.u_decodestage.u_regfile0.register[2] = 32'd10;
        u_microprocessor0.u_core.u_decodestage.u_regfile0.register[3] = 32'd0;
        repeat (40) @(posedge clk);
        check_reg(5'd5, 32'd0, "Hazard branch flush x5");
        check_reg(5'd6, 32'd2, "Hazard branch target x6");

        // Case 6: Jump control hazard flush
        clear_case();
        u_microprocessor0.u_instruction_memory.u_memory.mem[0] = enc_j(21'd8, 5'd9, OP_JAL);
        u_microprocessor0.u_instruction_memory.u_memory.mem[1] = enc_i(12'd1, 5'd0, 3'b000, 5'd7, OP_I);
        u_microprocessor0.u_instruction_memory.u_memory.mem[2] = enc_i(12'd2, 5'd0, 3'b000, 5'd7, OP_I);
        start_case();
        repeat (40) @(posedge clk);
        check_reg(5'd9, 32'd4, "Hazard jump link x9");
        check_reg(5'd7, 32'd2, "Hazard jump target x7");

        // Case 7: In-order WAR-like sequencing sanity
        clear_case();
        u_microprocessor0.u_instruction_memory.u_memory.mem[0] = enc_i(12'd3, 5'd0, 3'b000, 5'd2, OP_I);
        u_microprocessor0.u_instruction_memory.u_memory.mem[1] = enc_i(12'd4, 5'd0, 3'b000, 5'd3, OP_I);
        u_microprocessor0.u_instruction_memory.u_memory.mem[2] = enc_r(7'b0000000, 5'd3, 5'd2, 3'b000, 5'd4, OP_R);
        u_microprocessor0.u_instruction_memory.u_memory.mem[3] = enc_i(12'd9, 5'd0, 3'b000, 5'd2, OP_I);
        u_microprocessor0.u_instruction_memory.u_memory.mem[4] = enc_r(7'b0000000, 5'd3, 5'd2, 3'b000, 5'd5, OP_R);
        start_case();
        repeat (44) @(posedge clk);
        check_reg(5'd4, 32'd7, "Hazard WAR-like older read x4");
        check_reg(5'd5, 32'd13, "Hazard WAR-like new value x5");

        // Case 8: Store->Load same-address ordering
        clear_case();
        u_microprocessor0.u_instruction_memory.u_memory.mem[0] = enc_i(12'd0, 5'd0, 3'b000, 5'd1, OP_I);              // base x1=0
        u_microprocessor0.u_instruction_memory.u_memory.mem[1] = enc_i(12'd77, 5'd0, 3'b000, 5'd2, OP_I);             // x2=77
        u_microprocessor0.u_instruction_memory.u_memory.mem[2] = enc_s(12'd0, 5'd2, 5'd1, 3'b010, OP_S);              // sw x2,0(x1)
        u_microprocessor0.u_instruction_memory.u_memory.mem[3] = enc_i(12'd0, 5'd1, 3'b010, 5'd3, OP_LOAD);           // lw x3,0(x1)
        start_case();
        repeat (44) @(posedge clk);
        check_mem(8'd0, 32'd77, "Hazard store-load mem0");
        check_reg(5'd3, 32'd77, "Hazard store-load x3");

        // Case 9: Partial store byte then dependent loads
        clear_case();
        u_microprocessor0.u_instruction_memory.u_memory.mem[0] = enc_i(12'd0, 5'd0, 3'b000, 5'd1, OP_I);              // base x1=0
        u_microprocessor0.u_instruction_memory.u_memory.mem[1] = enc_i(12'h055, 5'd0, 3'b000, 5'd2, OP_I);            // x2=0x55
        u_microprocessor0.u_instruction_memory.u_memory.mem[2] = enc_s(12'd1, 5'd2, 5'd1, 3'b000, OP_S);              // sb x2,1(x1)
        u_microprocessor0.u_instruction_memory.u_memory.mem[3] = enc_i(12'd1, 5'd1, 3'b100, 5'd3, OP_LOAD);           // lbu x3,1(x1)
        u_microprocessor0.u_instruction_memory.u_memory.mem[4] = enc_i(12'd0, 5'd1, 3'b001, 5'd4, OP_LOAD);           // lh x4,0(x1)
        u_microprocessor0.u_data_memory.u_memory.mem[0] = 32'hAABB_CCDD;
        start_case();
        repeat (48) @(posedge clk);
        check_mem(8'd0, 32'hAABB_55DD, "Hazard partial-store mem0");
        check_reg(5'd3, 32'h0000_0055, "Hazard partial-store lbu x3");
        check_reg(5'd4, 32'h0000_55DD, "Hazard partial-store lh x4");

        // Case 10: Load->Branch dependency (stall + correct compare)
        clear_case();
        u_microprocessor0.u_instruction_memory.u_memory.mem[0] = enc_i(12'd0, 5'd1, 3'b010, 5'd2, OP_LOAD);           // lw x2,0(x1)
        u_microprocessor0.u_instruction_memory.u_memory.mem[1] = enc_b(13'd8, 5'd3, 5'd2, 3'b000, OP_B);              // beq x2,x3,+8
        u_microprocessor0.u_instruction_memory.u_memory.mem[2] = enc_i(12'd1, 5'd0, 3'b000, 5'd5, OP_I);              // flushed if taken
        u_microprocessor0.u_instruction_memory.u_memory.mem[3] = enc_i(12'd2, 5'd0, 3'b000, 5'd6, OP_I);              // target
        u_microprocessor0.u_data_memory.u_memory.mem[0] = 32'd9;
        start_case();
        u_microprocessor0.u_core.u_decodestage.u_regfile0.register[1] = 32'd0;
        u_microprocessor0.u_core.u_decodestage.u_regfile0.register[3] = 32'd9;
        repeat (48) @(posedge clk);
        check_reg(5'd5, 32'd0, "Hazard load-branch flush x5");
        check_reg(5'd6, 32'd2, "Hazard load-branch target x6");

        // Case 11: Wrong-path store must not commit after taken branch
        clear_case();
        u_microprocessor0.u_instruction_memory.u_memory.mem[0] = enc_i(12'd0, 5'd0, 3'b000, 5'd1, OP_I);              // base x1=0
        u_microprocessor0.u_instruction_memory.u_memory.mem[1] = enc_i(12'd99, 5'd0, 3'b000, 5'd2, OP_I);             // x2=99
        u_microprocessor0.u_instruction_memory.u_memory.mem[2] = enc_b(13'd8, 5'd0, 5'd0, 3'b000, OP_B);              // beq x0,x0,+8
        u_microprocessor0.u_instruction_memory.u_memory.mem[3] = enc_s(12'd0, 5'd2, 5'd1, 3'b010, OP_S);              // wrong-path sw
        u_microprocessor0.u_instruction_memory.u_memory.mem[4] = enc_i(12'd3, 5'd0, 3'b000, 5'd7, OP_I);              // target
        u_microprocessor0.u_data_memory.u_memory.mem[0] = 32'hDEAD_BEEF;
        start_case();
        repeat (48) @(posedge clk);
        check_mem(8'd0, 32'hDEAD_BEEF, "Hazard wrong-path store suppressed");
        check_reg(5'd7, 32'd3, "Hazard branch target after store flush");

        // Case 12: Back-to-back control hazards (jal then taken beq)
        clear_case();
        u_microprocessor0.u_instruction_memory.u_memory.mem[0] = enc_j(21'd8, 5'd9, OP_JAL);                          // jal -> mem[2]
        u_microprocessor0.u_instruction_memory.u_memory.mem[1] = enc_i(12'd1, 5'd0, 3'b000, 5'd10, OP_I);             // wrong-path
        u_microprocessor0.u_instruction_memory.u_memory.mem[2] = enc_b(13'd8, 5'd0, 5'd0, 3'b000, OP_B);              // beq taken -> mem[4]
        u_microprocessor0.u_instruction_memory.u_memory.mem[3] = enc_i(12'd1, 5'd0, 3'b000, 5'd11, OP_I);             // wrong-path
        u_microprocessor0.u_instruction_memory.u_memory.mem[4] = enc_i(12'd2, 5'd0, 3'b000, 5'd12, OP_I);             // final target
        start_case();
        repeat (56) @(posedge clk);
        check_reg(5'd9, 32'd4, "Hazard ctrl-ctrl jal link x9");
        check_reg(5'd10, 32'd0, "Hazard ctrl-ctrl jal flush x10");
        check_reg(5'd11, 32'd0, "Hazard ctrl-ctrl beq flush x11");
        check_reg(5'd12, 32'd2, "Hazard ctrl-ctrl final target x12");

        if (errors == 0) begin
            $display("RESULT: PASS (all hazard scenarios passed)");
        end else begin
            $display("RESULT: FAIL (%0d checks failed)", errors);
        end

        $finish;
    end

endmodule

