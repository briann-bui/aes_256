class aes256_reg_smoke_seq extends aes256_base_seq;
  `uvm_object_utils(aes256_reg_smoke_seq)

  function new(string name = "aes256_reg_smoke_seq");
    super.new(name);
  endfunction

  task body();
    bit [31:0] data;

    axi_read(`AES256_ADDR_VERSION, data);
    if (data != `AES256_IP_VERSION)
      `uvm_error("REG", $sformatf("VERSION got 0x%08h expected 0x%08h", data, `AES256_IP_VERSION))

    axi_read(`AES256_ADDR_CTRL, data);
    if (data != 32'd0)
      `uvm_error("RESET", $sformatf("CTRL reset value got 0x%08h", data))

    axi_write(`AES256_ADDR_IRQ_EN, 32'h0000_0003);
    axi_read(`AES256_ADDR_IRQ_EN, data);
    if (data != 32'h0000_0003)
      `uvm_error("REG", "IRQ_EN readback mismatch")

    axi_write(`AES256_ADDR_DIN_CTRL, 32'h0000_0003);
    axi_read(`AES256_ADDR_DIN_CTRL, data);
    if (data != 32'h0000_0003)
      `uvm_error("REG", "DIN_CTRL readback mismatch")

    for (int i = 0; i < 8; i++) begin
      axi_write(`AES256_ADDR_KEY0 + i*4, 32'hA500_0000 + i);
      axi_read(`AES256_ADDR_KEY0 + i*4, data);
      if (data != (32'hA500_0000 + i))
        `uvm_error("REG", $sformatf("KEY%0d readback mismatch", i))
    end
    wait_key_ready();

    axi_read(8'hFC, data);
    if (data != 32'd0)
      `uvm_error("REG", $sformatf("Unmapped read got 0x%08h", data))
  endtask
endclass
