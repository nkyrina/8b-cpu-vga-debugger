//Write-back Mux for CPU

//Selects the value written to the register file, based on the instruction.

module wb_mux(wb_sel, alu_result, imm8, ram_data, sw_in, wr_data);
    input [1:0] wb_sel;
    input [7:0] alu_result, imm8, ram_data, sw_in;
    output reg [7:0] wr_data;

    always @(*) begin
        case (wb_sel)
            2'd0: wr_data = alu_result;
            2'd1: wr_data = imm8;
            2'd2: wr_data = ram_data;
            2'd3: wr_data = sw_in;
            default: wr_data = 8'b0;
        endcase
    end

endmodule