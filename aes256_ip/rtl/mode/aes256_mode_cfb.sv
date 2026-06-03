//================================================================
// Module      : aes256_mode_cfb
// Project     : AES-256 IP Core
// Description : Cipher Feedback (CFB) mode
// Parameters  : None
// Ports       : Data handshake, Enc/Dec switch, IV
// Notes       : Uses only encryption datapath. 
//               Enc: r_iv_next = ciphertext = E(r_iv) ^ plaintext
//               Dec: ciphertext buffered, plaintext = E(r_iv) ^ ciphertext
//                    r_iv_next = ciphertext
//================================================================

module aes256_mode_cfb
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
  // Registers
  //--------------------------------------------------------------
  logic [127:0] r_iv;
  logic [127:0] r_din_buf;

  //--------------------------------------------------------------
  // Internal signals
  //--------------------------------------------------------------
  logic [127:0] w_enc_dout;
  logic         w_enc_dout_valid;
  logic         w_enc_din_ready;

  //--------------------------------------------------------------
  // Datapath mapping
  //--------------------------------------------------------------
  assign o_aes_din_ready = w_enc_din_ready;

  //--------------------------------------------------------------
  // CFB tracking logic
  //--------------------------------------------------------------
  always_ff @(posedge i_aes_clk or negedge i_aes_rst_n) begin
    if (!i_aes_rst_n) begin
      r_iv      <= 128'd0;
      r_din_buf <= 128'd0;
    end else begin
      if (i_aes_iv_valid) begin
        r_iv <= i_aes_iv;
      end else begin
        // Buffer input data when accepted by datapath
        if (i_aes_din_valid && w_enc_din_ready) begin
          r_din_buf <= i_aes_din;
        end
        
        // Update IV when output block has been processed and accepted
        if (w_enc_dout_valid && i_aes_dout_ready) begin
          if (i_aes_enc_dec == 1'b1) begin
            // Encrypt CFB: new IV is the generated ciphertext
            r_iv <= w_enc_dout ^ r_din_buf;
          end else begin
            // Decrypt CFB: new IV is the received ciphertext
            r_iv <= r_din_buf;
          end
        end
      end
    end
  end

  //--------------------------------------------------------------
  // Encrypt datapath instance reference
  //--------------------------------------------------------------
  aes256_enc_datapath u_enc_dp (
    .i_aes_clk        (i_aes_clk),
    .i_aes_rst_n      (i_aes_rst_n),
    
    .i_aes_din        (r_iv), // DP always encrypts the IV/Feedback shift register
    .i_aes_din_valid  (i_aes_din_valid),
    .o_aes_din_ready  (w_enc_din_ready),
    
    .o_aes_dout       (w_enc_dout),
    .o_aes_dout_valid (w_enc_dout_valid),
    .i_aes_dout_ready (i_aes_dout_ready),
    
    .i_aes_rkey       (i_aes_rkey),
    .i_aes_rkey_valid (i_aes_rkey_valid)
  );

  //--------------------------------------------------------------
  // Output routing
  //--------------------------------------------------------------
  // In CFB mode, the output block is always E(IV) XOR input_data
  assign o_aes_dout       = w_enc_dout ^ r_din_buf;
  assign o_aes_dout_valid = w_enc_dout_valid;

endmodule
