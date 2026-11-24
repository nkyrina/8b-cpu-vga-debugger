// Testbench for the kitty's mood selection in vga_pet_debug_draw.v.
// Drives the pet registers (R1 food, R2 fun, R4 sleep, R6 switches) through every mood. 
// !!! FOR MODELSIM ONLY

// Expected face in the waveform (first match wins):
//   1  food 8, fun 8             -> 0 happy
//   2  food 2, fun 8             -> 1 hungry     (food <= 3)
//   3  food 8, fun 2             -> 2 sad        (fun <= 3)
//   4  food 8, fun 8, sleep 4    -> 3 sleeping
//   5  food 0, fun 6             -> 4 game over  (a stat hit 0)
//   6  food 7, fun 6, SW[0] on   -> 5 eating
//   7  food 7, fun 6, SW[1] on   -> 6 playing
//   8  food 2, fun 8, sleep 4    -> 3 sleeping   (sleeping beats hungry)
//   9  food 0, fun 6, sleep 4    -> 4 game over  (game over beats everything)
//  10  food 0, fun 0             -> 0 happy      (not started, right after reset)

`timescale 1ns/1ps

module mood_tb;

    reg         Clk = 0;
    reg         Reset = 1;
    reg  [63:0] dis_regs = 64'd0;

    wire [8:0] x;
    wire [7:0] y;
    wire [8:0] color;
    wire       write;

    vga_debug_draw dut (
        .Clk(Clk),
        .Reset(Reset),
        .pc(5'd0),
        .dis_regs(dis_regs),
        .ir(16'h0000),
        .state(2'd0),
        .zero_flag(1'b0),
        .x(x),
        .y(y),
        .color(color),
        .write(write)
    );

    // 50 MHz clock: period 20 ns
    always #10 Clk = ~Clk;

    // Set the pet registers, then hold for 5 clocks so each mood is easy to see
    // dis_regs = {R7, R6, R5, R4, R3, R2, R1, R0}
    task pet(input [7:0] food, input [7:0] fun, input [7:0] sleep, input [7:0] sw);
        begin
            dis_regs = {8'd0, sw, 8'd0, sleep, 8'd0, fun, food, 8'd0};
            repeat (5) @(posedge Clk);
        end
    endtask

    initial begin
        // Reset for 2 clock cycles
        repeat (2) @(posedge Clk);
        #1 Reset = 0;

        //   food fun sleep switches
        pet(8,  8,  0,  0);     //  1 happy
        pet(2,  8,  0,  0);     //  2 hungry
        pet(8,  2,  0,  0);     //  3 sad
        pet(8,  8,  4,  0);     //  4 sleeping
        pet(0,  6,  0,  0);     //  5 game over
        pet(7,  6,  0,  1);     //  6 eating  (SW[0])
        pet(7,  6,  0,  2);     //  7 playing (SW[1])
        pet(2,  8,  4,  0);     //  8 sleeping beats hungry
        pet(0,  6,  4,  0);     //  9 game over beats sleeping
        pet(0,  0,  0,  0);     // 10 not started -> happy

        $stop;
    end

endmodule
