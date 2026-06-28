// secure_fabric_top.v
// Fully deterministic FSM with arithmetic modular mixing layers

module secure_fabric_top (
    input  wire        clk,           // Master System Clock
    input  wire        rst_n,         // Active-Low Reset
    
    // Processor Interface (Data In)
    input  wire [31:0] cpu_data_in,
    input  wire        cpu_valid,
    
    // Memory Interface (Data Out)
    output reg  [31:0] mem_data_out,
    output reg         mem_valid
);

    // FSM State Encoding
    localparam STATE_IDLE    = 2'b00;
    localparam STATE_LOAD    = 2'b01;
    localparam STATE_PROCESS = 2'b10;
    localparam STATE_DONE    = 2'b11;

    reg [1:0] current_state;
    reg [1:0] next_state;

    // 128-bit internal block buffer split into four 32-bit chunks
    reg [31:0] block_reg_0;
    reg [31:0] block_reg_1;
    reg [31:0] block_reg_2;
    reg [31:0] block_reg_3;
    
    // Counter to track our 4 loading cycles
    reg [1:0]  load_counter;

    // 1. FSM & Data Buffering Register Stage (Sequential)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= STATE_IDLE;
            load_counter  <= 2'b00;
            block_reg_0   <= 32'h0;
            block_reg_1   <= 32'h0;
            block_reg_2   <= 32'h0;
            block_reg_3   <= 32'h0;
        end else begin
            current_state <= next_state;
            
            // Multi-cycle loading buffer mechanism
            if (current_state == STATE_LOAD && cpu_valid) begin
                load_counter <= load_counter + 1'b1;
                case (load_counter)
                    2'b00: block_reg_0 <= cpu_data_in;
                    2'b01: block_reg_1 <= cpu_data_in;
                    2'b10: block_reg_2 <= cpu_data_in;
                    2'b11: block_reg_3 <= cpu_data_in;
                endcase
            end else if (current_state == STATE_PROCESS) begin
                // Parallel modular addition stage using independent targets
                block_reg_0 <= block_reg_0 + block_reg_1;
                block_reg_1 <= block_reg_1 + block_reg_2;
                block_reg_2 <= block_reg_2 + block_reg_3;
                block_reg_3 <= block_reg_3 + 32'h5A5A5A5A; // Stable injection parameter to break linear symmetry safely
            end else if (current_state == STATE_IDLE) begin
                load_counter <= 2'b00; // Reset counter when sitting idle
            end
        end
    end

    // 2. Next State Logic (Combinational)
    always @(*) begin
        next_state   = current_state;
        mem_data_out = 32'h0;
        mem_valid    = 1'b0;

        case (current_state)
            STATE_IDLE: begin
                if (cpu_valid) begin
                    next_state = STATE_LOAD;
                end
            end
            
            STATE_LOAD: begin
                // Only move to process once all 4 chunks (128-bits total) are buffered
                if (load_counter == 2'b11 && cpu_valid) begin
                    next_state = STATE_PROCESS;
                end
            end
            
            STATE_PROCESS: begin
                next_state = STATE_DONE;
            end
            
            STATE_DONE: begin
                // Output combined state result layer
                mem_data_out = block_reg_0 ^ block_reg_1 ^ block_reg_2 ^ block_reg_3;
                mem_valid    = 1'b1;
                next_state   = STATE_IDLE;
            end
            
            default: begin
                next_state = STATE_IDLE;
            end
        endcase
    end

endmodule
