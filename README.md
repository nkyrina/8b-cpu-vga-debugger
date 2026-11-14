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
