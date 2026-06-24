class aes256_irq_seq extends aes256_base_seq;
  `uvm_object_utils(aes256_irq_seq)

  function new(string name = "aes256_irq_seq");
    super.new(name);
  endfunction

  task body();
    bit [127:0] dout;
    bit [31:0] irq_stat;

    aes_single_block(`AES256_MODE_ECB,
                     1'b1,
                     256'h603deb1015ca71be2b73aef0857d77811f352c073b6108d72d9810a30914dff4,
                     128'd0,
                     128'h6bc1bee22e409f96e93d7e117393172a,
                     dout);

    axi_read(`AES256_ADDR_IRQ_STAT, irq_stat);
    if (irq_stat[0] != 1'b0)
      `uvm_error("IRQ", "IRQ_STAT should be clear after write-one-to-clear")
  endtask
endclass
