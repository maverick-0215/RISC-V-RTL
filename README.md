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

## Hazard Handling

The current testbench suite covers common pipeline hazard/control scenarios:

- RAW (read-after-write) adjacent dependency.
- RAW with multi-cycle gap.
- Load-use dependency.
- Store-data dependency after producer instruction.
- Store-load ordering interactions.
- Load-to-branch and branch/control transfer interactions.
- Control hazard scenarios (branch/branch, control-control, jump-jump mixes).


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
