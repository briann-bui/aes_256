class aes256_ecb_vector_seq extends aes256_base_seq;
  `uvm_object_utils(aes256_ecb_vector_seq)

  function new(string name = "aes256_ecb_vector_seq");
    super.new(name);
  endfunction

  task body();
    bit [255:0] key;
    bit [127:0] plain;
    bit [127:0] exp_cipher;
    bit [127:0] cipher;
    bit [127:0] recovered;

    key        = 256'h603deb1015ca71be2b73aef0857d77811f352c073b6108d72d9810a30914dff4;
    plain      = 128'h6bc1bee22e409f96e93d7e117393172a;
    exp_cipher = 128'hf3eed1bdb5d2a03c064b5a7e3db181f8;

    aes_single_block(`AES256_MODE_ECB, 1'b1, key, 128'd0, plain, cipher);
    if (cipher != exp_cipher)
      `uvm_error("ECB", $sformatf("Encrypt got 0x%032h expected 0x%032h", cipher, exp_cipher))

    aes_single_block(`AES256_MODE_ECB, 1'b0, key, 128'd0, cipher, recovered);
    if (recovered != plain)
      `uvm_error("ECB", $sformatf("Decrypt got 0x%032h expected 0x%032h", recovered, plain))
  endtask
endclass
