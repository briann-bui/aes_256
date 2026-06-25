# AES-256 Cryptographic IP Core

AES-256 hardware IP core written in SystemVerilog for FPGA and ASIC integration. The project includes synthesizable RTL, an AXI4-Lite register interface, multiple AES operating modes, and a UVM verification environment.

## Documentation

Read the full vendor-style IP documentation here:

[AES-256 IP GitHub Pages](https://briann-bui.github.io/aes_256/)

## Key Features

| Item | Description |
| --- | --- |
| Algorithm | AES-256 |
| Block size | 128-bit |
| Key size | 256-bit |
| Interface | AXI4-Lite register interface |
| RTL language | SystemVerilog |
| Modes | ECB, CBC, CTR, CFB, OFB, GCM |
| Verification | UVM testbench |
| Lint | Verilator |
| Simulation | ModelSim |
| Target | FPGA / ASIC |

## Project Keywords

`AES-256`, `AES IP core`, `cryptographic accelerator`, `SystemVerilog RTL`, `AXI4-Lite`, `UVM verification`, `FPGA`, `ASIC`, `Verilator`, `ModelSim`, `hardware security`, `SoC IP`.

## Repository Structure

```text
.
|-- inc/        Register definitions and global macros
|-- rtl/        Synthesizable AES-256 RTL
|-- uvm/        UVM verification environment
|-- docs/       GitHub Pages documentation source
|-- filelist.f  RTL/UVM compile filelist
`-- Makefile    Lint, compile, run, coverage, and clean targets
```

## Build and Verification

Run Verilator lint:

```sh
make lint
```

Compile with ModelSim:

```sh
make compile
```

Run the UVM regression:

```sh
make run
```

Run a specific UVM test:

```sh
make run UVM_TEST=aes256_ecb_vector_test
```

## UVM Tests

- `aes256_reg_test`
- `aes256_ecb_vector_test`
- `aes256_cbc_roundtrip_test`
- `aes256_modes_roundtrip_test`
- `aes256_gcm_smoke_test`
- `aes256_irq_test`
- `aes256_b2b_test`
- `aes256_axi_error_test`
- `aes256_all_test`

## Author

Brian Bui  
LinkedIn: [buiminhnhut114](https://www.linkedin.com/in/buiminhnhut114/)

## Notes

This project is intended as a reusable AES-256 RTL IP core and verification portfolio project. Before production use, extend the verification plan with additional official NIST vectors, side-channel review, key zeroization policy, and implementation-specific security checks.
