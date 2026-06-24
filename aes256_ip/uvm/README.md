# AES-256 UVM Verification

Thu muc nay chua UVM testbench cho `aes256_wrapper` qua AXI4-Lite register map.

## Directory tree

```text
uvm/
|-- agent/
|   |-- aes256_agent.sv
|   |-- aes256_axi_item.sv
|   `-- aes256_axi_sequencer.sv
|-- driver/
|   `-- aes256_axi_driver.sv
|-- env/
|   `-- aes256_env.sv
|-- monitor/
|   `-- aes256_axi_monitor.sv
|-- scoreboard/
|   `-- aes256_scoreboard.sv
|-- sequences/
|   |-- aes256_base_seq.sv
|   |-- aes256_ecb_vector_seq.sv
|   |-- aes256_gcm_smoke_seq.sv
|   |-- aes256_irq_seq.sv
|   |-- aes256_modes_roundtrip_seq.sv
|   `-- aes256_reg_smoke_seq.sv
|-- tb/
|   |-- aes256_axi_if.sv
|   |-- aes256_tb_top.sv
|   `-- aes256_uvm_pkg.sv
|-- tests/
|   |-- aes256_all_test.sv
|   |-- aes256_base_test.sv
|   |-- aes256_ecb_vector_test.sv
|   |-- aes256_gcm_smoke_test.sv
|   |-- aes256_irq_test.sv
|   |-- aes256_modes_roundtrip_test.sv
|   `-- aes256_reg_test.sv
```

## Testcases

- `aes256_reg_test`: reset value, VERSION, register read/write, unmapped read.
- `aes256_ecb_vector_test`: AES-256 ECB encrypt/decrypt voi NIST known-answer vector.
- `aes256_modes_roundtrip_test`: encrypt/decrypt round-trip cho ECB, CBC, CTR, CFB, OFB.
- `aes256_irq_test`: DOUT-valid IRQ va write-one-to-clear `IRQ_STAT`.
- `aes256_gcm_smoke_test`: GCM data output, tag output va IRQ bits.
- `aes256_all_test`: chay tat ca cac sequence tren.

## Questa example

Chay tu thu muc `aes256_ip`:

```sh
make compile
make run
```

Chay test rieng:

```sh
make run UVM_TEST=aes256_ecb_vector_test
```

Neu ModelSim/Questa chua nam trong `PATH`, truyen duong dan tool:

```sh
make compile VLIB=/path/to/vlib VLOG=/path/to/vlog
make run VLIB=/path/to/vlib VLOG=/path/to/vlog VSIM=/path/to/vsim
```
