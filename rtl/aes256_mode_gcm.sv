module aes256_mode_gcm
  import aes256_pkg::*;
(
  input  logic                i_aes_clk,
  input  logic                i_aes_rst_n,

  input  logic                i_aes_enc_dec,

  input  logic [127:0]        i_aes_iv,
  input  logic                i_aes_iv_valid,

  input  logic [127:0]        i_aes_aad,
  input  logic                i_aes_aad_valid,
  input  logic                i_aes_aad_last,
  output logic                o_aes_aad_ready,

  input  logic [127:0]        i_aes_din,
  input  logic                i_aes_din_valid,
  input  logic                i_aes_din_last,
  output logic                o_aes_din_ready,

  output logic [127:0]        o_aes_dout,
  output logic                o_aes_dout_valid,
  output logic                o_aes_dout_last,
  input  logic                i_aes_dout_ready,

  output logic [127:0]        o_aes_tag,
  output logic                o_aes_tag_valid,

  input  logic [127:0]        i_aes_rkey [0:C_NR],
  input  logic                i_aes_rkey_valid
);

  typedef enum logic [2:0] {
    ST_IDLE,
    ST_INIT_H,
    ST_WAIT_H,
    ST_AAD,
    ST_DATA,
    ST_WAIT_T,
    ST_TAG
  } t_gcm_fsm_e;

  t_gcm_fsm_e   r_fsm;
  logic [127:0]  r_H;
  logic [127:0]  r_J0;
  logic [127:0]  r_ctr;
  logic [127:0]  r_ghash;
  logic [127:0]  r_final_ghash;
  logic [127:0]  r_din_buf;
  logic [63:0]   r_len_aad;
  logic [63:0]   r_len_data;
  logic          r_din_last;

  logic [127:0]  w_enc_din;
  logic          w_enc_din_valid;
  logic [127:0]  w_enc_dout;
  logic          w_enc_dout_valid;
  logic          w_enc_din_ready;

  logic [127:0]  w_gf_in_x;
  logic [127:0]  w_gf_out;

  function automatic logic [127:0] f_gf128_mult(input logic [127:0] X, input logic [127:0] Y);
    logic [127:0] V;
    logic [127:0] Z;
    V = Y;
    Z = 128'd0;
    for (int i = 0; i < 128; i++) begin
      if (X[127 - i])
        Z = Z ^ V;
      if (V[0])
        V = {1'b0, V[127:1]} ^ 128'hE1000000000000000000000000000000;
      else
        V = {1'b0, V[127:1]};
    end
    return Z;
  endfunction

  assign w_gf_out = f_gf128_mult(w_gf_in_x, r_H);

  always_ff @(posedge i_aes_clk or negedge i_aes_rst_n) begin
    if (!i_aes_rst_n) begin
      r_fsm         <= ST_IDLE;
      r_H           <= 128'd0;
      r_J0          <= 128'd0;
      r_ctr         <= 128'd0;
      r_ghash       <= 128'd0;
      r_final_ghash <= 128'd0;
      r_din_buf     <= 128'd0;
      r_din_last    <= 1'b0;
      r_len_aad     <= 64'd0;
      r_len_data    <= 64'd0;
    end else begin
      unique case (r_fsm)
        ST_IDLE: begin
          if (i_aes_iv_valid) begin
            r_J0       <= i_aes_iv;
            r_ctr      <= i_aes_iv + 128'd1;
            r_ghash    <= 128'd0;
            r_len_aad  <= 64'd0;
            r_len_data <= 64'd0;
            r_fsm      <= ST_INIT_H;
          end
        end

        ST_INIT_H: begin
          if (w_enc_din_ready)
            r_fsm <= ST_WAIT_H;
        end

        ST_WAIT_H: begin
          if (w_enc_dout_valid) begin
            r_H   <= w_enc_dout;
            if (i_aes_aad_valid || i_aes_din_valid)
              r_fsm <= (i_aes_aad_valid) ? ST_AAD : ST_DATA;
            else
              r_fsm <= ST_AAD;
          end
        end

        ST_AAD: begin
          if (i_aes_aad_valid && o_aes_aad_ready) begin
            r_ghash   <= w_gf_out;
            r_len_aad <= r_len_aad + 64'd128;
            if (i_aes_aad_last)
              r_fsm <= ST_DATA;
          end else if (!i_aes_aad_valid && i_aes_din_valid) begin
            r_fsm <= ST_DATA;
          end
        end

        ST_DATA: begin
          if (i_aes_din_valid && w_enc_din_ready) begin
            r_ctr      <= r_ctr + 128'd1;
            r_din_buf  <= i_aes_din;
            r_len_data <= r_len_data + 64'd128;
            r_din_last <= i_aes_din_last;
          end

          if (w_enc_dout_valid && i_aes_dout_ready) begin
            r_ghash <= w_gf_out;
            if (r_din_last)
              r_fsm <= ST_WAIT_T;
          end
        end

        ST_WAIT_T: begin
          if (w_enc_din_ready) begin
            r_final_ghash <= w_gf_out;
            r_fsm         <= ST_TAG;
          end
        end

        ST_TAG: begin
          if (w_enc_dout_valid)
            r_fsm <= ST_IDLE;
        end

        default: r_fsm <= ST_IDLE;
      endcase
    end
  end

  always_comb begin
    w_enc_din       = 128'd0;
    w_enc_din_valid = 1'b0;
    w_gf_in_x      = 128'd0;

    unique case (r_fsm)
      ST_INIT_H: begin
        w_enc_din       = 128'd0;
        w_enc_din_valid = 1'b1;
      end

      ST_AAD: begin
        w_gf_in_x = r_ghash ^ i_aes_aad;
      end

      ST_DATA: begin
        w_enc_din       = r_ctr;
        w_enc_din_valid = i_aes_din_valid;
        if (i_aes_enc_dec == 1'b1)
          w_gf_in_x = r_ghash ^ (w_enc_dout ^ r_din_buf);
        else
          w_gf_in_x = r_ghash ^ r_din_buf;
      end

      ST_WAIT_T: begin
        w_enc_din       = r_J0;
        w_enc_din_valid = 1'b1;
        w_gf_in_x      = r_ghash ^ {r_len_aad, r_len_data};
      end

      default: ;
    endcase
  end

  assign o_aes_aad_ready = (r_fsm == ST_AAD);
  assign o_aes_din_ready = (r_fsm == ST_DATA) && w_enc_din_ready;

  assign o_aes_dout       = w_enc_dout ^ r_din_buf;
  assign o_aes_dout_valid = (r_fsm == ST_DATA) && w_enc_dout_valid;
  assign o_aes_dout_last  = r_din_last;

  assign o_aes_tag        = w_enc_dout ^ r_final_ghash;
  assign o_aes_tag_valid  = (r_fsm == ST_TAG) && w_enc_dout_valid;

  aes256_enc_datapath u_enc_dp (
    .i_aes_clk        (i_aes_clk),
    .i_aes_rst_n      (i_aes_rst_n),
    .i_aes_din        (w_enc_din),
    .i_aes_din_valid  (w_enc_din_valid),
    .o_aes_din_ready  (w_enc_din_ready),
    .o_aes_dout       (w_enc_dout),
    .o_aes_dout_valid (w_enc_dout_valid),
    .i_aes_dout_ready (i_aes_dout_ready | (r_fsm == ST_WAIT_H) | (r_fsm == ST_TAG)),
    .i_aes_rkey       (i_aes_rkey),
    .i_aes_rkey_valid (i_aes_rkey_valid)
  );

endmodule
