
// Simple testbench for step_control.
// check results in modelsim waveform
// RUN_DIV is set to 5 so run mode simulates quicker

// Expected in the waveform:
//   Short press:     1 En pulse
//   Long press:      1 En pulse (even though b_step is held for 200 clocks)
//   Three presses:   3 En pulses
//   Run mode:        1 En pulse every 5 clocks (10 pulses in 50 clocks)
//   Step mode again: no En pulses

`timescale 1ns/1ps

module step_control_tb;

    // Inputs to step control
    reg  Clk = 0;
    reg  Reset = 1;
    reg  b_step = 0;
    reg  m_run = 0;

    // Output from step control
    wire En;

    step_control #(.RUN_DIV(5)) dut (
        .Clk(Clk),
        .Reset(Reset),
        .b_step(b_step),
        .m_run(m_run),
        .En(En)
    );

    // 50 MHz clock: period 20 ns
    always #10 Clk = ~Clk;

    // Press the button, hold it for some clock cycles, then let go
    task press(input integer hold);
        begin
            b_step = 1;
            repeat (hold) @(posedge Clk);
            #1 b_step = 0;
            repeat (5) @(posedge Clk);
        end
    endtask

    initial begin
        // Reset for 3 clock cycles
        repeat (3) @(posedge Clk);
        #1 Reset = 0;

        // No press for 20 clocks
        repeat (20) @(posedge Clk);

        // Short press (1 clock)
        press(1);

        // Long press (200 clocks)
        press(200);

        // Three presses
        press(3); press(3); press(3);

        // Run mode for 50 clocks
        #1 m_run = 1;
        repeat (54) @(posedge Clk);

        // Back to step mode for 50 clocks
        #1 m_run = 0;
        repeat (54) @(posedge Clk);

        $stop;
    end

endmodule