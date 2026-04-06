## Vivado Setup

1. Add all files in `design/` to Design Sources.
2. Add all files in `tb/` (and optionally `tb_new/`) to Simulation Sources.
3. Set the required testbench module as simulation top.
4. Run Behavioral Simulation.

## Main Testbenches In `tb/`

- `FPGA_TB.v`: top-level integration-style testbench using `basys3_top` and file-based instruction memory loading.
- `Basys3_top_tb.v`: board-wrapper connectivity/reset/clock sanity checks.
- `Microprocessor_rtype_single_inst_tb.v`: R-type instruction checks.
- `Microprocessor_itype_single_inst_tb.v`: I-type instruction checks.
- `Microprocessor_load_single_inst_tb.v`: load instruction checks.
- `Microprocessor_stype_single_inst_tb.v`: store instruction checks.
- `Microprocessor_btype_single_inst_tb.v`: branch instruction checks.
- `Microprocessor_jtype_single_inst_tb.v`: J-type checks.
- `Microprocessor_utype_single_inst_tb.v`: U-type checks.
- `Microprocessor_jalr_single_inst_tb.v`: JALR checks.
- `Microprocessor_rv32i_all37_tb.v`: broader RV32I instruction coverage run.

## Hazard Testbenches In `tb/`

- `Microprocessor_hazard_raw_adj_tb.v`: RAW dependency with adjacent instructions.
- `Microprocessor_hazard_raw_gap1_tb.v`: RAW dependency with one instruction gap.
- `Microprocessor_hazard_lw_add_tb.v`: load-use style dependency (load followed by ALU consumer).
- `Microprocessor_hazard_store_data_tb.v`: producer-to-store data hazard.
- `Microprocessor_hazard_add_beq_tb.v`: ALU result feeding branch decision path.
- `Microprocessor_hazard_war_like_tb.v`: ordering checks in WAR-like patterns.
- `Microprocessor_hazard_free_tb.v`: no-hazard reference behavior.
- `Microprocessor_hazard_stress_tb.v`: mixed hazard stress sequence.
- `Microprocessor_hazards_all_tb.v`: combined hazard regression run.

## Hazard Handling

The current testbench suite covers common pipeline hazard/control scenarios:

- RAW (read-after-write) adjacent dependency.
- RAW with multi-cycle gap.
- Load-use dependency.
- Store-data dependency after producer instruction.
- Store-load ordering interactions.
- Load-to-branch and branch/control transfer interactions.
- Control hazard scenarios (branch/branch, control-control, jump-jump mixes).

## Verilog Design Hierarchy

This repository uses a layered RISC-V pipeline design. The major module hierarchy and data/control flow are:

- `basys3_top.v` (FPGA board wrapper)
  - `clock_divider.v` (generates slow CPU clock for implementation)
  - `microprocessor.v` (CPU + memories integration)
    - `instruc_mem_top.v` (instruction memory wrapper)
      - `instruction_memory.v` (instruction ROM/data fetch)
    - `core.v` (pipeline datapath and control)
      - `fetch.v` (fetch stage, PC/address generation)
      - `fetch_pipe.v` (fetch/decode stage pipeline register)
      - `decode.v` (instruction decode, register read, immediate selection, control signals)
      - `decode_pipe.v` (decode/execute stage pipeline register)
      - `execute_forwarding.v` (forwarding logic for RAW hazard resolution)
      - `branch.v` (branch decision logic)
      - `execute.v` (ALU and next-address computation)
        - `alu.v` (arithmetic/logic operations)
        - `adder.v` (branch/JALR target address computation)
      - `execute_pipe.v` (execute/memory stage pipeline register)
      - `memory_stage.v` (memory access stage, request logic)
      - `memory_pipe.v` (memory/writeback stage pipeline register)
      - `Write_back.v` (write-back stage)
        - `mux2_4.v` (write-back data selection)
    - `data_memory_top.v` (data memory wrapper)
      - `data_memory.v` (data RAM and store/load behavior)

Supporting modules used by the datapath/control logic:

- `control_unit.v`
  - `type_decoder.v` (instruction type decode)
  - `control_decoder.v` (control signal generation)
- `register_file.v` (register read/write stage)
- `immediate_gen.v` (sign-extended immediate values)
- `type_decoder.v` (opcode type classification)
- `mux1_2.v`, `mux2_4.v`, `mux3_8.v` (multiplexer support)
- `wrapper_memory.v` (memory interface wrapper)

### Connection Notes

- `basys3_top` connects board clock/reset to `microprocessor` and presents `x1`–`x4` debug nibbles to LEDs.
- `microprocessor` connects instruction fetch output (`pc_address`, `instruction`) to `core`, and data memory handshake (`data_mem_request`, `data_mem_valid`) to `data_memory_top`.
- `core` implements a 5-stage pipeline: Fetch → Decode → Execute → Memory → Write-back.
- `execute_forwarding` provides forwarded operands into `execute` and branch evaluation to resolve hazards without stalling when possible.
- `instruc_mem_top` and `data_memory_top` add `valid` request/response handshake around the raw memory blocks.

## Tool Chain To Convert C To RISC-V Assembly Code (Windows)

### Pre reqs

- Make sure to have WSL installed if you have a windows laptop.
- All files in `design/` and `tb/` folders should be added to design sources and simulation sources in Vivado.

### Steps

Open a WSL terminal and go to the required directory.

```bash
sudo apt install gcc-riscv64-unknown-elf
```

```bash
riscv64-unknown-elf-gcc -march=rv32i -mabi=ilp32 -O3 -nostdlib -S main.c -o program.s
```

(this gives the assembly code of the C code, this may contain pseudo instructions)

```bash
riscv64-unknown-elf-gcc -march=rv32i -mabi=ilp32 -O3 -nostdlib -Wl,-Ttext=0x00000000 main.c -o program.elf
```

(In the above commands, change `main.c` to the C file path you have.)

```bash
riscv64-unknown-elf-objcopy -O binary program.elf program.bin
```

```bash
hexdump -v -e '1/4 "%08x\n"' program.bin > program.hex
```

(this creates a hex file that contains machine code)

## Running C-Generated Hex In Simulation

1. Use `tb/FPGA_TB.v` as top in Vivado Simulation Sources.
2. Set instruction file path (or runtime override) to `program.hex`.
3. Update checks in `FPGA_TB.v` based on the program behavior.
4. Current `FPGA_TB.v` checks are for max-of-5 style output.
