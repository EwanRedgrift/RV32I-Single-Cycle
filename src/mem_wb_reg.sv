import risc_pkg::*;

// Between the memory access and writeback stages

module mem_wb_reg (
    input logic clk,
    input logic reset_n,

    input logic valid_in,

    // Values produced or retained by the memory stage
    input logic [31:0] dmem_rd_data_in,
    input logic [31:0] alu_res_in,
    input logic [31:0] immediate_in,
    input logic [31:0] next_seq_pc_in,

    // Destination register and writeback controls
    input logic [4:0] rd_addr_in,
    input wb_src_t rf_wr_data_sel_in,
    input logic rf_wr_en_in,

    // Outputs
    output logic valid_out,

    output logic [31:0] dmem_rd_data_out,
    output logic [31:0] alu_res_out,
    output logic [31:0] immediate_out,
    output logic [31:0] next_seq_pc_out,

    output logic [4:0] rd_addr_out,
    output wb_src_t rf_wr_data_sel_out,
    output logic rf_wr_en_out
);

    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            valid_out <= 1'b0;

            dmem_rd_data_out <= 32'b0;
            alu_res_out <= 32'b0;
            immediate_out <= 32'b0;
            next_seq_pc_out <= 32'b0;

            rd_addr_out <= 5'b0;
            rf_wr_data_sel_out <= WB_SRC_ALU;
            rf_wr_en_out <= 1'b0;
        end else begin
            valid_out <= valid_in;

            dmem_rd_data_out <= dmem_rd_data_in;
            alu_res_out <= alu_res_in;
            immediate_out <= immediate_in;
            next_seq_pc_out <= next_seq_pc_in;

            rd_addr_out <= rd_addr_in;
            rf_wr_data_sel_out <= rf_wr_data_sel_in;
            rf_wr_en_out <= rf_wr_en_in;
        end
    end

endmodule
