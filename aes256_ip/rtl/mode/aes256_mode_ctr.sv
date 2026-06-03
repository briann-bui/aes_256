//================================================================
// Module      : aes256_mode_ctr
// Project     : AES-256 IP Core
// Description : Counter (CTR) mode
// Parameters  : None
// Ports       : Data handshake, Enc/Dec switch, IV
// Notes       : Only uses encryption datapath. Encrypts counter,
//               then XORs the output with input data.
//================================================================

module aes256_mode_ctr
  import aes256_pkg::*;
(
  input  logic                i_aes_clk,
  input  logic                i_aes_rst_n,
  
  input  logic                i_aes_enc_dec, // 1=Encrypt, 0=Decrypt (CTR uses Enc for both)
  /* verilator lint_off UNUSED */ // CTR always uses encryption datapath

  // Initialization Vector / Nonce + Counter
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
  logic [127:0] r_ctr;
  logic [127:0] r_din_buf;
  logic         r_iv_loaded;   // Guard: IV must be set before accepting data

  //--------------------------------------------------------------
  // Internal signals
  //--------------------------------------------------------------
  logic [127:0] w_enc_dout;
  logic         w_enc_dout_valid;
  logic         w_enc_din_ready;

  //--------------------------------------------------------------
  // Datapath mapping
  //--------------------------------------------------------------
  // Datapath is fed with the current counter
  // Valid goes straight into datapath
  assign o_aes_din_ready = w_enc_din_ready && r_iv_loaded;

  //--------------------------------------------------------------
  // Counter and Buffer Tracking
  //--------------------------------------------------------------
  always_ff @(posedge i_aes_clk or negedge i_aes_rst_n) begin
    if (!i_aes_rst_n) begin
      r_ctr       <= 128'd0;
      r_din_buf   <= 128'd0;
      r_iv_loaded <= 1'b0;
    end else begin
      if (i_aes_iv_valid) begin
        // IV is the initial counter value
        r_ctr       <= i_aes_iv;
        r_iv_loaded <= 1'b1;
      end else begin
        // When input is accepted, save data and increment counter
        if (i_aes_din_valid && o_aes_din_ready) begin
          // Standard full 128-bit increment (can be customized for specific 32-bit CTR formats)
          r_ctr     <= r_ctr + 128'd1;
          r_din_buf <= i_aes_din;
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
    
    .i_aes_din        (r_ctr),
    .i_aes_din_valid  (i_aes_din_valid && r_iv_loaded),
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
  // Output is the XOR of the encrypted counter and the buffered input data
  // This applies to BOTH encrypt and decrypt in CTR mode
  assign o_aes_dout       = w_enc_dout ^ r_din_buf;
  assign o_aes_dout_valid = w_enc_dout_valid;

endmodule
