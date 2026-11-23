import risc_pkg::*;
// Register between execute and memory access

module ex_mem_reg (
    input logic clk,
    input logic reset_n,

    input logic valid_in,

    // ALU input
    input logic [31:0] alu_res_in,
    input logic [31:0] rs2_data_in,
    input logic [31:0] immediate_in,
    input logic next_seq_pc_in,

    // Destination register info
    input logic [4:0] rd_addr_in,

    // Memory control signals
    input logic dmem_req_in,
    input mem_size_t dmem_size_in,
    input logic dmem_wr_en_in,
    input logic dmem_zero_extend_in,

    // WB control signals
    input wb_src_t rf_wr_data_sel_in,
    input logic rf_wr_en_in,

    // Output
    output logic valid_out,

    output logic [31:0] alu_res_out,
    output logic [31:0] rs2_data_out,
    output logic [31:0] immediate_out,
    output logic [31:0] next_seq_pc_out,
    output logic [4:0] rd_addr_out,

    output logic dmem_req_out,
    output mem_size_t dmem_size_out,
    output logic dmem_wr_en_out,
    output logic dmem_zero_extend_out,

    output wb_src_t rf_wr_data_sel_out,
    output logic rf_wr_en_out
);

    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            valid_out <= 1'b0;

            alu_res_out <= 32'b0;
            rs2_data_out <= 32'b0;

            immediate_out <= 32'b0;
            next_seq_pc_out <= 32'b0;
            rd_addr_out <= 5'b0;

            dmem_req_out <= 1'b0;
            dmem_size_out <= BYTE;
            dmem_wr_en_out <= 1'b0;
            dmem_zero_extend_out <= 1'b0;

            rf_wr_data_sel_out <= WB_SRC_ALU;
            rf_wr_en_out <= 1'b0;
        end else begin
            valid_out <= valid_in;

            alu_res_out <= alu_res_in;
            rs2_data_out <= rs2_data_in;

            immediate_out <= immediate_in;
            next_seq_pc_out <= next_seq_pc_in;
            rd_addr_out <= rd_addr_in;

            dmem_req_out <= dmem_req_in;
            dmem_size_out <= dmem_size_in;
            dmem_wr_en_out <= dmem_wr_en_in;
            dmem_zero_extend_out <= dmem_zero_extend_in;

            rf_wr_data_sel_out <= rf_wr_data_sel_in;
            rf_wr_en_out <= rf_wr_en_in;
        end
    end


endmodule
