module aes256_round_func
  import aes256_pkg::*;
(
  input  logic [127:0] i_aes_state,
  input  logic [127:0] i_aes_rkey,
  input  logic         i_aes_is_last_round,
  input  logic         i_aes_enc_dec,
  output logic [127:0] o_aes_state
);

  logic [127:0] w_enc_after_sub;
  logic [127:0] w_enc_after_shift;
  logic [127:0] w_enc_after_mix;
  logic [127:0] w_enc_after_ark;

  logic [127:0] w_dec_after_shift;
  logic [127:0] w_dec_after_sub;
  logic [127:0] w_dec_after_ark;
  logic [127:0] w_dec_after_mix;

  t_state_t     w_in_state;
  t_state_t     w_enc_sub_state;
  t_state_t     w_enc_shift_state;
  t_state_t     w_enc_mix_state;
  t_state_t     w_dec_shift_state;
  t_state_t     w_dec_sub_state;

  logic [7:0]   w_sbox_enc_in  [0:15];
  logic [7:0]   w_sbox_enc_out [0:15];
  logic [7:0]   w_sbox_dec_in  [0:15];
  logic [7:0]   w_sbox_dec_out [0:15];

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

  assign w_in_state = f_flat_to_state(i_aes_state);

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

  always_comb begin
    for (int c = 0; c < 4; c++) begin
      w_enc_shift_state[0][c] = w_enc_sub_state[0][c];
      w_enc_shift_state[1][c] = w_enc_sub_state[1][(c + 1) % 4];
      w_enc_shift_state[2][c] = w_enc_sub_state[2][(c + 2) % 4];
      w_enc_shift_state[3][c] = w_enc_sub_state[3][(c + 3) % 4];
    end
  end

  assign w_enc_after_shift = f_state_to_flat(w_enc_shift_state);

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

  always_comb begin
    if (i_aes_is_last_round)
      w_enc_after_ark = w_enc_after_shift ^ i_aes_rkey;
    else
      w_enc_after_ark = w_enc_after_mix ^ i_aes_rkey;
  end

  always_comb begin
    for (int c = 0; c < 4; c++) begin
      w_dec_shift_state[0][c] = w_in_state[0][c];
      w_dec_shift_state[1][c] = w_in_state[1][(c + 3) % 4];
      w_dec_shift_state[2][c] = w_in_state[2][(c + 2) % 4];
      w_dec_shift_state[3][c] = w_in_state[3][(c + 1) % 4];
    end
  end

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
  assign w_dec_after_ark = w_dec_after_sub ^ i_aes_rkey;

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

  always_comb begin
    if (i_aes_enc_dec) begin
      o_aes_state = w_enc_after_ark;
    end else begin
      if (i_aes_is_last_round)
        o_aes_state = w_dec_after_ark;
      else
        o_aes_state = w_dec_after_mix;
    end
  end

endmodule
