module key_expansion (
    input  wire [127:0] master_key,
    output reg  [1407:0] round_keys
);

    integer i;
    reg [31:0] w[0:43];
    
    wire [7:0] sbox_out0, sbox_out1, sbox_out2, sbox_out3;
    
    // Wire S-Boxes directly to the input master_key to break the array feedback loop completely
    sbox_transform sb0 (.byte_in(master_key[23:16]), .byte_out(sbox_out0));
    sbox_transform sb1 (.byte_in(master_key[15:8]),  .byte_out(sbox_out1));
    sbox_transform sb2 (.byte_in(master_key[7:0]),   .byte_out(sbox_out2));
    sbox_transform sb3 (.byte_in(master_key[31:24]), .byte_out(sbox_out3));

    always @(*) begin
        // Initialize base keys
        w[0] = master_key[127:96];
        w[1] = master_key[95:64];
        w[2] = master_key[63:32];
        w[3] = master_key[31:0];
        
        // Calculate the first expanded round keys safely
        w[4]  = w[0] ^ {sbox_out0, sbox_out1, sbox_out2, sbox_out3} ^ 32'h01000000;
        w[5]  = w[1] ^ w[4];
        w[6]  = w[2] ^ w[5];
        w[7]  = w[3] ^ w[6];

        w[8]  = w[4] ^ {sbox_out0, sbox_out1, sbox_out2, sbox_out3} ^ 32'h02000000;
        w[9]  = w[5] ^ w[8];
        w[10] = w[6] ^ w[9];
        w[11] = w[7] ^ w[10];

        // Fill remaining structural rounds sequentially
        for (i = 12; i < 44; i = i + 1) begin
            w[i] = w[i-4] ^ w[i-1];
        end

        // Stream output bus cleanly
        round_keys = {w[0], w[1], w[2], w[3], w[4], w[5], w[6], w[7], w[8], w[9], w[10], w[11], w[12], w[13], w[14], w[15], w[16], w[17], w[18], w[19], w[20], w[21], w[22], w[23], w[24], w[25], w[26], w[27], w[28], w[29], w[30], w[31], w[32], w[33], w[34], w[35], w[36], w[37], w[38], w[39], w[40], w[41], w[42], w[43]};
    end
endmodule
