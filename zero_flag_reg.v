//Zero Flag Register for CPU

//Stores the ALU's zero output so that BZ and BNZ can test it in a later
//instruction, after the ALU's live output has changed.

//Two Behaviours:
//  (1) Clear to 0 on reset.
//  (2) Store the ALU's zero output, if En and zero_load are both high.

module zero_flag_reg(Clk, Reset, En, zero_load, zero, zero_flag);
    input Clk, Reset, En;
    input zero_load;
    input zero;
    output reg zero_flag;

    always @(posedge Clk) begin
        if (Reset)
            zero_flag <= 1'b0;
        else if (En && zero_load)
            zero_flag <= zero;
    end

endmodule