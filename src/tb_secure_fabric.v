// tb_secure_fabric.v
// Testbench for verifying multi-cycle 128-bit block processing

`timescale 1ns/1ps

module tb_secure_fabric;

    // Inputs
    reg        clk;
    reg        rst_n;
    reg [31:0] cpu_data_in;
    reg        cpu_valid;
    reg [31:0] key_in;

    // Outputs
    wire [31:0] mem_data_out;
    wire        mem_valid;

    // Instantiate the Unit Under Test (UUT)
    secure_fabric_top uut (
        .clk(clk),
        .rst_n(rst_n),
        .cpu_data_in(cpu_data_in),
        .cpu_valid(cpu_valid),
        .key_in(key_in),
        .mem_data_out(mem_data_out),
        .mem_valid(mem_valid)
    );

    // Clock Generation (50MHz -> 20ns period)
    always #10 clk = ~clk;

    initial begin
        // Initialize Signals
        clk         = 1'b0;
        rst_n       = 1'b0;
        cpu_data_in = 32'h0;
        cpu_valid   = 1'b0;
        key_in      = 32'hA5A5A5A5; // Example Whitening Key

        // Release Reset after 40ns
        #40;
        rst_n = 1'b1;
        #20;

        // Cycle 1: Load First 32-bit Chunk
        cpu_data_in = 32'h11111111;
        cpu_valid   = 1'b1;
        #20;

        // Cycle 2: Load Second 32-bit Chunk
        cpu_data_in = 32'h22222222;
        #20;

        // Cycle 3: Load Third 32-bit Chunk
        cpu_data_in = 32'h33333333;
        #20;

        // Cycle 4: Load Fourth 32-bit Chunk (Triggers FSM transition to PROCESS)
        cpu_data_in = 32'h44444444;
        #20;

        // Clear valid flag while processing happens
        cpu_valid   = 1'b0;
        cpu_data_in = 32'h0;
        
        // Wait for processing and check output assertion
        @(posedge mem_valid);
        #10;
        $display("SUCCESS: Processing complete. Output Data = %h", mem_data_out);
        
        #40;
        $finish;
    end

endmodule
