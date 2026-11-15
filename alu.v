//Arithmetic Logic Unit (ALU) for CPU

//Handles eight possible computational cases based on the given op code

module alu(a, b, op, result, zero);
    input [7:0]a, b;
    input [2:0]op;
    output reg[7:0] result;

    output [0:0]zero;
    assign zero = !result;

    //Handles the respective op code
    always @(*) begin
        case(op)
        3'b000: result = a + b;
        3'b001: result = a - b;
        3'b010: result = a & b;
        3'b011: result = a | b;
        3'b100: result = a ^ b;
        3'b101: result = a << 1;
        3'b110: result = a >> 1;
        default: result = 8'd0;
        endcase
    end

endmodule
