// vga_debug_draw.v
// Draws the CPU debugger screen, one pixel per clock cycle.
//
// Screen: 320 x 240 pixels, 3-bit color {R, G, B}.
// Text:   8 x 8 pixel characters, so the screen is 40 columns x 30 rows of text.
//
// How it works:
//   1. Two counters (x, y) sweep every pixel on the screen, over and over.
//   2. For each pixel, work out which text character it is inside, and which
//      pixel of that character.
//   3. Look the character up in the font ROM to see if that pixel is on or off.
//   4. Send (x, y, color) to the VGA adapter with write = 1.
//
// A full sweep takes 320 x 240 = 76,800 cycles = about 1.5 ms at 50 MHz,
// so the screen always shows the live CPU values.

module vga_debug_draw (
    input  wire        Clk,
    input  wire        Reset,       // active high, synchronous
    // CPU Values
    input  wire [4:0]  pc,
    input  wire [63:0] dis_regs,    // R0 = [7:0], ..., R7 = [63:56]
    input  wire [15:0] ir,
    input  wire [1:0]  state,
    input  wire        zero_flag,
    // What goes to the Adapter
    output reg  [8:0]  x,           // to vga_adapter
    output reg  [7:0]  y,
    output reg  [2:0]  color,
    output reg         write
);

    // ---------------- Colors {R, G, B} ----------------
    // Every color is 3 bits, each bit turns that color full on or off
    // eg, 110 -> red on, green on, blue off = yellow
    localparam BLACK  = 3'b000,
               BLUE   = 3'b001,
               GREEN  = 3'b010,
               CYAN   = 3'b011,
               RED    = 3'b100,
               YELLOW = 3'b110,
               WHITE  = 3'b111;

    localparam BG = BLACK;  // background color

    // ---------------- Pixel counters ----------------
    reg [8:0] px;   // 0 to 319
    reg [7:0] py;   // 0 to 239

    always @(posedge Clk) begin
        if (Reset) begin // reset px and py to top left
            px <= 9'd0;
            py <= 8'd0;
        end
        else if (px == 9'd319) begin // at end of row, go back to x = 0 and move down one row
            px <= 9'd0;
            if (py == 8'd239) // at bottom, wrap back to top, otherwise y + 1
                 py <= 8'd0;
            else
            py <= py + 8'd1;
        end
        else begin
            px <= px + 9'd1; // move one pixel right
        end
    end

    // Which text cell (row, col) and which pixel inside the 8x8 cell
    // each character is 8x8 so text row is y/8 and column is x/8
    // dividing by 8 = 2^3 so drop the bottom 3 bits
    wire [4:0] cr = py[7:3];   // text row,    0 to 29
    wire [5:0] cc = px[8:3];   // text column, 0 to 39
    wire [2:0] fr = py[2:0];   // pixel row inside the character
    wire [2:0] fc = px[2:0];   // pixel column inside the character

    // ---------------- Helper functions ----------------

    // Character number idx (0 = first) of a string with len characters
    // strings are stored with ASCII bytes, with first letter in hgihest bits
    function [6:0] str_char(input [8*20-1:0] s, input [4:0] len, input [5:0] idx);
        str_char = s[8*(len - 1 - idx) +: 7]; // finds where letter starts; eg, PC = 2
    endfunction

    // One hex digit -> ASCII
    // turns a 4 bit number into the ASCII code for 0-9 or A-F
    function [6:0] hex_char(input [3:0] n);
        if (n < 4'd10)
            hex_char = 7'h30 + n;
        else
            hex_char = 7'h41 + n - 4'd10;
    endfunction

    // Opcode -> 3-letter name
    function [8*3-1:0] op_name(input [3:0] op);
        case (op)
        // short words padded with space
            4'd0:  op_name = "NOP";
            4'd1:  op_name = "ADD";
            4'd2:  op_name = "SUB";
            4'd3:  op_name = "AND";
            4'd4:  op_name = "OR ";
            4'd5:  op_name = "XOR";
            4'd6:  op_name = "SHL";
            4'd7:  op_name = "SHR";
            4'd8:  op_name = "LDI";
            4'd9:  op_name = "LD ";
            4'd10: op_name = "ST ";
            4'd11: op_name = "JMP";
            4'd12: op_name = "BZ ";
            4'd13: op_name = "BNZ";
            4'd14: op_name = "IN ";
            default: op_name = "OUT";
        endcase
    endfunction

   // State -> name (7 letters)
    function [8*7-1:0] state_name(input [1:0] s);
        case (s)
            2'd0:    state_name = "FETCH  ";
            2'd1:    state_name = "DECODE ";
            2'd2:    state_name = "EXECUTE";
            default: state_name = "WRITE  ";
        endcase
    endfunction

    // ---------------- Screen layout ----------------
    //
    //   col: 0 2     8     14
    //   row 1   8-BIT CPU DEBUGGER
    //   row 4   PC    05
    //   row 6   IR    1A50  ADD
    //   row 8   STATE EXECUTE
    //   row 10  ZERO  0
    //   row 13  REGISTERS
    //   row 15  R0  03     R4  00
    //   row 17  R1  1F     R5  00
    //   row 19  R2  00     R6  00
    //   row 21  R3  00     R7  00

    reg  [6:0] ch;      // character at this text cell (ASCII)
    reg  [2:0] fg;      // its color

    wire [4:0] rr = cr - 5'd15;                      // 0, 2, 4, 6 on register rows
    wire [1:0] ri = rr[2:1];                         // register row 0 to 3
    wire [7:0] reg_l = dis_regs[8*ri +: 8];          // R0 to R3
    wire [7:0] reg_r = dis_regs[8*(ri + 3'd4) +: 8]; // R4 to R7

    always @(*) begin
        ch = 7'h20;   // space
        fg = WHITE;

        // Title
        if (cr == 5'd1 && cc >= 6'd2 && cc < 6'd20) begin
            ch = str_char("8-BIT CPU DEBUGGER", 5'd18, cc - 6'd2);
            fg = YELLOW;
        end

        // PC
        else if (cr == 5'd4) begin
            if (cc >= 6'd2 && cc < 6'd4)  begin ch = str_char("PC", 5'd2, cc - 6'd2); fg = CYAN; end
            else if (cc == 6'd8)          ch = hex_char({3'b000, pc[4]});
            else if (cc == 6'd9)          ch = hex_char(pc[3:0]);
        end

        // IR (hex and opcode name)
        else if (cr == 5'd6) begin
            if (cc >= 6'd2 && cc < 6'd4)  begin ch = str_char("IR", 5'd2, cc - 6'd2); fg = CYAN; end
            else if (cc == 6'd8)          ch = hex_char(ir[15:12]);
            else if (cc == 6'd9)          ch = hex_char(ir[11:8]);
            else if (cc == 6'd10)         ch = hex_char(ir[7:4]);
            else if (cc == 6'd11)         ch = hex_char(ir[3:0]);
            else if (cc >= 6'd14 && cc < 6'd17) begin
                ch = str_char(op_name(ir[15:12]), 5'd3, cc - 6'd14);
                fg = GREEN;
            end
        end

        // State
        else if (cr == 5'd8) begin
            if (cc >= 6'd2 && cc < 6'd7)  begin ch = str_char("STATE", 5'd5, cc - 6'd2); fg = CYAN; end
            else if (cc >= 6'd8 && cc < 6'd15) begin
                ch = str_char(state_name(state), 5'd7, cc - 6'd8);
                fg = GREEN;
            end
        end

        // Zero flag
        else if (cr == 5'd10) begin
            if (cc >= 6'd2 && cc < 6'd6) begin
                ch = str_char("ZERO", 5'd4, cc - 6'd2);
                fg = CYAN;
            end
            else if (cc == 6'd8) begin
                if (zero_flag)
                    ch = 7'h31;
                else
                    ch = 7'h30;
            end
        end

        // Registers heading
        else if (cr == 5'd13 && cc >= 6'd2 && cc < 6'd11) begin
            ch = str_char("REGISTERS", 5'd9, cc - 6'd2);
            fg = YELLOW;
        end

        // Registers: R0-R3 on the left, R4-R7 on the right
        else if (cr >= 5'd15 && cr < 5'd22 && cr[0] == 1'b1) begin
            if      (cc == 6'd2)  begin ch = 7'h52; fg = CYAN; end            // 'R'
            else if (cc == 6'd3)  begin ch = hex_char({2'b00, ri}); fg = CYAN; end
            else if (cc == 6'd6)  ch = hex_char(reg_l[7:4]);
            else if (cc == 6'd7)  ch = hex_char(reg_l[3:0]);
            else if (cc == 6'd12) begin ch = 7'h52; fg = CYAN; end
            else if (cc == 6'd13) begin ch = hex_char({2'b01, ri}); fg = CYAN; end
            else if (cc == 6'd16) ch = hex_char(reg_r[7:4]);
            else if (cc == 6'd17) ch = hex_char(reg_r[3:0]);
        end
    end

    // ---------------- Font lookup ----------------
    wire [7:0] font_bits;

    font_rom font (
        .ascii(ch),
        .row(fr),
        .bits(font_bits)
    );

    wire pixel_on = font_bits[3'd7 - fc];   // bit 7 is the leftmost pixel

    // ---------------- Output to the VGA adapter ----------------
    // Registered, so x, y and color always line up.
    always @(posedge Clk) begin
        if (Reset) begin
            x     <= 9'd0;
            y     <= 8'd0;
            color <= BG;
            write <= 1'b0;
        end
        else begin
            x     <= px;
            y     <= py;
            if (pixel_on)
                color <= fg;
            else
                color <= BG;
            write <= 1'b1;
        end
    end

endmodule