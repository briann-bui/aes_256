//================================================================
// Module      : aes256_mode_ecb
// Project     : AES-256 IP Core
// Description : Electronic Codebook (ECB) mode
// Parameters  : None
// Ports       : Data handshake, Enc/Dec switch
// Notes       : Instantiates enc and dec datapaths, muxes output
//================================================================

module aes256_mode_ecb
  import aes256_pkg::*;
(
  input  logic                i_aes_clk,
  input  logic                i_aes_rst_n,
  
  input  logic                i_aes_enc_dec, // 1=Encrypt, 0=Decrypt

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
  // Internal signals
  //--------------------------------------------------------------
  // Encrypt datapath
  logic [127:0] w_enc_dout;
  logic         w_enc_dout_valid;
  logic         w_enc_din_ready;
  logic         w_enc_din_valid;

  // Decrypt datapath
  logic [127:0] w_dec_dout;
  logic         w_dec_dout_valid;
  logic         w_dec_din_ready;
  logic         w_dec_din_valid;

  //--------------------------------------------------------------
  // Input routing (gating valid based on enc/dec)
  //--------------------------------------------------------------
  assign w_enc_din_valid = (i_aes_enc_dec == 1'b1) ? i_aes_din_valid : 1'b0;
  assign w_dec_din_valid = (i_aes_enc_dec == 1'b0) ? i_aes_din_valid : 1'b0;

  assign o_aes_din_ready = (i_aes_enc_dec == 1'b1) ? w_enc_din_ready : w_dec_din_ready;

  //--------------------------------------------------------------
  // Encrypt datapath instance
  //--------------------------------------------------------------
  aes256_enc_datapath u_enc_dp (
    .i_aes_clk        (i_aes_clk),
    .i_aes_rst_n      (i_aes_rst_n),
    
    .i_aes_din        (i_aes_din),
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
    
    .o_aes_dout       (w_dec_dout),
    .o_aes_dout_valid (w_dec_dout_valid),
    .i_aes_dout_ready (i_aes_dout_ready),
    
    .i_aes_rkey       (i_aes_rkey),
    .i_aes_rkey_valid (i_aes_rkey_valid)
  );

  //--------------------------------------------------------------
  // Output routing
  //--------------------------------------------------------------
  assign o_aes_dout       = (i_aes_enc_dec == 1'b1) ? w_enc_dout       : w_dec_dout;
  assign o_aes_dout_valid = (i_aes_enc_dec == 1'b1) ? w_enc_dout_valid : w_dec_dout_valid;

endmodule
