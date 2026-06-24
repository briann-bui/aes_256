class aes256_scoreboard extends uvm_component;
  `uvm_component_utils(aes256_scoreboard)

  uvm_analysis_imp #(aes256_axi_item, aes256_scoreboard) analysis_export;
  bit [31:0] mirror [bit [7:0]];

  function new(string name, uvm_component parent);
    super.new(name, parent);
    analysis_export = new("analysis_export", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    reset_mirror();
  endfunction

  function void reset_mirror();
    mirror.delete();
    mirror[`AES256_ADDR_CTRL]     = 32'd0;
    mirror[`AES256_ADDR_IRQ_EN]   = 32'd0;
    mirror[`AES256_ADDR_DIN_CTRL] = 32'd0;
    for (int i = 0; i < 8; i++) mirror[`AES256_ADDR_KEY0 + i*4] = 32'd0;
    for (int i = 0; i < 4; i++) begin
      mirror[`AES256_ADDR_IV0  + i*4] = 32'd0;
      mirror[`AES256_ADDR_DIN0 + i*4] = 32'd0;
      mirror[`AES256_ADDR_AAD0 + i*4] = 32'd0;
    end
  endfunction

  function bit is_mirrored_addr(bit [7:0] addr);
    return mirror.exists(addr);
  endfunction

  function void write(aes256_axi_item tr);
    if (tr.cmd == AES256_AXI_WRITE) begin
      if (is_mirrored_addr(tr.addr))
        mirror[tr.addr] = tr.data;
    end else begin
      if (tr.addr == `AES256_ADDR_VERSION) begin
        if (tr.data != `AES256_IP_VERSION)
          `uvm_error("REG", $sformatf("VERSION read 0x%08h, expected 0x%08h", tr.data, `AES256_IP_VERSION))
      end else if (is_mirrored_addr(tr.addr)) begin
        if (tr.data != mirror[tr.addr])
          `uvm_error("REG", $sformatf("Readback mismatch addr=0x%02h got=0x%08h exp=0x%08h",
                                      tr.addr, tr.data, mirror[tr.addr]))
      end else if ((tr.addr > `AES256_ADDR_VERSION) && (tr.data != 32'd0)) begin
        `uvm_error("REG", $sformatf("Unmapped read addr=0x%02h returned 0x%08h", tr.addr, tr.data))
      end
    end
  endfunction
endclass
