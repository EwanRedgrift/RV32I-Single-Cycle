module fetch (
    input logic clk,
    input logic reset_n,

    input logic [31:0] pc, // Program counter input

    output logic imem_req,
    output logic [31:0] imem_addr,

    input logic [31:0] imem_data,
    output logic [31:0] instruction // Decoded instruction
);

    logic req_reg;

    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            req_reg <= 1'b0;
        end else begin
            req_reg <= 1'b1; // Start instruction fetch after reset
        end
    end

    assign imem_req = req_reg;
    assign imem_addr = pc;
    assign instruction = imem_data;

endmodule
