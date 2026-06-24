class aes256_all_test extends aes256_base_test;
  `uvm_component_utils(aes256_all_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    aes256_reg_smoke_seq       reg_seq;
    aes256_ecb_vector_seq      ecb_seq;
    aes256_modes_roundtrip_seq modes_seq;
    aes256_irq_seq             irq_seq;
    aes256_gcm_smoke_seq       gcm_seq;
    aes256_b2b_seq             b2b_seq;
    aes256_axi_error_seq       err_seq;

    phase.raise_objection(this);
    reg_seq   = aes256_reg_smoke_seq::type_id::create("reg_seq");
    ecb_seq   = aes256_ecb_vector_seq::type_id::create("ecb_seq");
    modes_seq = aes256_modes_roundtrip_seq::type_id::create("modes_seq");
    irq_seq   = aes256_irq_seq::type_id::create("irq_seq");
    gcm_seq   = aes256_gcm_smoke_seq::type_id::create("gcm_seq");
    b2b_seq   = aes256_b2b_seq::type_id::create("b2b_seq");
    err_seq   = aes256_axi_error_seq::type_id::create("err_seq");

    reset_dut();
    ecb_seq.start(env.agent.sequencer);
    reset_dut();
    modes_seq.start(env.agent.sequencer);
    reset_dut();
    irq_seq.start(env.agent.sequencer);
    reset_dut();
    gcm_seq.start(env.agent.sequencer);
    reset_dut();
    reg_seq.start(env.agent.sequencer);
    reset_dut();
    b2b_seq.start(env.agent.sequencer);
    reset_dut();
    err_seq.start(env.agent.sequencer);
    phase.drop_objection(this);
  endtask
endclass
