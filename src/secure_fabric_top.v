// secure_fabric_top.v
// Memory-Mapped Bus Interconnect Wrapper for RISC-V Processor Integration

module secure_fabric_top (
    input  wire        clk,           // Master System Clock
    input  wire        rst_n,         // Active-Low Reset
    
    // Simple Processor System Bus Interface
    input  wire [31:0] bus_addr,      // Memory Address Bus
    input  wire [31:0] bus_wdata,     // Write Data Bus
    input  wire        bus_write,     // Write Enable Signal
    input  wire        bus_sel,       // Module Select (Chip Select)
    
    output reg  [31:0] bus_rdata,     // Read Data Bus
    output reg         bus_ready      // Transfer Acknowledge
);

    // Memory Map Definitions
    localparam ADDR_CTRL = 2'b00;     // 0x0 : Control/Status
    localparam ADDR_KEY  = 2'b01;     // 0x4 : Whitening Key
    localparam ADDR_DATA = 2'b10;     // 0x8 : Data Input Mailbox
    localparam ADDR_OUT  = 2'b11;     // 0xC : Processed Output

    // Internal Control/Config Registers
    reg [31:0] reg_ctrl;
    reg [31:0] reg_key;
    reg [31:0] reg_data_in;
    reg        internal_valid;

    // Core Fabric Wire Connections
    wire [31:0] core_mem_out;
    wire        core_mem_valid;

    // Suppress unused address bits warning cleanly by picking out bits [3:2]
    wire [1:0] addr_select = bus_addr[3:2];

    // Instantiate our verified data-path core underneath the bus layer
    secure_fabric_core core_inst (
        .clk(clk),
        .rst_n(rst_n),
        .cpu_data_in(reg_data_in),
        .cpu_valid(internal_valid),
        .key_in(reg_key),
        .mem_data_out(core_mem_out),
        .mem_valid(core_mem_valid)
    );

    // 1. Bus Write Operations (CPU writing to registers)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_ctrl       <= 32'h0;
            reg_key        <= 32'h0;
            reg_data_in    <= 32'h0;
            internal_valid <= 1'b0;
        end else begin
            internal_valid <= 1'b0; // Default pulse
            
            if (bus_sel && bus_write) begin
                case (addr_select)
                    ADDR_CTRL: reg_ctrl    <= bus_wdata;
                    ADDR_KEY:  reg_key     <= bus_wdata;
                    ADDR_DATA: begin
                        reg_data_in    <= bus_wdata;
                        internal_valid <= 1'b1; // Trigger core loading step
                    end
                    default: ;
                endcase
            end
            
            // Capture completion flag into control register Status Bit (Bit 1)
            if (core_mem_valid) begin
                reg_ctrl[1] <= 1'b1; 
            end else if (bus_sel && bus_write && (addr_select == ADDR_CTRL)) begin
                reg_ctrl[1] <= bus_wdata[1]; // Allow CPU to clear status bit
            end
        end
    end

    // 2. Bus Read Operations (CPU reading from registers)
    always @(*) begin
        bus_rdata = 32'h0;
        bus_ready = 1'b0;
        
        if (bus_sel) begin
            bus_ready = 1'b1; // Single-cycle bus response acknowledgment
            if (!bus_write) begin
                case (addr_select)
                    ADDR_CTRL: bus_rdata = reg_ctrl;
                    ADDR_KEY:  bus_rdata = reg_key;
                    ADDR_DATA: bus_rdata = reg_data_in;
                    ADDR_OUT:  bus_rdata = core_mem_out;
                    default:   bus_rdata = 32'h0;
                endcase
            end
        end
    end

endmodule
