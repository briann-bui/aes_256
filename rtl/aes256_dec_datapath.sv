module aes256_dec_datapath
  import aes256_pkg::*;
(
  input  logic                i_aes_clk,
  input  logic                i_aes_rst_n,

  input  logic [127:0]        i_aes_din,
  input  logic                i_aes_din_valid,
  output logic                o_aes_din_ready,

  output logic [127:0]        o_aes_dout,
  output logic                o_aes_dout_valid,
  input  logic                i_aes_dout_ready,

  input  logic [127:0]        i_aes_rkey [0:C_NR],
  input  logic                i_aes_rkey_valid
);

  t_dp_fsm_e    r_fsm;
  logic [3:0]   r_round_cnt;
  logic [127:0] r_state;

  logic [127:0] w_rf_in_state;
  logic [127:0] w_rf_in_rkey;
  logic         w_rf_is_last;
  logic [127:0] w_rf_out_state;

  aes256_round_func u_round_func (
    .i_aes_state         (w_rf_in_state),
    .i_aes_rkey          (w_rf_in_rkey),
    .i_aes_is_last_round (w_rf_is_last),
    .i_aes_enc_dec       (1'b0),
    .o_aes_state         (w_rf_out_state)
  );

  assign w_rf_in_state = r_state;
  assign w_rf_in_rkey  = i_aes_rkey[4'd13 - r_round_cnt];
  assign w_rf_is_last  = (r_round_cnt == 4'd13);

  always_ff @(posedge i_aes_clk or negedge i_aes_rst_n) begin
    if (!i_aes_rst_n) begin
      r_fsm       <= DP_IDLE;
      r_round_cnt <= 4'd0;
    end else begin
      unique case (r_fsm)
        DP_IDLE: begin
          if (i_aes_din_valid && i_aes_rkey_valid)
            r_fsm <= DP_LOAD;
        end
        DP_LOAD: begin
          r_fsm       <= DP_ROUND;
          r_round_cnt <= 4'd0;
        end
        DP_ROUND: begin
          if (r_round_cnt == 4'd13) begin
            r_fsm <= DP_OUTPUT;
          end else begin
            r_round_cnt <= r_round_cnt + 4'd1;
          end
        end
        DP_OUTPUT: begin
          if (i_aes_dout_ready) begin
            if (i_aes_din_valid && i_aes_rkey_valid)
              r_fsm <= DP_LOAD;
            else
              r_fsm <= DP_IDLE;
          end
        end
        default: r_fsm <= DP_IDLE;
      endcase
    end
  end

  always_ff @(posedge i_aes_clk or negedge i_aes_rst_n) begin
    if (!i_aes_rst_n) begin
      r_state <= 128'd0;
    end else begin
      unique case (r_fsm)
        DP_IDLE:   ;
        DP_LOAD:   r_state <= i_aes_din ^ i_aes_rkey[C_NR];
        DP_ROUND:  r_state <= w_rf_out_state;
        DP_OUTPUT: ;
        default:   r_state <= 128'd0;
      endcase
    end
  end

  assign o_aes_din_ready  = (r_fsm == DP_IDLE) ||
                            ((r_fsm == DP_OUTPUT) && i_aes_dout_ready);
  assign o_aes_dout_valid = (r_fsm == DP_OUTPUT);
  assign o_aes_dout       = r_state;

endmodule
