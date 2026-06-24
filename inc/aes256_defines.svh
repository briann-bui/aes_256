`ifndef AES256_DEFINES_SVH
`define AES256_DEFINES_SVH

`define AES256_NR                    14
`define AES256_NK                    8
`define AES256_KEY_LEN               256
`define AES256_BLOCK_LEN             128
`define AES256_NB                    4
`define AES256_RKEY_NUM              15

`define AES256_MODE_ECB              3'b000
`define AES256_MODE_CBC              3'b001
`define AES256_MODE_CTR              3'b010
`define AES256_MODE_CFB              3'b011
`define AES256_MODE_OFB              3'b100
`define AES256_MODE_GCM              3'b101

`define AES256_AXI_DATA_WIDTH        32
`define AES256_AXI_ADDR_WIDTH        8

`define AES256_ADDR_CTRL             8'h00
`define AES256_ADDR_STATUS           8'h04
`define AES256_ADDR_IRQ_EN           8'h08
`define AES256_ADDR_IRQ_STAT         8'h0C
`define AES256_ADDR_KEY0             8'h10
`define AES256_ADDR_KEY1             8'h14
`define AES256_ADDR_KEY2             8'h18
`define AES256_ADDR_KEY3             8'h1C
`define AES256_ADDR_KEY4             8'h20
`define AES256_ADDR_KEY5             8'h24
`define AES256_ADDR_KEY6             8'h28
`define AES256_ADDR_KEY7             8'h2C
`define AES256_ADDR_IV0              8'h30
`define AES256_ADDR_IV1              8'h34
`define AES256_ADDR_IV2              8'h38
`define AES256_ADDR_IV3              8'h3C
`define AES256_ADDR_DIN0             8'h40
`define AES256_ADDR_DIN1             8'h44
`define AES256_ADDR_DIN2             8'h48
`define AES256_ADDR_DIN3             8'h4C
`define AES256_ADDR_DOUT0            8'h50
`define AES256_ADDR_DOUT1            8'h54
`define AES256_ADDR_DOUT2            8'h58
`define AES256_ADDR_DOUT3            8'h5C
`define AES256_ADDR_AAD0             8'h60
`define AES256_ADDR_AAD1             8'h64
`define AES256_ADDR_AAD2             8'h68
`define AES256_ADDR_AAD3             8'h6C
`define AES256_ADDR_TAG0             8'h70
`define AES256_ADDR_TAG1             8'h74
`define AES256_ADDR_TAG2             8'h78
`define AES256_ADDR_TAG3             8'h7C
`define AES256_ADDR_DIN_CTRL         8'h80
`define AES256_ADDR_VERSION          8'h84

`define AES256_IP_VERSION            32'h0001_0000

`define AES256_CTRL_START_BIT        0
`define AES256_CTRL_ENC_DEC_BIT      1
`define AES256_CTRL_MODE_LSB         2
`define AES256_CTRL_MODE_MSB         4

`define AES256_STATUS_BUSY_BIT       0
`define AES256_STATUS_DONE_BIT       1
`define AES256_STATUS_KEY_READY_BIT  2
`define AES256_STATUS_ERR_BIT        3

`define AES256_IRQ_DOUT_VALID_BIT    0
`define AES256_IRQ_TAG_VALID_BIT     1

`endif
