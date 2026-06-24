class aes256_base_test extends uvm_test;
  `uvm_component_utils(aes256_base_test)

  aes256_env env;
  virtual aes256_axi_if vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = aes256_env::type_id::create("env", this);
    if (!uvm_config_db#(virtual aes256_axi_if)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", "Missing aes256_axi_if for test")
  endfunction

  task reset_dut();
    vif.aresetn <= 1'b0;
    vif.init_master();
    repeat (8) @(posedge vif.aclk);
    vif.aresetn <= 1'b1;
    repeat (2) @(posedge vif.aclk);
    env.sb.reset_mirror();
  endtask
endclass
