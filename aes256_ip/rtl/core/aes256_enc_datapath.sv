//================================================================
// Module      : aes256_enc_datapath
// Project     : AES-256 IP Core
// Description : Iterative encryption datapath (14 rounds)
// Parameters  : None
// Ports       : i_aes_clk, i_aes_rst_n, data handshake, rkey
// Notes       : IDLE -> LOAD -> ROUND[0..13] -> OUTPUT
//================================================================

module aes256_enc_datapath
  import aes256_pkg::*;
(
  input  logic                i_aes_clk,
  input  logic                i_aes_rst_n,

  // Input data handshake
  input  logic [127:0]        i_aes_din,
  input  logic                i_aes_din_valid,
  output logic                o_aes_din_ready,

  // Output data handshake
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
  t_dp_fsm_e    r_fsm;
  logic [3:0]   r_round_cnt;  // 0 to 13
  logic [127:0] r_state;

  //--------------------------------------------------------------
  // Combinational signals
  //--------------------------------------------------------------
  logic [127:0] w_rf_in_state;
  logic [127:0] w_rf_in_rkey;
  logic         w_rf_is_last;
  logic [127:0] w_rf_out_state;

  //--------------------------------------------------------------
  // Round function instance (Combinational)
  //--------------------------------------------------------------
  aes256_round_func u_round_func (
    .i_aes_state         (w_rf_in_state),
    .i_aes_rkey          (w_rf_in_rkey),
    .i_aes_is_last_round (w_rf_is_last),
    .i_aes_enc_dec       (1'b1), // 1 = Encrypt
    .o_aes_state         (w_rf_out_state)
  );

  // Mapping inputs to round function
  assign w_rf_in_state = r_state;
  // r_round_cnt is 0..13, mapped to round key 1..14
  assign w_rf_in_rkey  = i_aes_rkey[r_round_cnt + 4'd1];
  assign w_rf_is_last  = (r_round_cnt == 4'd13);

  //--------------------------------------------------------------
  // FSM Logic
  //--------------------------------------------------------------
  always_ff @(posedge i_aes_clk or negedge i_aes_rst_n) begin
    if (!i_aes_rst_n) begin
      r_fsm       <= DP_IDLE;
      r_round_cnt <= 4'd0;
    end else begin
      unique case (r_fsm)
        DP_IDLE: begin
          if (i_aes_din_valid && i_aes_rkey_valid) begin
            r_fsm <= DP_LOAD;
          end
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
            // Immediately start next if available, else idle
            if (i_aes_din_valid && i_aes_rkey_valid) begin
              r_fsm <= DP_LOAD;
            end else begin
              r_fsm <= DP_IDLE;
            end
          end
        end

        default: r_fsm <= DP_IDLE;
      endcase
    end
  end

  //--------------------------------------------------------------
  // Datapath Logic
  //--------------------------------------------------------------
  always_ff @(posedge i_aes_clk or negedge i_aes_rst_n) begin
    if (!i_aes_rst_n) begin
      r_state <= 128'd0;
    end else begin
      unique case (r_fsm)
        DP_IDLE: begin
          // Hold state
        end

        DP_LOAD: begin
          // Round 0: Initial AddRoundKey
          r_state <= i_aes_din ^ i_aes_rkey[0];
        end

        DP_ROUND: begin
          // Round 1 to 14: SubBytes -> ShiftRows -> MixColumns -> AddRoundKey
          r_state <= w_rf_out_state;
        end

        DP_OUTPUT: begin
          // Hold valid output data
        end

        default: r_state <= 128'd0;
      endcase
    end
  end

  //--------------------------------------------------------------
  // Output assignments
  //--------------------------------------------------------------
  assign o_aes_din_ready  = (r_fsm == DP_IDLE) || 
                            ((r_fsm == DP_OUTPUT) && i_aes_dout_ready);
                            
  assign o_aes_dout_valid = (r_fsm == DP_OUTPUT);
  assign o_aes_dout       = r_state;

endmodule
