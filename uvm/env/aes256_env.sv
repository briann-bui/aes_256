class aes256_env extends uvm_env;
  `uvm_component_utils(aes256_env)

  aes256_agent      agent;
  aes256_scoreboard sb;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    agent = aes256_agent::type_id::create("agent", this);
    sb    = aes256_scoreboard::type_id::create("sb", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    agent.monitor.ap.connect(sb.analysis_export);
  endfunction
endclass
