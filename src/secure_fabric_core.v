// secure_fabric_core.v
// Crypto-Agile Multi-Cycle Core with Programmable Round Scalability

module secure_fabric_core (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [31:0] cpu_data_in,
    input  wire        cpu_valid,
    input  wire [31:0] key_in,
    input  wire [3:0]  runtime_rounds, // New input from bus configuration
    output reg  [31:0] mem_data_out,
    output reg         mem_valid
);

    // Architectural State Definitions
    localparam STATE_IDLE    = 2'b00;
    localparam STATE_LOAD    = 2'b01;
    localparam STATE_PROCESS = 2'b10;
    localparam STATE_DONE    = 2'b11;

    reg [1:0]  current_state;
    reg [1:0]  next_state;
    reg [31:0] block_reg_0, block_reg_1, block_reg_2, block_reg_3;
    reg [1:0]  load_counter;
    reg [3:0]  round_counter;

    // Non-linear Substitution Box (S-Box) Transformation Function
    function [7:0] sbox_transform (input [7:0] byte_in);
        case (byte_in)
            8'h00: sbox_transform = 8'h63; 8'h01: sbox_transform = 8'h7c;
            8'h02: sbox_transform = 8'h77; 8'h03: sbox_transform = 8'h7b;
            8'h04: sbox_transform = 8'hf2; 8'h05: sbox_transform = 8'h6b;
            8'h06: sbox_transform = 8'h6f; 8'h07: sbox_transform = 8'hc5;
            default: sbox_transform = byte_in ^ 8'h99; 
        endcase
    endfunction

    // Sequential Logic Layer
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= STATE_IDLE;
            load_counter  <= 2'b00;
            round_counter <= 4'd0;
            block_reg_0   <= 32'h0;
            block_reg_1   <= 32'h0;
            block_reg_2   <= 32'h0;
            block_reg_3   <= 32'h0;
        end else begin
            current_state <= next_state;
            
            if (current_state == STATE_LOAD && cpu_valid) begin
                load_counter <= load_counter + 1'b1;
                case (load_counter)
                    2'b00: block_reg_0 <= cpu_data_in;
                    2'b01: block_reg_1 <= cpu_data_in;
                    2'b10: block_reg_2 <= cpu_data_in;
                    2'b11: block_reg_3 <= cpu_data_in;
                endcase
            end 
            else if (current_state == STATE_PROCESS) begin
                round_counter <= round_counter + 1'b1;
                
                block_reg_0 <= block_reg_0 + block_reg_1;
                block_reg_1 <= block_reg_1 + block_reg_2;
                block_reg_2 <= block_reg_2 + block_reg_3;
                block_reg_3 <= block_reg_3 + 32'h5A5A5A5A;
                
                block_reg_0[31:24] <= sbox_transform(block_reg_0[31:24]);
                block_reg_1[31:24] <= sbox_transform(block_reg_1[31:24]);
                block_reg_2[31:24] <= sbox_transform(block_reg_2[31:24]);
                block_reg_3[31:24] <= sbox_transform(block_reg_3[31:24]);
            end 
            else if (current_state == STATE_IDLE) begin
                load_counter  <= 2'b00;
                round_counter <= 4'd0;
                