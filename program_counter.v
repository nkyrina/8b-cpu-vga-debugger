//Program Counter for CPU

//Walks through the program instructions and keeps track of the CPU's position
//in the instructions. Holds address of current instruction and selects instructions
//from pseudo-ROM register.

//Three Behaviours:
//  (1) Start at the beginning of the program.
//  (2) Move to the next line.
//  (3) Jump to a different line in the program.

module program_counter(Clk, Reset, En, pc_inc, pc_load, target, pc);

    input [0:0] Clk, Reset, En;
    input [0:0] pc_inc, pc_load;
    input [4:0] target;
    output reg [4:0] pc;

    always @(posedge Clk) begin
        if (Reset)
            pc <= 5'b00000;
        else if (En) begin
            if (pc_load)
                pc <= target;
            else if (pc_inc)
                pc <= pc + 5'd1;
        end
    end

endmodule
