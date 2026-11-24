// Draws the CPU's state and the virtual pet, one pixel per clock cycle.

// Screen: 320 x 240 pixels, 9-bit color {RRR, GGG, BBB}.
// Digits: 8 x 8 pixels each, so the screen is a 40 x 30 grid of digit cells.

// Left side, debug digits (text row, text column):
//   row 2   col 2-3     PC           (white)
//   row 4   col 2-5     IR           (white)
//   row 6   col 2       state 0-3    (green)
//   row 8   col 2       zero flag    (green)
//   row 11  col 2-3  R0     col 7-8  R4     (yellow)
//   row 13  col 2-3  R1     col 7-8  R5
//   row 15  col 2-3  R2     col 7-8  R6
//   row 17  col 2-3  R3     col 7-8  R7

// Right side, virtual pet:
//   pet sprite  x 200-263, y 32-95   (32 x 32 sprite drawn 2x bigger, 64 x 64)
//   food bar    x 200-263, y 104-111 (orange, 8 pixels per point of food)
//   fun bar     x 200-263, y 116-123 (cyan,   8 pixels per point of fun)

// Pet registers (set by the pet program): R1 = food, R2 = fun, R4 = sleep flag,
// R6 = switches read by IN (bit 0 = feed, bit 1 = play).
// Face order: game over -> sleeping -> eating -> playing -> hungry -> sad -> happy
// (first match wins).

