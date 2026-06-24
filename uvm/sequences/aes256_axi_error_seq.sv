class aes256_axi_error_seq extends aes256_base_seq;
  `uvm_object_utils(aes256_axi_error_seq)

  function new(string name = "aes256_axi_error_seq");
    super.new(name);
  endfunction

  task body();
    bit [31:0] rdata;
    
    `uvm_info("AXI_ERR", "Testing write to read-only STATUS register", UVM_LOW)
    axi_read(`AES256_ADDR_STATUS, rdata);
    axi_write(`AES256_ADDR_STATUS, 32'hFFFF_FFFF);
    axi_read(`AES256_ADDR_STATUS, rdata);
    if (rdata == 32'hFFFF_FFFF)
      `uvm_error("AXI_ERR", "STATUS register was overwritten!")
      
    `uvm_info("AXI_ERR", "Testing read from unmapped address (0x88)", UVM_LOW)
    axi_read(8'h88, rdata);
    if (rdata != 32'h0000_0000)
      `uvm_error("AXI_ERR", $sformatf("Unmapped address returned 0x%08h", rdata))

    `uvm_info("AXI_ERR", "Testing write to unmapped address (0x88)", UVM_LOW)
    axi_write(8'h88, 32'hDEADBEEF);
    axi_read(8'h88, rdata);
    if (rdata == 32'hDEADBEEF)
      `uvm_error("AXI_ERR", "Unmapped address stored data!")

    `uvm_info("AXI_ERR", "Testing write to read-only VERSION register", UVM_LOW)
    axi_read(`AES256_ADDR_VERSION, rdata);
    if (rdata != `AES256_IP_VERSION)
      `uvm_error("AXI_ERR", $sformatf("VERSION mismatch: got 0x%08h expected 0x%08h", rdata, `AES256_IP_VERSION))

    axi_write(`AES256_ADDR_VERSION, 32'hDEADBEEF);
    axi_read(`AES256_ADDR_VERSION, rdata);
    if (rdata == 32'hDEADBEEF)
      `uvm_error("AXI_ERR", "VERSION register was overwritten!")

    `uvm_info("AXI_ERR", "AXI error checking finished.", UVM_LOW)
  endtask
endclass
