//================================================================
// Module      : aes256_mode_gcm
// Project     : AES-256 IP Core
// Description : Galois/Counter Mode (GCM)
// Parameters  : None
// Ports       : AAD, Tag, standard data handshake
// Notes       : Synthesizable GF(2^128) for GHASH + CTR block encrypt.
//================================================================

module aes256_mode_gcm
  import aes256_pkg::*;
(
  input  logic                i_aes_clk,
  input  logic                i_aes_rst_n,
  
  input  logic                i_aes_enc_dec, // 1=Encrypt, 0=Decrypt

  // Initialization Vector (usually 96-bit padded to 128)
  input  logic [127:0]        i_aes_iv,
  input  logic                i_aes_iv_valid,

  // AAD (Additional Authenticated Data)
  input  logic [127:0]        i_aes_aad,
  input  logic                i_aes_aad_valid,
  input  logic                i_aes_aad_last,
  output logic                o_aes_aad_ready,

  // Data in
  input  logic [127:0]        i_aes_din,
  input  logic                i_aes_din_valid,
  input  logic                i_aes_din_last,
  output logic                o_aes_din_ready,

  // Data out
  output logic [127:0]        o_aes_dout,
  output logic                o_aes_dout_valid,
  output logic                o_aes_dout_last,
  input  logic                i_aes_dout_ready,

  // Tag
  output logic [127:0]        o_aes_tag,
  output logic                o_aes_tag_valid,

  // Key schedule
  input  logic [127:0]        i_aes_rkey [0:C_NR],
  input  logic                i_aes_rkey_valid
);

  //--------------------------------------------------------------
  // FSM and Registers
  //--------------------------------------------------------------
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
  logic [127:0] r_H;              // Hash subkey
  logic [127:0] r_J0;             // J0 value for tag encryption
  logic [127:0] r_ctr;            // Counter for data encryption
  logic [127:0] r_ghash;          // Current GHASH accumulator
  logic [127:0] r_final_ghash;    // Final GHASH for tag computation
  logic [127:0] r_din_buf;        // Buffer for data
  logic [127:0] r_len_aad;        // Length of AAD (bits)
  logic [127:0] r_len_data;       // Length of Data (bits)
  logic         r_din_last;

  //--------------------------------------------------------------
  // Internal signals
  //--------------------------------------------------------------
  logic [127:0] w_enc_din;
  logic         w_enc_din_valid;
  logic [127:0] w_enc_dout;
  logic         w_enc_dout_valid;
  logic         w_enc_din_ready;
  
  logic [127:0] w_gf_in_x;
  logic [127:0] w_gf_out;

  //--------------------------------------------------------------
  // Synthesizable GF(2^128) Multiplier (Combinational)
  // X * Y (mod x^128 + x^7 + x^2 + x + 1)
  // GCM uses bit-reversed fields.
  //--------------------------------------------------------------
  function automatic logic [127:0] f_gf128_mult(input logic [127:0] X, input logic [127:0] Y);
    logic [127:0] V;
    logic [127:0] Z;
    V = Y;
    Z = 128'd0;
    for (int i = 0; i < 128; i++) begin
      if (X[127 - i]) begin
        Z = Z ^ V;
      end
      if (V[0]) begin
        V = {1'b0, V[127:1]} ^ 128'hE1000000000000000000000000000000;
      end else begin
        V = {1'b0, V[127:1]};
      end
    end
    return Z;
  endfunction

  assign w_gf_out = f_gf128_mult(w_gf_in_x, r_H);

  //--------------------------------------------------------------
  // FSM Logic
  //--------------------------------------------------------------
  always_ff @(posedge i_aes_clk or negedge i_aes_rst_n) begin
    if (!i_aes_rst_n) begin
      r_fsm          <= ST_IDLE;
      r_H            <= 128'd0;
      r_J0           <= 128'd0;
      r_ctr          <= 128'd0;
      r_ghash        <= 128'd0;
      r_final_ghash  <= 128'd0;
      r_din_buf      <= 128'd0;
      r_din_last     <= 1'b0;
      r_len_aad      <= 128'd0;
      r_len_data     <= 128'd0;
    end else begin
      unique case (r_fsm)
        ST_IDLE: begin
          if (i_aes_iv_valid) begin
            r_J0        <= i_aes_iv; // Typically {Nonce(96), 31'd0, 1'b1}
            r_ctr       <= i_aes_iv + 128'd1; // CTR starts from J0+1
            r_ghash     <= 128'd0;
            r_len_aad   <= 128'd0;
            r_len_data  <= 128'd0;
            r_fsm       <= ST_INIT_H;
          end
        end

        ST_INIT_H: begin
          // Send 0 to generate H = E(0)
          if (w_enc_din_ready) begin
            r_fsm <= ST_WAIT_H;
          end
        end

        ST_WAIT_H: begin
          if (w_enc_dout_valid) begin
            r_H   <= w_enc_dout;
            if (i_aes_aad_valid || i_aes_din_valid) begin
              r_fsm <= (i_aes_aad_valid) ? ST_AAD : ST_DATA;
            end else begin
              r_fsm <= ST_AAD;
            end
          end
        end

        ST_AAD: begin
          if (i_aes_aad_valid && o_aes_aad_ready) begin
            r_ghash   <= w_gf_out;
            r_len_aad <= r_len_aad + 128'd128;
            if (i_aes_aad_last) begin
              r_fsm <= ST_DATA;
            end
          end else if (!i_aes_aad_valid && i_aes_din_valid) begin // skip AAD if data comes first
            r_fsm <= ST_DATA;
          end
        end

        ST_DATA: begin
          if (i_aes_din_valid && w_enc_din_ready) begin
            r_ctr      <= r_ctr + 128'd1;
            r_din_buf  <= i_aes_din;
            r_len_data <= r_len_data + 128'd128;
            r_din_last <= i_aes_din_last;
            
            // Wait for DP to finish this block to compute output and GHASH next
          end
          
          if (w_enc_dout_valid && i_aes_dout_ready) begin
            r_ghash <= w_gf_out;
            if (r_din_last) begin
              r_fsm <= ST_WAIT_T;
            end
          end
        end

        ST_WAIT_T: begin
          // Final GHASH with Length block
          // Capture final GHASH = GF_mult(r_ghash ^ {len_A, len_C}, H)
          // before transitioning, since w_gf_in_x is zeroed in ST_TAG
          if (w_enc_din_ready) begin
            r_final_ghash <= w_gf_out;
            r_fsm         <= ST_TAG;
          end
        end

        ST_TAG: begin
          if (w_enc_dout_valid) begin
            // Final tag logic
            r_fsm <= ST_IDLE;
          end
        end

        default: r_fsm <= ST_IDLE;
      endcase
    end
  end

  //--------------------------------------------------------------
  // GHASH / DP Input Routing
  //--------------------------------------------------------------
  always_comb begin
    w_enc_din       = 128'd0;
    w_enc_din_valid = 1'b0;
    w_gf_in_x       = 128'd0;
    
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
        if (i_aes_enc_dec == 1'b1) begin
          w_gf_in_x = r_ghash ^ (w_enc_dout ^ r_din_buf); // GHASH over Ciphertext
        end else begin
          w_gf_in_x = r_ghash ^ r_din_buf; // Receive Ciphertext
        end
      end
      
      ST_WAIT_T: begin
        w_enc_din       = r_J0;
        w_enc_din_valid = 1'b1;
        w_gf_in_x       = r_ghash ^ {r_len_aad, r_len_data}; // Final GHASH step
      end
      
      default: ;
    endcase
  end

  //--------------------------------------------------------------
  // Ready/Valid Logic
  //--------------------------------------------------------------
  assign o_aes_aad_ready = (r_fsm == ST_AAD);
  assign o_aes_din_ready = (r_fsm == ST_DATA) && w_enc_din_ready;
  
  assign o_aes_dout       = w_enc_dout ^ r_din_buf;
  assign o_aes_dout_valid = (r_fsm == ST_DATA) && w_enc_dout_valid;
  assign o_aes_dout_last  = r_din_last;

  assign o_aes_tag       = w_enc_dout ^ r_final_ghash;
  assign o_aes_tag_valid = (r_fsm == ST_TAG) && w_enc_dout_valid;

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
    .i_aes_dout_ready (i_aes_dout_ready | (r_fsm == ST_WAIT_H) | (r_fsm == ST_TAG)),
    
    .i_aes_rkey       (i_aes_rkey),
    .i_aes_rkey_valid (i_aes_rkey_valid)
  );

endmodule
