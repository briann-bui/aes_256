class aes256_axi_driver extends uvm_driver #(aes256_axi_item);
  `uvm_component_utils(aes256_axi_driver)

  virtual aes256_axi_if vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual aes256_axi_if)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", "Missing aes256_axi_if for driver")
  endfunction

  task run_phase(uvm_phase phase);
    aes256_axi_item tr;
    vif.init_master();
    wait (vif.aresetn == 1'b1);
    forever begin
      seq_item_port.get_next_item(tr);
      case (tr.cmd)
        AES256_AXI_WRITE: axi_write(tr);
        AES256_AXI_READ : axi_read(tr);
        default         : `uvm_error("DRV", "Unsupported AXI command")
      endcase
      seq_item_port.item_done();
    end
  endtask

  task automatic axi_write(aes256_axi_item tr);
    @(posedge vif.aclk);
    vif.awaddr  <= tr.addr;
    vif.awprot  <= 3'b000;
    vif.awvalid <= 1'b1;
    vif.wdata   <= tr.data;
    vif.wstrb   <= tr.strb;
    vif.wvalid  <= 1'b1;
    vif.bready  <= 1'b1;

    do @(posedge vif.aclk);
    while (!(vif.awready && vif.wready));

    vif.awvalid <= 1'b0;
    vif.wvalid  <= 1'b0;
    vif.awaddr  <= '0;
    vif.wdata   <= '0;
    vif.wstrb   <= '0;

    do @(posedge vif.aclk);
    while (!vif.bvalid);

    tr.resp = vif.bresp;
    @(posedge vif.aclk);
    vif.bready <= 1'b0;

    if (tr.resp != 2'b00)
      `uvm_error("AXI_WR", $sformatf("BRESP error addr=0x%02h resp=%0d", tr.addr, tr.resp))
  endtask

  task automatic axi_read(aes256_axi_item tr);
    @(posedge vif.aclk);
    vif.araddr  <= tr.addr;
    vif.arprot  <= 3'b000;
    vif.arvalid <= 1'b1;
    vif.rready  <= 1'b1;

    do @(posedge vif.aclk);
    while (!vif.arready);

    vif.arvalid <= 1'b0;
    vif.araddr  <= '0;

    do @(posedge vif.aclk);
    while (!vif.rvalid);

    tr.data = vif.rdata;
    tr.resp = vif.rresp;
    @(posedge vif.aclk);
    vif.rready <= 1'b0;

    if (tr.resp != 2'b00)
      `uvm_error("AXI_RD", $sformatf("RRESP error addr=0x%02h resp=%0d", tr.addr, tr.resp))
  endtask
endclass