// Pipeline: the sprite ROM takes 1 clock to read, so every other signal is delayed
// by 1 clock to line up with it, then registered once more for the output.

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
    output reg  [8:0]  color,
    output reg         write
);

    // Colors {RRR, GGG, BBB} 
    localparam BLACK  = 9'b000_000_000,
               GRAY   = 9'b010_010_010,
               GREEN  = 9'b000_111_000,
               YELLOW = 9'b111_111_000,
               WHITE  = 9'b111_111_111,
               ORANGE = 9'b111_100_000,
               CYAN   = 9'b000_110_111,
               TRANSP = 9'b111_000_111;   // magenta = see-through in the sprite

    // Pet position 
    localparam PET_X = 9'd200,
               PET_Y = 8'd32,
               FOOD_Y = 8'd104,
               FUN_Y  = 8'd116;

    // Pixel counters 
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

    // Debug digits (same as before)
    wire [4:0] cr = py[7:3];   // cell row,    0 to 29   (y / 8)
    wire [5:0] cc = px[8:3];   // cell column, 0 to 39   (x / 8)
    wire [2:0] fr = py[2:0];   // pixel row inside the digit    (y mod 8)
    wire [2:0] fc = px[2:0];   // pixel column inside the digit (x mod 8)

    wire [4:0] rr    = cr - 5'd11;
    wire [1:0] line  = rr[2:1];
    wire [7:0] reg_l = dis_regs[8*line +: 8];        // R0 to R3
    wire [7:0] reg_r = dis_regs[8*(line + 4) +: 8];  // R4 to R7

    reg       show;
    reg [3:0] digit;
    reg [8:0] fg;

    always @(*) begin
        show  = 1'b0;
        digit = 4'h0;
        fg    = WHITE;

        if (cr == 5'd2) begin
            if (cc == 6'd2) begin show = 1'b1; digit = {3'b000, pc[4]}; end
            if (cc == 6'd3) begin show = 1'b1; digit = pc[3:0]; end
        end
        else if (cr == 5'd4) begin
            if (cc == 6'd2) begin show = 1'b1; digit = ir[15:12]; end
            if (cc == 6'd3) begin show = 1'b1; digit = ir[11:8];  end
            if (cc == 6'd4) begin show = 1'b1; digit = ir[7:4];   end
            if (cc == 6'd5) begin show = 1'b1; digit = ir[3:0];   end
        end
        else if (cr == 5'd6) begin
            fg = GREEN;
            if (cc == 6'd2) begin show = 1'b1; digit = {2'b00, state}; end
        end
        else if (cr == 5'd8) begin
            fg = GREEN;
            if (cc == 6'd2) begin show = 1'b1; digit = {3'b000, zero_flag}; end
        end
        else if (cr >= 5'd11 && cr <= 5'd17 && cr[0] == 1'b1) begin
            fg = YELLOW;
            if (cc == 6'd2) begin show = 1'b1; digit = reg_l[7:4]; end
            if (cc == 6'd3) begin show = 1'b1; digit = reg_l[3:0]; end
            if (cc == 6'd7) begin show = 1'b1; digit = reg_r[7:4]; end
            if (cc == 6'd8) begin show = 1'b1; digit = reg_r[3:0]; end
        end
    end

    wire [7:0] font_bits;

    font_rom font (
        .digit(digit),
        .row(fr),
        .bits(font_bits)
    );

    wire pixel_on = show & font_bits[3'd7 - fc];

    // Color from the text and bars (everything except the sprite)
    reg [8:0] base_color;
    // Pet: mood, sprite position, stat bars
    // Pet stats are pulled out of registers 
    wire [7:0] food  = dis_regs[15:8];    // R1
    wire [7:0] fun   = dis_regs[23:16];   // R2
    wire [7:0] sleep = dis_regs[39:32];   // R4
    wire [7:0] sw_in = dis_regs[55:48];   // R6: switches from the last IN

    // Before the program starts, every register is 0. That is "not started", not game over.
    wire not_started = (food == 8'd0) && (fun == 8'd0);
    wire game_over   = !not_started && ((food == 8'd0) || (fun == 8'd0));

    reg [2:0] face;
    // if/else if chain picks face, in order of priority 
    always @(*) begin
        if (game_over)            
            face = 3'd4;   // game over
        else if (sleep != 8'd0)   
            face = 3'd3;   // sleeping
        else if (sw_in[0])        
            face = 3'd5;   // eating  (feed switch on)
        else if (sw_in[1])        
            face = 3'd6;   // playing (play switch on)
        else if 
            (food <= 8'd3 && !not_started) face = 3'd1;   // hungry
        else if 
            (fun  <= 8'd3 && !not_started) face = 3'd2;   // sad
        else                      
            face = 3'd0;   // happy
    end

    // Position inside the pet's 64 x 64 box on screen
    wire [8:0] dx = px - PET_X;
    wire [7:0] dy = py - PET_Y;

    wire in_pet  = (px >= PET_X) && (px < PET_X + 9'd64) &&
                   (py >= PET_Y) && (py < PET_Y + 8'd64);

    // Drawn 2x bigger: drop the lowest bit, so each sprite pixel is a 2 x 2 block
    wire [4:0] sx = dx[5:1];
    wire [4:0] sy = dy[5:1];

    wire [8:0] sprite_color;

    pet_rom pet (
        .Clk(Clk),
        .face(face),
        .sx(sx),
        .sy(sy),
        .color(sprite_color)
    );

    // Stat bars: 8 pixels wide per point, up to 8 points = 64 pixels
    wire in_bar_x = (px >= PET_X) && (px < PET_X + 9'd64); // inside bar columns (x from 200 to 263)
    wire in_food  = in_bar_x && (py >= FOOD_Y) && (py < FOOD_Y + 8'd8); // inside food rows (104-111)
    wire in_fun   = in_bar_x && (py >= FUN_Y)  && (py < FUN_Y  + 8'd8); // inside fun rows (116-123)
    wire food_on  = ({3'b000, dx} < {food, 3'b000});   // dx < food x 8 (e.g. food = 5, dx < 40, first 40 pixels of the bar are orange)
    wire fun_on   = ({3'b000, dx} < {fun,  3'b000});   // dx < fun x 8 (e.g. fun = 3, dx < 24)

    always @(*) begin
    if (in_food) begin
        if (food_on)
            base_color = ORANGE;
        else
            base_color = GRAY;
    end
    else if (in_fun) begin
        if (fun_on)
            base_color = CYAN;
        else
            base_color = GRAY;
    end
    else if (pixel_on)
        base_color = fg;
    else
        base_color = BLACK;
    end

    // Pipeline and output
    // Stage 1: wait one clock for the sprite ROM
    // sprite color arrives from ROM one clock late; we match 
    // other signals to line up with it, then register everything again for the output.
    reg [8:0] x1;
    reg [7:0] y1;
    reg [8:0] base1;
    reg       in_pet1;

    always @(posedge Clk) begin
        x1      <= px;
        y1      <= py;
        base1   <= base_color;
        in_pet1 <= in_pet;
    end

    // Stage 2: pick sprite or background, send to the VGA adapter
    // x,y, color all travel togeteher, so we can register them together for the output.
    // sends delayed x and y 
    // if inside the kitty sprite, and the sprite pixel is not transparent, 
    // send the sprite color; otherwise send the base color (text or bar).
    always @(posedge Clk) begin
        if (Reset) begin
            x     <= 9'd0;
            y     <= 8'd0;
            color <= BLACK;
            write <= 1'b0;
        end
        else begin
            x     <= x1;
            y     <= y1;
            color <= (in_pet1 && sprite_color != TRANSP) ? sprite_color : base1;
            write <= 1'b1;
        end
    end

endmodule
