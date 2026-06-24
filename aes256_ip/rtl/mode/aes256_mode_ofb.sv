//================================================================
// Module      : aes256_mode_ofb
// Project     : AES-256 IP Core
// Description : Output Feedback (OFB) mode
// Parameters  : None
// Ports       : Data handshake, Enc/Dec switch, IV
// Notes       : Only requires encryption datapath.
//               Feedback is purely E(r_iv), independent of plaintext.
//================================================================

module aes256_mode_ofb
  import aes256_pkg::*;
(
  input  logic                i_aes_clk,
  input  logic                i_aes_rst_n,
  
  input  logic                i_aes_enc_dec, // 1=Encrypt, 0=Decrypt (OFB uses Enc for both)
  /* verilator lint_off UNUSED */ // OFB always uses encryption datapath

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
  // Feedback tracking logic
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
        
        // Update IV with output of encryption (pure block cipher output)
        if (w_enc_dout_valid && i_aes_dout_ready) begin
          r_iv <= w_enc_dout;
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
    
    .i_aes_din        (r_iv), // DP encrypts the previous IV/Feedback
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
  // OFB output block is always E(IV) XOR input_data (for both enc and dec)
  assign o_aes_dout       = w_enc_dout ^ r_din_buf;
  assign o_aes_dout_valid = w_enc_dout_valid;

endmodule
