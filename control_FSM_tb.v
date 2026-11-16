// simple testbench for the control fsm model
// drives inputs and we check for outputs in modelsim
//
// expected in the waveform:
//   state 0 FETCH:   ir_load = 1, pc_inc = 1        (every instruction)
//   state 1 DECODE:  all outputs 0                  (every instruction)
//   state 2 EXECUTE: pc_load = 1 for JMP, and for BZ when zero_flag = 1
//   state 3 WRITE:   ADD -> wr_en = 1, wb_sel = 0, zero_load = 1
//                    LDI -> wr_en = 1, wb_sel = 1
//                    ST  -> ram_wr_en = 1
//                    OUT -> out_load = 1

`timescale 1ns/1ps

module control_fsm_tb;

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

    control_fsm dut (
        .Clk(Clk), .Reset(Reset), .En(En),
        .opcode(opcode), .zero_flag(zero_flag),
        .state(state),
        .ir_load(ir_load), .pc_inc(pc_inc), .pc_load(pc_load),
        .wr_en(wr_en), .wb_sel(wb_sel), .alu_op(alu_op),
        .zero_load(zero_load), .ram_wr_en(ram_wr_en), .out_load(out_load)
    );

    // 50 MHz clock: period 20 ns
    always #10 Clk = ~Clk;

    // One step: En = 1 for one clock cycle, then wait one more cycle
    task step;
        begin
            En = 1;
            @(posedge Clk);
            #1 En = 0;
            @(posedge Clk);
        end
    endtask

    // Run one full instruction: set the opcode, then step through all 4 states
    task run_instr(input [3:0] op, input z);
        begin
            opcode = op;
            zero_flag = z;
            step; step; step; step;
        end
    endtask

    initial begin
        // Reset for 2 clock cycles
        @(posedge Clk); @(posedge Clk);
        #1 Reset = 0;

        // En = 0 for 3 clocks: state should stay at 0
        repeat (3) @(posedge Clk);

        run_instr(4'd1,  0);   // ADD
        run_instr(4'd8,  0);   // LDI
        run_instr(4'd10, 0);   // ST
        run_instr(4'd15, 0);   // OUT
        run_instr(4'd11, 0);   // JMP
        run_instr(4'd12, 1);   // BZ, zero_flag = 1 (jump)
        run_instr(4'd12, 0);   // BZ, zero_flag = 0 (no jump)

        // Reset in the middle: state should go back to 0
        step; step;
        Reset = 1; @(posedge Clk); #1 Reset = 0;
        repeat (3) @(posedge Clk);

        $stop;
    end

endmodule
