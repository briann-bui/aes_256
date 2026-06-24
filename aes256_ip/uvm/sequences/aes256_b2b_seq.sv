class aes256_b2b_seq extends aes256_base_seq;
  `uvm_object_utils(aes256_b2b_seq)

  function new(string name = "aes256_b2b_seq");
    super.new(name);
  endfunction

  task automatic aes_stream_blocks(bit [2:0] mode,
                                   bit enc,
                                   bit [255:0] key,
                                   bit [127:0] iv,
                                   bit [127:0] din_arr[],
                                   output bit [127:0] dout_arr[]);
    int num_blocks = din_arr.size();
    dout_arr = new[num_blocks];

    axi_write(`AES256_ADDR_CTRL, ctrl_value(1'b0, enc, mode));
    write_key(key);
    wait_key_expand_done();
    write_block(`AES256_ADDR_IV0, iv);
    axi_write(`AES256_ADDR_IRQ_EN, 32'h0000_0003);
    axi_write(`AES256_ADDR_CTRL, ctrl_value(1'b1, enc, mode));
    
    for (int i = 0; i < num_blocks; i++) begin
      if (i == num_blocks - 1)
        axi_write(`AES256_ADDR_DIN_CTRL, 32'h0000_0001); // last block
      else
        axi_write(`AES256_ADDR_DIN_CTRL, 32'h0000_0000);

      write_block(`AES256_ADDR_DIN0, din_arr[i]);
      wait_status_done();
      wait_irq_stat(32'h0000_0001);
      read_block(`AES256_ADDR_DOUT0, dout_arr[i]);
      axi_write(`AES256_ADDR_IRQ_STAT, 32'h0000_0003); // clear IRQ
    end
  endtask

  task automatic test_b2b_mode(string name, bit [2:0] mode);
    bit [255:0] key;
    bit [127:0] iv;
    bit [127:0] plain[];
    bit [127:0] cipher[];
    bit [127:0] recovered[];

    key = 256'h000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f;
    iv  = 128'h101112131415161718191a1b1c1d1e1f;

    plain = new[5];
    for (int i = 0; i < 5; i++) begin
      plain[i] = {96'd0, 32'(i + 1)};
    end

    `uvm_info("B2B_SEQ", $sformatf("Starting back-to-back %s encryption", name), UVM_LOW)
    aes_stream_blocks(mode, 1'b1, key, iv, plain, cipher);

    `uvm_info("B2B_SEQ", $sformatf("Starting back-to-back %s decryption", name), UVM_LOW)
    aes_stream_blocks(mode, 1'b0, key, iv, cipher, recovered);

    for (int i = 0; i < 5; i++) begin
      if (recovered[i] != plain[i]) begin
        `uvm_error("B2B_SEQ", $sformatf("%s round-trip failed at block %0d: got 0x%032h expected 0x%032h", name, i, recovered[i], plain[i]))
      end
    end
  endtask

  task body();
    test_b2b_mode("ECB", `AES256_MODE_ECB);
    test_b2b_mode("CBC", `AES256_MODE_CBC);
    test_b2b_mode("CTR", `AES256_MODE_CTR);
    test_b2b_mode("CFB", `AES256_MODE_CFB);
    test_b2b_mode("OFB", `AES256_MODE_OFB);
  endtask
endclass
