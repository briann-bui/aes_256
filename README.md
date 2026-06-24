# AES-256 Cryptographic IP Core

<p align="center">
  <img src="https://img.shields.io/badge/Language-SystemVerilog-3178C6?style=for-the-badge&logo=verilog" />
  <img src="https://img.shields.io/badge/Standard-IEEE_1800--2017-00599C?style=for-the-badge" />
  <img src="https://img.shields.io/badge/Compliance-FIPS--197-228B22?style=for-the-badge" />
  <img src="https://img.shields.io/badge/License-MIT-yellow?style=for-the-badge" />
</p>

A high-performance, fully synthesizable **AES-256** IP Core written in pure **SystemVerilog (IEEE 1800-2017)**. Designed for seamless integration into cryptographic System-on-Chip (SoC) designs — no external macros, no software dependencies, no latches.

> **Copyright © 2026 Brian Bui — All rights reserved.**

---

## ✨ Key Highlights

| Feature | Detail |
|---------|--------|
| **Algorithm** | AES-256 per FIPS-197 (Rijndael) |
| **Key Length** | 256 bits |
| **Block Size** | 128 bits |
| **Architecture** | Iterative datapath — 14-cycle latency per block |
| **S-Box** | Full 256-entry LUT (forward & inverse), latch-free |
| **Interface** | Valid/Ready handshake (AXI-Stream compatible) |
| **Modes** | ECB · CBC · CTR · CFB · OFB · GCM |
| **GCM Engine** | Built-in GF(2¹²⁸) GHASH multiplier |
| **Target** | ASIC / FPGA (vendor agnostic) |

---

## 🏗️ Architecture

```
                            ┌─────────────────────────────────────────────┐
                            │              aes256_top                     │
  ┌────────┐                │  ┌──────────────────────┐                   │
  │  Key   │───key[255:0]──▶│  │  aes256_key_expansion│──rkey[0:14]──┐   │
  │ Input  │   key_valid    │  │  (FSM, 13 steps)     │  rkey_valid  │   │
  └────────┘                │  └──────────────────────┘              │   │
                            │                                        ▼   │
  ┌────────┐                │  ┌─────────────────────────────────────┐   │
  │  Mode  │───mode[2:0]──▶ │  │   Mode Router (ECB/CBC/CTR/CFB/    │   │
  │ Config │   enc_dec      │  │                OFB/GCM)             │   │
  └────────┘                │  │  ┌───────────┐   ┌───────────┐     │   │
                            │  │  │  enc_dp   │   │  dec_dp   │     │   │
  ┌────────┐   din[127:0]   │  │  │ (14 rnds) │   │ (14 rnds) │     │   │
  │  Data  │───din_valid───▶│  │  └─────┬─────┘   └─────┬─────┘     │   │
  │ Input  │   din_last     │  │        │               │            │   │
  └────────┘◀──din_ready────│  │        ▼               ▼            │   │
                            │  │  ┌───────────────────────────┐      │   │
  ┌────────┐◀──dout[127:0]──│  │  │    aes256_round_func     │      │   │
  │  Data  │   dout_valid   │  │  │  (SubBytes + ShiftRows + │      │   │
  │ Output │───dout_ready──▶│  │  │   MixColumns + AddRKey)  │      │   │
  └────────┘   dout_last    │  │  └───────────────────────────┘      │   │
                            │  └─────────────────────────────────────┘   │
                            └─────────────────────────────────────────────┘
```

### Encryption Round (Rounds 1–13)
```
State ──▶ SubBytes ──▶ ShiftRows ──▶ MixColumns ──▶ AddRoundKey ──▶ State'
```

### Encryption Final Round (Round 14)
```
State ──▶ SubBytes ──▶ ShiftRows ──▶ AddRoundKey ──▶ Ciphertext
```

### Decryption Round (Rounds 1–13)
```
State ──▶ InvShiftRows ──▶ InvSubBytes ──▶ AddRoundKey ──▶ InvMixColumns ──▶ State'
```

### Decryption Final Round (Round 14)
```
State ──▶ InvShiftRows ──▶ InvSubBytes ──▶ AddRoundKey ──▶ Plaintext
```

---

## 📁 Directory Structure

```
aes256_ip/
├── rtl/
│   ├── pkg/
│   │   └── aes256_pkg.sv               # Package: constants, types, GF(2⁸) functions
│   ├── core/
│   │   ├── aes256_sbox_enc.sv          # Forward S-Box (256-entry LUT)
│   │   ├── aes256_sbox_dec.sv          # Inverse S-Box (256-entry LUT)
│   │   ├── aes256_key_expansion.sv     # Key Schedule FSM (60 words, 4/cycle)
│   │   ├── aes256_round_func.sv        # Shared round function (enc + dec)
│   │   ├── aes256_enc_datapath.sv      # Iterative encryption (14 rounds)
│   │   └── aes256_dec_datapath.sv      # Iterative decryption (14 rounds)
│   ├── mode/
│   │   ├── aes256_mode_ecb.sv          # Electronic Codebook
│   │   ├── aes256_mode_cbc.sv          # Cipher Block Chaining
│   │   ├── aes256_mode_ctr.sv          # Counter Mode
│   │   ├── aes256_mode_cfb.sv          # Cipher Feedback
│   │   ├── aes256_mode_ofb.sv          # Output Feedback
│   │   └── aes256_mode_gcm.sv          # Galois/Counter Mode + GHASH
│   └── top/
│       └── aes256_top.sv               # Top-level integration
└── README.md
```

---

## 🔌 Top-Level Interface

### `aes256_top` Port Map

#### Clock & Reset

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `i_aes_clk` | Input | 1 | System clock |
| `i_aes_rst_n` | Input | 1 | Asynchronous active-low reset |

