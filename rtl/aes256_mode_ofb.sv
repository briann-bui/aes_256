module aes256_mode_ofb
  import aes256_pkg::*;
(
  input  logic                i_aes_clk,
  input  logic                i_aes_rst_n,

  input  logic                i_aes_enc_dec,

  input  logic [127:0]        i_aes_iv,
  input  logic                i_aes_iv_valid,

  input  logic [127:0]        i_aes_din,
  input  logic                i_aes_din_valid,
  output logic                o_aes_din_ready,

  output logic [127:0]        o_aes_dout,
  output logic                o_aes_dout_valid,
  input  logic                i_aes_dout_ready,

  input  logic [127:0]        i_aes_rkey [0:C_NR],
  input  logic                i_aes_rkey_valid
);

  logic [127:0] r_iv;
  logic [127:0] r_din_buf;

  logic [127:0] w_enc_dout;
  logic         w_enc_dout_valid;
  logic         w_enc_din_ready;

  assign o_aes_din_ready = w_enc_din_ready;

  always_ff @(posedge i_aes_clk or negedge i_aes_rst_n) begin
    if (!i_aes_rst_n) begin
      r_iv      <= 128'd0;
      r_din_buf <= 128'd0;
    end else begin
      if (i_aes_iv_valid) begin
        r_iv <= i_aes_iv;
      end else begin
        if (i_aes_din_valid && w_enc_din_ready)
          r_din_buf <= i_aes_din;

        if (w_enc_dout_valid && i_aes_dout_ready)
          r_iv <= w_enc_dout;
      end
    end
  end

  aes256_enc_datapath u_enc_dp (
    .i_aes_clk        (i_aes_clk),
    .i_aes_rst_n      (i_aes_rst_n),
    .i_aes_din        (r_iv),
    .i_aes_din_valid  (i_aes_din_valid),
    .o_aes_din_ready  (w_enc_din_ready),
    .o_aes_dout       (w_enc_dout),
    .o_aes_dout_valid (w_enc_dout_valid),
    .i_aes_dout_ready (i_aes_dout_ready),
    .i_aes_rkey       (i_aes_rkey),
    .i_aes_rkey_valid (i_aes_rkey_valid)
  );

  assign o_aes_dout       = w_enc_dout ^ r_din_buf;
  assign o_aes_dout_valid = w_enc_dout_valid;

endmodule
