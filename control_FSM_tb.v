// simplified testbench for control_fsm.
// runs 7 instructions through all 4 states and prints the outputs.
// check waveform against expected behavior in these comments
`timescale 1ns/1ps

module control_fsm_tb; // set unit of time for simulation 

    // Inputs to the FSM
    reg        Clk = 0;
    reg        Reset = 1;
    reg        En = 0;
    reg  [3:0] opcode = 0;
    reg        zero_flag = 0;

    // Outputs from the FSM
    wire [1:0] state;
    wire       ir_load, pc_inc, pc_load, wr_en, zero_load, ram_wr_en, out_load;
    wire [1:0] wb_sel;
    wire [2:0] alu_op;

    control_fsm testing (
        .Clk(Clk), .Reset(Reset), .En(En),
        .opcode(opcode), .zero_flag(zero_flag),
        .state(state),
        .ir_load(ir_load), .pc_inc(pc_inc), .pc_load(pc_load),
        .wr_en(wr_en), .wb_sel(wb_sel), .alu_op(alu_op),
        .zero_load(zero_load), .ram_wr_en(ram_wr_en), .out_load(out_load)
    );

    // 50 MHz clock: period 20 ns
    // wait 10ns then flip clock (0->1->0) every 10ns
    always #10 Clk = ~Clk;

    // Print the current state and outputs
    task show;
        begin
            #1;
            // prints line to transcript with opcode, zero_flag, state, and all outputs
            $display("op=%2d z=%b | state=%0d | ir_load=%b pc_inc=%b pc_load=%b wr_en=%b wb_sel=%0d zero_load=%b ram_wr_en=%b out_load=%b",
                     opcode, zero_flag, state, ir_load, pc_inc, pc_load, wr_en, wb_sel, zero_load, ram_wr_en, out_load);
        end
    endtask

    // One step: En = 1 for one clock cycle
    task step;
        begin
            En = 1;
            @(posedge Clk);
            #1 En = 0;
        end
    endtask

    // Run one full instruction (4 steps), printing each state
    task run_instr(input [3:0] op, input z);
        begin
            opcode = op;
            zero_flag = z;
            show; step;   // state 0 FETCH
            show; step;   // state 1 DECODE
            show; step;   // state 2 EXECUTE
            show; step;   // state 3 WRITE
            $display("");
        end
    endtask

    initial begin
        // Reset for 2 clock cycles
        @(posedge Clk); @(posedge Clk);
        #1 Reset = 0;

        // En = 0: state should stay at 0
        repeat (3) @(posedge Clk);
        $display("After 3 clocks with En = 0, state = %0d (expect 0)\n", state);

        // ADD: expect WRITE -> wr_en=1, wb_sel=0, zero_load=1
        $display("--- ADD ---");
        run_instr(4'd1, 0);

        // LDI: expect WRITE -> wr_en=1, wb_sel=1
        $display("--- LDI ---");
        run_instr(4'd8, 0);

        // ST: expect WRITE -> ram_wr_en=1
        $display("--- ST ---");
        run_instr(4'd10, 0);

        // OUT: expect WRITE -> out_load=1
        $display("--- OUT ---");
        run_instr(4'd15, 0);

        // JMP: expect EXECUTE -> pc_load=1
        $display("--- JMP ---");
        run_instr(4'd11, 0);

        // BZ with zero flag = 1: expect EXECUTE -> pc_load=1
        $display("--- BZ, zero_flag = 1 (jump) ---");
        run_instr(4'd12, 1);

        // BZ with zero flag = 0: expect pc_load=0 everywhere
        $display("--- BZ, zero_flag = 0 (no jump) ---");
        run_instr(4'd12, 0);

        // Reset in the middle: expect state back to 0
        step; step;
        Reset = 1; @(posedge Clk); #1 Reset = 0;
        $display("After reset in the middle, state = %0d (expect 0)", state);

        $stop;
    end

endmodule