class aes256_agent extends uvm_component;
  `uvm_component_utils(aes256_agent)

  aes256_axi_sequencer sequencer;
  aes256_axi_driver    driver;
  aes256_axi_monitor   monitor;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    sequencer = aes256_axi_sequencer::type_id::create("sequencer", this);
    driver    = aes256_axi_driver::type_id::create("driver", this);
    monitor   = aes256_axi_monitor::type_id::create("monitor", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    driver.seq_item_port.connect(sequencer.seq_item_export);
  endfunction
endclass
