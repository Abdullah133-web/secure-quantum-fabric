// secure_fabric_core.v
// Crypto-Agile Multi-Cycle Core with Hardware-Accelerated Transformations

module secure_fabric_core (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [31:0] cpu_data_in,
    input  wire        cpu_valid,
    input  wire [31:0] key_in,
    input  wire [3:0]  runtime_rounds,
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

    // --- Sub-module Interconnection Wiring ---
    wire [127:0] state_matrix_in;
    wire [127:0] shifted_state;
    wire [127:0] mixed_state;
    wire [1407:0] all_round_keys;
    wire [127:0] current_round_key;

    // Pack individual 32-bit registers into a single 128-bit AES block
    assign state_matrix_in = {block_reg_0, block_reg_1, block_reg_2, block_reg_3};

    // Instantiate your new key expansion scheduling block
    // Expands your key_in (padded to 128-bit) into all round sub-keys
    key_expansion ke_inst (
        .master_key({4{key_in}}),
        .round_keys(all_round_keys)
    );

    // Dynamic round key slice selection based on current round_counter
    assign current_round_key = all_round_keys[(round_counter * 128) +: 128];

    // Instantiate your hardware-accelerated state transformations
    shift_rows sr_inst (
        .state_in(state_matrix_in), 
        .state_out(shifted_state)
    );
    
    mix_columns mc_inst (
        .state_in(shifted_state), 
        .state_out(mixed_state)
    );

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
                
                // Perform hardware transformation round mixed with the round key schedule
                if (round_counter < (runtime_rounds - 1'b1)) begin
                    // Standard processing round: ShiftRows -> MixColumns -> AddRoundKey
                    block_reg_0 <= mixed_state[127:96] ^ current_round_key[127:96];
                    block_reg_1 <= mixed_state[95:64]  ^ current_round_key[95:64];
                    block_reg_2 <= mixed_state[63:32]  ^ current_round_key[63:32];
                    block_reg_3 <= mixed_state[31:0]   ^ current_round_key[31:0];
                end else begin
                    // Final round: Omits MixColumns layer entirely per crypto specification
                    block_reg_0 <= shifted_state[127:96] ^ current_round_key[127:96];
                    block_reg_1 <= shifted_state[95:64]  ^ current_round_key[95:64];
                    block_reg_2 <= shifted_state[63:32]  ^ current_round_key[63:32];
                    block_reg_3 <= shifted_state[31:0]   ^ current_round_key[31:0];
                end
            end 
            else if (current_state == STATE_IDLE) begin
                load_counter  <= 2'b00;
                round_counter <= 4'd0;
            end
        end
    end

    // Combinational Next-State Logic Layer
    always @(*) begin
        next_state    = current_state;
        mem_data_out = 32'h0;
        mem_valid    = 1'b0;
        
        case (current_state)
            STATE_IDLE: begin
                if (cpu_valid) next_state = STATE_LOAD;
            end
            STATE_LOAD: begin
                if (load_counter == 2'b11 && cpu_valid) next_state = STATE_PROCESS;
            end
            STATE_PROCESS: begin
                if (round_counter == (runtime_rounds - 1'b1)) begin
                    next_state = STATE_DONE;
                end
            end
            STATE_DONE: begin
                // Format the final scrambled block reduction layer
                mem_data_out = (block_reg_0 ^ block_reg_1 ^ block_reg_2 ^ block_reg_3);
                mem_valid    = 1'b1;
                next_state   = STATE_IDLE;
            end
            default: next_state = STATE_IDLE;
        endcase
    end

endmodule
