//================================================================
// Module      : aes256_mode_cbc
// Project     : AES-256 IP Core
// Description : Cipher Block Chaining (CBC) mode
// Parameters  : None
// Ports       : Data handshake, Enc/Dec switch, IV
// Notes       : Enc: plaintext XOR prev_ciphertext -> DP
//               Dec: DP -> output XOR prev_ciphertext
//================================================================

module aes256_mode_cbc
  import aes256_pkg::*;
(
  input  logic                i_aes_clk,
  input  logic                i_aes_rst_n,
  
  input  logic                i_aes_enc_dec, // 1=Encrypt, 0=Decrypt

  // Initialization Vector
  input  logic [127:0]        i_aes_iv,
  input  logic                i_aes_iv_valid,

  // Data in
  input  logic [127:0]        i_aes_din,
  input  logic                i_aes_din_valid,
  output logic                o_aes_din_ready,

  // Data out
  output logic [127:0]        o_aes_dout,
  output logic                o_aes_dout_valid,
  input  logic                i_aes_dout_ready,

  // Key schedule
  input  logic [127:0]        i_aes_rkey [0:C_NR],
  input  logic                i_aes_rkey_valid
);

  //--------------------------------------------------------------
  // Feedback registers
  //--------------------------------------------------------------
  logic [127:0] r_iv;
  logic [127:0] r_dec_next_iv;

  //--------------------------------------------------------------
  // Internal signals
  //--------------------------------------------------------------
  // Encrypt datapath
  logic [127:0] w_enc_din;
  logic [127:0] w_enc_dout;
  logic         w_enc_dout_valid;
  logic         w_enc_din_ready;
  logic         w_enc_din_valid;

  // Decrypt datapath
  logic [127:0] w_dec_dout_dp;
  logic [127:0] w_dec_dout;
  logic         w_dec_dout_valid;
  logic         w_dec_din_ready;
  logic         w_dec_din_valid;

  //--------------------------------------------------------------
  // Input routing & Logic
  //--------------------------------------------------------------
  // Encrypt: input to DP is (plaintext XOR r_iv)
  assign w_enc_din       = i_aes_din ^ r_iv;
  assign w_enc_din_valid = (i_aes_enc_dec == 1'b1) ? i_aes_din_valid : 1'b0;

  // Decrypt: input to DP is the ciphertext itself
  assign w_dec_din_valid = (i_aes_enc_dec == 1'b0) ? i_aes_din_valid : 1'b0;

  assign o_aes_din_ready = (i_aes_enc_dec == 1'b1) ? w_enc_din_ready : w_dec_din_ready;

  //--------------------------------------------------------------
  // IV / Feedback tracking
  //--------------------------------------------------------------
  always_ff @(posedge i_aes_clk or negedge i_aes_rst_n) begin
    if (!i_aes_rst_n) begin
      r_iv          <= 128'd0;
      r_dec_next_iv <= 128'd0;
    end else begin
      if (i_aes_iv_valid) begin
        r_iv <= i_aes_iv;
      end else if (i_aes_enc_dec == 1'b1) begin
        // ENCRYPT: Update r_iv with ciphertext when it is output
        if (w_enc_dout_valid && i_aes_dout_ready) begin
          r_iv <= w_enc_dout;
        end
      end else begin
        // DECRYPT: 
        // 1. Capture current input ciphertext to use for next block
        if (w_dec_din_valid && w_dec_din_ready) begin
          r_dec_next_iv <= i_aes_din;
        end
        // 2. Advance r_iv when output is ready
        if (w_dec_dout_valid && i_aes_dout_ready) begin
          r_iv <= r_dec_next_iv;
        end
      end
    end
  end

  //--------------------------------------------------------------
  // Encrypt datapath instance
  //--------------------------------------------------------------
  aes256_enc_datapath u_enc_dp (
    .i_aes_clk        (i_aes_clk),
    .i_aes_rst_n      (i_aes_rst_n),
    
    .i_aes_din        (w_enc_din),
    .i_aes_din_valid  (w_enc_din_valid),
    .o_aes_din_ready  (w_enc_din_ready),
    
    .o_aes_dout       (w_enc_dout),
    .o_aes_dout_valid (w_enc_dout_valid),
    .i_aes_dout_ready (i_aes_dout_ready),
    
    .i_aes_rkey       (i_aes_rkey),
    .i_aes_rkey_valid (i_aes_rkey_valid)
  );

  //--------------------------------------------------------------
  // Decrypt datapath instance
  //--------------------------------------------------------------
  aes256_dec_datapath u_dec_dp (
    .i_aes_clk        (i_aes_clk),
    .i_aes_rst_n      (i_aes_rst_n),
    
    .i_aes_din        (i_aes_din),
    .i_aes_din_valid  (w_dec_din_valid),
    .o_aes_din_ready  (w_dec_din_ready),
    
    .o_aes_dout       (w_dec_dout_dp),
    .o_aes_dout_valid (w_dec_dout_valid),
    .i_aes_dout_ready (i_aes_dout_ready),
    
    .i_aes_rkey       (i_aes_rkey),
    .i_aes_rkey_valid (i_aes_rkey_valid)
  );

  //--------------------------------------------------------------
  // Output routing & Logic
  //--------------------------------------------------------------
  // Decrypt: Output is (DP_output XOR r_iv)
  assign w_dec_dout       = w_dec_dout_dp ^ r_iv;

  assign o_aes_dout       = (i_aes_enc_dec == 1'b1) ? w_enc_dout       : w_dec_dout;
  assign o_aes_dout_valid = (i_aes_enc_dec == 1'b1) ? w_enc_dout_valid : w_dec_dout_valid;

endmodule
