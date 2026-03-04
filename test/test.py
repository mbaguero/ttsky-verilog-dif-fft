# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge


def safe_read(sig):
    try:
        val = sig.value
        if isinstance(val, int):
            return val
        return int(val)
    except (ValueError, AttributeError):
        return -1


def safe_read_uio_out(sig):
    """uio_out[7:4] are outputs, [3:0] are inputs (X/Z) - mask to upper nibble only."""
    try:
        val = 0
        raw = sig.value
        for bit in range(4, 8):
            b = raw[bit]
            if str(b) in ('0', '1'):
                val |= (int(b) << bit)
        return val
    except (ValueError, AttributeError):
        return -1


def pack_input(real, imag):
    # real      → ui_in[5:0]
    # imag[1:0] → ui_in[7:6]
    # imag[5:2] → uio_in[3:0]
    ui  = (real & 0x3F) | ((imag & 0x3) << 6)
    uio = (imag >> 2) & 0xF
    return ui, uio


def unpack_output(uo, uio):
    # real      → uo_out[5:0]
    # imag[1:0] → uo_out[7:6]
    # imag[5:2] → uio_out[7:4]
    real = uo & 0x3F
    imag = ((uio >> 4) << 2) | (uo >> 6)
    return real, imag


def to_signed(val, bits=6):
    if val >= (1 << (bits - 1)):
        val -= (1 << bits)
    return val


async def reset_dut(dut):
    dut.ena.value    = 1
    dut.ui_in.value  = 0
    dut.uio_in.value = 0
    dut.rst_n.value  = 0
    await ClockCycles(dut.clk, 10)
    # rst_n released in send_and_receive on the same edge as first sample


async def send_and_receive(dut, samples):
    # Load first sample onto the bus BEFORE releasing reset.
    # This guarantees wr_addr_q=0 when en_i first goes high.
    real, imag = samples[0]
    ui, uio = pack_input(real, imag)
    dut.ui_in.value  = ui
    dut.uio_in.value = uio

    # Release reset — SIPO sees en_i=1 and wr_addr=0 simultaneously
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)   # captures sample[0] into buf[0]

    # Send remaining samples back-to-back
    for real, imag in samples[1:]:
        ui, uio = pack_input(real, imag)
        dut.ui_in.value  = ui
        dut.uio_in.value = uio
        await RisingEdge(dut.clk)

    dut.ui_in.value  = 0
    dut.uio_in.value = 0

    # Wait for PISO active_q — advance one clock each iteration
    for _ in range(20):
        await RisingEdge(dut.clk)
        active = safe_read(dut.dut.piso_inst.active_q)
        if active == 1:
            results = []
            for j in range(4):
                uo  = safe_read(dut.uo_out)
                uio = safe_read_uio_out(dut.uio_out)
                r, i = unpack_output(uo, uio)
                results.append((to_signed(r), to_signed(i)))
                dut._log.info(f"  output {j}: real={to_signed(r)} imag={to_signed(i)}")
                if j < 3:
                    await RisingEdge(dut.clk)
            return results

    dut._log.error("Timed out waiting for PISO active")
    return [(-1, -1)] * 4


@cocotb.test()
async def test_dc(dut):
    """DC input [8,8,8,8] real only.
       FFT([8,8,8,8]) = [32, 0, 0, 0]
       Two stages each divide by 2 → total /4 → [8, 0, 0, 0]
    """
    dut._log.info("Test DC: input [8,8,8,8]")
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    await reset_dut(dut)

    samples = [(8, 0), (8, 0), (8, 0), (8, 0)]
    results = await send_and_receive(dut, samples)

    for k, got in enumerate(results):
        dut._log.info(f"  bin {k}: real={got[0]}, imag={got[1]}")

    assert results[0] == (8, 0), f"bin 0 expected (8,0), got {results[0]}"
    assert results[1] == (0, 0), f"bin 1 expected (0,0), got {results[1]}"
    assert results[2] == (0, 0), f"bin 2 expected (0,0), got {results[2]}"
    assert results[3] == (0, 0), f"bin 3 expected (0,0), got {results[3]}"

    dut._log.info("PASSED")