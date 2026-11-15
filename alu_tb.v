//Arithmetic Logic Unit (ALU) Testbench

//Tests the ALU by simulating a case: drive the inputs and relay the outputs

`timescale 1ns/ 1ps

module alu_tb();

    reg [7:0]a, b;
    reg [2:0]op;
    wire [7:0] result;
    wire [0:0]zero;

    alu alu1(.a(a), .b(b), .op(op), .result(result), .zero(zero));

    initial begin
        a = 8'd6; 
        b = 8'd7;
        op = 3'b000;
        #10;        //wait 10 time units
        $stop;      //end simulation
    end 

endmodule