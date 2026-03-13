![](../../workflows/gds/badge.svg) ![](../../workflows/docs/badge.svg) ![](../../workflows/test/badge.svg) ![](../../workflows/fpga/badge.svg)

# 4-Point Decimation in Frequecy Fast Fourier Transform Tiny Tapeout
This project implements a 4-point DIF FFT, with an IO of:

Inputs:
ui_in[5:0] -> 6 bit real sample
{uio_in[3:0], ui_in[7:6]} -> 6 bit imaginary sample

Outputs:
uo_out[5:0] -> 6 bit real FFT result
{uio_out[7:4], uo_out[7:6]} -> 6 bit imaginary FFT result


This is achieved by having an "SIPO" that instead of loading a bit at a time loads 2 6 bit inputs (6 bits for real and 6 bits for imaginary -> 1 complex sample) then outputs 4 6 bit real samples alongside 4 6 bit imagimary samples. This is then fed into a 4-point DIF FFT, which outputs the computed frames. The output of the FFT is then fed into a "PISO" which takes the 4 6 bit real results and 4 6 bit imaginary results as an input then outputs 1 6 bit real result and 1 6 bit imaginary result(1 compelx result). 


## 4-Point FFT Overview
- **Authors**: Michael Aguero
- **Architecture**: 4-point FFT using radix-2 decimation-in-frequecy
- **Input/Output**: 6-bit complex samples (6-bit real and imaginary components)
- **Clock**: 100kHz
- **Processing Time**: TBD


