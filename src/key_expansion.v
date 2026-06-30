module key_expansion (
    input  wire [127:0] master_key,
    output reg  [1407:0] round_keys
);

    integer i;
    reg [31:0] w[0:43];
    
    // Static wire array allocations for the S-box substitutions
    wire [7:0] sbox_out0, sbox_out1, sbox_out2, sbox_out3;
    reg [31:0] rot_word;
    
    // Wire up Sbox components cleanly to static un-looped index endpoints
    sbox_transform sb0 (.byte_in(rot_word[23:16]), .byte_out(sbox_out0));
    sbox_transform sb1 (.byte_in(rot_word[15:8]),  .byte_out(sbox_out1));
    sbox_transform sb2 (.byte_in(rot_word[7:0]),   .byte_out(sbox_out2));
    sbox_transform sb3 (.byte_in(rot_word[31:24]), .byte_out(sbox_out3));

    always @(*) begin
        // Initialize words with Master Key values
        w[0] = master_key[127:96];
        w[1] = master_key[95:64];
        w[2] = master_key[63:32];
        w[3] = master_key[31:0];
        
        rot_word = 32'h0;
        
        for (i = 4; i < 44; i = i + 1) begin
            if (i % 4 == 0) begin
                // Latch the word rotation slice explicitly
                rot_word = w[i-1];
                w[i] = w[i-4] ^ {sbox_out0, sbox_out1, sbox_out2, sbox_out3};
                
                // Add Round Constants sequentially
                if (i == 4)       w[i] = w[i] ^ 32'h01000000;
                else if (i == 8)  w[i] = w[i] ^ 32'h02000000;
                else if (i == 12) w[i] = w[i] ^ 32'h04000000;
                else if (i == 16) w[i] = w[i] ^ 32'h08000000;
                else if (i == 20) w[i] = w[i] ^ 32'h10000000;
                else if (i == 24) w[i] = w[i] ^ 32'h20000000;
                else if (i == 28) w[i] = w[i] ^ 32'h40000000;
                else if (i == 32) w[i] = w[i] ^ 32'h80000000;
                else if (i == 36) w[i] = w[i] ^ 32'h1B000000;
                else if (i == 40) w[i] = w[i] ^ 32'h36000000;
            end else begin
                w[i] = w[i-4] ^ w[i-1];
            end
        end

        // Concat structure back into output bus lane
        round_keys = {w[0], w[1], w[2], w[3], w[4], w[5], w[6], w[7], w[8], w[9], w[10], w[11], w[12], w[13], w[14], w[15], w[16], w[17], w[18], w[19], w[20], w[21], w[22], w[23], w[24], w[25], w[26], w[27], w[28], w[29], w[30], w[31], w[32], w[33], w[34], w[35], w[36], w[37], w[38], w[39], w[40], w[41], w[42], w[43]};
    end
endmodule
