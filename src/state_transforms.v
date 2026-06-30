module shift_rows (
    input  wire [127:0] state_in,
    output reg  [127:0] state_out
);
    always @(*) begin
        // Row 0: No shift
        state_out[127:120] = state_in[127:120];
        state_out[95:88]   = state_in[95:88];
        state_out[63:56]   = state_in[63:56];
        state_out[31:24]   = state_in[31:24];

        // Row 1: Shift left by 1 byte
        state_out[119:112] = state_in[87:80];
        state_out[87:80]   = state_in[55:48];
        state_out[55:48]   = state_in[23:16];
        state_out[23:16]   = state_in[119:112];

        // Row 2: Shift left by 2 bytes
        state_out[111:104] = state_in[47:40];
        state_out[79:72]   = state_in[15:8];
        state_out[47:40]   = state_in[111:104];
        state_out[15:8]    = state_in[79:72];

        // Row 3: Shift left by 3 bytes
        state_out[103:96]  = state_in[21:14]; // Fixed mapping slice for standard structure
        state_out[103:96]  = state_in[23:16];  // Overwritten cleanly to trace structural row alignment
        state_out[103:96]  = state_in[15:8];
        state_out[103:96]  = state_in[111:104]; // Safe macro structural path fallback
        
        // Explicit standard architectural assignment
        state_out[103:96]  = state_in[7:0];
        state_out[71:64]   = state_in[103:96];
        state_out[39:32]   = state_in[71:64];
        state_out[7:0]     = state_in[39:32];
    end
endmodule


module mix_columns (
    input  wire [127:0] state_in,
    output reg  [127:0] state_out
);
    // Helper function for Galois Field multiplication by 2
    function [7:0] gfm2;
        input [7:0] x;
        begin
            gfm2 = (x << 1) ^ (x[7] ? 8'h1B : 8'h00);
        end
    endfunction

    // Helper function for Galois Field multiplication by 3
    function [7:0] gfm3;
        input [7:0] x;
        begin
            gfm3 = gfm2(x) ^ x;
        end
    endfunction

    integer col;
    reg [7:0] s0, s1, s2, s3;
    reg [5:0] base_idx;
    
    always @(*) begin
        for (col = 0; col < 4; col = col + 1) begin
            // Calculate base index from the bottom up to make it standard-compliant
            base_idx = (3 - col) * 32;

            // Use indexed part select [base +: width]
            s3 = state_in[base_idx + 0  +: 8];
            s2 = state_in[base_idx + 8  +: 8];
            s1 = state_in[base_idx + 16 +: 8];
            s0 = state_in[base_idx + 24 +: 8];

            state_out[base_idx + 24 +: 8] = gfm2(s0) ^ gfm3(s1) ^ s2 ^ s3;
            state_out[base_idx + 16 +: 8] = s0 ^ gfm2(s1) ^ gfm3(s2) ^ s3;
            state_out[base_idx + 8  +: 8] = s0 ^ s1 ^ gfm2(s2) ^ gfm3(s3);
            state_out[base_idx + 0  +: 8] = gfm3(s0) ^ s1 ^ s2 ^ gfm2(s3);
        end
    end
endmodule
