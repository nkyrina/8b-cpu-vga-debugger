// Stores the program as fixed 16-bit instructions, selected by the program counter.
// the contents are constants, so nothing can write to it while the CPU runs.

// Current Program: Virtual Pet (uses all 16 opcodes).
//  R1 = food, R2 = fun, R3 = score, R4 = sleep flag
//  SW[0] = feed, SW[1] = play, SW[2] = sleep toggle

// Unused addresses return NOP (0x0000).

module pseudo_rom(pc, instr);
    input [4:0] pc;
    output reg [15:0] instr;

    always @(*) begin
        case (pc)
            5'd0:  instr = 16'h8208;    // LDI R1, 8        food starts full
            5'd1:  instr = 16'h8408;    // LDI R2, 8        fun starts full
            z5'd2:  instr = 16'h0000;    // NOP       
            5'd3:  instr = 16'hF1C0;    // OUT R7           show last score on LEDs
            5'd4:  instr = 16'hEC00;    // IN R6            tick: read switches
            5'd5:  instr = 16'h8A01;    // LDI R5, 1        mask SW[0], constant 1
            5'd6:  instr = 16'h3FA8;    // AND R7, R6, R5   feed switch on?
            5'd7:  instr = 16'hC009;    // BZ 9             no: skip feeding
            5'd8:  instr = 16'h8208;    // LDI R1, 8        feed: food = full
            5'd9:  instr = 16'h2268;    // SUB R1, R1, R5   food - 1
            5'd10: instr = 16'hC01C;    // BZ 28            food = 0: game over
            5'd11: instr = 16'h16E8;    // ADD R3, R3, R5   score + 1
            5'd12: instr = 16'h6B40;    // SHL R5, R5       mask = 2 (SW[1])
            5'd13: instr = 16'h3FA8;    // AND R7, R6, R5   play switch on?
            5'd14: instr = 16'hC010;    // BZ 16            no: skip playing
            5'd15: instr = 16'h8408;    // LDI R2, 8        play: fun = full
            5'd16: instr = 16'h6B40;    // SHL R5, R5       mask = 4 (SW[2])
            5'd17: instr = 16'h3FA8;    // AND R7, R6, R5   sleep switch on?
            5'd18: instr = 16'hC014;    // BZ 20            no: do not toggle
            5'd19: instr = 16'h5928;    // XOR R4, R4, R5   toggle sleep
            5'd20: instr = 16'h4F20;    // OR R7, R4, R4    zero flag = awake
            5'd21: instr = 16'hD019;    // BNZ 25           asleep: skip fun drain
            5'd22: instr = 16'h7B40;    // SHR R5, R5       4 -> 2
            5'd23: instr = 16'h24A8;    // SUB R2, R2, R5   fun - 2
            5'd24: instr = 16'hC01C;    // BZ 28            fun = 0: game over
            5'd25: instr = 16'hF040;    // OUT R1           food on LEDs
            5'd26: instr = 16'h0000;    // NOP              padding
            5'd27: instr = 16'hB004;    // JMP 4            next tick
            5'd28: instr = 16'h0000;    // NOP
            5'd29: instr = 16'hB01D;    // JMP 29           stop until reset
            default: instr = 16'h0000;    // NOP -> unused addresses
        endcase
    end

endmodule
