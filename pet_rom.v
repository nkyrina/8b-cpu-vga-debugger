// Sprite ROM for the virtual pet: 7 faces, each 32 x 32 pixels.

// Reads the output of an online "PNG to hex" tool directly:
//   one 24-bit colour per pixel, written as 6 hex digits RRGGBB (e.g. ffffff),
//   row by row, left to right, separated by spaces or new lines


// One file per sprite, in the Quartus project folder:
//   face0.txt happy, face1.txt hungry, face2.txt sad, face3.txt sleeping,
//   face4.txt game over, face5.txt eating, face6.txt playing

// Pure black (000000) is treated as transparent, turns transparent into pure blac in the VGA output.

// The 24-bit colour is cut down to the VGA's 9-bit RRR GGG BBB by keeping the
// top 3 bits of each colour. The read is clocked (1 cycle delay) so Quartus puts
// this in on-chip block memory.

module pet_rom (
    input  wire       Clk,
    input  wire [2:0] face,     // which sprite, 0 to 6
    input  wire [4:0] sx,       // x inside the sprite, 0 to 31
    input  wire [4:0] sy,       // y inside the sprite, 0 to 31
    output reg  [8:0] color
);

    localparam TRANSP = 9'b111_000_111;   // what the drawer treats as see-through

    reg [23:0] mem [0:7167];    // 7 faces x 1024 pixels, 24-bit RRGGBB

    // Load each face into its own block of 1024 pixels
    initial begin
        $readmemh("kitty_faces/face0.txt", mem,    0, 1023);   // happy
        $readmemh("kitty_faces/face1.txt", mem, 1024, 2047);   // hungry
        $readmemh("kitty_faces/face2.txt", mem, 2048, 3071);   // sad
        $readmemh("kitty_faces/face3.txt", mem, 3072, 4095);   // sleeping
        $readmemh("kitty_faces/face4.txt", mem, 4096, 5119);   // game over
        $readmemh("kitty_faces/face5.txt", mem, 5120, 6143);   // eating
        $readmemh("kitty_faces/face6.txt", mem, 6144, 7167);   // playing
    end

    reg [23:0] c;

    // address = face x 1024 + sy x 32 + sx  (just the bits glued together)
    always @(posedge Clk) begin
        c = mem[{face, sy, sx}];
        if (c == 24'h000000)
            color <= TRANSP;                            // black = see-through
        else
            color <= {c[23:21], c[15:13], c[7:5]};      // top 3 bits of R, G, B
    end

endmodule
