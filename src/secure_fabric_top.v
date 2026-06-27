// secure_fabric_top.v
// Core control and data-path skeleton with FSM synchronization

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

    // Internal registers
    reg [31:0] lattice_noise;

    // 1. FSM State Register (Sequential)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= STATE_IDLE;
            lattice_noise <= 32'h0;
        end else begin
            current_state <= next_state;
            if (current_state == STATE_PROCESS) begin
                lattice_noise <= lattice_noise ^ cpu_data_in; // Injection cycle
            end
        end
    end

    // 2. Next State Logic & Outputs (Combinational)
    always @(*) begin
        // Defaults
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
                next_state = STATE_PROCESS;
            end
            
            STATE_PROCESS: begin
                next_state = STATE_DONE;
            end
            
            STATE_DONE: begin
                mem_data_out = lattice_noise;
                mem_valid    = 1'b1;
                next_state   = STATE_IDLE;
            end
            
            default: begin
                next_state = STATE_IDLE;
            end
        endcase
    end

endmodule
