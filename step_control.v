// Step control for the 8-bit CPU 

// Makes the En pulse that lets the CPU move forward.
//   Step mode (m_run = 0): one press of b_step -> En = 1 for exactly one clock cycle
//   Run mode  (m_run = 1): En = 1 for one clock cycle every RUN_DIV cycles
//
// b_step must already be active high (KEY is inverted once in top.v).

// 4 Parts:
// 1. SYNCRHONIZER: button and switch aren't synced with clock, clean both to align
// 2. EDGE DETECTOR: Fires only when 0->1, so holding gives 1 pulse
// 3. SLOW COUNTER: Counts clock ticks and fires once every RUN_DIV tick; default 4 steps per second
// (means 1 instruction per second, since each instruction is 4 steps)
// 4. OUTPUT: En follows edge detector in step mode, always 1 clock tick long

module step_control #(
    parameter RUN_DIV = 12_500_000   // 50 MHz / 12.5M = 4 steps per second
) (
    // PORTS
    input  wire Clk,
    input  wire Reset,    // active high, synchronous
    input  wire b_step,   // step button, 1 = pressed
    input  wire m_run,    // 1 = run freely, 0 = single step
    output reg  En        // one-cycle step pulse
);

    // ---------------- Synchronize the inputs ----------------
    // Buttons and switches are not in sync with Clk
    // Passing them through two flip-flops prevents glitches
    reg [1:0] step_sync;
    reg [1:0] run_sync;

    always @(posedge Clk) begin
        if (Reset) begin
            // 2 Bit Registers (2 Flip Flops)
            step_sync <= 2'b00;
            run_sync  <= 2'b00;
        end
        else begin
            // CONCATENATION: glues bits together
            // Every tick, button value shifts one step at a time
            // Second flip flop gives a full tick to settle if button changes mid tick
            step_sync <= {step_sync[0], b_step};
            run_sync  <= {run_sync[0],  m_run};
        end
    end

    wire step_now = step_sync[1];
    wire run_now  = run_sync[1];

    // ---------------- Edge detection (step mode) ----------------
    // step_prev holds the button value from the last clock cycle.
    // A press is when it was 0 last cycle and is 1 now.

    // what button was last tick
    reg step_prev;

    always @(posedge Clk) begin
        if (Reset)
            step_prev <= 1'b0; // reset
        else
            step_prev <= step_now; // every tick copy current button into previous
    end

    // on ONLY if now is 1, prev. is 0: prevents holding
    wire step_pulse = step_now & ~step_prev; 

    // ---------------- Slow counter (run mode) ----------------
    // Counts 0, 1, ..., RUN_DIV - 1, then wraps.
    // run_tick is 1 for the one cycle when the count wraps.
    reg [31:0] count;

    always @(posedge Clk) begin
        if (Reset || !run_now) // Reset condiitons
            count <= 32'd0;
        else if (count == RUN_DIV - 1) // Wrap back to 0
            count <= 32'd0;
        else // Otherwise add 1
            count <= count + 32'd1; 
    end

    // ticks when the counter is at its last value ONLY in run mode
    wire run_tick = run_now && (count == RUN_DIV - 1);

    // ---------------- Output ----------------
    // En is registered so it is a clean one-cycle pulse.
    always @(posedge Clk) begin
        if (Reset)
            En <= 1'b0;
        else if (run_now) // in run mode, en copies the counter's tick
            En <= run_tick;
        else // in step mode, En copies button's edge pulse
            En <= step_pulse;
    end

endmodule