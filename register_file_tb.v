//Register File Testbench

//Tests the register file by driving its inputs through each behaviour:
//reset, writing every register, reading two registers at once, write enable off,
//step enable off, and reading a register while it is being written.

//Each register Rn is written with the hex value 1n (R0 = 10, R1 = 11, ... R7 = 17),
//so the register number is visible in the value and in dis_regs.

//Rising clock edges are at 5, 15, 25 ns and so on. Inputs change every 10 ns
//starting at 0, so each 10 ns step contains exactly one rising edge.

`timescale 1ns / 1ps

module register_file_tb();

    //Driven by the testbench
    reg [0:0] Clk, Reset, En;
    reg [0:0] wr_en;
    reg [2:0] r_a, r_b, wr_loc;
    reg [7:0] wr_data;

    //Driven by the register file
    wire [7:0] a, b;
    wire [63:0] dis_regs;

    integer i;

    register_file rf1(.Clk(Clk), .Reset(Reset), .En(En), .wr_en(wr_en), .r_a(r_a), .r_b(r_b),
                      .wr_loc(wr_loc), .wr_data(wr_data), .a(a), .b(b), .dis_regs(dis_regs));

    //Clock: time period is 10 units
    initial Clk = 0;
    always #5 Clk = ~Clk;

    initial begin

        //GENERAL CASES

        Reset = 1'b1;
        En = 1'b0;
        wr_en = 1'b0;
        r_a = 3'd0;
        r_b = 3'd0;
        wr_loc = 3'd0;
        wr_data = 8'h00;    //Reset: expect dis_regs = 0000000000000000
        #10;

        Reset = 1'b0;
        En = 1'b1;
        wr_en = 1'b1;       //Write R0 to R7, one per clock edge
        for (i = 0; i < 8; i = i + 1) begin
            wr_loc = i;
            wr_data = 8'h10 + i;
            #10;
        end                 //expect dis_regs = 1716151413121110

        Reset = 1'b0;
        En = 1'b1;
        wr_en = 1'b0;
        r_a = 3'd2;
        r_b = 3'd5;
        wr_loc = 3'd0;
        wr_data = 8'h00;    //Read two registers at once: expect a = 12, b = 15
        #10;

        //EDGE CASES

        Reset = 1'b0;
        En = 1'b1;
        wr_en = 1'b0;
        r_a = 3'd3;
        r_b = 3'd5;
        wr_loc = 3'd3;
        wr_data = 8'hFF;    //Write enable off: expect a = 13 (R3 unchanged)
        #10;

        Reset = 1'b0;
        En = 1'b0;
        wr_en = 1'b1;
        r_a = 3'd3;
        r_b = 3'd5;
        wr_loc = 3'd3;
        wr_data = 8'hFF;    //Step enable off: expect a = 13 (R3 unchanged)
        #10;

        Reset = 1'b0;
        En = 1'b1;
        wr_en = 1'b1;
        r_a = 3'd3;
        r_b = 3'd5;
        wr_loc = 3'd3;
        wr_data = 8'hAA;    //Read during write: expect a = 13 before the edge, AA after
        #10;

        Reset = 1'b1;
        En = 1'b0;
        wr_en = 1'b0;
        r_a = 3'd3;
        r_b = 3'd5;
        wr_loc = 3'd0;
        wr_data = 8'h00;    //Reset: expect dis_regs = 0000000000000000, a = 00, b = 00
        #10;

        $stop;              //end simulation
    end

endmodule