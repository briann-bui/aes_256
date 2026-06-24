class aes256_axi_monitor extends uvm_component;
  `uvm_component_utils(aes256_axi_monitor)

  virtual aes256_axi_if vif;
  uvm_analysis_port #(aes256_axi_item) ap;
  bit [7:0] pending_araddr;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual aes256_axi_if)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", "Missing aes256_axi_if for monitor")
  endfunction

  task run_phase(uvm_phase phase);
    forever begin
      @(posedge vif.aclk);
      if (!vif.aresetn) begin
        pending_araddr = '0;
      end else begin
        if (vif.awvalid && vif.awready && vif.wvalid && vif.wready) begin
          aes256_axi_item wr = aes256_axi_item::type_id::create("wr");
          wr.cmd  = AES256_AXI_WRITE;
          wr.addr = vif.awaddr;
          wr.data = vif.wdata;
          wr.strb = vif.wstrb;
          ap.write(wr);
        end

        if (vif.arvalid && vif.arready)
          pending_araddr = vif.araddr;

        if (vif.rvalid && vif.rready) begin
          aes256_axi_item rd = aes256_axi_item::type_id::create("rd");
          rd.cmd  = AES256_AXI_READ;
          rd.addr = pending_araddr;
          rd.data = vif.rdata;
          rd.resp = vif.rresp;
          ap.write(rd);
        end
      end
    end
  endtask
endclass
