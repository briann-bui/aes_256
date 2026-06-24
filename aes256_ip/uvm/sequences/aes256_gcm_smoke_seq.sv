class aes256_gcm_smoke_seq extends aes256_base_seq;
  `uvm_object_utils(aes256_gcm_smoke_seq)

  function new(string name = "aes256_gcm_smoke_seq");
    super.new(name);
  endfunction

  task body();
    bit [127:0] dout;
    bit [127:0] tag;
    bit [31:0] irq_stat;

    axi_write(`AES256_ADDR_CTRL, ctrl_value(1'b0, 1'b1, `AES256_MODE_GCM));
    write_key(256'h000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f);
    wait_key_expand_done();
    write_block(`AES256_ADDR_IV0,  128'hcafebabefacedbaddecaf88800000001);
    axi_write(`AES256_ADDR_IRQ_EN, 32'h0000_0003);
    axi_write(`AES256_ADDR_CTRL, ctrl_value(1'b1, 1'b1, `AES256_MODE_GCM));
    axi_write(`AES256_ADDR_DIN_CTRL, 32'h0000_0003);
    idle_status_reads(40);
    write_block(`AES256_ADDR_AAD0, 128'hfeedfacedeadbeeffeedfacedeadbeef);
    write_block(`AES256_ADDR_DIN0, 128'hd9313225f88406e5a55909c5aff5269a);
    wait_status_done();
    wait_irq_stat(32'h0000_0003);
    read_block(`AES256_ADDR_DOUT0, dout);
    read_block(`AES256_ADDR_TAG0, tag);
    axi_read(`AES256_ADDR_IRQ_STAT, irq_stat);
    if ((irq_stat & 32'h3) != 32'h3)
      `uvm_error("GCM", $sformatf("Expected data/tag IRQ bits, got 0x%08h", irq_stat))
    if (tag == 128'd0)
      `uvm_error("GCM", "GCM tag is all zero")
  endtask
endclass
