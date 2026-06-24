module aes256_mode_ctr
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

  logic [127:0] r_ctr;
  logic [127:0] r_din_buf;
  logic         r_iv_loaded;

  logic [127:0] w_enc_dout;
  logic         w_enc_dout_valid;
  logic         w_enc_din_ready;

  assign o_aes_din_ready = w_enc_din_ready && r_iv_loaded;

  always_ff @(posedge i_aes_clk or negedge i_aes_rst_n) begin
    if (!i_aes_rst_n) begin
      r_ctr       <= 128'd0;
      r_din_buf   <= 128'd0;
      r_iv_loaded <= 1'b0;
    end else begin
      if (i_aes_iv_valid) begin
        r_ctr       <= i_aes_iv;
        r_iv_loaded <= 1'b1;
      end else begin
        if (i_aes_din_valid && o_aes_din_ready) begin
          r_ctr     <= r_ctr + 128'd1;
          r_din_buf <= i_aes_din;
        end
      end
    end
  end

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

  assign o_aes_dout       = w_enc_dout ^ r_din_buf;
  assign o_aes_dout_valid = w_enc_dout_valid;

endmodule
