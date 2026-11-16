//

// Board controls:
//   KEY[0]   reset (back to FETCH)
//   KEY[1]   step (one press = one state)
//   SW[9]    run mode (1 = step automatically, 0 = use KEY[1])
//   SW[3:0]  fake opcode   (stands in for ir[15:12])
//   SW[4]    fake zero flag
//
// LEDs show the FSM's control signals:
//   LEDR[0] ir_load    LEDR[1] pc_inc     LEDR[2] pc_load
//   LEDR[3] wr_en      LEDR[4] zero_load  LEDR[5] ram_wr_en
//   LEDR[6] out_load   LEDR[7] En (flashes on each step)
//   LEDR[9:8] state
//
// VGA shows: PC = 00, IR = opcode from SW[3:0], state, zero flag = SW[4], registers = 00.

module milestone1top (
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

    // standins
    // switches -> opcode
	 // sw4 -> zeroflag
    wire [3:0]  opcode    = SW[3:0];
    wire        zero_flag = SW[4];
    wire [4:0]  pc        = 5'd0;
    wire [15:0] ir        = {opcode, 12'h000};
    wire [63:0] dis_regs  = 64'd0;

    // step control
    wire En;

    step_control sc (
        .Clk(CLOCK_50),
        .Reset(Reset),
        .b_step(b_step),
        .m_run(m_run),
        .En(En)
    );

    // control fsm
    wire [1:0] state;
    wire       ir_load, pc_inc, pc_load, wr_en, zero_load, ram_wr_en, out_load;
    wire [1:0] wb_sel;
    wire [2:0] alu_op;

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

    assign LEDR[0]   = ir_load;
    assign LEDR[1]   = pc_inc;
    assign LEDR[2]   = pc_load;
    assign LEDR[3]   = wr_en;
    assign LEDR[4]   = zero_load;
    assign LEDR[5]   = ram_wr_en;
    assign LEDR[6]   = out_load;
    assign LEDR[7]   = (en_blink != 23'd0);
    assign LEDR[9:8] = state;

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
