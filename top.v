`default_nettype none

//Top Level: 8-bit CPU with Live VGA Debugger

//Connects the CPU datapath, the control FSM, the step control, and the VGA
//debugger to the DE1-SoC board. The CPU runs the program stored in the
//pseudo-ROM, one FSM state per step.

// Board controls:
//   KEY[0]   reset (PC, IR, registers and flags clear; FSM returns to FETCH)
//   KEY[1]   step (one press = one FSM state)
//   SW[9]    run mode (1 = step automatically, 0 = use KEY[1])
//   SW[7:0]  input value for the IN instruction

// LEDs:
//   LEDR[7:0]  value from the most recent OUT instruction
//   LEDR[9:8]  current FSM state (0 FETCH, 1 DECODE, 2 EXECUTE, 3 WRITE)

// VGA shows the live CPU state: PC, IR, FSM state, zero flag, and R0 to R7.

module top (
    input  wire       CLOCK_50,
    input  wire [3:0] KEY,
    input  wire [9:0] SW,
    output wire [9:0] LEDR,

    output wire [7:0] VGA_R,
    output wire [7:0] VGA_G,
    output wire [7:0] VGA_B,
    output wire       VGA_HS,
    output wire       VGA_VS,
    output wire       VGA_BLANK_N,
    output wire       VGA_SYNC_N,
    output wire       VGA_CLK
);

    // ---------------- Board inputs ----------------
    // KEYs are active low (0 when pressed), so invert them here
    wire Reset  = ~KEY[0];
    wire b_step = ~KEY[1];
    wire m_run  = SW[9];

    // cpu signals, driven by the referenced module
    wire [4:0] pc;          // program_counter
    wire [15:0] instr;      // pseudo_rom
    wire [15:0] ir;         // instr_reg
    wire [63:0] dis_regs;   // register_file
    wire zero_flag;         // zero flag register

    // op code (four bits of instruction from ir)
    wire [3:0] opcode = ir[15:12];

    wire [7:0] reg_a, reg_b;    // register file -> ALU
    wire [7:0] alu_result;      // ALU -> write-back mux
    wire alu_zero;              // ALU -> zero flag register
    wire [7:0] wr_data;         // write-back mux -> register file
    wire [7:0] led_out;         // output register -> LEDs

    // step control
    wire En;
    
    // control fsm
    wire [1:0] state;
    wire       ir_load, pc_inc, pc_load, wr_en, zero_load, ram_wr_en, out_load;
    wire [1:0] wb_sel;
    wire [2:0] alu_op;

    //module instantiation

    program_counter pc1 (
        .Clk(CLOCK_50),
        .Reset(Reset),
        .En(En),
        .pc_inc(pc_inc),
        .pc_load(pc_load),
        .target(ir[4:0]),
        .pc(pc)
    );

    pseudo_rom pr1 (
        .pc(pc),
        .instr(instr)
    );

    instr_reg ir1(
        .Clk(CLOCK_50),
        .Reset(Reset),
        .En(En),
        .ir_load(ir_load),
        .instr(instr),
        .ir(ir)
    );

    register_file rf1 (
        .Clk(CLOCK_50),
        .Reset(Reset),
        .En(En),
        .wr_en(wr_en),
        .wr_loc(ir[11:9]),
        .r_a(ir[8:6]),
        .r_b(ir[5:3]),
        .wr_data(wr_data),
        .a(reg_a),
        .b(reg_b),
        .dis_regs(dis_regs)
    );

    alu alu1 (
        .a(reg_a),
        .b(reg_b),
        .op(alu_op),
        .result(alu_result),
        .zero(alu_zero)
    );

    zero_flag_reg zfr1 (
        .Clk(CLOCK_50),
        .Reset(Reset),
        .En(En),
        .zero_load(zero_load),
        .zero(alu_zero),
        .zero_flag(zero_flag)
    );
    
    wb_mux wbm1 (
        .wb_sel(wb_sel),
        .alu_result(alu_result),
        .imm8(ir[7:0]),
        .ram_data(8'd0),            // no RAM yet, so LD loads 0
        .sw_in(SW[7:0]),
        .wr_data(wr_data)
    );

    out_reg out1 (
        .Clk(CLOCK_50),
        .Reset(Reset),
        .En(En),
        .out_load(out_load),
        .out_data(reg_a),
        .leds(led_out)
    );

    step_control sc (
        .Clk(CLOCK_50),
        .Reset(Reset),
        .b_step(b_step),
        .m_run(m_run),
        .En(En)
    );

    control_fsm fsm (
        .Clk(CLOCK_50),
        .Reset(Reset),
        .En(En),
        .opcode(opcode),
        .zero_flag(zero_flag),
        .state(state),
        .ir_load(ir_load),
        .pc_inc(pc_inc),
        .pc_load(pc_load),
        .wr_en(wr_en),
        .wb_sel(wb_sel),
        .alu_op(alu_op),
        .zero_load(zero_load),
        .ram_wr_en(ram_wr_en),
        .out_load(out_load)
    );

    // leds
    // En is only 1 for 1 clock cycle, so stretch it to about 0.1 s so the LED visibly flashes.
    reg [22:0] en_blink;

    always @(posedge CLOCK_50) begin
        if (Reset)
            en_blink <= 23'd0;
        else if (En)
            en_blink <= 23'd5_000_000;
        else if (en_blink != 23'd0)
            en_blink <= en_blink - 23'd1;
    end

    assign LEDR[7:0] = led_out;     // value from the last OUT instruction
    assign LEDR[9:8] = state;       // current FSM state

    // vga debugger
    vga_debug dbg (
        .Clk(CLOCK_50),
        .Reset(Reset),
        .pc(pc),
        .dis_regs(dis_regs),
        .ir(ir),
        .state(state),
        .zero_flag(zero_flag),
        .VGA_R(VGA_R),
        .VGA_G(VGA_G),
        .VGA_B(VGA_B),
        .VGA_HS(VGA_HS),
        .VGA_VS(VGA_VS),
        .VGA_BLANK_N(VGA_BLANK_N),
        .VGA_SYNC_N(VGA_SYNC_N),
        .VGA_CLK(VGA_CLK)
    );

endmodule

`default_nettype wire
