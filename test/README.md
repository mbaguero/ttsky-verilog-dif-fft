# 256-point Short Time Fast Fourier Transform

This directory contains the STFFT for the digital signal preprocessing pipeline. The STFFT is a form of the previously mentioned FFT, however in essence it computes multiple smaller FFT over certain windows. This allows the STFFT to determine audio signals with overlapping frequencies and frequencies that change over time, in our case speech. 

## STFFT Overview

- **Authors**: Michael Aguero: STFFT Wrapper RTL & Verfication, Jose Peralta Window Function Verfication
- **Architecture**: 256-point SFFT using radix-2 decimation-in-frequecy
- **Input/Output**: 16-bit complex samples (16-bit real and imaginary components)
- **Clock**: TBD
- **Processing Time**: TBD

## 256-point FFT Core

Gisselquist Technology's ZipCPU created an open source pipelined FFT generator, this allows us to generate a custom FFT core for the ASIC. This can be done by downloading and building the https://github.com/ZipCPU/dblclockfft that is available on GitHub by ZipCPU. Once the `make` command is complete there will be a `fftgen` executable in the `sw/` directory. Using this executable alongside parameters we can build the custom core:

`./fftgen -f 256 -n 14 -m 18 -k 4 -p 1`


## Windowing Function

## Running Testbench

## Running Simulation

To run the RTL simulation:

```sh
make -B
```

To run gatelevel simulation, first harden your project and copy `../runs/wokwi/results/final/verilog/gl/{your_module_name}.v` to `gate_level_netlist.v`.

Then run:

```sh
make -B GATES=yes
```

If you wish to save the waveform in VCD format instead of FST format, edit tb.v to use `$dumpfile("tb.vcd");` and then run:

```sh
make -B FST=
```

This will generate `tb.vcd` instead of `tb.fst`.

## How to view the waveform file

Using GTKWave

```sh
gtkwave tb.fst tb.gtkw
```

Using Surfer

```sh
surfer tb.fst
```
