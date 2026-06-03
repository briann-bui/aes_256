//================================================================
// Module      : aes256_round_func
// Project     : AES-256 IP Core
// Description : Single AES round (encrypt & decrypt), combinational
// Parameters  : None
// Ports       : i_aes_state, i_aes_rkey, i_aes_is_last_round,
//               i_aes_enc_dec, o_aes_state
// Notes       : Enc: SubBytes→ShiftRows→MixColumns→AddRoundKey
//               Dec: InvShiftRows→InvSubBytes→AddRoundKey→InvMixColumns
//               MixColumns/InvMixColumns skipped on last round
//================================================================

module aes256_round_func
  import aes256_pkg::*;
(
  input  logic [127:0] i_aes_state,
  input  logic [127:0] i_aes_rkey,
  input  logic         i_aes_is_last_round,
  input  logic         i_aes_enc_dec,       // 1=encrypt, 0=decrypt
  output logic [127:0] o_aes_state
);

  //--------------------------------------------------------------
  // Internal wires
  //--------------------------------------------------------------
  // Encrypt path
  logic [127:0] w_enc_after_sub;
  logic [127:0] w_enc_after_shift;
  logic [127:0] w_enc_after_mix;
  logic [127:0] w_enc_after_ark;
  // Decrypt path
  logic [127:0] w_dec_after_shift;
  logic [127:0] w_dec_after_sub;
  logic [127:0] w_dec_after_ark;
  logic [127:0] w_dec_after_mix;

  // State matrices
  t_state_t w_in_state;
  // Encrypt intermediates
  t_state_t w_enc_sub_state;
  t_state_t w_enc_shift_state;
  t_state_t w_enc_mix_state;
  // Decrypt intermediates
  t_state_t w_dec_shift_state;
  t_state_t w_dec_sub_state;

  //--------------------------------------------------------------
  // S-Box wires (16 bytes enc + 16 bytes dec)
  //--------------------------------------------------------------
  logic [7:0] w_sbox_enc_in  [0:15];
  logic [7:0] w_sbox_enc_out [0:15];
  logic [7:0] w_sbox_dec_in  [0:15];
  logic [7:0] w_sbox_dec_out [0:15];

  //--------------------------------------------------------------
  // S-Box instances: 16 for encrypt, 16 for decrypt
  //--------------------------------------------------------------
  genvar gi;
  generate
    for (gi = 0; gi < 16; gi++) begin : gen_sbox_enc
      aes256_sbox_enc u_sbox_enc (
        .i_aes_byte (w_sbox_enc_in[gi]),
        .o_aes_byte (w_sbox_enc_out[gi])
      );
    end
    for (gi = 0; gi < 16; gi++) begin : gen_sbox_dec
      aes256_sbox_dec u_sbox_dec (
        .i_aes_byte (w_sbox_dec_in[gi]),
        .o_aes_byte (w_sbox_dec_out[gi])
      );
    end
  endgenerate

  //--------------------------------------------------------------
  // Input state conversion
  //--------------------------------------------------------------
  assign w_in_state = f_flat_to_state(i_aes_state);

  //============================================================
  // ENCRYPT PATH: SubBytes → ShiftRows → MixColumns → AddRoundKey
  //============================================================

  // --- SubBytes (encrypt) ---
  always_comb begin
    for (int r = 0; r < 4; r++) begin
      for (int c = 0; c < 4; c++) begin
        w_sbox_enc_in[4*r + c] = w_in_state[r][c];
      end
    end
  end

  always_comb begin
    for (int r = 0; r < 4; r++) begin
      for (int c = 0; c < 4; c++) begin
        w_enc_sub_state[r][c] = w_sbox_enc_out[4*r + c];
      end
    end
  end

  // --- ShiftRows (encrypt): row r shifts left by r positions ---
  always_comb begin
    for (int c = 0; c < 4; c++) begin
      w_enc_shift_state[0][c] = w_enc_sub_state[0][c];
      w_enc_shift_state[1][c] = w_enc_sub_state[1][(c + 1) % 4];
      w_enc_shift_state[2][c] = w_enc_sub_state[2][(c + 2) % 4];
      w_enc_shift_state[3][c] = w_enc_sub_state[3][(c + 3) % 4];
    end
  end

  assign w_enc_after_shift = f_state_to_flat(w_enc_shift_state);

  // --- MixColumns (encrypt) ---
  // Each column: [s0,s1,s2,s3] →
  //   [2*s0 ^ 3*s1 ^ s2   ^ s3,
  //    s0   ^ 2*s1 ^ 3*s2 ^ s3,
  //    s0   ^ s1   ^ 2*s2 ^ 3*s3,
  //    3*s0 ^ s1   ^ s2   ^ 2*s3]
  always_comb begin
    for (int c = 0; c < 4; c++) begin
      w_enc_mix_state[0][c] = f_xtime(w_enc_shift_state[0][c]) ^
                               (f_xtime(w_enc_shift_state[1][c]) ^ w_enc_shift_state[1][c]) ^
                               w_enc_shift_state[2][c] ^
                               w_enc_shift_state[3][c];

      w_enc_mix_state[1][c] = w_enc_shift_state[0][c] ^
                               f_xtime(w_enc_shift_state[1][c]) ^
                               (f_xtime(w_enc_shift_state[2][c]) ^ w_enc_shift_state[2][c]) ^
                               w_enc_shift_state[3][c];

      w_enc_mix_state[2][c] = w_enc_shift_state[0][c] ^
                               w_enc_shift_state[1][c] ^
                               f_xtime(w_enc_shift_state[2][c]) ^
                               (f_xtime(w_enc_shift_state[3][c]) ^ w_enc_shift_state[3][c]);

      w_enc_mix_state[3][c] = (f_xtime(w_enc_shift_state[0][c]) ^ w_enc_shift_state[0][c]) ^
                               w_enc_shift_state[1][c] ^
                               w_enc_shift_state[2][c] ^
                               f_xtime(w_enc_shift_state[3][c]);
    end
  end

  assign w_enc_after_mix = f_state_to_flat(w_enc_mix_state);

  // --- AddRoundKey + MixColumns bypass on last round ---
  always_comb begin
    if (i_aes_is_last_round) begin
      w_enc_after_ark = w_enc_after_shift ^ i_aes_rkey;
    end else begin
      w_enc_after_ark = w_enc_after_mix ^ i_aes_rkey;
    end
  end

  //============================================================
  // DECRYPT PATH: InvShiftRows → InvSubBytes → AddRoundKey → InvMixColumns
  //============================================================

  // --- InvShiftRows: row r shifts right by r positions ---
  always_comb begin
    for (int c = 0; c < 4; c++) begin
      w_dec_shift_state[0][c] = w_in_state[0][c];
      w_dec_shift_state[1][c] = w_in_state[1][(c + 3) % 4];
      w_dec_shift_state[2][c] = w_in_state[2][(c + 2) % 4];
      w_dec_shift_state[3][c] = w_in_state[3][(c + 1) % 4];
    end
  end

  // --- InvSubBytes (decrypt) ---
  always_comb begin
    for (int r = 0; r < 4; r++) begin
      for (int c = 0; c < 4; c++) begin
        w_sbox_dec_in[4*r + c] = w_dec_shift_state[r][c];
      end
    end
  end

  always_comb begin
    for (int r = 0; r < 4; r++) begin
      for (int c = 0; c < 4; c++) begin
        w_dec_sub_state[r][c] = w_sbox_dec_out[4*r + c];
      end
    end
  end

  assign w_dec_after_sub = f_state_to_flat(w_dec_sub_state);

  // --- AddRoundKey (decrypt — applied before InvMixColumns) ---
  assign w_dec_after_ark = w_dec_after_sub ^ i_aes_rkey;

  // --- InvMixColumns (decrypt) ---
  // Multiply by inverse matrix: {0E, 0B, 0D, 09}
  always_comb begin : blk_inv_mix
    t_state_t w_ark_state;
    w_ark_state = f_flat_to_state(w_dec_after_ark);

    for (int c = 0; c < 4; c++) begin
      w_dec_after_mix[127 - 32*c -: 8] =
        f_gf_mul(8'h0E, w_ark_state[0][c]) ^ f_gf_mul(8'h0B, w_ark_state[1][c]) ^
        f_gf_mul(8'h0D, w_ark_state[2][c]) ^ f_gf_mul(8'h09, w_ark_state[3][c]);

      w_dec_after_mix[119 - 32*c -: 8] =
        f_gf_mul(8'h09, w_ark_state[0][c]) ^ f_gf_mul(8'h0E, w_ark_state[1][c]) ^
        f_gf_mul(8'h0B, w_ark_state[2][c]) ^ f_gf_mul(8'h0D, w_ark_state[3][c]);

      w_dec_after_mix[111 - 32*c -: 8] =
        f_gf_mul(8'h0D, w_ark_state[0][c]) ^ f_gf_mul(8'h09, w_ark_state[1][c]) ^
        f_gf_mul(8'h0E, w_ark_state[2][c]) ^ f_gf_mul(8'h0B, w_ark_state[3][c]);

      w_dec_after_mix[103 - 32*c -: 8] =
        f_gf_mul(8'h0B, w_ark_state[0][c]) ^ f_gf_mul(8'h0D, w_ark_state[1][c]) ^
        f_gf_mul(8'h09, w_ark_state[2][c]) ^ f_gf_mul(8'h0E, w_ark_state[3][c]);
    end
  end

  //--------------------------------------------------------------
  // Output mux: encrypt or decrypt
  //--------------------------------------------------------------
  always_comb begin
    if (i_aes_enc_dec) begin
      o_aes_state = w_enc_after_ark;
    end else begin
      if (i_aes_is_last_round) begin
        o_aes_state = w_dec_after_ark; // No InvMixColumns on last round
      end else begin
        o_aes_state = w_dec_after_mix;
      end
    end
  end

endmodule
