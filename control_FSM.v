// Control FSM
// Control unit for 8 bit CPU

// 4 States:
// ============================
//   FETCH   (0): IR <= ROM[PC], PC <= PC + 1
//   DECODE  (1): nothing is written; register file outputs settle
//   EXECUTE (2): branches/jumps load the PC
//   WRITE   (3): results go to the register file, RAM, zero flag or LEDs
// ============================

// The FSM only moves forward when En = 1 (step pulse from Step Control)
// All outputs are combinational (they depend on state and opcode).
// every module recieving these signals are gated by En, so nothing happens if we pause the CPU.

module control_fsm (
    input  wire       Clk,        // Clock
    input  wire       Reset,      // active high, synchronous Reset
    input  wire       En,         // one-cycle step pulse from Step Control
    input  wire [3:0] opcode,     // ir[15:12]
    input  wire       zero_flag,  // stored zero flag (from the datapath)

    output reg  [1:0] state,      // to the VGA debugger
 
    output reg        ir_load,    // IR <= ROM[pc]
    output reg        pc_inc,     // PC <= PC + 1
    output reg        pc_load,    // PC <= addr5
    output reg        wr_en,      // register file write enable
    output reg  [1:0] wb_sel,     // write-back mux select (see below)
    output reg  [2:0] alu_op,     // ALU operation
    output reg        zero_load,  // zero flag <= ALU zero
    output reg        ram_wr_en,  // RAM[r_a] <= r_b
    output reg        out_load    // LED register <= r_a
);

    // States
    localparam S_FETCH   = 2'd0, // 1
               S_DECODE  = 2'd1, // 2
               S_EXECUTE = 2'd2, // 3
               S_WRITE   = 2'd3; // 4

    // OpCodes
    // assign names to all opcodes (see README)
    localparam OP_NOP = 4'd0, 
               OP_ADD = 4'd1,
               OP_SUB = 4'd2,
               OP_AND = 4'd3,
               OP_OR  = 4'd4,
               OP_XOR = 4'd5,
               OP_SHL = 4'd6,
               OP_SHR = 4'd7,
               OP_LDI = 4'd8,
               OP_LD  = 4'd9,
               OP_ST  = 4'd10,
               OP_JMP = 4'd11,
               OP_BZ  = 4'd12,
               OP_BNZ = 4'd13,
               OP_IN  = 4'd14,
               OP_OUT = 4'd15;

    // Writeback Mux Select
    // This is a mux that selects what result to be saved to register.
    localparam WB_ALU = 2'd0,   // ALU result
               WB_IMM = 2'd1,   // ir[7:0]
               WB_RAM = 2'd2,   // RAM[r_a]
               WB_SW  = 2'd3;   // SW[7:0]

    // State Register
    // FSM Memory
    reg [1:0] next_state;

    always @(posedge Clk) begin
        if (Reset)
            state <= S_FETCH; // Go to Fetch when Reset is on
        else if (En)
            state <= next_state; // Move to next state if Reset is off
    end
    // Next state logic
    // Combinational; not clocked.
    always @(*) begin
        // moves states in circle (see README)
        case (state)
            S_FETCH:   next_state = S_DECODE; 
            S_DECODE:  next_state = S_EXECUTE;
            S_EXECUTE: next_state = S_WRITE;
            S_WRITE:   next_state = S_FETCH;
            default:   next_state = S_FETCH;    
        endcase
    end

    // ALU instructions are opcodes 1 to 7
    wire is_alu = (opcode >= OP_ADD) && (opcode <= OP_SHR);

    // Output logic
    always @(*) begin
        // defaults: do nothing
        ir_load   = 1'b0;
        pc_inc    = 1'b0;
        pc_load   = 1'b0;
        wr_en     = 1'b0;
        wb_sel    = WB_ALU;
        alu_op    = opcode[2:0] - 3'd1;  // ADD(1) -> 0, ..., SHR(7) -> 6
        zero_load = 1'b0;
        ram_wr_en = 1'b0;
        out_load  = 1'b0;

    case (state)
            S_FETCH: begin
                ir_load = 1'b1;
                pc_inc  = 1'b1;
            end

            S_DECODE: begin
                // nothing written; lets the debugger show the new IR
            end

            S_EXECUTE: begin
                case (opcode)
                    // JUMP: Always sets pc_Load
                    OP_JMP: pc_load = 1'b1; 
                    // BZ: Jumps only if zero_flag was true (Previous was 0.)
                    OP_BZ:  pc_load = zero_flag;
                    // BNZ: Jumps only if zero_flag was NOT true (previous was not 0.)
                    OP_BNZ: pc_load = ~zero_flag;
                    default: ;
                endcase
            end

            S_WRITE: begin
                // Save ALU answer to register and update zero flag.
                if (is_alu) begin // op codes 1-7
                    wr_en     = 1'b1;
                    wb_sel    = WB_ALU;
                    zero_load = 1'b1;
                end
                else begin
                    case (opcode)
                        // OP_LDI/LD/IN: Updates register using wb_sel as selector for source
                        OP_LDI: begin wr_en = 1'b1; wb_sel = WB_IMM; end
                        OP_LD:  begin wr_en = 1'b1; wb_sel = WB_RAM; end
                        OP_IN:  begin wr_en = 1'b1; wb_sel = WB_SW;  end 
                        OP_ST:  ram_wr_en = 1'b1; // Saves to RAM
                        OP_OUT: out_load  = 1'b1; // Updates the LEDs
                        default: ;  // NOP, JMP, BZ, BNZ: Everything else does nothing.
                    endcase
                end
            end
        endcase
    end

endmodule

