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
            base_idx = (3 - col) * 32;

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
