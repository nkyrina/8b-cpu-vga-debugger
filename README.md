# 8b-cpu-vga-debugger
Custom, 8-register CPU with multi-cycle instruction timing, and register arrays acting as ROM and RAM. The processor’s internal state is displayed on a real-time VGA monitor to facilitate debugging. Buttons and switches are used to control the execution of instructions from a pre-written program stored in the ROM register.

## Port Table

| Module | Port | Direction | Width | Description |
|---|---|---|---|---|
| Step Control | `Clk`, `Reset` | IN | 1 | shared clock and reset |
| | `b_step` | IN | 1 | step button |
| | `m_run` | IN | 1 | 1 = walks through freely |
| | `En` | OUT | 1 | one-cycle step pulse |
| Program Counter | `Clk`, `Reset`, `En` | IN | 1 | shared clock, reset, enable |
| | `pc_inc` | IN | 1 | increments by 1 |
| | `pc_load` | IN | 1 | 1 = load target to PC |
| | `target` | IN | 5 | target address from IR |
| | `pc` | OUT | 5 | current address |
| Register File | `Clk`, `Reset`, `En` | IN | 1 | shared clock, reset, enable |
| | `wr_en` | IN | 1 | write enable |
| | `r_a`, `r_b`, `wr_loc` | IN | 3 | two read addresses, one write destination |
| | `wr_data` | IN | 8 | value to write |
| | `a`, `b` | OUT | 8 | values of r_a and r_b |
| | `dis_regs` | OUT | 64 | eight registers to display |
| ALU | `a`, `b` | IN | 8 | operands |
| | `op` | IN | 3 | selected operation |
| | `result` | OUT | 8 | result |
| | `zero` | OUT | 1 | result = 0 |
| Hex Display | `Clk`, `Reset` | IN | 1 | shared clock and reset |
| | `pc` | IN | 5 | values to display | 
| | `dis_regs` | IN | 64 | values to display | 
| | `ir` | IN | 16 | instruction being executed |
| | `state` | IN | 2 | FSM state |
| | `zero_flag` | IN | 1 | most recent zero flag |
| | `VGA` | OUT | varies | outputs feeding display adapter |

## Conventions

- `Reset` is active high, synchronous. Key inputs are inverted once in top.v.
- Stored values updated on clock edge if `En` = 1.
- Buses are written high to low bit (e.g. [6:0]).
- For display registers: R0 = [7:0], ..., R7 = [63:56].
- If both `pc_load` and `pc_inc` are high, output follows load.

## ALU Op Codes

| op | Operation |
|---|---|
| 0 | ADD |
| 1 | SUB |
| 2 | AND |
| 3 | OR |
| 4 | XOR |
| 5 | SHL |
| 6 | SHR |

## Instruction format (16 bits)

| Bits | Field | Used by |
|---|---|---|
| [15:12] | opcode | all instructions |
| [11:9] | `wr_loc` | register to write |
| [8:6] | `r_a` | first register to read |
| [5:3] | `r_b` | second register to read |
| [7:0] | `imm8` | LDI only (overlaps r_a, r_b) |
| [4:0] | `addr5` | JMP, BZ, BNZ only |

## Instructions

| Op | Name | Expression | Sets Zero Flag |
|---|---|---|---|
| 0 | NOP | nothing | no |
| 1 | ADD wr_loc, r_a, r_b | wr_loc = r_a + r_b | yes |
| 2 | SUB wr_loc, r_a, r_b | wr_loc = r_a - r_b | yes |
| 3 | AND wr_loc, r_a, r_b | wr_loc = r_a & r_b | yes |
| 4 | OR wr_loc, r_a, r_b | wr_loc = r_a \| r_b | yes |
| 5 | XOR wr_loc, r_a, r_b | wr_loc = r_a ^ r_b | yes |
| 6 | SHL wr_loc, r_a | wr_loc = r_a << 1 | yes |
| 7 | SHR wr_loc, r_a | wr_loc = r_a >> 1 | yes |
| 8 | LDI wr_loc, imm8 | wr_loc = imm8 | no |
| 9 | LD wr_loc, [r_a] | wr_loc = RAM[r_a] | no |
| 10 | ST [r_a], r_b | RAM[r_a] = r_b | no |
| 11 | JMP addr5 | PC = addr5 | no |
| 12 | BZ addr5 | if zero flag, PC = addr5 | no |
| 13 | BNZ addr5 | if not zero flag, PC = addr5 | no |
| 14 | IN wr_loc | wr_loc = switches | no |
| 15 | OUT r_a | show r_a on LEDs | no |

