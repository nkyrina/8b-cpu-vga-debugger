//Pseudo-ROM for CPU

//Stores the program as fixed 16-bit instructions, selected by the program counter.
//The contents are constants, so nothing can write to it while the CPU runs.

//Current Program: Counter (counts up in R1 and shows it on the LEDs).
//Unused addresses return NOP (0x0000).

module pseudo_rom(pc, instr);
    input [4:0] pc;
    output reg [15:0] instr;

        //Cases are assigned based off the demo program as in README
        always @(*) begin
            case(pc)
            16'h00000: instr = 16'h8200;    // LDI R1, 0
            16'h00001: instr = 16'h8401;    // LDI R2, 1
            16'h00002: instr = 16'h1250;    // ADD R1, R1, R2
            16'h00003: instr = 16'hF040;    // OUT R1
            16'h00004: instr = 16'hB002;    // JMP 2
            default: instr = 16'h0000;      // Default Case
            endcase
        end

endmodule