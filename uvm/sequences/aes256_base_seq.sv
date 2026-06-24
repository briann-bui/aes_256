class aes256_base_seq extends uvm_sequence #(aes256_axi_item);
  `uvm_object_utils(aes256_base_seq)

  localparam int POLL_LIMIT = 300;

  function new(string name = "aes256_base_seq");
    super.new(name);
  endfunction

  task automatic axi_write(bit [7:0] addr, bit [31:0] data, bit [3:0] strb = 4'hF);
    aes256_axi_item tr = aes256_axi_item::type_id::create("wr");
    start_item(tr);
    tr.cmd  = AES256_AXI_WRITE;
    tr.addr = addr;
    tr.data = data;
    tr.strb = strb;
    finish_item(tr);
  endtask

  task automatic axi_read(bit [7:0] addr, output bit [31:0] data);
    aes256_axi_item tr = aes256_axi_item::type_id::create("rd");
    start_item(tr);
    tr.cmd  = AES256_AXI_READ;
    tr.addr = addr;
    tr.data = '0;
    tr.strb = 4'hF;
    finish_item(tr);
    data = tr.data;
  endtask

  task automatic write_block(bit [7:0] base_addr, bit [127:0] block);
    bit [31:0] words[4];
    words[0] = block[127:96];
    words[1] = block[95:64];
    words[2] = block[63:32];
    words[3] = block[31:0];
    for (int i = 0; i < 4; i++)
      axi_write(base_addr + i*4, words[i]);
  endtask

  task automatic write_key(bit [255:0] key);
    bit [31:0] words[8];
    for (int i = 0; i < 8; i++)
      words[i] = key[255 - i*32 -: 32];
    for (int i = 0; i < 8; i++)
      axi_write(`AES256_ADDR_KEY0 + i*4, words[i]);
  endtask

  task automatic read_block(bit [7:0] base_addr, output bit [127:0] block);
    bit [31:0] w0;
    bit [31:0] w1;
    bit [31:0] w2;
    bit [31:0] w3;
    axi_read(base_addr + 8'h00, w0);
    axi_read(base_addr + 8'h04, w1);
    axi_read(base_addr + 8'h08, w2);
    axi_read(base_addr + 8'h0C, w3);
    block = {w0, w1, w2, w3};
  endtask

  function automatic bit [31:0] ctrl_value(bit start, bit enc, bit [2:0] mode);
    return {27'd0, mode, enc, start};
  endfunction

  task automatic wait_status_done();
    bit [31:0] status;
    for (int i = 0; i < POLL_LIMIT; i++) begin
      axi_read(`AES256_ADDR_STATUS, status);
      if (status[`AES256_STATUS_DONE_BIT])
        return;
    end
    `uvm_error("TIMEOUT", "Timed out waiting for STATUS.done")
  endtask

  task automatic wait_key_ready();
    bit [31:0] status;
    for (int i = 0; i < POLL_LIMIT; i++) begin
      axi_read(`AES256_ADDR_STATUS, status);
      if (status[`AES256_STATUS_KEY_READY_BIT])
        return;
    end
    `uvm_error("TIMEOUT", "Timed out waiting for STATUS.key_ready")
  endtask

  task automatic wait_key_expand_done();
    bit [31:0] status;
    bit        seen_not_ready;

    seen_not_ready = 1'b0;
    for (int i = 0; i < POLL_LIMIT; i++) begin
      axi_read(`AES256_ADDR_STATUS, status);
      if (!status[`AES256_STATUS_KEY_READY_BIT])
        seen_not_ready = 1'b1;
      if (seen_not_ready && status[`AES256_STATUS_KEY_READY_BIT])
        return;
    end
    `uvm_error("TIMEOUT", "Timed out waiting for key expansion to complete")
  endtask

  task automatic idle_status_reads(int count);
    bit [31:0] status;
    for (int i = 0; i < count; i++)
      axi_read(`AES256_ADDR_STATUS, status);
  endtask

  task automatic wait_irq_stat(bit [31:0] mask);
    bit [31:0] irq_stat;
    for (int i = 0; i < POLL_LIMIT; i++) begin
      axi_read(`AES256_ADDR_IRQ_STAT, irq_stat);
      if ((irq_stat & mask) == mask)
        return;
    end
    `uvm_error("TIMEOUT", $sformatf("Timed out waiting for IRQ_STAT mask 0x%08h", mask))
  endtask

  task automatic aes_single_block(bit [2:0] mode,
                                  bit enc,
                                  bit [255:0] key,
                                  bit [127:0] iv,
                                  bit [127:0] din,
                                  output bit [127:0] dout);
    axi_write(`AES256_ADDR_CTRL, ctrl_value(1'b0, enc, mode));
    write_key(key);
    wait_key_expand_done();
    write_block(`AES256_ADDR_IV0, iv);
    axi_write(`AES256_ADDR_IRQ_EN, 32'h0000_0003);
    axi_write(`AES256_ADDR_CTRL, ctrl_value(1'b1, enc, mode));
    axi_write(`AES256_ADDR_DIN_CTRL, 32'h0000_0001);
    write_block(`AES256_ADDR_DIN0, din);
    wait_status_done();
    wait_irq_stat(32'h0000_0001);
    read_block(`AES256_ADDR_DOUT0, dout);
    axi_write(`AES256_ADDR_IRQ_STAT, 32'h0000_0003);
  endtask
endclass
