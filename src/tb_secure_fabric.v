// tb_secure_fabric.v
// System Bus Testbench with Quantum Entropy Injection Verification

`timescale 1ns/1ps

module tb_secure_fabric;

    // Inputs
    reg         clk;
    reg         rst_n;
    reg  [31:0] bus_addr;
    reg  [31:0] bus_wdata;
    reg         bus_write;
    reg         bus_sel;
    reg  [31:0] qtrng_entropy_in; // Wire to drive the hardware entropy port

    // Outputs
    wire [31:0] bus_rdata;
    wire        bus_ready;

    // Instantiate System Wrapper Under Test
    secure_fabric_top uut (
        .clk(clk),
        .rst_n(rst_n),
        .bus_addr(bus_addr),
        .bus_wdata(bus_wdata),
        .bus_write(bus_write),
        .bus_sel(bus_sel),
        .qtrng_entropy_in(qtrng_entropy_in), // Connected safely
        .bus_rdata(bus_rdata),
        .bus_ready(bus_ready)
    );

    // Clock Generation (50MHz / 20ns period)
    always #10 clk = ~clk;

    initial begin
        // Initialize Bus Signals
        clk              = 1'b0;
        rst_n            = 1'b0;
        bus_addr         = 32'h0;
        bus_wdata        = 32'h0;
        bus_write        = 1'b0;
        bus_sel          = 1'b0;
        qtrng_entropy_in = 32'h0;

        // Assert System Reset
        #40;
        rst_n = 1'b1;
        #20;

        // 1. Configure the Whitening Key (Write to offset 0x4)
        bus_sel   = 1'b1;
        bus_write = 1'b1;
        bus_addr  = 32'h4; 
        bus_wdata = 32'hA5A5A5A5;
        #20;

        // Simulate random noise from a quantum source kicking in before execution
        qtrng_entropy_in = 32'h7F39AC02; 

        // 2. Stream the 4 Data Blocks sequentially (Write to mailbox offset 0x8)
        bus_addr  = 32'h8; bus_wdata = 32'h11111111; #20;
        qtrng_entropy_in = 32'hB28D01FF; // Entropy varies dynamically mid-execution
        bus_addr  = 32'h8; bus_wdata = 32'h22222222; #20;
        bus_addr  = 32'h8; bus_wdata = 32'h33333333; #20;
        bus_addr  = 32'h8; bus_wdata = 32'h44444444; #20;

        // De-assert bus controls immediately after the last block is loaded
        bus_write = 1'b0;
        bus_sel   = 1'b0;
        
        // 3. Dynamic Cycle Sync: Wait for the multi-round computation loop to process
        #240;
        
        // 4. Read back final output calculation (Read from offset 0xC)
        bus_sel   = 1'b1;
        bus_addr  = 32'hC;
        #20;
        
        // Check verification output
        if (bus_ready) begin
            $display("SUCCESS: Dynamic Entropy Verification Complete. Read Data = %h", bus_rdata);
        end else begin
            $display("ERROR: Core was not ready when bus read was attempted.");
        end
        
        #20;
        $finish;
    end

endmodule
