# RS(16,8) Encoder Notes

Files:
- `rtl/rs_lfsr_16_8.v` (core LFSR)
- `rtl/rs_encoder_16_8.v` (top wrapper)
- `rtl/gf256mul_dec.v` (GF(256) constant multiply)

Parameters:
- GF(256), primitive polynomial 0x11d, alpha = 0x02
- N=16, K=8, R=8, t=4
- Generator: g(x) = Π_{i=1..8}(x - alpha^i)
- Coefficients (x^7..x^0, hex): `E3, 2C, B2, 47, AC, 08, E0, 25`

Behavior:
- Data phase: accept 8 symbols with `din_val` asserted, `din_sop` on first symbol.
- Parity phase: outputs 8 parity symbols after data symbols.
- Output stream: first 8 = data, last 8 = parity.
