// Register between instruction fetch and instruction decode

module if_id_reg (
    input logic clk,
    input logic reset_n
    
    input logic [31:0] pc_in, // Program counter
    input logic [31:0] instruction_in, // Fetched instruction

    output logic valid_out,
    output logic [31:0] pc_out,
    output logic [31:0] instruction_out
);

    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            valid_out <= 1'b0;
            pc_out <= 32'b0;
            instruction_out <= 32'b0;
        end else begin
            valid_out <= 1'b1;
            pc_out <= pc_in;
            instruction_out <= instruction_in;
        end
    end

endmodule
