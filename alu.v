//Arithmetic Logic Unit (ALU) for CPU

//Handles seven possible operations based on the given op code.

module alu(a, b, op, result, zero);
    input [7:0]a, b;
    input [2:0]op;
    output reg[7:0] result;

    output [0:0]zero;
    assign zero = !result;

    //Handles the respective op code
    always @(*) begin
        case(op)
        3'b000: result = a + b;     // ADD
        3'b001: result = a - b;     // SUB
        3'b010: result = a & b;     // AND
        3'b011: result = a | b;     // OR
        3'b100: result = a ^ b;     // XOR
        3'b101: result = a << 1;    // SHL
        3'b110: result = a >> 1;    // SHR
        default: result = 8'd0;     //Default
        endcase
    end

endmodule
