class aes256_cbc_roundtrip_seq extends aes256_base_seq;
  `uvm_object_utils(aes256_cbc_roundtrip_seq)

  function new(string name = "aes256_cbc_roundtrip_seq");
    super.new(name);
  endfunction

  task body();
    bit [255:0] key;
    bit [127:0] iv;
    bit [127:0] plain;
    bit [127:0] cipher;
    bit [127:0] recovered;

    key   = 256'h000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f;
    iv    = 128'h101112131415161718191a1b1c1d1e1f;
    plain = 128'h00112233445566778899aabbccddeeff;

    aes_single_block(`AES256_MODE_CBC, 1'b1, key, iv, plain, cipher);
    aes_single_block(`AES256_MODE_CBC, 1'b0, key, iv, cipher, recovered);
    if (recovered != plain)
      `uvm_error("CBC", $sformatf("CBC round-trip failed: cipher=0x%032h got=0x%032h expected=0x%032h",
                                  cipher, recovered, plain))
  endtask
endclass
