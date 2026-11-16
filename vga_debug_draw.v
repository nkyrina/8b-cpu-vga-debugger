
// Draws the CPU's state on the screen as hex numbers, one pixel per clock cycle.

// Screen: 320 x 240 pixels, 3-bit color {R, G, B}.
// Digits: 8 x 8 pixels each, so the screen is a 40 x 30 grid of digit cells.

// Layout (text row, text column), no labels, each line has its own color:

//   row 2   col 2-3     PC           (white)
//   row 4   col 2-5     IR           (white)
//   row 6   col 2       state 0-3    (green)
//   row 8   col 2       zero flag    (green)
//   row 11  col 2-3  R0     col 7-8  R4     (yellow)
//   row 13  col 2-3  R1     col 7-8  R5
//   row 15  col 2-3  R2     col 7-8  R6
//   row 17  col 2-3  R3     col 7-8  R7

module vga_debug_draw (
    input  wire        Clk,
    input  wire        Reset,       // active high, synchronous
    input  wire [4:0]  pc,
    input  wire [63:0] dis_regs,    // R0 = [7:0], ..., R7 = [63:56]
    input  wire [15:0] ir,
    input  wire [1:0]  state,
    input  wire        zero_flag,

    output reg  [8:0]  x,           // to vga_adapter
    output reg  [7:0]  y,
    output reg  [2:0]  color,
    output reg         write
);

    // Colors {R, G, B}
    localparam BLACK  = 3'b000,
               GREEN  = 3'b010,
               YELLOW = 3'b110,
               WHITE  = 3'b111;

    // pixel counters
    // sweep left to right, then top to bottom
    // while running
    reg [8:0] px;   // 0 to 319
    reg [7:0] py;   // 0 to 239

    always @(posedge Clk) begin
        if (Reset) begin
            px <= 9'd0;
            py <= 8'd0;
        end
        else if (px == 9'd319) begin
            px <= 9'd0;
            py <= (py == 8'd239) ? 8'd0 : py + 8'd1;
        end
        else begin
            px <= px + 9'd1;
        end
    end

    // Which cell, which pixel
    wire [4:0] cr = py[7:3];   // cell row,    0 to 29   (y / 8)
    wire [5:0] cc = px[8:3];   // cell column, 0 to 39   (x / 8)
    wire [2:0] fr = py[2:0];   // pixel row inside the digit    (y mod 8)
    wire [2:0] fc = px[2:0];   // pixel column inside the digit (x mod 8)

    // Register lines are rows 11, 13, 15, 17 -> line 0, 1, 2, 3
    wire [4:0] rr    = cr - 5'd11;
    wire [1:0] line  = rr[2:1];
    wire [7:0] reg_l = dis_regs[8*line +: 8];        // R0 to R3
    wire [7:0] reg_r = dis_regs[8*(line + 4) +: 8];  // R4 to R7

    // layout: what digit goes in this cell
    reg       show;    // 1 = this cell has a digit
    reg [3:0] digit;   // which digit
    reg [2:0] fg;      // its color

    always @(*) begin
        show  = 1'b0;
        digit = 4'h0;
        fg    = WHITE;

        // PC
        if (cr == 5'd2) begin
            if (cc == 6'd2) begin show = 1'b1; digit = {3'b000, pc[4]}; end
            if (cc == 6'd3) begin show = 1'b1; digit = pc[3:0]; end
        end

        // IR
        else if (cr == 5'd4) begin
            if (cc == 6'd2) begin show = 1'b1; digit = ir[15:12]; end
            if (cc == 6'd3) begin show = 1'b1; digit = ir[11:8];  end
            if (cc == 6'd4) begin show = 1'b1; digit = ir[7:4];   end
            if (cc == 6'd5) begin show = 1'b1; digit = ir[3:0];   end
        end

        // State
        else if (cr == 5'd6) begin
            fg = GREEN;
            if (cc == 6'd2) begin show = 1'b1; digit = {2'b00, state}; end
        end

        // Zero flag      
        else if (cr == 5'd8) begin
            fg = GREEN;
            if (cc == 6'd2) begin show = 1'b1; digit = {3'b000, zero_flag}; end
        end

        // Registers: rows 11, 13, 15, 17
        else if (cr >= 5'd11 && cr <= 5'd17 && cr[0] == 1'b1) begin
            fg = YELLOW;
            if (cc == 6'd2) begin show = 1'b1; digit = reg_l[7:4]; end
            if (cc == 6'd3) begin show = 1'b1; digit = reg_l[3:0]; end
            if (cc == 6'd7) begin show = 1'b1; digit = reg_r[7:4]; end
            if (cc == 6'd8) begin show = 1'b1; digit = reg_r[3:0]; end
        end
    end

    // ---------------- Font lookup ----------------
    wire [7:0] font_bits;

    font_rom font (
        .digit(digit),
        .row(fr),
        .bits(font_bits)
    );

    // bit 7 is the leftmost pixel
    wire pixel_on = show & font_bits[3'd7 - fc];

    // ---------------- Output to the VGA adapter ----------------
    always @(posedge Clk) begin
        if (Reset) begin
            x     <= 9'd0;
            y     <= 8'd0;
            color <= BLACK;
            write <= 1'b0;
        end
        else begin
            x     <= px;
            y     <= py;
            color <= pixel_on ? fg : BLACK;
            write <= 1'b1;
        end
    end

endmodule
