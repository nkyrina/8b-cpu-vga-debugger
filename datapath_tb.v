//Fetch Testbench (Program Counter + Pseudo-ROM + Instruction Register)

//Tests the fetch path of the CPU by connecting three modules together:
//program_counter --pc--> pseudo_rom --instr--> instr_reg --ir-->

//The testbench plays the role of the control FSM in its FETCH state by setting
//ir_load and pc_inc together. On each enabled clock edge the IR takes the
//instruction at the current address and the PC moves on to the next address.

//Rising clock edges are at 5, 15, 25 ns and so on. Inputs change every 10 ns
//starting at 0, so each 10 ns step contains exactly one rising edge.

`timescale 1ns / 1ps

module fetch_tb();

    //Driven by the testbench
    reg [0:0] Clk, Reset, En;
    reg [0:0] pc_inc, pc_load, ir_load;
    reg [4:0] target;

    //Driven by the modules
    wire [4:0] pc;          //program counter -> pseudo-ROM
    wire [15:0] instr;      //pseudo-ROM -> instruction register
    wire [15:0] ir;         //instruction being executed

    program_counter pc1(.Clk(Clk), .Reset(Reset), .En(En), .pc_inc(pc_inc), .pc_load(pc_load),
                        .target(target), .pc(pc));

    pseudo_rom rom1(.pc(pc), .instr(instr));

    instr_reg ir1(.Clk(Clk), .Reset(Reset), .En(En), .ir_load(ir_load), .instr(instr), .ir(ir));

    //Clock: time period is 10 units
    initial Clk = 0;
    always #5 Clk = ~Clk;

    initial begin

        Reset = 1'b1;
        En = 1'b0;
        pc_inc = 1'b0;
        pc_load = 1'b0;
        ir_load = 1'b0;
        target = 5'd0;      //Reset: expect pc = 0, ir = 0000
        #10;

        Reset = 1'b0;
        En = 1'b1;
        pc_inc = 1'b1;
        pc_load = 1'b0;
        ir_load = 1'b1;
        target = 5'd0;      //Fetch six times: expect ir = 8200, 8401, 1250, F040, B002, 0000
        #60;                //                 and pc = 1, 2, 3, 4, 5, 6

        Reset = 1'b0;
        En = 1'b0;
        pc_inc = 1'b1;
        pc_load = 1'b0;
        ir_load = 1'b1;
        target = 5'd0;      //Enable off for two edges: expect pc = 6, ir = 0000 (unchanged)
        #20;

        Reset = 1'b0;
        En = 1'b1;
        pc_inc = 1'b0;
        pc_load = 1'b1;
        ir_load = 1'b0;
        target = 5'd2;      //Jump to address 2: expect pc = 2, ir = 0000 (IR holds)
        #10;

        Reset = 1'b0;
        En = 1'b1;
        pc_inc = 1'b1;
        pc_load = 1'b0;
        ir_load = 1'b1;
        target = 5'd0;      //Fetch twice from address 2: expect ir = 1250, F040 and pc = 3, 4
        #20;

        $stop;              //end simulation

    end

endmodule
