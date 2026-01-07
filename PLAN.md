# RS(16,8) 8-bit Encoder/Decoder Plan

Target:
- GF(256) RS(16,8) with 8 parity symbols (t=4)

Generator:
- g(x) = Π_{i=1..8}(x - alpha^i), alpha=0x02 (poly 0x11d)
- Coefficients (x^7..x^0): `E3, 2C, B2, 47, AC, 08, E0, 25`

Modules:
- Encoder: `rs_lfsr_16_8.v`, `rs_encoder_16_8.v`
- Decoder: `syndrome_16_8.v`, `kes_16_8.v`, `err_locate_16_8.v`, `err_value_16_8.v`, `dec_ctrl_16_8.v`, `err_correct_16_8.v`, `rs_decoder_16_8.v`
- Shared GF(256): `gf256_tables.v`, `gf256mul.v`, `gf256mul_dec.v`, `gf256_lut_func.sv`

Tests:
- `sim/tb_rs_encoder_16_8.v`
- `sim/tb_rs_decoder_16_8.v`
