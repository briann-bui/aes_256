typedef enum bit [1:0] {
  AES256_AXI_WRITE,
  AES256_AXI_READ
} aes256_axi_cmd_e;

class aes256_axi_item extends uvm_sequence_item;
  rand aes256_axi_cmd_e cmd;
  rand bit [7:0]        addr;
  rand bit [31:0]       data;
  rand bit [3:0]        strb;
       bit [1:0]        resp;

  constraint c_strb_default { strb == 4'hF; }

  `uvm_object_utils_begin(aes256_axi_item)
    `uvm_field_enum(aes256_axi_cmd_e, cmd, UVM_ALL_ON)
    `uvm_field_int(addr, UVM_HEX)
    `uvm_field_int(data, UVM_HEX)
    `uvm_field_int(strb, UVM_HEX)
    `uvm_field_int(resp, UVM_HEX)
  `uvm_object_utils_end

  function new(string name = "aes256_axi_item");
    super.new(name);
  endfunction
endclass
