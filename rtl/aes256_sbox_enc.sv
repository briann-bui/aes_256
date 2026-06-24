module aes256_sbox_enc
  import aes256_pkg::*;
(
  input  logic [7:0] i_aes_byte,
  output logic [7:0] o_aes_byte
);

  function automatic logic [7:0] f_sbox_enc(input logic [7:0] in);
    logic [7:0] w_out;
    unique case (in)
      8'h00: w_out = 8'h63;  8'h01: w_out = 8'h7C;  8'h02: w_out = 8'h77;  8'h03: w_out = 8'h7B;
      8'h04: w_out = 8'hF2;  8'h05: w_out = 8'h6B;  8'h06: w_out = 8'h6F;  8'h07: w_out = 8'hC5;
      8'h08: w_out = 8'h30;  8'h09: w_out = 8'h01;  8'h0A: w_out = 8'h67;  8'h0B: w_out = 8'h2B;
      8'h0C: w_out = 8'hFE;  8'h0D: w_out = 8'hD7;  8'h0E: w_out = 8'hAB;  8'h0F: w_out = 8'h76;
      8'h10: w_out = 8'hCA;  8'h11: w_out = 8'h82;  8'h12: w_out = 8'hC9;  8'h13: w_out = 8'h7D;
      8'h14: w_out = 8'hFA;  8'h15: w_out = 8'h59;  8'h16: w_out = 8'h47;  8'h17: w_out = 8'hF0;
      8'h18: w_out = 8'hAD;  8'h19: w_out = 8'hD4;  8'h1A: w_out = 8'hA2;  8'h1B: w_out = 8'hAF;
      8'h1C: w_out = 8'h9C;  8'h1D: w_out = 8'hA4;  8'h1E: w_out = 8'h72;  8'h1F: w_out = 8'hC0;
      8'h20: w_out = 8'hB7;  8'h21: w_out = 8'hFD;  8'h22: w_out = 8'h93;  8'h23: w_out = 8'h26;
      8'h24: w_out = 8'h36;  8'h25: w_out = 8'h3F;  8'h26: w_out = 8'hF7;  8'h27: w_out = 8'hCC;
      8'h28: w_out = 8'h34;  8'h29: w_out = 8'hA5;  8'h2A: w_out = 8'hE5;  8'h2B: w_out = 8'hF1;
      8'h2C: w_out = 8'h71;  8'h2D: w_out = 8'hD8;  8'h2E: w_out = 8'h31;  8'h2F: w_out = 8'h15;
      8'h30: w_out = 8'h04;  8'h31: w_out = 8'hC7;  8'h32: w_out = 8'h23;  8'h33: w_out = 8'hC3;
      8'h34: w_out = 8'h18;  8'h35: w_out = 8'h96;  8'h36: w_out = 8'h05;  8'h37: w_out = 8'h9A;
      8'h38: w_out = 8'h07;  8'h39: w_out = 8'h12;  8'h3A: w_out = 8'h80;  8'h3B: w_out = 8'hE2;
      8'h3C: w_out = 8'hEB;  8'h3D: w_out = 8'h27;  8'h3E: w_out = 8'hB2;  8'h3F: w_out = 8'h75;
      8'h40: w_out = 8'h09;  8'h41: w_out = 8'h83;  8'h42: w_out = 8'h2C;  8'h43: w_out = 8'h1A;
      8'h44: w_out = 8'h1B;  8'h45: w_out = 8'h6E;  8'h46: w_out = 8'h5A;  8'h47: w_out = 8'hA0;
      8'h48: w_out = 8'h52;  8'h49: w_out = 8'h3B;  8'h4A: w_out = 8'hD6;  8'h4B: w_out = 8'hB3;
      8'h4C: w_out = 8'h29;  8'h4D: w_out = 8'hE3;  8'h4E: w_out = 8'h2F;  8'h4F: w_out = 8'h84;
      8'h50: w_out = 8'h53;  8'h51: w_out = 8'hD1;  8'h52: w_out = 8'h00;  8'h53: w_out = 8'hED;
      8'h54: w_out = 8'h20;  8'h55: w_out = 8'hFC;  8'h56: w_out = 8'hB1;  8'h57: w_out = 8'h5B;
      8'h58: w_out = 8'h6A;  8'h59: w_out = 8'hCB;  8'h5A: w_out = 8'hBE;  8'h5B: w_out = 8'h39;
      8'h5C: w_out = 8'h4A;  8'h5D: w_out = 8'h4C;  8'h5E: w_out = 8'h58;  8'h5F: w_out = 8'hCF;
      8'h60: w_out = 8'hD0;  8'h61: w_out = 8'hEF;  8'h62: w_out = 8'hAA;  8'h63: w_out = 8'hFB;
      8'h64: w_out = 8'h43;  8'h65: w_out = 8'h4D;  8'h66: w_out = 8'h33;  8'h67: w_out = 8'h85;
      8'h68: w_out = 8'h45;  8'h69: w_out = 8'hF9;  8'h6A: w_out = 8'h02;  8'h6B: w_out = 8'h7F;
      8'h6C: w_out = 8'h50;  8'h6D: w_out = 8'h3C;  8'h6E: w_out = 8'h9F;  8'h6F: w_out = 8'hA8;
      8'h70: w_out = 8'h51;  8'h71: w_out = 8'hA3;  8'h72: w_out = 8'h40;  8'h73: w_out = 8'h8F;
      8'h74: w_out = 8'h92;  8'h75: w_out = 8'h9D;  8'h76: w_out = 8'h38;  8'h77: w_out = 8'hF5;
      8'h78: w_out = 8'hBC;  8'h79: w_out = 8'hB6;  8'h7A: w_out = 8'hDA;  8'h7B: w_out = 8'h21;
      8'h7C: w_out = 8'h10;  8'h7D: w_out = 8'hFF;  8'h7E: w_out = 8'hF3;  8'h7F: w_out = 8'hD2;
      8'h80: w_out = 8'hCD;  8'h81: w_out = 8'h0C;  8'h82: w_out = 8'h13;  8'h83: w_out = 8'hEC;
      8'h84: w_out = 8'h5F;  8'h85: w_out = 8'h97;  8'h86: w_out = 8'h44;  8'h87: w_out = 8'h17;
      8'h88: w_out = 8'hC4;  8'h89: w_out = 8'hA7;  8'h8A: w_out = 8'h7E;  8'h8B: w_out = 8'h3D;
      8'h8C: w_out = 8'h64;  8'h8D: w_out = 8'h5D;  8'h8E: w_out = 8'h19;  8'h8F: w_out = 8'h73;
      8'h90: w_out = 8'h60;  8'h91: w_out = 8'h81;  8'h92: w_out = 8'h4F;  8'h93: w_out = 8'hDC;
      8'h94: w_out = 8'h22;  8'h95: w_out = 8'h2A;  8'h96: w_out = 8'h90;  8'h97: w_out = 8'h88;
      8'h98: w_out = 8'h46;  8'h99: w_out = 8'hEE;  8'h9A: w_out = 8'hB8;  8'h9B: w_out = 8'h14;
      8'h9C: w_out = 8'hDE;  8'h9D: w_out = 8'h5E;  8'h9E: w_out = 8'h0B;  8'h9F: w_out = 8'hDB;
      8'hA0: w_out = 8'hE0;  8'hA1: w_out = 8'h32;  8'hA2: w_out = 8'h3A;  8'hA3: w_out = 8'h0A;
      8'hA4: w_out = 8'h49;  8'hA5: w_out = 8'h06;  8'hA6: w_out = 8'h24;  8'hA7: w_out = 8'h5C;
      8'hA8: w_out = 8'hC2;  8'hA9: w_out = 8'hD3;  8'hAA: w_out = 8'hAC;  8'hAB: w_out = 8'h62;
      8'hAC: w_out = 8'h91;  8'hAD: w_out = 8'h95;  8'hAE: w_out = 8'hE4;  8'hAF: w_out = 8'h79;
      8'hB0: w_out = 8'hE7;  8'hB1: w_out = 8'hC8;  8'hB2: w_out = 8'h37;  8'hB3: w_out = 8'h6D;
      8'hB4: w_out = 8'h8D;  8'hB5: w_out = 8'hD5;  8'hB6: w_out = 8'h4E;  8'hB7: w_out = 8'hA9;
      8'hB8: w_out = 8'h6C;  8'hB9: w_out = 8'h56;  8'hBA: w_out = 8'hF4;  8'hBB: w_out = 8'hEA;
      8'hBC: w_out = 8'h65;  8'hBD: w_out = 8'h7A;  8'hBE: w_out = 8'hAE;  8'hBF: w_out = 8'h08;
      8'hC0: w_out = 8'hBA;  8'hC1: w_out = 8'h78;  8'hC2: w_out = 8'h25;  8'hC3: w_out = 8'h2E;
      8'hC4: w_out = 8'h1C;  8'hC5: w_out = 8'hA6;  8'hC6: w_out = 8'hB4;  8'hC7: w_out = 8'hC6;
      8'hC8: w_out = 8'hE8;  8'hC9: w_out = 8'hDD;  8'hCA: w_out = 8'h74;  8'hCB: w_out = 8'h1F;
      8'hCC: w_out = 8'h4B;  8'hCD: w_out = 8'hBD;  8'hCE: w_out = 8'h8B;  8'hCF: w_out = 8'h8A;
      8'hD0: w_out = 8'h70;  8'hD1: w_out = 8'h3E;  8'hD2: w_out = 8'hB5;  8'hD3: w_out = 8'h66;
      8'hD4: w_out = 8'h48;  8'hD5: w_out = 8'h03;  8'hD6: w_out = 8'hF6;  8'hD7: w_out = 8'h0E;
      8'hD8: w_out = 8'h61;  8'hD9: w_out = 8'h35;  8'hDA: w_out = 8'h57;  8'hDB: w_out = 8'hB9;
      8'hDC: w_out = 8'h86;  8'hDD: w_out = 8'hC1;  8'hDE: w_out = 8'h1D;  8'hDF: w_out = 8'h9E;
      8'hE0: w_out = 8'hE1;  8'hE1: w_out = 8'hF8;  8'hE2: w_out = 8'h98;  8'hE3: w_out = 8'h11;
      8'hE4: w_out = 8'h69;  8'hE5: w_out = 8'hD9;  8'hE6: w_out = 8'h8E;  8'hE7: w_out = 8'h94;
      8'hE8: w_out = 8'h9B;  8'hE9: w_out = 8'h1E;  8'hEA: w_out = 8'h87;  8'hEB: w_out = 8'hE9;
      8'hEC: w_out = 8'hCE;  8'hED: w_out = 8'h55;  8'hEE: w_out = 8'h28;  8'hEF: w_out = 8'hDF;
      8'hF0: w_out = 8'h8C;  8'hF1: w_out = 8'hA1;  8'hF2: w_out = 8'h89;  8'hF3: w_out = 8'h0D;
      8'hF4: w_out = 8'hBF;  8'hF5: w_out = 8'hE6;  8'hF6: w_out = 8'h42;  8'hF7: w_out = 8'h68;
      8'hF8: w_out = 8'h41;  8'hF9: w_out = 8'h99;  8'hFA: w_out = 8'h2D;  8'hFB: w_out = 8'h0F;
      8'hFC: w_out = 8'hB0;  8'hFD: w_out = 8'h54;  8'hFE: w_out = 8'hBB;  8'hFF: w_out = 8'h16;
    endcase
    return w_out;
  endfunction

  assign o_aes_byte = f_sbox_enc(i_aes_byte);

endmodule
