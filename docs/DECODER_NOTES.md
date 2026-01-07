# RS(16,8) Decoder Notes

Files:
- `rtl/rs_decoder_16_8.v` (top)
- `rtl/syndrome_16_8.v`
- `rtl/kes_16_8.v` (Berlekamp-Massey)
- `rtl/err_locate_16_8.v` (Chien search)
- `rtl/err_value_16_8.v` (Forney)
- `rtl/dec_ctrl_16_8.v`, `rtl/err_correct_16_8.v`

Parameters:
- GF(256), primitive polynomial 0x11d, alpha = 0x02
- N=16, K=8, R=8, t=4

Shortening:
- RS(16,8) is shortened from RS(255,247) by 239 leading zeros.
- Syndrome compensation uses alpha_off(i) = alpha^{(i+1)*239}.
- alpha_off (i=1..8, hex): `16, 09, A6, 41, FF, 73, 54, CC`

Flow:
- Syndrome (8 values) -> KES (lambda/omega) -> Chien (locations) -> Forney (values)
- FIFO + err_correct produces corrected output symbols.
