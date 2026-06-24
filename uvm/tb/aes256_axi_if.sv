interface aes256_axi_if #(
  parameter int C_S_AXI_DATA_WIDTH = 32,
  parameter int C_S_AXI_ADDR_WIDTH = 8
) (
  input logic aclk
);

  logic                              aresetn;
  logic [C_S_AXI_ADDR_WIDTH-1:0]     awaddr;
  logic [2:0]                        awprot;
  logic                              awvalid;
  logic                              awready;
  logic [C_S_AXI_DATA_WIDTH-1:0]     wdata;
  logic [(C_S_AXI_DATA_WIDTH/8)-1:0] wstrb;
  logic                              wvalid;
  logic                              wready;
  logic [1:0]                        bresp;
  logic                              bvalid;
  logic                              bready;
  logic [C_S_AXI_ADDR_WIDTH-1:0]     araddr;
  logic [2:0]                        arprot;
  logic                              arvalid;
  logic                              arready;
  logic [C_S_AXI_DATA_WIDTH-1:0]     rdata;
  logic [1:0]                        rresp;
  logic                              rvalid;
  logic                              rready;
  logic                              irq;

  task automatic init_master();
    awaddr  <= '0;
    awprot  <= '0;
    awvalid <= 1'b0;
    wdata   <= '0;
    wstrb   <= '0;
    wvalid  <= 1'b0;
    bready  <= 1'b0;
    araddr  <= '0;
    arprot  <= '0;
    arvalid <= 1'b0;
    rready  <= 1'b0;
  endtask

endinterface
