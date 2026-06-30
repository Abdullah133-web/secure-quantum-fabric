module key_expansion (
    input  wire [127:0] master_key,
    output reg  [1407:0] round_keys
);

    // Temp variables for key scheduling logic
    reg [31:0] temp;
    integer i;
    
    // Wire up connections to instantiate S-Box lookups for the key schedule
    wire [7:0] sbox_out0, sbox_out1, sbox_out2, sbox_out3;
    
    sbox_transform sb0 (.byte_in(temp[23:16]), .byte_out(sbox_out0));
    sbox_transform sb1 (.byte_in(temp[15:8]),  .byte_out(sbox_out1));
    sbox_transform sb2 (.byte_in(temp[7:0]),   .byte_out(sbox_out2));
    sbox_transform sb3 (.byte_in(temp[31:24]), .byte_out(sbox_out3));

    always @(*) begin
        // Round 0 key is just the master key itself
        round_keys[127:0] = master_key;
        
        // Compute remaining 10 rounds of keys
        for (i = 4; i < 44; i = i + 1) begin
            temp = round_keys[(i-1)*32 +: 32];
            
            if (i % 4 == 0) begin
                // Apply RotWord, SubWord, and Rcon XOR operations
                temp = {sbox_out0, sbox_out1, sbox_out2, sbox_out3};
                
                // Simple static lookup approximation for standard Rcon values
                if (i == 4)       temp = temp ^ 32'h01000000;
                else if (i == 8)  temp = temp ^ 32'h02000000;
                else if (i == 12) temp = temp ^ 32'h04000000;
                else if (i == 16) temp = temp ^ 32'h08000000;
                else if (i == 20) temp = temp ^ 32'h10000000;
                else if (i == 24) temp = temp ^ 32'h20000000;
                else if (i == 28) temp = temp ^ 32'h40000000;
                else if (i == 32) temp = temp ^ 32'h80000000;
                else if (i == 36) temp = temp ^ 32'h1B000000;
                else if (i == 40) temp = temp ^ 32'h36000000;
            end
            
            round_keys[i*32 +: 32] = round_keys[(i-4)*32 +: 32] ^ temp;
        end
    end
endmodule
