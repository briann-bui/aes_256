//================================================================
// Module      : aes256_top
// Project     : AES-256 IP Core
// Description : Top level AES IP Core integrating Key Expansion 
//               and Mode routing for ECB, CBC, CTR, CFB, OFB, GCM.
// Parameters  : None
// Ports       : Standard IP boundary ports
// Notes       : Routes data to appropriate mode instantiated module
//================================================================

module aes256_top
  import aes256_pkg::*;
(
  input  logic          i_aes_clk,
  input  logic          i_aes_rst_n,

  // Configuration
  input  logic [2:0]    i_aes_mode,     // 0=ECB, 1=CBC, 2=CTR, 3=CFB, 4=OFB, 5=GCM
  input  logic          i_aes_enc_dec,  // 1=encrypt 0=decrypt

  // Key System
  input  logic [255:0]  i_aes_key,
  input  logic          i_aes_key_valid,
  output logic          o_aes_key_ready,

  // IV/Nonce (CBC, CTR, CFB, OFB, GCM)
  input  logic [127:0]  i_aes_iv,
  input  logic          i_aes_iv_valid,

  // Input Data (handshake)
  input  logic [127:0]  i_aes_din,
  input  logic          i_aes_din_valid,
  input  logic          i_aes_din_last,
  output logic          o_aes_din_ready,

  // Output Data (handshake)
  output logic [127:0]  o_aes_dout,
  output logic          o_aes_dout_valid,
  output logic          o_aes_dout_last,
  input  logic          i_aes_dout_ready,

  // GCM: Additional Authenticated Data
  input  logic [127:0]  i_aes_aad,
  input  logic          i_aes_aad_valid,
  input  logic          i_aes_aad_last,
  output logic          o_aes_aad_ready,

  // GCM: Auth tag
  output logic [127:0]  o_aes_tag,
  output logic          o_aes_tag_valid,

  // Status
  output logic          o_aes_busy,
  output logic          o_aes_err
);

  //--------------------------------------------------------------
  // Constants
  //--------------------------------------------------------------
  localparam int C_NUM_MODES = 6;

  //--------------------------------------------------------------
  // Key Expansion Signals
  //--------------------------------------------------------------
  logic [127:0] w_rkey [0:C_NR];
  logic         w_rkey_valid;
  
  // Track ongoing operations for status
  logic         r_busy;
  
  // Mode-specific output wires
  logic [127:0] w_dout       [0:C_NUM_MODES-1];
  logic         w_dout_valid [0:C_NUM_MODES-1];
  logic         w_din_ready  [0:C_NUM_MODES-1];
  logic         w_dout_last  [0:C_NUM_MODES-1];

  //--------------------------------------------------------------
  // Pipeline register: delay i_aes_din_last to match output timing
  // (Iterative architecture: 1 block in flight, single register)
  //--------------------------------------------------------------
  logic r_dout_last_buf;

  //--------------------------------------------------------------
  // Gating static configuration
  // (Assuming static while busy)
  //--------------------------------------------------------------
  logic [2:0] r_internal_mode;
  logic       r_internal_enc_dec;

  always_ff @(posedge i_aes_clk or negedge i_aes_rst_n) begin
    if (!i_aes_rst_n) begin
      r_internal_mode    <= 3'd0;
      r_internal_enc_dec <= 1'b1;
      r_busy             <= 1'b0;
      r_dout_last_buf    <= 1'b0;
    end else begin
      if (i_aes_iv_valid || i_aes_key_valid) begin // Initialization asserts busy
        r_busy <= 1'b1;
      end else if (o_aes_dout_last && o_aes_dout_valid && i_aes_dout_ready) begin // Clears when final block processed
        r_busy <= 1'b0;
      end
      
      if (!r_busy) begin // Only update when harmless
        r_internal_mode    <= i_aes_mode;
        r_internal_enc_dec <= i_aes_enc_dec;
      end

      // Capture din_last on input handshake (non-GCM modes)
      if (i_aes_din_valid && o_aes_din_ready) begin
        r_dout_last_buf <= i_aes_din_last;
      end
    end
  end

  assign o_aes_busy = (r_busy && !o_aes_key_ready) || (w_rkey_valid == 0);
  assign o_aes_err  = 1'b0; // Error flag hook

  //--------------------------------------------------------------
  // Key Expansion instance
  //--------------------------------------------------------------
  aes256_key_expansion u_key_expand (
    .i_aes_clk        (i_aes_clk),
    .i_aes_rst_n      (i_aes_rst_n),
    
    .i_aes_key        (i_aes_key),
    .i_aes_key_valid  (i_aes_key_valid),
    .o_aes_key_ready  (o_aes_key_ready),
    
    .o_aes_rkey       (w_rkey),
    .o_aes_rkey_valid (w_rkey_valid)
  );

  //--------------------------------------------------------------
  // Mode module instantiations
  //--------------------------------------------------------------
  // Gating input valid signals based on current mode
  logic w_din_valid [0:C_NUM_MODES-1];
  
  genvar gi;
  generate
    for (gi = 0; gi < C_NUM_MODES; gi++) begin : gen_demux
      assign w_din_valid[gi] = (r_internal_mode == gi[2:0]) ? i_aes_din_valid : 1'b0;
    end
  endgenerate

  // 0: ECB
  aes256_mode_ecb u_mode_ecb (
    .i_aes_clk(i_aes_clk), .i_aes_rst_n(i_aes_rst_n),
    .i_aes_enc_dec(r_internal_enc_dec),
    .i_aes_din(i_aes_din), .i_aes_din_valid(w_din_valid[0]), .o_aes_din_ready(w_din_ready[0]),
    .o_aes_dout(w_dout[0]), .o_aes_dout_valid(w_dout_valid[0]), .i_aes_dout_ready(i_aes_dout_ready),
    .i_aes_rkey(w_rkey), .i_aes_rkey_valid(w_rkey_valid)
  );
  assign w_dout_last[0] = r_dout_last_buf;

  // 1: CBC
  aes256_mode_cbc u_mode_cbc (
    .i_aes_clk(i_aes_clk), .i_aes_rst_n(i_aes_rst_n),
    .i_aes_enc_dec(r_internal_enc_dec),
    .i_aes_iv(i_aes_iv), .i_aes_iv_valid(i_aes_iv_valid),
    .i_aes_din(i_aes_din), .i_aes_din_valid(w_din_valid[1]), .o_aes_din_ready(w_din_ready[1]),
    .o_aes_dout(w_dout[1]), .o_aes_dout_valid(w_dout_valid[1]), .i_aes_dout_ready(i_aes_dout_ready),
    .i_aes_rkey(w_rkey), .i_aes_rkey_valid(w_rkey_valid)
  );
  assign w_dout_last[1] = r_dout_last_buf;

  // 2: CTR
  aes256_mode_ctr u_mode_ctr (
    .i_aes_clk(i_aes_clk), .i_aes_rst_n(i_aes_rst_n),
    .i_aes_enc_dec(r_internal_enc_dec),
    .i_aes_iv(i_aes_iv), .i_aes_iv_valid(i_aes_iv_valid),
    .i_aes_din(i_aes_din), .i_aes_din_valid(w_din_valid[2]), .o_aes_din_ready(w_din_ready[2]),
    .o_aes_dout(w_dout[2]), .o_aes_dout_valid(w_dout_valid[2]), .i_aes_dout_ready(i_aes_dout_ready),
    .i_aes_rkey(w_rkey), .i_aes_rkey_valid(w_rkey_valid)
  );
  assign w_dout_last[2] = r_dout_last_buf;

  // 3: CFB
  aes256_mode_cfb u_mode_cfb (
    .i_aes_clk(i_aes_clk), .i_aes_rst_n(i_aes_rst_n),
    .i_aes_enc_dec(r_internal_enc_dec),
    .i_aes_iv(i_aes_iv), .i_aes_iv_valid(i_aes_iv_valid),
    .i_aes_din(i_aes_din), .i_aes_din_valid(w_din_valid[3]), .o_aes_din_ready(w_din_ready[3]),
    .o_aes_dout(w_dout[3]), .o_aes_dout_valid(w_dout_valid[3]), .i_aes_dout_ready(i_aes_dout_ready),
    .i_aes_rkey(w_rkey), .i_aes_rkey_valid(w_rkey_valid)
  );
  assign w_dout_last[3] = r_dout_last_buf;

  // 4: OFB
  aes256_mode_ofb u_mode_ofb (
    .i_aes_clk(i_aes_clk), .i_aes_rst_n(i_aes_rst_n),
    .i_aes_enc_dec(r_internal_enc_dec),
    .i_aes_iv(i_aes_iv), .i_aes_iv_valid(i_aes_iv_valid),
    .i_aes_din(i_aes_din), .i_aes_din_valid(w_din_valid[4]), .o_aes_din_ready(w_din_ready[4]),
    .o_aes_dout(w_dout[4]), .o_aes_dout_valid(w_dout_valid[4]), .i_aes_dout_ready(i_aes_dout_ready),
    .i_aes_rkey(w_rkey), .i_aes_rkey_valid(w_rkey_valid)
  );
  assign w_dout_last[4] = r_dout_last_buf;

  // GCM-specific signals: gated by mode to prevent leaking
  logic         w_gcm_aad_ready;
  logic [127:0] w_gcm_tag;
  logic         w_gcm_tag_valid;
  logic         w_gcm_ready;
  logic [127:0] w_gcm_dout;
  logic         w_gcm_dout_valid;
  logic         w_gcm_dout_last;
  aes256_mode_gcm u_mode_gcm (
    .i_aes_clk(i_aes_clk), .i_aes_rst_n(i_aes_rst_n),
    .i_aes_enc_dec(r_internal_enc_dec),
    .i_aes_iv(i_aes_iv), .i_aes_iv_valid(i_aes_iv_valid),
    
    .i_aes_aad(i_aes_aad), .i_aes_aad_valid(i_aes_aad_valid), 
    .i_aes_aad_last(i_aes_aad_last), .o_aes_aad_ready(w_gcm_aad_ready),
    
    .i_aes_din(i_aes_din), .i_aes_din_valid(w_din_valid[5]), 
    .i_aes_din_last(i_aes_din_last), .o_aes_din_ready(w_gcm_ready),
    
    .o_aes_dout(w_gcm_dout), .o_aes_dout_valid(w_gcm_dout_valid), 
    .o_aes_dout_last(w_gcm_dout_last), .i_aes_dout_ready(i_aes_dout_ready),
    
    .o_aes_tag(w_gcm_tag), .o_aes_tag_valid(w_gcm_tag_valid),
    
    .i_aes_rkey(w_rkey), .i_aes_rkey_valid(w_rkey_valid)
  );
  
  // Gate GCM-specific outputs by mode selection
  assign o_aes_aad_ready = (r_internal_mode == AES_MODE_GCM) ? w_gcm_aad_ready : 1'b0;
  assign o_aes_tag       = (r_internal_mode == AES_MODE_GCM) ? w_gcm_tag       : 128'd0;
  assign o_aes_tag_valid = (r_internal_mode == AES_MODE_GCM) ? w_gcm_tag_valid : 1'b0;

  assign w_dout[5]       = w_gcm_dout;
  assign w_dout_valid[5] = w_gcm_dout_valid;
  assign w_dout_last[5]  = w_gcm_dout_last;
  assign w_din_ready[5]  = w_gcm_ready;

  //--------------------------------------------------------------
  // Output MUXing
  //--------------------------------------------------------------
  always_comb begin
    o_aes_din_ready  = 1'b0;
    o_aes_dout       = 128'd0;
    o_aes_dout_valid = 1'b0;
    o_aes_dout_last  = 1'b0;
    
    case (r_internal_mode)
      AES_MODE_ECB: begin o_aes_din_ready = w_din_ready[0]; o_aes_dout = w_dout[0]; o_aes_dout_valid = w_dout_valid[0]; o_aes_dout_last = w_dout_last[0]; end
      AES_MODE_CBC: begin o_aes_din_ready = w_din_ready[1]; o_aes_dout = w_dout[1]; o_aes_dout_valid = w_dout_valid[1]; o_aes_dout_last = w_dout_last[1]; end
      AES_MODE_CTR: begin o_aes_din_ready = w_din_ready[2]; o_aes_dout = w_dout[2]; o_aes_dout_valid = w_dout_valid[2]; o_aes_dout_last = w_dout_last[2]; end
      AES_MODE_CFB: begin o_aes_din_ready = w_din_ready[3]; o_aes_dout = w_dout[3]; o_aes_dout_valid = w_dout_valid[3]; o_aes_dout_last = w_dout_last[3]; end
      AES_MODE_OFB: begin o_aes_din_ready = w_din_ready[4]; o_aes_dout = w_dout[4]; o_aes_dout_valid = w_dout_valid[4]; o_aes_dout_last = w_dout_last[4]; end
      AES_MODE_GCM: begin o_aes_din_ready = w_din_ready[5]; o_aes_dout = w_dout[5]; o_aes_dout_valid = w_dout_valid[5]; o_aes_dout_last = w_dout_last[5]; end
      default: ;
    endcase
  end

endmodule
