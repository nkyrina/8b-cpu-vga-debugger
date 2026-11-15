// vga_debug.v
// VGA debugger: shows the CPU's PC, IR, state, zero flag and registers on a monitor.
// Ports match README display ports 

// Uses the course-provided vga_adapter file at 320 x 240 with 3-bit color

// Needs these files in the Quartus project:
//   vga_debug_draw.v, font_rom.v
//   vga_adapter/vga_adapter.v, vga_controller.v, vga_pll.v, vga_address_translator.v (FROM VGA ADAPTER)

module vga_debug (
    input  wire        Clk,         // must be CLOCK_50
    input  wire        Reset,       // active high, synchronous
    input  wire [4:0]  pc,
    input  wire [63:0] dis_regs,    // R0 = [7:0], ..., R7 = [63:56]
    input  wire [15:0] ir,
    input  wire [1:0]  state,
    input  wire        zero_flag,

    // VGA pins (connect straight to the DE1-SoC pins in top.v)
    output wire [7:0]  VGA_R,
    output wire [7:0]  VGA_G,
    output wire [7:0]  VGA_B,
    output wire        VGA_HS,
    output wire        VGA_VS,
    output wire        VGA_BLANK_N,
    output wire        VGA_SYNC_N,
    output wire        VGA_CLK
);

    // 320 x 240 display
    wire [8:0] x; // 9 bits -> 2^9 = 512 > 319
    wire [7:0] y; // 8 bits -> 2^8 = 256 > 239
    wire [2:0] color; // 1 bit for R, G, B
    wire       write; // save pixel

    vga_debug_draw draw (
        // passes clock, cpu values, and vga drawer values in
        .Clk(Clk),
        .Reset(Reset),
        .pc(pc),
        .dis_regs(dis_regs),
        .ir(ir),
        .state(state),
        .zero_flag(zero_flag),
        .x(x),
        .y(y),
        .color(color),
        .write(write)
    );

    vga_adapter #(
        // change vga adapter parameters from defaults
        .RESOLUTION("320x240"),
        .COLOR_DEPTH(3),
        .BACKGROUND_IMAGE("UNUSED") // black pixels
    ) vga (
        .resetn(~Reset),            // the adapter's reset is active low
        .clock(Clk),
        .color(color),
        .x(x),
        .y(y),
        .write(write),
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