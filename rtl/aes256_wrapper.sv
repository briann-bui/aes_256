module aes256_wrapper
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

  aes256_axi4_interface #(
    .C_S_AXI_DATA_WIDTH  (C_S_AXI_DATA_WIDTH),
    .C_S_AXI_ADDR_WIDTH  (C_S_AXI_ADDR_WIDTH)
  ) u_aes_axi4 (
    .i_aes_aclk          (i_aes_aclk),
    .i_aes_aresetn       (i_aes_aresetn),
    .i_aes_awaddr        (i_aes_awaddr),
    .i_aes_awprot        (i_aes_awprot),
    .i_aes_awvalid       (i_aes_awvalid),
    .o_aes_awready       (o_aes_awready),
    .i_aes_wdata         (i_aes_wdata),
    .i_aes_wstrb         (i_aes_wstrb),
    .i_aes_wvalid        (i_aes_wvalid),
    .o_aes_wready        (o_aes_wready),
    .o_aes_bresp         (o_aes_bresp),
    .o_aes_bvalid        (o_aes_bvalid),
    .i_aes_bready        (i_aes_bready),
    .i_aes_araddr        (i_aes_araddr),
    .i_aes_arprot        (i_aes_arprot),
    .i_aes_arvalid       (i_aes_arvalid),
    .o_aes_arready       (o_aes_arready),
    .o_aes_rdata         (o_aes_rdata),
    .o_aes_rresp         (o_aes_rresp),
    .o_aes_rvalid        (o_aes_rvalid),
    .i_aes_rready        (i_aes_rready),
    .o_aes_irq           (o_aes_irq)
  );

endmodule
