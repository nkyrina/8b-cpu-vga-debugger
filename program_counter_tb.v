//Program Counter Testbench

//Tests the program counter by driving its inputs through each behaviour:
//reset, increment, enable off, hold, load, load priority, and wraparound.

//Rising clock edges are at 5, 15, 25 ns and so on. Inputs change every 10 ns
//starting at 0, so each 10 ns step contains exactly one rising edge.

`timescale 1ns/ 1ps

module program_counter_tb();

    reg [0:0] Clk, Reset, En;
    reg [0:0] pc_inc, pc_load;
    reg [4:0] target;
    wire [4:0] pc;

    program_counter pc1(.Clk(Clk), .Reset(Reset), .En(En), .pc_inc(pc_inc), .pc_load(pc_load),
                        .target(target), .pc(pc));

    //Clock: time period is 10 units
    initial Clk = 0;
    always #5 Clk = ~Clk;

    initial begin

        //GENERAL CASES

        Reset = 1'b1;
        En = 1'b0;
        pc_inc = 1'b0;
        pc_load = 1'b0;
        target = 5'd0;      //Reset: expect 0
        #10;

        Reset = 1'b0;
        En = 1'b1;
        pc_inc = 1'b1;
        pc_load = 1'b0;
        target = 5'd0;      //Increment three times: expect 1, 2, 3
        #30;

        Reset = 1'b0;
        En = 1'b0;
        pc_inc = 1'b1;
        pc_load = 1'b0;
        target = 5'd0;      //Enable off: expect 3 (unchanged)
        #10;

        Reset = 1'b0;
        En = 1'b1;
        pc_inc = 1'b0;
        pc_load = 1'b0;
        target = 5'd0;      //Hold: expect 3 (unchanged)
        #10;

        Reset = 1'b0;
        En = 1'b1;
        pc_inc = 1'b0;
        pc_load = 1'b1;
        target = 5'd20;     //Load: expect 20
        #10;

        //EDGE CASES

        Reset = 1'b0;
        En = 1'b1;
        pc_inc = 1'b1;
        pc_load = 1'b1;
        target = 5'd9;      //Load beats increment: expect 9, not 21
        #10;

        Reset = 1'b0;
        En = 1'b1;
        pc_inc = 1'b0;
        pc_load = 1'b1;
        target = 5'd31;     //Load the maximum: expect 31
        #10;

        Reset = 1'b0;
        En = 1'b1;
        pc_inc = 1'b1;
        pc_load = 1'b0;
        target = 5'd0;      //Wraparound, then one more: expect 0, then 1
        #20;

        Reset = 1'b1;
        En = 1'b0;
        pc_inc = 1'b0;
        pc_load = 1'b0;
        target = 5'd0;      //Reset beats enable off: expect 0
        #10;

        $stop;          //end simulation
    end 

endmodule