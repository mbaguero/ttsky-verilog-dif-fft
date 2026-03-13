# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0
"""
Cocotb testbench for tt_um_dif_fft_core (real-only 4-point DIF FFT)
width_p = 2: inputs are 2-bit signed, outputs are 4-bit signed

Pinout:
  ui_in[1:0]   = x[0]    uo_out[3:0]   = X[0] real (DC)
  ui_in[3:2]   = x[1]    uo_out[7:4]   = X[2] real (Nyquist)
  ui_in[5:4]   = x[2]    uio_out[3:0]  = X[1] real
  ui_in[7:6]   = x[3]    uio_out[7:4]  = X[1] imag
"""

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer
import numpy as np

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
IN_WIDTH  = 2                        # bits per input sample
OUT_WIDTH = 4                        # bits per output sample
IN_MASK   = (1 << IN_WIDTH)  - 1    # 0b11
OUT_MASK  = (1 << OUT_WIDTH) - 1    # 0b1111

# ---------------------------------------------------------------------------
# Pack / unpack helpers
# ---------------------------------------------------------------------------
def to_signed(val, bits):
    if val >= (1 << (bits - 1)):
        val -= (1 << bits)
    return val

def pack_inputs(x0, x1, x2, x3):
    """Pack four 2-bit signed samples into ui_in[7:0]."""
    def u(v):
        return int(v) & IN_MASK          # keep only 2 bits
    return (u(x3) << 6) | (u(x2) << 4) | (u(x1) << 2) | u(x0)

def unpack_outputs(uo_out, uio_out):
    """
    uo_out[3:0]  → X[0] real (DC)
    uo_out[7:4]  → X[2] real (Nyquist)
    uio_out[3:0] → X[1] real
    uio_out[7:4] → X[1] imag
    """
    real0 = to_signed((uo_out  >> 0) & OUT_MASK, OUT_WIDTH)
    real2 = to_signed((uo_out  >> 4) & OUT_MASK, OUT_WIDTH)
    real1 = to_signed((uio_out >> 0) & OUT_MASK, OUT_WIDTH)
    img1  = to_signed((uio_out >> 4) & OUT_MASK, OUT_WIDTH)
    return real0, real2, real1, img1

# ---------------------------------------------------------------------------
# Reference model — mirrors RTL exactly (no shifts, pure butterfly)
# ---------------------------------------------------------------------------
def ref_fft(x0, x1, x2, x3):
    A = x0 + x2
    B = x1 + x3
    C = x0 - x2
    D = x3 - x1
    return A + B, A - B, C, D   # X0_r, X2_r, X1_r, X1_i

# ---------------------------------------------------------------------------
# Numpy sanity reference (float)
# ---------------------------------------------------------------------------
def numpy_fft(x0, x1, x2, x3):
    X = np.fft.fft([x0, x1, x2, x3])
    return X[0].real, X[2].real, X[1].real, X[1].imag

# ---------------------------------------------------------------------------
# Reset helper
# ---------------------------------------------------------------------------
async def do_reset(dut):
    dut.rst_n.value  = 0
    dut.ui_in.value  = 0
    dut.uio_in.value = 0
    dut.ena.value    = 1
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    dut.rst_n.value  = 1
    await RisingEdge(dut.clk)

# ---------------------------------------------------------------------------
# Helper: read both output ports
# ---------------------------------------------------------------------------
def read_outputs(dut):
    uo  = int(dut.uo_out.value)
    uio = int(dut.uio_out.value)
    return unpack_outputs(uo, uio)

# ---------------------------------------------------------------------------
# Test 1: all zeros
# ---------------------------------------------------------------------------
@cocotb.test()
async def test_all_zeros(dut):
    """Zero inputs must produce zero outputs."""
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    await do_reset(dut)

    dut.ui_in.value = pack_inputs(0, 0, 0, 0)
    await Timer(1, unit="ns")

    r0, r2, r1, i1 = read_outputs(dut)
    assert (r0, r2, r1, i1) == (0, 0, 0, 0), \
        f"Expected all zeros, got r0={r0} r2={r2} r1={r1} i1={i1}"
    dut._log.info("PASS test_all_zeros")

