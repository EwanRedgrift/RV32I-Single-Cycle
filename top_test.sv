import risc_pkg::*;

// Five-stage pipelined RV32I processor top-level.
//
// Pipeline stages:
//   IF  -> IF/ID -> ID -> ID/EX -> EX -> EX/MEM -> MEM -> MEM/WB -> WB
//
// This is the basic pipeline integration only. Hazard detection, forwarding,
// stalls, and flushes are intentionally not implemented yet.

module top #(
    parameter RESET_PC = 32'h0000
)(
    input logic clk,
    input logic reset_n
);

    // ---------------------------------------------------------------------
    // IF: Instruction Fetch
    // ---------------------------------------------------------------------
    logic [31:0] pc;
    logic [31:0] next_seq_pc;
    logic [31:0] next_pc;
    logic reset_seen;

    logic imem_req;
    logic [31:0] imem_addr;
    logic [31:0] imem_data;
    logic [31:0] fetched_instruction;

    instruction_memory u_instruction_memory (
        .imem_req(imem_req),
        .imem_addr(imem_addr),
        .imem_data(imem_data)
    );

    fetch u_fetch (
        .clk(clk),
        .reset_n(reset_n),
        .pc(pc),
        .imem_req(imem_req),
        .imem_addr(imem_addr),
        .imem_data(imem_data),
        .instruction(fetched_instruction)
    );

    assign next_seq_pc = pc + 32'd4;

    // The branch/jump decision is made in EX. The target is the EX ALU result.
    // JALR and branch/jump targets are aligned by clearing bit zero.
    logic ex_pc_redirect;
    logic [31:0] ex_alu_result;
    assign next_pc = ex_pc_redirect ? {ex_alu_result[31:1], 1'b0} : next_seq_pc;

    // Preserve the original startup behavior: hold RESET_PC for the first
    // active clock edge while the fetch request becomes valid.
    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n)
            reset_seen <= 1'b0;
        else
            reset_seen <= 1'b1;
    end

    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n)
            pc <= RESET_PC;
        else if (reset_seen)
            pc <= next_pc;
    end

    // ---------------------------------------------------------------------
    // IF/ID: Fetch/Decode pipeline register
    // ---------------------------------------------------------------------
    logic        ifid_valid;
    logic [31:0] ifid_pc;
    logic [31:0] ifid_instruction;

    if_id u_if_id (
        .clk(clk),
        .reset_n(reset_n),
        .pc_in(pc),
        .instruction_in(fetched_instruction),
        .valid_out(ifid_valid),
        .pc_out(ifid_pc),
        .instruction_out(ifid_instruction)
    );

    // ---------------------------------------------------------------------
    // ID: Instruction Decode, Register Read, and Control Generation
    // ---------------------------------------------------------------------
    logic [6:0] id_opcode;
    logic [2:0] id_funct3;
    logic [6:0] id_funct7;
    logic [4:0] id_rs1_addr;
    logic [4:0] id_rs2_addr;
    logic [4:0] id_rd_addr;
    logic [31:0] id_immediate;

    logic id_r_type;
    logic id_i_type;
    logic id_s_type;
    logic id_b_type;
    logic id_u_type;
    logic id_j_type;

    logic [31:0] id_rs1_data;
    logic [31:0] id_rs2_data;

    logic id_pc_sel;
    logic id_op1_sel;
    logic id_op2_sel;
    alu_op_t id_alu_op;
    wb_src_t id_rf_wr_data_sel;
    logic id_dmem_req;
    mem_size_t id_dmem_size;
    logic id_dmem_wr_en;
    logic id_dmem_zero_extend;
    logic id_rf_wr_en;

    decode u_decode (
        .instruction(ifid_instruction),
        .rs1_addr(id_rs1_addr),
        .rs2_addr(id_rs2_addr),
        .rd_addr(id_rd_addr),
        .opcode(id_opcode),
        .funct3(id_funct3),
        .funct7(id_funct7),
        .r_type(id_r_type),
        .i_type(id_i_type),
        .s_type(id_s_type),
        .b_type(id_b_type),
        .u_type(id_u_type),
        .j_type(id_j_type),
        .immediate(id_immediate)
    );

    control u_control (
        .r_type(id_r_type),
        .i_type(id_i_type),
        .s_type(id_s_type),
        .b_type(id_b_type),
        .u_type(id_u_type),
        .j_type(id_j_type),
        .funct3(id_funct3),
        .funct7(id_funct7),
        .opcode(id_opcode),
        .pc_sel(id_pc_sel),
        .op1_sel(id_op1_sel),
        .op2_sel(id_op2_sel),
        .alu_op(id_alu_op),
        .rf_wr_data_sel(id_rf_wr_data_sel),
        .dmem_req(id_dmem_req),
        .dmem_size(id_dmem_size),
        .dmem_wr_en(id_dmem_wr_en),
        .dmem_zero_extend(id_dmem_zero_extend),
        .rf_wr_en(id_rf_wr_en)
    );

    // Writeback signals are declared here because the register file is read
    // in ID but written in WB.
    logic        memwb_valid;
    logic [31:0] memwb_mem_read_data;
    logic [31:0] memwb_alu_result;
    logic [31:0] memwb_immediate;
    logic [31:0] memwb_pc_plus4;
    logic [4:0]  memwb_rd_addr;
    wb_src_t     memwb_rf_wr_data_sel;
    logic        memwb_rf_wr_en;
    logic [31:0] wb_wr_data;
    logic        wb_rf_wr_en;

    // Writeback selection uses values carried through MEM/WB.
    always_comb begin
        case (memwb_rf_wr_data_sel)
            WB_SRC_ALU: wb_wr_data = memwb_alu_result;
            WB_SRC_MEM: wb_wr_data = memwb_mem_read_data;
            WB_SRC_IMM: wb_wr_data = memwb_immediate;
            WB_SRC_PC:  wb_wr_data = memwb_pc_plus4;
            default:    wb_wr_data = 32'b0;
        endcase
    end

    // A bubble/invalid pipeline slot must never modify architectural state.
    assign wb_rf_wr_en = memwb_valid && memwb_rf_wr_en;

    register_file u_register_file (
        .clk(clk),
        .reset_n(reset_n),
        .rs1_addr(id_rs1_addr),
        .rs2_addr(id_rs2_addr),
        .rd_addr(memwb_rd_addr),
        .rf_wr_en(wb_rf_wr_en),
        .wr_data(wb_wr_data),
        .rs1_data(id_rs1_data),
        .rs2_data(id_rs2_data)
    );

    // ---------------------------------------------------------------------
    // ID/EX: Decode/Execute pipeline register
    // ---------------------------------------------------------------------
    logic        idex_valid;
    logic [31:0] idex_pc;
    logic [4:0]  idex_rs1_addr;
    logic [4:0]  idex_rs2_addr;
    logic [4:0]  idex_rd_addr;
    logic [2:0]  idex_funct3;
    logic        idex_b_type;
    logic [31:0] idex_rs1_data;
    logic [31:0] idex_rs2_data;
    logic [31:0] idex_immediate;
    logic        idex_pc_sel;
    logic        idex_op1_sel;
    logic        idex_op2_sel;
    alu_op_t     idex_alu_op;
    wb_src_t     idex_rf_wr_data_sel;
    logic        idex_dmem_req;
    mem_size_t   idex_dmem_size;
    logic        idex_dmem_wr_en;
    logic        idex_dmem_zero_extend;
    logic        idex_rf_wr_en;

    id_ex u_id_ex (
        .clk(clk),
        .reset_n(reset_n),
        .valid_in(ifid_valid),
        .pc_in(ifid_pc),
        .rs1_addr_in(id_rs1_addr),
        .rs2_addr_in(id_rs2_addr),
        .rd_addr_in(id_rd_addr),
        .funct3_in(id_funct3),
        .b_type_in(id_b_type),
        .rs1_data_in(id_rs1_data),
        .rs2_data_in(id_rs2_data),
        .immediate_in(id_immediate),
        .pc_sel_in(id_pc_sel),
        .op1_sel_in(id_op1_sel),
        .op2_sel_in(id_op2_sel),
        .alu_op_in(id_alu_op),
        .rf_wr_data_sel_in(id_rf_wr_data_sel),
        .dmem_req_in(id_dmem_req),
        .dmem_size_in(id_dmem_size),
        .dmem_wr_en_in(id_dmem_wr_en),
        .dmem_zero_extend_in(id_dmem_zero_extend),
        .rf_wr_en_in(id_rf_wr_en),
        .valid_out(idex_valid),
        .pc_out(idex_pc),
        .rs1_addr_out(idex_rs1_addr),
        .rs2_addr_out(idex_rs2_addr),
        .rd_addr_out(idex_rd_addr),
        .funct3_out(idex_funct3),
        .b_type_out(idex_b_type),
        .rs1_data_out(idex_rs1_data),
        .rs2_data_out(idex_rs2_data),
        .immediate_out(idex_immediate),
        .pc_sel_out(idex_pc_sel),
        .op1_sel_out(idex_op1_sel),
        .op2_sel_out(idex_op2_sel),
        .alu_op_out(idex_alu_op),
        .rf_wr_data_sel_out(idex_rf_wr_data_sel),
        .dmem_req_out(idex_dmem_req),
        .dmem_size_out(idex_dmem_size),
        .dmem_wr_en_out(idex_dmem_wr_en),
        .dmem_zero_extend_out(idex_dmem_zero_extend),
        .rf_wr_en_out(idex_rf_wr_en)
    );

    // ---------------------------------------------------------------------
    // EX: Execute, Address Generation, and Branch Comparison
    // ---------------------------------------------------------------------
    logic [31:0] ex_alu_a;
    logic [31:0] ex_alu_b;
    logic        ex_branch_taken;

    assign ex_alu_a = idex_op1_sel ? idex_pc : idex_rs1_data;
    assign ex_alu_b = idex_op2_sel ? idex_immediate : idex_rs2_data;

    alu u_alu (
        .alu_a(ex_alu_a),
        .alu_b(ex_alu_b),
        .alu_op(idex_alu_op),
        .alu_res(ex_alu_result)
    );

    branch_control u_branch_control (
        .opr_a(idex_rs1_data),
        .opr_b(idex_rs2_data),
        .is_b_type(idex_b_type && idex_valid),
        .funct3(idex_funct3),
        .branch_taken(ex_branch_taken)
    );

    assign ex_pc_redirect = idex_valid && (idex_pc_sel || ex_branch_taken);

    // ---------------------------------------------------------------------
    // EX/MEM: Execute/Memory pipeline register
    // ---------------------------------------------------------------------
    logic        exmem_valid;
    logic [31:0] exmem_alu_result;
    logic [31:0] exmem_rs2_data;
    logic [31:0] exmem_immediate;
    logic [31:0] exmem_pc_plus4;
    logic [4:0]  exmem_rd_addr;
    logic        exmem_dmem_req;
    mem_size_t   exmem_dmem_size;
    logic        exmem_dmem_wr_en;
    logic        exmem_dmem_zero_extend;
    wb_src_t     exmem_rf_wr_data_sel;
    logic        exmem_rf_wr_en;

    ex_mem u_ex_mem (
        .clk(clk),
        .reset_n(reset_n),
        .valid_in(idex_valid),
        .alu_result_in(ex_alu_result),
        .rs2_data_in(idex_rs2_data),
        .immediate_in(idex_immediate),
        .pc_plus4_in(idex_pc + 32'd4),
        .rd_addr_in(idex_rd_addr),
        .dmem_req_in(idex_dmem_req),
        .dmem_size_in(idex_dmem_size),
        .dmem_wr_en_in(idex_dmem_wr_en),
        .dmem_zero_extend_in(idex_dmem_zero_extend),
        .rf_wr_data_sel_in(idex_rf_wr_data_sel),
        .rf_wr_en_in(idex_rf_wr_en),
        .valid_out(exmem_valid),
        .alu_result_out(exmem_alu_result),
        .rs2_data_out(exmem_rs2_data),
        .immediate_out(exmem_immediate),
        .pc_plus4_out(exmem_pc_plus4),
        .rd_addr_out(exmem_rd_addr),
        .dmem_req_out(exmem_dmem_req),
        .dmem_size_out(exmem_dmem_size),
        .dmem_wr_en_out(exmem_dmem_wr_en),
        .dmem_zero_extend_out(exmem_dmem_zero_extend),
        .rf_wr_data_sel_out(exmem_rf_wr_data_sel),
        .rf_wr_en_out(exmem_rf_wr_en)
    );

    // ---------------------------------------------------------------------
    // MEM: Data Memory Access
    // ---------------------------------------------------------------------
    logic        dmem_req;
    logic [31:0] dmem_rd_data;

    // Only a valid instruction may access memory. In particular, this
    // prevents an invalid slot from accidentally performing a store.
    assign dmem_req = exmem_valid && exmem_dmem_req;

    data_memory u_data_memory (
        .clk(clk),
        .dmem_req(dmem_req),
        .dmem_wr_en(exmem_dmem_wr_en),
        .dmem_data_size(exmem_dmem_size),
        .dmem_addr(exmem_alu_result),
        .dmem_wr_data(exmem_rs2_data),
        .dmem_zero_extend(exmem_dmem_zero_extend),
        .dmem_rd_data(dmem_rd_data)
    );

    // ---------------------------------------------------------------------
    // MEM/WB: Memory/Writeback pipeline register
    // ---------------------------------------------------------------------
    mem_wb u_mem_wb (
        .clk(clk),
        .reset_n(reset_n),
        .valid_in(exmem_valid),
        .mem_read_data_in(dmem_rd_data),
        .alu_result_in(exmem_alu_result),
        .immediate_in(exmem_immediate),
        .pc_plus4_in(exmem_pc_plus4),
        .rd_addr_in(exmem_rd_addr),
        .rf_wr_data_sel_in(exmem_rf_wr_data_sel),
        .rf_wr_en_in(exmem_rf_wr_en),
        .valid_out(memwb_valid),
        .mem_read_data_out(memwb_mem_read_data),
        .alu_result_out(memwb_alu_result),
        .immediate_out(memwb_immediate),
        .pc_plus4_out(memwb_pc_plus4),
        .rd_addr_out(memwb_rd_addr),
        .rf_wr_data_sel_out(memwb_rf_wr_data_sel),
        .rf_wr_en_out(memwb_rf_wr_en)
    );

endmodule
