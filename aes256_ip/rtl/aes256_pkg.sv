package aes256_pkg;

  localparam int C_NR        = 14;
  localparam int C_NK        = 8;
  localparam int C_KEY_LEN   = 256;
  localparam int C_BLOCK_LEN = 128;
  localparam int C_NB        = 4;
  localparam int C_RKEY_NUM  = C_NR + 1;

  typedef enum logic [2:0] {
    AES_MODE_ECB = 3'b000,
    AES_MODE_CBC = 3'b001,
    AES_MODE_CTR = 3'b010,
    AES_MODE_CFB = 3'b011,
    AES_MODE_OFB = 3'b100,
    AES_MODE_GCM = 3'b101
  } t_aes_mode_e;

  typedef logic [7:0] t_state_t [0:3][0:3];

  typedef logic [127:0] t_round_key_arr_t [0:C_NR];

  typedef enum logic [1:0] {
    KEY_IDLE   = 2'b00,
    KEY_EXPAND = 2'b01,
    KEY_DONE   = 2'b10
  } t_key_fsm_e;

  typedef enum logic [1:0] {
    DP_IDLE   = 2'b00,
    DP_LOAD   = 2'b01,
    DP_ROUND  = 2'b10,
    DP_OUTPUT = 2'b11
  } t_dp_fsm_e;

  typedef logic [7:0] t_rcon_arr_t [0:9];

  localparam t_rcon_arr_t C_RCON = '{
    8'h01, 8'h02, 8'h04, 8'h08, 8'h10,
    8'h20, 8'h40, 8'h80, 8'h1B, 8'h36
  };

  function automatic t_state_t f_flat_to_state(input logic [127:0] flat);
    t_state_t w_state;
    for (int col = 0; col < 4; col++) begin
      for (int row = 0; row < 4; row++) begin
        w_state[row][col] = flat[127 - 8*(4*col + row) -: 8];
      end
    end
    return w_state;
  endfunction

  function automatic logic [127:0] f_state_to_flat(input t_state_t state);
    logic [127:0] w_flat;
    for (int col = 0; col < 4; col++) begin
      for (int row = 0; row < 4; row++) begin
        w_flat[127 - 8*(4*col + row) -: 8] = state[row][col];
      end
    end
    return w_flat;
  endfunction

  function automatic logic [7:0] f_xtime(input logic [7:0] b);
    return {b[6:0], 1'b0} ^ (8'h1B & {8{b[7]}});
  endfunction

  function automatic logic [7:0] f_gf_mul(input logic [7:0] a, input logic [7:0] b);
    logic [7:0] w_result;
    logic [7:0] w_tmp;
    w_result = 8'h00;
    w_tmp    = a;
    for (int i = 0; i < 8; i++) begin
      if (b[i])
        w_result = w_result ^ w_tmp;
      w_tmp = f_xtime(w_tmp);
    end
    return w_result;
  endfunction

endpackage
