import risc_pkg::*;
// Register between instruction decode and execute

module id_ex_reg (
    input logic clk,
    input logic reset_n,

    // Instruction info
    input logic valid_in,
    input logic [31:0] pc_in,
    input logic [4:0] rs1_addr_in,
    input logic [4:0] rs2_addr_in,
    input logic [4:0] rd_addr_in,
    input logic [2:0] funct3_in,
    input logic b_type_in,

    // Operand values
    input logic [31:0] rs1_data_in,
    input logic [31:0] rs2_data_in,
    input logic [31:0] immediate_in,

    // Control signals
    input logic pc_sel_in,
    input logic op1_sel_in,
    input logic op2_sel_in,
    input alu_op_t alu_op_in,
    input wb_src_t rf_wr_data_sel_in,
    input logic dmem_req_in,
    input mem_size_t dmem_size_in,
    input logic dmem_wr_en_in,
    input logic dmem_zero_extend_in,
    input logic rf_wr_en_in,

    // Outputs
    output logic valid_out,
    output logic [31:0] pc_out,
    output logic [4:0] rs1_addr_out,
    output logic [4:0] rs2_addr_out,
    output logic [4:0] rd_addr_out,
    output logic [2:0] funct3_out,
    output logic b_type_out,

    output logic [31:0] rs1_data_out,
    output logic [31:0] rs2_data_out,
    output logic [31:0] immediate_out,

    output logic pc_sel_out,
    output logic op1_sel_out,
    output logic op2_sel_out,
    output alu_op_t alu_op_out,
    output wb_src_t rf_wr_data_sel_out,
    output logic dmem_req_out,
    output mem_size_t dmem_size_out,
    output logic dmem_wr_en_out,
    output logic dmem_zero_extend_out,
    output logic rf_wr_en_out
);

    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            valid_out <= 1'b0;

            pc_out <= 32'b0;
            rs1_addr_out <= 5'b0;
            rs2_addr_out <= 5'b0;
            rd_addr_out <= 5'b0;
            funct3_out <= 3'b0;
            b_type_out <= 1'b0;


            rs1_data_out <= 32'b0;
            rs2_data_out <= 32'b0;
            immediate_out <= 32'b0;

            pc_sel_out <= 1'b0;
            op1_sel_out <= 1'b0;
            op2_sel_out <= 1'b0;
            alu_op_out <= ADD; // Default
            rf_wr_data_sel_out <= WB_SRC_ALU;
            dmem_req_out <= 1'b0;
            dmem_size_out <= BYTE;
            dmem_wr_en_out <= 1'b0;
            dmem_zero_extend_out <= 1'b0;
            rf_wr_en_out <= 1'b0;
        end else begin
            valid_out <= valid_in;

            pc_out <= pc_in;
            rs1_addr_out <= rs1_addr_in;
            rs2_addr_out <= rs2_addr_in;
            rd_addr_out <= rd_addr_in;
            funct3_out <= funct3_in;
            b_type_out <= b_type_in;


            rs1_data_out <= rs1_data_in;
            rs2_data_out <= rs2_data_in;
            immediate_out <= immediate_in;

            pc_sel_out <= pc_sel_in;
            op1_sel_out <= op1_sel_in;
            op2_sel_out <= op2_sel_in;
            alu_op_out <= alu_op_in;
            rf_wr_data_sel_out <= rf_wr_data_sel_in;
            dmem_req_out <= dmem_req_in;
            dmem_size_out <= dmem_size_in;
            dmem_wr_en_out <= dmem_wr_en_in;
            dmem_zero_extend_out <= dmem_zero_extend_in;
            rf_wr_en_out <= rf_wr_en_in;
        end
    end

endmodule
