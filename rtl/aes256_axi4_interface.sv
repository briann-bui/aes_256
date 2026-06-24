module aes256_axi4_interface
  import aes256_pkg::*;
#(
  parameter int C_S_AXI_DATA_WIDTH = 32,
  parameter int C_S_AXI_ADDR_WIDTH = 8
)
(
  input  logic                                i_aes_aclk,
  input  logic                                i_aes_aresetn,

  input  logic [C_S_AXI_ADDR_WIDTH-1:0]       i_aes_awaddr,
  input  logic [2:0]                          i_aes_awprot,
  input  logic                                i_aes_awvalid,
  output logic                                o_aes_awready,

  input  logic [C_S_AXI_DATA_WIDTH-1:0]       i_aes_wdata,
  input  logic [(C_S_AXI_DATA_WIDTH/8)-1:0]   i_aes_wstrb,
  input  logic                                i_aes_wvalid,
  output logic                                o_aes_wready,

  output logic [1:0]                          o_aes_bresp,
  output logic                                o_aes_bvalid,
  input  logic                                i_aes_bready,

  input  logic [C_S_AXI_ADDR_WIDTH-1:0]       i_aes_araddr,
  input  logic [2:0]                          i_aes_arprot,
  input  logic                                i_aes_arvalid,
  output logic                                o_aes_arready,

  output logic [C_S_AXI_DATA_WIDTH-1:0]       o_aes_rdata,
  output logic [1:0]                          o_aes_rresp,
  output logic                                o_aes_rvalid,
  input  logic                                i_aes_rready,

  output logic                                o_aes_irq
);

  localparam logic [C_S_AXI_ADDR_WIDTH-1:0] ADDR_CTRL     = 8'h00;
  localparam logic [C_S_AXI_ADDR_WIDTH-1:0] ADDR_STATUS   = 8'h04;
  localparam logic [C_S_AXI_ADDR_WIDTH-1:0] ADDR_IRQ_EN   = 8'h08;
  localparam logic [C_S_AXI_ADDR_WIDTH-1:0] ADDR_IRQ_STAT = 8'h0C;
  localparam logic [C_S_AXI_ADDR_WIDTH-1:0] ADDR_KEY0     = 8'h10;
  localparam logic [C_S_AXI_ADDR_WIDTH-1:0] ADDR_KEY1     = 8'h14;
  localparam logic [C_S_AXI_ADDR_WIDTH-1:0] ADDR_KEY2     = 8'h18;
  localparam logic [C_S_AXI_ADDR_WIDTH-1:0] ADDR_KEY3     = 8'h1C;
  localparam logic [C_S_AXI_ADDR_WIDTH-1:0] ADDR_KEY4     = 8'h20;
  localparam logic [C_S_AXI_ADDR_WIDTH-1:0] ADDR_KEY5     = 8'h24;
  localparam logic [C_S_AXI_ADDR_WIDTH-1:0] ADDR_KEY6     = 8'h28;
  localparam logic [C_S_AXI_ADDR_WIDTH-1:0] ADDR_KEY7     = 8'h2C;
  localparam logic [C_S_AXI_ADDR_WIDTH-1:0] ADDR_IV0      = 8'h30;
  localparam logic [C_S_AXI_ADDR_WIDTH-1:0] ADDR_IV1      = 8'h34;
  localparam logic [C_S_AXI_ADDR_WIDTH-1:0] ADDR_IV2      = 8'h38;
  localparam logic [C_S_AXI_ADDR_WIDTH-1:0] ADDR_IV3      = 8'h3C;
  localparam logic [C_S_AXI_ADDR_WIDTH-1:0] ADDR_DIN0     = 8'h40;
  localparam logic [C_S_AXI_ADDR_WIDTH-1:0] ADDR_DIN1     = 8'h44;
  localparam logic [C_S_AXI_ADDR_WIDTH-1:0] ADDR_DIN2     = 8'h48;
  localparam logic [C_S_AXI_ADDR_WIDTH-1:0] ADDR_DIN3     = 8'h4C;
  localparam logic [C_S_AXI_ADDR_WIDTH-1:0] ADDR_DOUT0    = 8'h50;
  localparam logic [C_S_AXI_ADDR_WIDTH-1:0] ADDR_DOUT1    = 8'h54;
  localparam logic [C_S_AXI_ADDR_WIDTH-1:0] ADDR_DOUT2    = 8'h58;
  localparam logic [C_S_AXI_ADDR_WIDTH-1:0] ADDR_DOUT3    = 8'h5C;
  localparam logic [C_S_AXI_ADDR_WIDTH-1:0] ADDR_AAD0     = 8'h60;
  localparam logic [C_S_AXI_ADDR_WIDTH-1:0] ADDR_AAD1     = 8'h64;
  localparam logic [C_S_AXI_ADDR_WIDTH-1:0] ADDR_AAD2     = 8'h68;
  localparam logic [C_S_AXI_ADDR_WIDTH-1:0] ADDR_AAD3     = 8'h6C;
  localparam logic [C_S_AXI_ADDR_WIDTH-1:0] ADDR_TAG0     = 8'h70;
  localparam logic [C_S_AXI_ADDR_WIDTH-1:0] ADDR_TAG1     = 8'h74;
  localparam logic [C_S_AXI_ADDR_WIDTH-1:0] ADDR_TAG2     = 8'h78;
  localparam logic [C_S_AXI_ADDR_WIDTH-1:0] ADDR_TAG3     = 8'h7C;
  localparam logic [C_S_AXI_ADDR_WIDTH-1:0] ADDR_DIN_CTRL = 8'h80;
  localparam logic [C_S_AXI_ADDR_WIDTH-1:0] ADDR_VERSION  = 8'h84;

  localparam logic [31:0] IP_VERSION = 32'h0001_0000;

  logic [C_S_AXI_ADDR_WIDTH-1:0]  r_awaddr;
  logic                           r_awready;
  logic                           r_wready;
  logic [1:0]                     r_bresp;
  logic                           r_bvalid;
  logic [C_S_AXI_ADDR_WIDTH-1:0]  r_araddr;
  logic                           r_arready;
  logic [C_S_AXI_DATA_WIDTH-1:0]  r_rdata;
  logic [1:0]                     r_rresp;
  logic                           r_rvalid;

  logic                           r_aw_en;

  logic [31:0]                    r_ctrl;
  logic [31:0]                    r_irq_en;
  logic [31:0]                    r_irq_stat;
  logic [31:0]                    r_din_ctrl;

  logic [31:0]                    r_key       [0:7];
  logic [31:0]                    r_iv        [0:3];
  logic [31:0]                    r_din       [0:3];
  logic [31:0]                    r_aad       [0:3];

  logic                           r_start_d;
  logic                           w_start_pulse;
  logic                           r_key_wr_done;
  logic                           r_iv_wr_done;
  logic                           r_din_wr_done;
  logic                           r_aad_wr_done;
  logic [7:0]                     r_key_wr_mask;
  logic [3:0]                     r_iv_wr_mask;
  logic [3:0]                     r_din_wr_mask;
  logic [3:0]                     r_aad_wr_mask;

  logic                           w_core_key_valid;
  logic                           w_core_key_ready;
  logic                           w_core_iv_valid;
  logic                           w_core_din_valid;
  logic                           w_core_din_ready;
  logic                           w_core_aad_valid;
  logic                           w_core_aad_ready;
  logic [127:0]                   w_core_dout;
  logic                           w_core_dout_valid;
  logic                           w_core_dout_last;
  logic [127:0]                   w_core_tag;
  logic                           w_core_tag_valid;
  logic                           w_core_busy;
  logic                           w_core_err;
  logic                           w_core_irq;

  logic                           r_done;
  logic                           r_dout_ready;
  logic [127:0]                   r_core_dout_buf;
  logic [127:0]                   r_core_tag_buf;
  logic                           w_wr_en;

  always_ff @(posedge i_aes_aclk or negedge i_aes_aresetn) begin
    if (!i_aes_aresetn) begin
      r_awready <= 1'b0;
      r_awaddr  <= '0;
      r_aw_en   <= 1'b1;
    end else begin
      if (~r_awready && i_aes_awvalid && i_aes_wvalid && r_aw_en) begin
        r_awready <= 1'b1;
        r_awaddr  <= i_aes_awaddr;
        r_aw_en   <= 1'b0;
      end else if (i_aes_bready && r_bvalid) begin
        r_aw_en   <= 1'b1;
        r_awready <= 1'b0;
      end else begin
        r_awready <= 1'b0;
      end
    end
  end

  assign o_aes_awready = r_awready;

  always_ff @(posedge i_aes_aclk or negedge i_aes_aresetn) begin
    if (!i_aes_aresetn) begin
      r_wready <= 1'b0;
    end else begin
      if (~r_wready && i_aes_wvalid && i_aes_awvalid && r_aw_en) begin
        r_wready <= 1'b1;
      end else begin
        r_wready <= 1'b0;
      end
    end
  end

  assign o_aes_wready = r_wready;

  assign w_wr_en = r_wready && i_aes_wvalid && r_awready && i_aes_awvalid;

  always_ff @(posedge i_aes_aclk or negedge i_aes_aresetn) begin
    if (!i_aes_aresetn) begin
      r_ctrl        <= 32'd0;
      r_irq_en      <= 32'd0;
      r_din_ctrl    <= 32'd0;
      for (int i = 0; i < 8; i++) r_key[i] <= 32'd0;
      for (int i = 0; i < 4; i++) r_iv[i]  <= 32'd0;
      for (int i = 0; i < 4; i++) r_din[i] <= 32'd0;
      for (int i = 0; i < 4; i++) r_aad[i] <= 32'd0;
      r_key_wr_mask <= 8'd0;
      r_iv_wr_mask  <= 4'd0;
      r_din_wr_mask <= 4'd0;
      r_aad_wr_mask <= 4'd0;
    end else begin
      if (w_start_pulse)  r_ctrl[0] <= 1'b0;
      if (r_key_wr_done)  r_key_wr_mask <= 8'd0;
      if (r_iv_wr_done)   r_iv_wr_mask  <= 4'd0;
      if (r_din_wr_done)  r_din_wr_mask <= 4'd0;
      if (r_aad_wr_done)  r_aad_wr_mask <= 4'd0;

      if (w_wr_en) begin
        case (r_awaddr)
          ADDR_CTRL     : r_ctrl     <= i_aes_wdata;
          ADDR_IRQ_EN   : r_irq_en   <= i_aes_wdata;
          ADDR_DIN_CTRL : r_din_ctrl <= i_aes_wdata;

          ADDR_KEY0 : begin r_key[0] <= i_aes_wdata; r_key_wr_mask[0] <= 1'b1; end
          ADDR_KEY1 : begin r_key[1] <= i_aes_wdata; r_key_wr_mask[1] <= 1'b1; end
          ADDR_KEY2 : begin r_key[2] <= i_aes_wdata; r_key_wr_mask[2] <= 1'b1; end
          ADDR_KEY3 : begin r_key[3] <= i_aes_wdata; r_key_wr_mask[3] <= 1'b1; end
          ADDR_KEY4 : begin r_key[4] <= i_aes_wdata; r_key_wr_mask[4] <= 1'b1; end
          ADDR_KEY5 : begin r_key[5] <= i_aes_wdata; r_key_wr_mask[5] <= 1'b1; end
          ADDR_KEY6 : begin r_key[6] <= i_aes_wdata; r_key_wr_mask[6] <= 1'b1; end
          ADDR_KEY7 : begin r_key[7] <= i_aes_wdata; r_key_wr_mask[7] <= 1'b1; end

          ADDR_IV0 : begin r_iv[0] <= i_aes_wdata; r_iv_wr_mask[0] <= 1'b1; end
          ADDR_IV1 : begin r_iv[1] <= i_aes_wdata; r_iv_wr_mask[1] <= 1'b1; end
          ADDR_IV2 : begin r_iv[2] <= i_aes_wdata; r_iv_wr_mask[2] <= 1'b1; end
          ADDR_IV3 : begin r_iv[3] <= i_aes_wdata; r_iv_wr_mask[3] <= 1'b1; end

          ADDR_DIN0 : begin r_din[0] <= i_aes_wdata; r_din_wr_mask[0] <= 1'b1; end
          ADDR_DIN1 : begin r_din[1] <= i_aes_wdata; r_din_wr_mask[1] <= 1'b1; end
          ADDR_DIN2 : begin r_din[2] <= i_aes_wdata; r_din_wr_mask[2] <= 1'b1; end
          ADDR_DIN3 : begin r_din[3] <= i_aes_wdata; r_din_wr_mask[3] <= 1'b1; end

          ADDR_AAD0 : begin r_aad[0] <= i_aes_wdata; r_aad_wr_mask[0] <= 1'b1; end
          ADDR_AAD1 : begin r_aad[1] <= i_aes_wdata; r_aad_wr_mask[1] <= 1'b1; end
          ADDR_AAD2 : begin r_aad[2] <= i_aes_wdata; r_aad_wr_mask[2] <= 1'b1; end
          ADDR_AAD3 : begin r_aad[3] <= i_aes_wdata; r_aad_wr_mask[3] <= 1'b1; end

          default : ;
        endcase
      end
    end
  end

  always_ff @(posedge i_aes_aclk or negedge i_aes_aresetn) begin
    if (!i_aes_aresetn) begin
      r_irq_stat <= 32'd0;
    end else begin
      if (w_core_dout_valid && r_dout_ready) r_irq_stat[0] <= 1'b1;
      if (w_core_tag_valid)                  r_irq_stat[1] <= 1'b1;
      if (w_wr_en && (r_awaddr == ADDR_IRQ_STAT)) begin
        r_irq_stat <= r_irq_stat & ~i_aes_wdata;
      end
    end
  end

  always_ff @(posedge i_aes_aclk or negedge i_aes_aresetn) begin
    if (!i_aes_aresetn) begin
      r_start_d <= 1'b0;
    end else begin
      r_start_d <= r_ctrl[0];
    end
  end

  assign w_start_pulse  = r_ctrl[0] & ~r_start_d;

  assign r_key_wr_done  = (r_key_wr_mask == 8'hFF);
  assign r_iv_wr_done   = (r_iv_wr_mask  == 4'hF);
  assign r_din_wr_done  = (r_din_wr_mask == 4'hF);
  assign r_aad_wr_done  = (r_aad_wr_mask == 4'hF);

  assign w_core_key_valid = r_key_wr_done;
  assign w_core_iv_valid  = r_iv_wr_done;
  assign w_core_din_valid = r_din_wr_done;
  assign w_core_aad_valid = r_aad_wr_done;

  always_ff @(posedge i_aes_aclk or negedge i_aes_aresetn) begin
    if (!i_aes_aresetn) begin
      r_done          <= 1'b0;
      r_dout_ready    <= 1'b1;
      r_core_dout_buf <= 128'd0;
      r_core_tag_buf  <= 128'd0;
    end else begin
      if (w_core_dout_valid && r_dout_ready) begin
        r_done          <= 1'b1;
        r_dout_ready    <= 1'b0;
        r_core_dout_buf <= w_core_dout;
      end
      if (w_core_tag_valid) begin
        r_core_tag_buf  <= w_core_tag;
      end
      if (w_start_pulse) begin
        r_done       <= 1'b0;
        r_dout_ready <= 1'b1;
      end
      if (w_wr_en && (r_awaddr == ADDR_IRQ_STAT) && i_aes_wdata[0]) begin
        r_done       <= 1'b0;
        r_dout_ready <= 1'b1;
      end
    end
  end

  always_ff @(posedge i_aes_aclk or negedge i_aes_aresetn) begin
    if (!i_aes_aresetn) begin
      r_bvalid <= 1'b0;
      r_bresp  <= 2'b00;
    end else begin
      if (r_awready && i_aes_awvalid && ~r_bvalid && r_wready && i_aes_wvalid) begin
        r_bvalid <= 1'b1;
        r_bresp  <= 2'b00;
      end else if (i_aes_bready && r_bvalid) begin
        r_bvalid <= 1'b0;
      end
    end
  end

  assign o_aes_bresp  = r_bresp;
  assign o_aes_bvalid = r_bvalid;

  always_ff @(posedge i_aes_aclk or negedge i_aes_aresetn) begin
    if (!i_aes_aresetn) begin
      r_arready <= 1'b0;
      r_araddr  <= '0;
    end else begin
      if (~r_arready && i_aes_arvalid) begin
        r_arready <= 1'b1;
        r_araddr  <= i_aes_araddr;
      end else begin
        r_arready <= 1'b0;
      end
    end
  end

  assign o_aes_arready = r_arready;

  always_ff @(posedge i_aes_aclk or negedge i_aes_aresetn) begin
    if (!i_aes_aresetn) begin
      r_rvalid <= 1'b0;
      r_rresp  <= 2'b00;
    end else begin
      if (r_arready && i_aes_arvalid && ~r_rvalid) begin
        r_rvalid <= 1'b1;
        r_rresp  <= 2'b00;
      end else if (r_rvalid && i_aes_rready) begin
        r_rvalid <= 1'b0;
      end
    end
  end

  assign o_aes_rvalid = r_rvalid;
  assign o_aes_rresp  = r_rresp;

  always_comb begin
    r_rdata = 32'd0;
    case (r_araddr)
      ADDR_CTRL     : r_rdata = r_ctrl;
      ADDR_STATUS   : r_rdata = {28'd0, w_core_err, w_core_key_ready, r_done, w_core_busy};
      ADDR_IRQ_EN   : r_rdata = r_irq_en;
      ADDR_IRQ_STAT : r_rdata = r_irq_stat;
      ADDR_KEY0     : r_rdata = r_key[0];
      ADDR_KEY1     : r_rdata = r_key[1];
      ADDR_KEY2     : r_rdata = r_key[2];
      ADDR_KEY3     : r_rdata = r_key[3];
      ADDR_KEY4     : r_rdata = r_key[4];
      ADDR_KEY5     : r_rdata = r_key[5];
      ADDR_KEY6     : r_rdata = r_key[6];
      ADDR_KEY7     : r_rdata = r_key[7];
      ADDR_IV0      : r_rdata = r_iv[0];
      ADDR_IV1      : r_rdata = r_iv[1];
      ADDR_IV2      : r_rdata = r_iv[2];
      ADDR_IV3      : r_rdata = r_iv[3];
      ADDR_DIN0     : r_rdata = r_din[0];
      ADDR_DIN1     : r_rdata = r_din[1];
      ADDR_DIN2     : r_rdata = r_din[2];
      ADDR_DIN3     : r_rdata = r_din[3];
      ADDR_DOUT0    : r_rdata = r_core_dout_buf[127:96];
      ADDR_DOUT1    : r_rdata = r_core_dout_buf[95:64];
      ADDR_DOUT2    : r_rdata = r_core_dout_buf[63:32];
      ADDR_DOUT3    : r_rdata = r_core_dout_buf[31:0];
      ADDR_AAD0     : r_rdata = r_aad[0];
      ADDR_AAD1     : r_rdata = r_aad[1];
      ADDR_AAD2     : r_rdata = r_aad[2];
      ADDR_AAD3     : r_rdata = r_aad[3];
      ADDR_TAG0     : r_rdata = r_core_tag_buf[127:96];
      ADDR_TAG1     : r_rdata = r_core_tag_buf[95:64];
      ADDR_TAG2     : r_rdata = r_core_tag_buf[63:32];
      ADDR_TAG3     : r_rdata = r_core_tag_buf[31:0];
      ADDR_DIN_CTRL : r_rdata = r_din_ctrl;
      ADDR_VERSION  : r_rdata = IP_VERSION;
      default       : r_rdata = 32'd0;
    endcase
  end

  assign o_aes_rdata = r_rdata;
  assign o_aes_irq   = |(r_irq_stat & r_irq_en);

  aes256_top_core u_aes_top_core (
    .i_aes_clk        (i_aes_aclk),
    .i_aes_rst_n      (i_aes_aresetn),
    .i_aes_mode       (r_ctrl[4:2]),
    .i_aes_enc_dec    (r_ctrl[1]),
    .i_aes_key        ({r_key[0], r_key[1], r_key[2], r_key[3],
                        r_key[4], r_key[5], r_key[6], r_key[7]}),
    .i_aes_key_valid  (w_core_key_valid),
    .o_aes_key_ready  (w_core_key_ready),
    .i_aes_iv         ({r_iv[0], r_iv[1], r_iv[2], r_iv[3]}),
    .i_aes_iv_valid   (w_core_iv_valid),
    .i_aes_din        ({r_din[0], r_din[1], r_din[2], r_din[3]}),
    .i_aes_din_valid  (w_core_din_valid),
    .i_aes_din_last   (r_din_ctrl[0]),
    .o_aes_din_ready  (w_core_din_ready),
    .o_aes_dout       (w_core_dout),
    .o_aes_dout_valid (w_core_dout_valid),
    .o_aes_dout_last  (w_core_dout_last),
    .i_aes_dout_ready (r_dout_ready),
    .i_aes_aad        ({r_aad[0], r_aad[1], r_aad[2], r_aad[3]}),
    .i_aes_aad_valid  (w_core_aad_valid),
    .i_aes_aad_last   (r_din_ctrl[1]),
    .o_aes_aad_ready  (w_core_aad_ready),
    .o_aes_tag        (w_core_tag),
    .o_aes_tag_valid  (w_core_tag_valid),
    .o_aes_busy       (w_core_busy),
    .o_aes_err        (w_core_err),
    .o_aes_irq        (w_core_irq)
  );

endmodule
