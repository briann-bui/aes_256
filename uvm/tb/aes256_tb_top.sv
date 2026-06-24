`timescale 1ns/1ps

module aes256_tb_top;
  import uvm_pkg::*;
  import aes256_uvm_pkg::*;

  bit aclk;

  always #5 aclk = ~aclk;

  aes256_axi_if aes_if(.aclk(aclk));

  aes256_wrapper dut (
    .i_aes_aclk    (aclk),
    .i_aes_aresetn (aes_if.aresetn),
    .i_aes_awaddr  (aes_if.awaddr),
    .i_aes_awprot  (aes_if.awprot),
    .i_aes_awvalid (aes_if.awvalid),
    .o_aes_awready (aes_if.awready),
    .i_aes_wdata   (aes_if.wdata),
    .i_aes_wstrb   (aes_if.wstrb),
    .i_aes_wvalid  (aes_if.wvalid),
    .o_aes_wready  (aes_if.wready),
    .o_aes_bresp   (aes_if.bresp),
    .o_aes_bvalid  (aes_if.bvalid),
    .i_aes_bready  (aes_if.bready),
    .i_aes_araddr  (aes_if.araddr),
    .i_aes_arprot  (aes_if.arprot),
    .i_aes_arvalid (aes_if.arvalid),
    .o_aes_arready (aes_if.arready),
    .o_aes_rdata   (aes_if.rdata),
    .o_aes_rresp   (aes_if.rresp),
    .o_aes_rvalid  (aes_if.rvalid),
    .i_aes_rready  (aes_if.rready),
    .o_aes_irq     (aes_if.irq)
  );

  initial begin
    aes_if.init_master();
    aes_if.aresetn = 1'b0;
    repeat (8) @(posedge aclk);
    aes_if.aresetn = 1'b1;
  end

  initial begin
    uvm_config_db#(virtual aes256_axi_if)::set(null, "uvm_test_top*", "vif", aes_if);
    uvm_config_db#(virtual aes256_axi_if)::set(null, "uvm_test_top.env.agent*", "vif", aes_if);
    run_test();
  end

endmodule
