// secure_fabric_top.v
// System Bus Interconnect with Agile Round Management Register

module secure_fabric_top (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [31:0] bus_addr,
    input  wire [31:0] bus_wdata,
    input  wire        bus_write,
    input  wire        bus_sel,
    output reg  [31:0] bus_rdata,
    output reg         bus_ready
);

    // Internal Bus Register File
    reg [31:0] reg_control;
    reg [31:0] reg_key;
    reg [31:0] reg_mailbox;
    reg [3:0]  reg_config_rounds; // Internal configuration register

    wire [31:0] core_out;
    wire        core_ready;
    reg         core_valid_pulse;

    // Connect Agile Multi-Cycle Security Engine
    secure_fabric_core core_eng (
        .clk(clk),
        .rst_n(rst_n),
        .cpu_data_in(reg_mailbox),
        .cpu_valid(core_valid_pulse),
        .key_in(reg_key),
        .runtime_rounds(reg_config_rounds), // Pass register value directly to core
        .mem_data_out(core_out),
        .mem_valid(core_ready)
    );

    // Memory-Mapped Bus Decoding Layer
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_control       <= 32'h0;
            reg_key           <= 32'h0;
            reg_mailbox       <= 32'h0;
            reg_config_rounds <= 4'd10; // Default out of reset to 10 rounds
            core_valid_pulse  <= 1'b0;
            bus_ready         <= 1'b0;
            bus_rdata         <= 32'h0;
        end else begin
            core_valid_pulse <= 1'b0;
            bus_ready        <= 1'b0;

            if (bus_sel) begin
                bus_ready <= 1'b1;
                if (bus_write) begin
                    case (bus_addr[4:0])
                        5'h00: reg_control <= bus_wdata;
                        5'h04: reg_key     <= bus_wdata;
                        5'h08: begin
                            reg_mailbox      <= bus_wdata;
                            core_valid_pulse <= 1'b1; // Trigger data processing stride
                        end
                        5'h10: reg_config_rounds <= bus_wdata[3:0]; // Map configurations to 0x10
                        default: ;
                    endcase
                end else begin
                    case (bus_addr[4:0])
                        5'h00: bus_rdata <= reg_control;
                        5'h04: bus_rdata <= reg_key;
                        5'h0C: bus_rdata <= core_out;
                        5'h10: bus_rdata <= {28'h0, reg_config_rounds};
                        default: bus_rdata <= 32'h0;
                    endcase
                end
            end
        end
    end

    // Maintain operational status registers
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // status tracking reset logic
        end else if (core_ready) begin
            reg_control <= 32'h1; // Mark transaction done
        end else if (core_valid_pulse) begin
            reg_control <= 32'h0; // Core busy processing
        end
    end

endmodule