#### Configuration

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `i_aes_mode` | Input | 3 | Mode select: `0`=ECB, `1`=CBC, `2`=CTR, `3`=CFB, `4`=OFB, `5`=GCM |
| `i_aes_enc_dec` | Input | 1 | `1` = Encrypt, `0` = Decrypt |

#### Key Interface (Valid/Ready Handshake)

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `i_aes_key` | Input | 256 | AES-256 cipher key |
| `i_aes_key_valid` | Input | 1 | Key valid strobe |
| `o_aes_key_ready` | Output | 1 | Core ready to accept key |

#### IV / Nonce (CBC, CTR, CFB, OFB, GCM)

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `i_aes_iv` | Input | 128 | Initialization Vector or Nonce |
| `i_aes_iv_valid` | Input | 1 | IV valid strobe |

#### Data Input (Valid/Ready Handshake)

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `i_aes_din` | Input | 128 | Input data block (plaintext or ciphertext) |
| `i_aes_din_valid` | Input | 1 | Input data valid |
| `i_aes_din_last` | Input | 1 | Marks last block of the stream |
| `o_aes_din_ready` | Output | 1 | Core ready to accept data |

#### Data Output (Valid/Ready Handshake)

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `o_aes_dout` | Output | 128 | Output data block |
| `o_aes_dout_valid` | Output | 1 | Output data valid |
| `o_aes_dout_last` | Output | 1 | Marks last block of the stream |
| `i_aes_dout_ready` | Input | 1 | Downstream ready to accept output |

#### GCM: Additional Authenticated Data

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `i_aes_aad` | Input | 128 | AAD block |
| `i_aes_aad_valid` | Input | 1 | AAD valid strobe |
| `i_aes_aad_last` | Input | 1 | Marks last AAD block |
| `o_aes_aad_ready` | Output | 1 | Core ready to accept AAD (gated by GCM mode) |

#### GCM: Authentication Tag

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `o_aes_tag` | Output | 128 | 128-bit authentication tag |
| `o_aes_tag_valid` | Output | 1 | Tag valid strobe (gated by GCM mode) |

#### Status

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `o_aes_busy` | Output | 1 | Core is processing (do not change mode/key/IV) |
| `o_aes_err` | Output | 1 | Error flag (reserved) |

---

## 🔐 Modes of Operation

| Mode | Encryption DP | Decryption DP | IV Required | Description |
|------|:---:|:---:|:---:|-------------|
| **ECB** | ✅ | ✅ | ❌ | Each block encrypted independently |
| **CBC** | ✅ | ✅ | ✅ | Plaintext XOR'd with previous ciphertext |
| **CTR** | ✅ | — | ✅ | Encrypts counter, XOR with data (symmetric) |
| **CFB** | ✅ | — | ✅ | Encrypts feedback register, XOR with data |
| **OFB** | ✅ | — | ✅ | Encrypts previous output block, XOR with data |
| **GCM** | ✅ | — | ✅ | CTR encryption + GF(2¹²⁸) GHASH authentication |

> **Note:** CTR, CFB, OFB, and GCM use **only the encryption datapath** for both directions. The `i_aes_enc_dec` signal is used by ECB and CBC to select the appropriate datapath.

---

## ⏱️ Timing & Usage

### Latency
- **Key Expansion**: 14 clock cycles (1 load + 13 expansion steps)
- **Data Block**: 16 clock cycles (1 load + 14 rounds + 1 output)

### Usage Protocol
```
1. Assert i_aes_key + i_aes_key_valid    → Wait for o_aes_key_ready to deassert
2. Assert i_aes_iv  + i_aes_iv_valid     → (modes requiring IV)
3. Assert i_aes_din + i_aes_din_valid    → Wait for o_aes_din_ready
4. Read   o_aes_dout when o_aes_dout_valid is high
5. Assert i_aes_dout_ready to consume output
```

### Important Constraints
- **Do not change** `i_aes_mode`, `i_aes_enc_dec`, key, or IV while `o_aes_busy` is high.
- **CTR mode** requires IV to be loaded before data is accepted (internally guarded).
- **GCM AAD/Tag signals** are gated — they will read `0` when not in GCM mode.
- `o_aes_dout_last` is **pipeline-delayed** to align with its corresponding output block.

---

## 🧩 Naming Conventions

| Prefix | Meaning | Example |
|--------|---------|---------|
| `i_` | Input port | `i_aes_din` |
| `o_` | Output port | `o_aes_dout` |
| `r_` | Registered signal (flip-flop) | `r_state` |
| `w_` | Combinational wire | `w_enc_dout` |
| `f_` | Function | `f_xtime()` |
| `t_` | Type definition | `t_state_t` |
| `C_` | Constant / localparam | `C_NR` |

---

## 🛠️ Synthesis Notes

- **No latches**: All combinational blocks are fully specified with `unique case` and `default` branches.
- **No macros**: Pure RTL — vendor and technology agnostic.
- **S-Box**: Implemented as 256-entry LUTs. Synthesis tools will optimize to ROM or logic fabric.
- **GF(2¹²⁸)**: The GHASH multiplier is fully combinational (128 iterations unrolled). Apply multicycle path constraints if targeting low-frequency designs.
- **Reset**: All flip-flops use asynchronous active-low reset (`negedge i_aes_rst_n`).

---

## 👨‍💻 Author

**Brian Bui (Bùi Minh Nhựt)**

[![LinkedIn](https://img.shields.io/badge/LinkedIn-Brian_Bui-0A66C2?style=flat-square&logo=linkedin)](https://www.linkedin.com/in/buiminhnhut114/)

---

## 📜 License

```
MIT License

Copyright (c) 2026 Brian Bui

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```
