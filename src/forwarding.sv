module forwarding (
    input logic idex_op1_sel, // if(op1_sel) {alu_a = pc}, if(!op1_sel) {alu_a = rs1_data}
    input logic idex_op2_sel, // if(op2_sel) {alu_b = immediate}, if(!op2_sel) {alu_b = rs2_data}

    input logic exmem_rf_wr_en, // if the register is being written
    input logic memwb_rf_wr_en,

    input logic [4:0] exmem_rd_addr, // take rd_addr from ex/mem
    input logic [4:0] memwb_rd_addr, // take rd_addr from mem/wb

    input logic [4:0]  idex_rs1_addr, // rs1 address
    input logic [4:0]  idex_rs2_addr, // rs2 address

    output logic [1:0] op1_sel,
    output logic [1:0] op2_sel
);
    always_comb begin

        op1_sel = 2'b00;
        op2_sel = 2'b00;

        if (idex_op1_sel) begin
            op1_sel = 2'b01;
        end 

        // ALU a
        else if (exmem_rf_wr_en && (exmem_rd_addr != 5'd0) && (exmem_rd_addr == idex_rs1_addr)) begin
            op1_sel = 2'b11;
        end 
        
        else if (memwb_rf_wr_en && (memwb_rd_addr != 5'd0) && (memwb_rd_addr == idex_rs1_addr)) begin
             op1_sel = 2'b10;
        end

        // ALU b
        if (idex_op2_sel) begin
            op2_sel = 2'b01;
        end 

        else if (exmem_rf_wr_en && (exmem_rd_addr != 5'd0) && (exmem_rd_addr == idex_rs2_addr)) begin
            op2_sel = 2'b11;
        end 
        
        else if (memwb_rf_wr_en && (memwb_rd_addr != 5'd0) && (memwb_rd_addr == idex_rs2_addr)) begin
             op2_sel = 2'b10;
        end
        
    end

endmodule
