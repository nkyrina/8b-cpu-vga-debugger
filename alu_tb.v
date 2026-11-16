//Arithmetic Logic Unit (ALU) Testbench

<<<<<<< Updated upstream
//Tests the ALU by driving each operation and several edge cases
=======
//Tests the ALU through case simulation: drive the inputs and relay the outputs
>>>>>>> Stashed changes

`timescale 1ns/ 1ps

module alu_tb();
    reg [7:0]a, b;
    reg [2:0]op;
    wire [7:0] result;
    wire [0:0]zero;

    alu alu1(.a(a), .b(b), .op(op), .result(result), .zero(zero));

    initial begin

        //GENERAL CASES
        a = 8'd12; 
        b = 8'd5;
        op = 3'b000;    //ADD: expect 17
        #10;            //wait 10 time units

        a = 8'd12; 
        b = 8'd5;
        op = 3'b001;    //SUB: expect 7
        #10;            //wait 10 time units

        a = 8'd204; 
        b = 8'd170;
        op = 3'b010;    //AND: expect 136
        #10;            //wait 10 time units

        a = 8'd204; 
        b = 8'd170;
        op = 3'b011;    //OR: expect 238
        #10;            //wait 10 time units

        a = 8'd204; 
        b = 8'd170;
        op = 3'b100;    //XOR: expect 102
        #10;            //wait 10 time units

        a = 8'd129; 
        b = 8'd0;
        op = 3'b101;    //SHL: expect 2
        #10;            //wait 10 time units

        a = 8'd129; 
        b = 8'd0;
        op = 3'b110;    //SHR: expect 64
        #10;            //wait 10 time units

        //EDGE CASES

        a = 8'd5; 
        b = 8'd5;
        op = 3'b001;    //Zero Flag: expect 0, zero = 1
        #10;            //wait 10 time units

        a = 8'd255; 
        b = 8'd1;
        op = 3'b000;    //Wraparound Up: expect 0, zero = 1
        #10;            //wait 10 time units

        a = 8'd0; 
        b = 8'd1;
        op = 3'b001;    //Wraparound Down: expect 255
        #10;            //wait 10 time units

        a = 8'd12; 
        b = 8'd5;
        op = 3'b111;    //Unused Op Code: expect 0, zero = 1
        #10;            //wait 10 time units

        $stop;          //end simulation
    end 

endmodule