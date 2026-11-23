//Output Register for CPU

//Holds the value shown on the LEDs by the OUT instruction. It keeps that value
//until the next OUT, so the LEDs stay steady while the rest of the program runs.

//Two Behaviours:
//  (1) Clear to 0 on reset.
//  (2) Store the value of r_a (from the register aile's a output), if En and
//      out_load are both high.

module out_reg(Clk, Reset, En, out_load, out_data, leds);
    input Clk, Reset, En;
    input out_load;
    input [7:0] out_data;
    output reg [7:0] leds;

    always @(posedge Clk) begin
        if (Reset)
            leds <= 8'b0;
        else if (En && out_load)
            leds <= out_data;
    end

endmodule