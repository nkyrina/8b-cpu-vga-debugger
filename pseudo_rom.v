//Pseudo-ROM for CPU

//Stores the program as fixed 16-bit instructions, selected by the program counter.
//The contents are constants, so nothing can write to it while the CPU runs.

//Counter Program: Counter (counts up in R1 and shows it on the LEDs).
//Unused addresses return NOP (0x0000).

//Component Test Program: Exercises every part of the datapath:
//  Part 1 (0-10):  each ALU operation, BZ not taken, OUT
//  Part 2 (11-17): countdown loop from 3, BNZ taken and not taken, BZ taken
//  Part 3 (18-20): IN from the switches, OUT, then stop
//The jumps to address 17 are traps: the PC only ends up there if a branch is wrong.
//Unused addresses return NOP (0x0000).

/* COUNTER PROGRAM

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
*/

// COMPONENT TEST PROGRAM

module pseudo_rom(pc, instr);
    input [4:0] pc;
    output reg [15:0] instr;

        always @(*) begin
            case(pc)
            //Part 1: ALU operations                                 result
            5'd0:  instr = 16'h820C;    // LDI R1, 12                R1 = 0C
            5'd1:  instr = 16'h8405;    // LDI R2, 5                 R2 = 05
            5'd2:  instr = 16'h1650;    // ADD R3, R1, R2            R3 = 11
            5'd3:  instr = 16'h2850;    // SUB R4, R1, R2            R4 = 07
            5'd4:  instr = 16'h3A50;    // AND R5, R1, R2            R5 = 04
            5'd5:  instr = 16'h4C50;    // OR  R6, R1, R2            R6 = 0D
            5'd6:  instr = 16'h5E50;    // XOR R7, R1, R2            R7 = 09
            5'd7:  instr = 16'h66C0;    // SHL R3, R3                R3 = 22
            5'd8:  instr = 16'h7900;    // SHR R4, R4                R4 = 03, zero flag = 0
            5'd9:  instr = 16'hC011;    // BZ 17                     not taken (flag is 0)
            5'd10: instr = 16'hF0C0;    // OUT R3                    LEDs = 22

            //Part 2: countdown loop
            5'd11: instr = 16'h8203;    // LDI R1, 3                 R1 = 03
            5'd12: instr = 16'h8401;    // LDI R2, 1                 R2 = 01
            5'd13: instr = 16'h2250;    // SUB R1, R1, R2            R1 = 02, 01, 00
            5'd14: instr = 16'hF040;    // OUT R1                    LEDs = 02, 01, 00
            5'd15: instr = 16'hD00D;    // BNZ 13                    taken twice, then not taken
            5'd16: instr = 16'hC012;    // BZ 18                     taken (flag is 1)
            5'd17: instr = 16'hB011;    // JMP 17                    trap: never reached

            //Part 3: switches
            5'd18: instr = 16'hE600;    // IN R3                     R3 = SW[7:0]
            5'd19: instr = 16'hF0C0;    // OUT R3                    LEDs = SW[7:0]
            5'd20: instr = 16'hB014;    // JMP 20                    stop here

            default: instr = 16'h0000;  // NOP
            endcase
        end

endmodule