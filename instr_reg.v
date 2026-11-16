//Instruction Register (IR) for CPU

//Holds the instruction currently being executed, so it stays stable through the
//decode, execute, and write states while the program counter moves on.

//Two Behaviours:
//  (1) Clear to NOP (0x0000) on reset.
//  (2) Load the instruction from the pseudo-ROM, if En and ir_load are both high.

module instr_reg(Clk, Reset, En, ir_load, instr, ir);
    input [0:0] Clk, Reset, En;
    input [0:0] ir_load;
    input [15:0] instr;
    output reg [15:0] ir;

    always @(posedge Clk) begin
        if (Reset)
            ir <= 16'd0;
        else if (En && ir_load)
            ir <= instr;
    end

endmodule
