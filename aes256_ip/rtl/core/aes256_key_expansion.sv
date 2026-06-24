//================================================================
// Module      : aes256_key_expansion
// Project     : AES-256 IP Core
// Description : AES-256 key schedule expansion (60 words)
// Parameters  : None
// Ports       : i_aes_* / o_aes_*
// Notes       : FSM-based, 4 words/cycle, 13 expand + 1 load = 14 cycles
//================================================================

module aes256_key_expansion
  import aes256_pkg::*;
(
  input  logic          i_aes_clk,
  input  logic          i_aes_rst_n,

  // Key input
  input  logic [255:0]  i_aes_key,
  input  logic          i_aes_key_valid,
  output logic          o_aes_key_ready,

  // Round keys output
  output logic [127:0]  o_aes_rkey [0:C_NR],
  output logic          o_aes_rkey_valid
);

  //--------------------------------------------------------------
  // Internal registers
  //--------------------------------------------------------------
  t_key_fsm_e           r_fsm;
  logic [31:0]          r_w [0:59];   // 60 key‐schedule words
  logic [3:0]           r_step;       // 0..12  (13 expansion steps)

  //--------------------------------------------------------------
  // Combinational signals
  //--------------------------------------------------------------
  logic [5:0]  w_base_idx;
  logic        w_need_rot;
  logic [2:0]  w_rcon_idx;
  logic [31:0] w_prev_word;
  logic [31:0] w_sbox_input;
  logic [7:0]  w_sbox_in  [0:3];
  logic [7:0]  w_sbox_out [0:3];
  logic [31:0] w_sub_result;
  logic [31:0] w_xor_rcon;
  logic [31:0] w_word0, w_word1, w_word2, w_word3;

  //--------------------------------------------------------------
  // S-Box instances for SubWord (4 bytes)
  //--------------------------------------------------------------
  genvar gi;
  generate
    for (gi = 0; gi < 4; gi++) begin : gen_sbox
      aes256_sbox_enc u_sbox (
        .i_aes_byte (w_sbox_in[gi]),
        .o_aes_byte (w_sbox_out[gi])
      );
    end
  endgenerate

  //--------------------------------------------------------------
  // Base index: 8 + r_step*4
  //--------------------------------------------------------------
  assign w_base_idx = 6'd8 + {2'b00, r_step, 2'b00};

  // base%8==0 → need RotWord+Rcon;  base%8==4 → SubWord only
  assign w_need_rot = ~w_base_idx[2];

  // Rcon index = base/8 − 1  (valid only when w_need_rot)
  assign w_rcon_idx = w_base_idx[5:3] - 3'd1;

  //--------------------------------------------------------------
  // Previous word & S-Box input mux
  //--------------------------------------------------------------
  always_comb begin
    w_prev_word = r_w[w_base_idx - 6'd1];

    if (w_need_rot) begin
      // RotWord: rotate left by one byte
      w_sbox_input = {w_prev_word[23:0], w_prev_word[31:24]};
    end else begin
      w_sbox_input = w_prev_word;
    end

    w_sbox_in[0] = w_sbox_input[31:24];
    w_sbox_in[1] = w_sbox_input[23:16];
    w_sbox_in[2] = w_sbox_input[15: 8];
    w_sbox_in[3] = w_sbox_input[ 7: 0];
  end

  //--------------------------------------------------------------
  // SubWord result
  //--------------------------------------------------------------
  assign w_sub_result = {w_sbox_out[0], w_sbox_out[1],
                         w_sbox_out[2], w_sbox_out[3]};

  //--------------------------------------------------------------
  // XOR with Rcon (only when base%8 == 0)
  //--------------------------------------------------------------
  always_comb begin
    if (w_need_rot) begin
      w_xor_rcon = w_sub_result ^ {C_RCON[w_rcon_idx], 24'h000000};
    end else begin
      w_xor_rcon = w_sub_result;
    end
  end

  //--------------------------------------------------------------
  // Compute 4 new words (cascaded XOR)
  //--------------------------------------------------------------
  always_comb begin
    w_word0 = r_w[w_base_idx - 6'd8] ^ w_xor_rcon;
    w_word1 = r_w[w_base_idx - 6'd7] ^ w_word0;
    w_word2 = r_w[w_base_idx - 6'd6] ^ w_word1;
    w_word3 = r_w[w_base_idx - 6'd5] ^ w_word2;
  end

  //--------------------------------------------------------------
  // FSM register
  //--------------------------------------------------------------
  always_ff @(posedge i_aes_clk or negedge i_aes_rst_n) begin
    if (!i_aes_rst_n) begin
      r_fsm <= KEY_IDLE;
    end else begin
      unique case (r_fsm)
        KEY_IDLE: begin
          if (i_aes_key_valid)
            r_fsm <= KEY_EXPAND;
        end
        KEY_EXPAND: begin
          if (r_step == 4'd12)
            r_fsm <= KEY_DONE;
        end
        KEY_DONE: begin
          if (i_aes_key_valid)
            r_fsm <= KEY_EXPAND;
        end
        default: r_fsm <= KEY_IDLE;
      endcase
    end
  end

  //--------------------------------------------------------------
  // Step counter register
  //--------------------------------------------------------------
  always_ff @(posedge i_aes_clk or negedge i_aes_rst_n) begin
    if (!i_aes_rst_n) begin
      r_step <= 4'd0;
    end else begin
      unique case (r_fsm)
        KEY_IDLE: begin
          r_step <= 4'd0;
        end
        KEY_EXPAND: begin
          if (r_step < 4'd12)
            r_step <= r_step + 4'd1;
        end
        KEY_DONE: begin
          if (i_aes_key_valid)
            r_step <= 4'd0;
        end
        default: r_step <= 4'd0;
      endcase
    end
  end

  //--------------------------------------------------------------
  // Key schedule word registers
  //--------------------------------------------------------------
  always_ff @(posedge i_aes_clk or negedge i_aes_rst_n) begin
    if (!i_aes_rst_n) begin
      for (int i = 0; i < 60; i++)
        r_w[i] <= 32'd0;
    end else begin
      unique case (r_fsm)
        KEY_IDLE: begin
          if (i_aes_key_valid) begin
            r_w[0] <= i_aes_key[255:224];
            r_w[1] <= i_aes_key[223:192];
            r_w[2] <= i_aes_key[191:160];
            r_w[3] <= i_aes_key[159:128];
            r_w[4] <= i_aes_key[127: 96];
            r_w[5] <= i_aes_key[ 95: 64];
            r_w[6] <= i_aes_key[ 63: 32];
            r_w[7] <= i_aes_key[ 31:  0];
          end
        end
        KEY_EXPAND: begin
          r_w[w_base_idx]        <= w_word0;
          r_w[w_base_idx + 6'd1] <= w_word1;
          r_w[w_base_idx + 6'd2] <= w_word2;
          r_w[w_base_idx + 6'd3] <= w_word3;
        end
        KEY_DONE: begin
          if (i_aes_key_valid) begin
            r_w[0] <= i_aes_key[255:224];
            r_w[1] <= i_aes_key[223:192];
            r_w[2] <= i_aes_key[191:160];
            r_w[3] <= i_aes_key[159:128];
            r_w[4] <= i_aes_key[127: 96];
            r_w[5] <= i_aes_key[ 95: 64];
            r_w[6] <= i_aes_key[ 63: 32];
            r_w[7] <= i_aes_key[ 31:  0];
          end
        end
        default: ;
      endcase
    end
  end

  //--------------------------------------------------------------
  // Output: round keys (combinational pack from word array)
  //--------------------------------------------------------------
  always_comb begin
    for (int j = 0; j <= C_NR; j++) begin
      o_aes_rkey[j] = {r_w[4*j], r_w[4*j+1], r_w[4*j+2], r_w[4*j+3]};
    end
  end

  //--------------------------------------------------------------
  // Status outputs
  //--------------------------------------------------------------
  assign o_aes_key_ready  = (r_fsm == KEY_IDLE) | (r_fsm == KEY_DONE);
  assign o_aes_rkey_valid = (r_fsm == KEY_DONE);

endmodule
