class aes256_axi_sequencer extends uvm_sequencer #(aes256_axi_item);
  `uvm_component_utils(aes256_axi_sequencer)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
endclass
