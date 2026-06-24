class aes256_gcm_smoke_test extends aes256_base_test;
  `uvm_component_utils(aes256_gcm_smoke_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    aes256_gcm_smoke_seq seq = aes256_gcm_smoke_seq::type_id::create("seq");
    phase.raise_objection(this);
    seq.start(env.agent.sequencer);
    phase.drop_objection(this);
  endtask
endclass