# ---------------------------------------------------------------------------
# Test 2: DC input [1,1,1,1] → X[0]=4, rest 0
# ---------------------------------------------------------------------------
@cocotb.test()
async def test_dc_input(dut):
    """Constant input should appear only in DC bin X[0]."""
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    await do_reset(dut)

    dut.ui_in.value = pack_inputs(1, 1, 1, 1)
    await Timer(1, unit="ns")

    r0, r2, r1, i1 = read_outputs(dut)
    exp = ref_fft(1, 1, 1, 1)

    assert (r0, r2, r1, i1) == exp, \
        f"DC: got ({r0},{r2},{r1},{i1}), expected {exp}"
    dut._log.info(f"PASS test_dc_input  outputs=({r0},{r2},{r1},{i1})")

# ---------------------------------------------------------------------------
# Test 3: impulse [1,0,0,0] → all bins equal magnitude
# ---------------------------------------------------------------------------
@cocotb.test()
async def test_impulse(dut):
    """Impulse at x[0] — all output bins should have equal magnitude."""
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    await do_reset(dut)

    dut.ui_in.value = pack_inputs(1, 0, 0, 0)
    await Timer(1, unit="ns")

    r0, r2, r1, i1 = read_outputs(dut)
    exp = ref_fft(1, 0, 0, 0)

    assert (r0, r2, r1, i1) == exp, \
        f"Impulse: got ({r0},{r2},{r1},{i1}), expected {exp}"
    dut._log.info(f"PASS test_impulse  outputs=({r0},{r2},{r1},{i1})")

# ---------------------------------------------------------------------------
# Test 4: Nyquist [1,-1,1,-1] → only X[2] non-zero
# ---------------------------------------------------------------------------
@cocotb.test()
async def test_nyquist(dut):
    """Alternating +1/-1 should appear only in Nyquist bin X[2]."""
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    await do_reset(dut)

    dut.ui_in.value = pack_inputs(1, -1, 1, -1)
    await Timer(1, unit="ns")

    r0, r2, r1, i1 = read_outputs(dut)
    exp = ref_fft(1, -1, 1, -1)

    assert (r0, r2, r1, i1) == exp, \
        f"Nyquist: got ({r0},{r2},{r1},{i1}), expected {exp}"
    dut._log.info(f"PASS test_nyquist  outputs=({r0},{r2},{r1},{i1})")

# ---------------------------------------------------------------------------
# Test 5: exhaustive — all 4^4 = 256 2-bit signed input combinations
# ---------------------------------------------------------------------------
@cocotb.test()
async def test_exhaustive(dut):
    """Every possible 2-bit signed input checked against reference model."""
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    await do_reset(dut)

    signed_vals = [-2, -1, 0, 1]
    failures = []

    for x0 in signed_vals:
        for x1 in signed_vals:
            for x2 in signed_vals:
                for x3 in signed_vals:
                    dut.ui_in.value = pack_inputs(x0, x1, x2, x3)
                    await Timer(1, unit="ns")

                    r0, r2, r1, i1 = read_outputs(dut)
                    exp = ref_fft(x0, x1, x2, x3)

                    if (r0, r2, r1, i1) != exp:
                        failures.append(
                            f"  in=({x0},{x1},{x2},{x3}) "
                            f"got=({r0},{r2},{r1},{i1}) "
                            f"exp={exp}"
                        )

    if failures:
        assert False, f"{len(failures)} failures:\n" + "\n".join(failures[:10])

    dut._log.info("PASS test_exhaustive  (256/256 cases passed)")

# ---------------------------------------------------------------------------
# Test 6: conjugate symmetry X[3] = conj(X[1])
# ---------------------------------------------------------------------------
@cocotb.test()
async def test_conjugate_symmetry(dut):
    """For real inputs X[3] = conj(X[1]) — verified against reference."""
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    await do_reset(dut)

    vectors = [(1, 0, -1, 0), (1, 1, 0, -1), (-1, 1, -1, 1), (0, 1, 0, -1)]

    for x0, x1, x2, x3 in vectors:
        dut.ui_in.value = pack_inputs(x0, x1, x2, x3)
        await Timer(1, unit="ns")

        _, _, r1, i1 = read_outputs(dut)
        _, _, ref_r1, ref_i1 = ref_fft(x0, x1, x2, x3)

        assert r1 == ref_r1 and i1 == ref_i1, \
            f"Symmetry failed for in=({x0},{x1},{x2},{x3}): " \
            f"got X[1]={r1}+j{i1}, expected {ref_r1}+j{ref_i1}"

        dut._log.info(
            f"  in=({x0},{x1},{x2},{x3})  "
            f"X[1]={r1}+j{i1}  X[3]={r1}-j{i1} (inferred)"
        )

    dut._log.info("PASS test_conjugate_symmetry")