## Control FSM
![Control FSM](docs/FSMmodel.png)

### Port Table

| Module | Port | Direction | Width | Description |
|---|---|---|---|---|
| Control FSM | `Clk`, `Reset`, `En` | IN | 1 | shared clock, reset, enable |
| | `opcode` | IN | 4 | instruction opcode, `ir[15:12]` |
| | `zero_flag` | IN | 1 | stored zero flag from the most recent ALU instruction |
| | `state` | OUT | 2 | current state, to the VGA debugger |
| | `ir_load` | OUT | 1 | 1 = load `ROM[pc]` into IR |
| | `pc_inc` | OUT | 1 | to Program Counter |
| | `pc_load` | OUT | 1 | to Program Counter |
| | `wr_en` | OUT | 1 | to Register File |
| | `wb_sel` | OUT | 2 | selects `wr_data` source (see below) |
| | `alu_op` | OUT | 3 | to ALU, always `opcode - 1` |
| | `zero_load` | OUT | 1 | 1 = save ALU `zero` into the zero flag register |
| | `ram_wr_en` | OUT | 1 | 1 = `RAM[r_a] = r_b` |
| | `out_load` | OUT | 1 | 1 = LED register gets `r_a` |

### States

| State | Name | Outputs | Purpose |
|---|---|---|---|
| 0 | FETCH | `ir_load`, `pc_inc` | IR = ROM[pc], pc = pc + 1 |
| 1 | DECODE | none | IR fields settle, register file and ALU outputs settle |
| 2 | EXECUTE | `pc_load` (jumps only) | JMP, BZ, BNZ update the PC |
| 3 | WRITE | depends on opcode | result is saved to a register, RAM, zero flag or LEDs |

- State moves to the next one (3 wraps to 0) on the clock edge if `En` = 1, otherwise it holds.
- `Reset` = 1 returns to FETCH from any state.

### Outputs by Opcode

Outputs not listed are 0.

| Op | Name | EXECUTE | WRITE |
|---|---|---|---|
| 0 | NOP | none | none |
| 1–7 | ADD, SUB, AND, OR, XOR, SHL, SHR | none | `wr_en`, `wb_sel` = 0, `zero_load` |
| 8 | LDI | none | `wr_en`, `wb_sel` = 1 |
| 9 | LD | none | `wr_en`, `wb_sel` = 2 |
| 10 | ST | none | `ram_wr_en` |
| 11 | JMP | `pc_load` | none |
| 12 | BZ | `pc_load` = `zero_flag` | none |
| 13 | BNZ | `pc_load` = `~zero_flag` | none |
| 14 | IN | none | `wr_en`, `wb_sel` = 3 |
| 15 | OUT | none | `out_load` |

### Write-back Select

| wb_sel | wr_data source | Used by |
|---|---|---|
| 0 | ALU `result` | ADD to SHR |
| 1 | `ir[7:0]` (imm8) | LDI |
| 2 | `RAM[r_a]` | LD |
| 3 | `SW[7:0]` | IN |

### Notes

- FSM outputs are combinational. Every module they drive (IR, PC, Register File, RAM, zero flag register, LED register) must only update when `En` = 1.
- BZ and BNZ test the stored `zero_flag`, not the ALU's live `zero` output.
- There is no HALT instruction. Use `JMP` to its own address to stop.
