//Register File for CPU

//Holds the eight 8-bit registers (R0 to R7) that the CPU uses as its working values.
//Two registers can be read at the same time, and one can be written per clock edge.

//Three Behaviours:
//  (1) Clear all registers on reset.
//  (2) Write wr_data into the register selected by wr_loc, if En and wr_en are both high.
//  (3) Output the registers selected by r_a and r_b on a and b, and all eight on dis_regs.

module register_file(Clk, Reset, En, wr_en, r_a, r_b, wr_loc, wr_data, a, b, dis_regs);
    input [0:0] Clk, Reset, En;
    input [0:0] wr_en;
    input [2:0] r_a, r_b, wr_loc;
    input [7:0] wr_data;
    output [7:0] a, b;
    output [63:0] dis_regs;

    integer i = 1'd0;

    reg [7:0] stor_regs [0:7];

    always @(posedge Clk) begin
        if (Reset)
            for (i = 0; i < 8; i = i+1) begin
                stor_regs[i] <= 8'b00000000;
            end
        else if (En) begin
            if (wr_en)
                stor_regs[wr_loc] <= wr_data;
        end
    end

    assign a = stor_regs[r_a];
    assign b = stor_regs[r_b];

    assign dis_regs = { stor_regs[7], 
                        stor_regs[6],
                        stor_regs[5],
                        stor_regs[4],
                        stor_regs[3],
                        stor_regs[2],
                        stor_regs[1],
                        stor_regs[0]};

endmodule
