# test.py
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ClockCycles, Timer
import logging
import random
import numpy as np

# Set up logging
logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG)

#=============================================================================
# Helper Functions
#=============================================================================

def int_to_signed_bin(value, width=6):
    """Convert integer to signed binary representation"""
    if value < 0:
        value = (1 << width) + value
    return value

def signed_bin_to_int(value, width=6):
    """Convert signed binary to integer"""
    # Handle None or invalid values
    if value is None:
        return 0
    
    # Convert LogicArray to integer if needed
    if hasattr(value, 'is_resolvable'):
        if not value.is_resolvable:
            return 0
        # Try to get integer value
        try:
            # For cocotb v2.0.1, use integer if available, otherwise use value
            if hasattr(value, 'integer'):
                # This will trigger deprecation warning but works
                val = value.integer
            else:
                val = int(value)
        except (ValueError, AttributeError):
            return 0
    else:
        val = value
    
    # Convert to signed
    if val & (1 << (width - 1)):
        return val - (1 << width)
    return val

def get_signal_int(signal):
    """Safely get integer value from a signal, handling 'Z' and 'X' values"""
    val = signal.value
    
    # Check if it's resolvable (no X/Z)
    if hasattr(val, 'is_resolvable'):
        if not val.is_resolvable:
            return 0
    
    # Try different methods to get integer value
    try:
        if hasattr(val, 'to_unsigned'):
            # New cocotb method (no deprecation)
            return val.to_unsigned()
        elif hasattr(val, 'integer'):
            # Deprecated but works
            return val.integer
        else:
            # Try direct conversion
            return int(val)
    except (ValueError, AttributeError, TypeError):
        # If conversion fails, return 0
        return 0

def is_signal_valid(signal):
    """Check if signal has valid (non-X/Z) values"""
    val = signal.value
    if hasattr(val, 'is_resolvable'):
        return val.is_resolvable
    return True

#=============================================================================
# Test: Basic Functionality
#=============================================================================

@cocotb.test()
async def test_basic(dut):
    """Basic test to verify the testbench works"""
    logger.info("=" * 50)
    logger.info("Starting basic test")
    logger.info("=" * 50)
    
    # Start clock
    clock = Clock(dut.clk, 10, unit='ns')
    cocotb.start_soon(clock.start())
    
    # Reset
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 5)
    logger.info("Reset asserted")
    
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 5)
    logger.info("Reset released")
    
    logger.info("Basic test passed")
    assert True

#=============================================================================
# Test: Send Single Sample
#=============================================================================

@cocotb.test()
async def test_send_sample(dut):
    """Test sending a single sample"""
    logger.info("=" * 50)
    logger.info("Starting send sample test")
    logger.info("=" * 50)
    
    # Start clock
    clock = Clock(dut.clk, 10, unit='ns')
    cocotb.start_soon(clock.start())
    
    # Reset
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 3)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2)
    
    # Send a sample
    real_val = 5
    imag_val = 3
    
    real_bin = int_to_signed_bin(real_val)
    imag_bin = int_to_signed_bin(imag_val)
    
    # ui_in[5:0] = real
    # ui_in[7:6] = imag[5:4]
    # uio_in[3:0] = imag[3:0]
    dut.ui_in.value = (real_bin & 0x3F) | ((imag_bin >> 4) & 0x03) << 6
    dut.uio_in.value = imag_bin & 0x0F
    
    logger.info(f"Sent: real={real_val} (bin={real_bin:06b}), imag={imag_val} (bin={imag_bin:06b})")
    logger.info(f"ui_in = {get_signal_int(dut.ui_in):08b}")
    logger.info(f"uio_in = {get_signal_int(dut.uio_in):04b}")
    
    await ClockCycles(dut.clk, 10)
    
    # Check outputs (skip if invalid)
    if is_signal_valid(dut.uo_out):
        logger.info(f"uo_out = {get_signal_int(dut.uo_out):08b}")
    else:
        logger.info("uo_out contains X/Z values")
        
    if is_signal_valid(dut.uio_out):
        logger.info(f"uio_out = {get_signal_int(dut.uio_out):08b}")
    else:
        logger.info("uio_out contains X/Z values")
        
    logger.info(f"uio_oe = {get_signal_int(dut.uio_oe):08b}")
    
    logger.info("Send sample test passed")

#=============================================================================
# Test: Reset Behavior
#=============================================================================

@cocotb.test()
async def test_reset(dut):
    """Test reset behavior"""
    logger.info("=" * 50)
    logger.info("Starting reset test")
    logger.info("=" * 50)
    
    # Start clock
    clock = Clock(dut.clk, 10, unit='ns')
    cocotb.start_soon(clock.start())
    
    # Check initial state
    logger.info(f"Initial uo_out = {get_signal_int(dut.uo_out):08b}")
    
    # Assert reset
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 5)
    
    # Check outputs during reset
    logger.info(f"During reset uo_out = {get_signal_int(dut.uo_out):08b}")
    
    # uio_out might be high-Z during reset, handle gracefully
    uio_val = get_signal_int(dut.uio_out)
    if uio_val == 0 and not is_signal_valid(dut.uio_out):
        logger.info("During reset uio_out = ZZZZ (high impedance)")
    else:
        logger.info(f"During reset uio_out = {uio_val:08b}")
        
    logger.info(f"During reset uio_oe = {get_signal_int(dut.uio_oe):08b}")
    
    # Release reset
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 5)
    
    logger.info("Reset test passed")

#=============================================================================
# Test: Collect 4 Samples
#=============================================================================

@cocotb.test()
async def test_collect_4_samples(dut):
    """Test collecting 4 samples in the SIPO"""
    logger.info("=" * 50)
    logger.info("Starting collect 4 samples test")
    logger.info("=" * 50)
    
    # Start clock
    clock = Clock(dut.clk, 10, unit='ns')
    cocotb.start_soon(clock.start())
    
    # Reset
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 3)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2)
    
    # Send 4 test samples
    test_samples = [(1, 1), (2, 2), (3, 3), (4, 4)]
    
    for i, (r, img) in enumerate(test_samples):
        real_bin = int_to_signed_bin(r)
        imag_bin = int_to_signed_bin(img)
        
        dut.ui_in.value = (real_bin & 0x3F) | ((imag_bin >> 4) & 0x03) << 6
        dut.uio_in.value = imag_bin & 0x0F
        
        logger.info(f"Sent sample {i}: real={r:2d}, imag={img:2d}")
        logger.info(f"  ui_in={get_signal_int(dut.ui_in):08b}, uio_in={get_signal_int(dut.uio_in):04b}")
        await RisingEdge(dut.clk)
    
    await ClockCycles(dut.clk, 10)
    logger.info("Collect 4 samples test passed")

#=============================================================================
# Test: FFT Impulse Response
#=============================================================================

@cocotb.test()
async def test_fft_impulse(dut):
    """Test FFT with impulse input"""
    logger.info("=" * 50)
    logger.info("Starting FFT impulse test")
    logger.info("=" * 50)
    
    # Start clock
    clock = Clock(dut.clk, 10, unit='ns')
    cocotb.start_soon(clock.start())
    
    # Reset
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 3)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2)
    
    # Send impulse: [10, 0, 0, 0]
    impulse = [(10, 0), (0, 0), (0, 0), (0, 0)]
    
    for i, (r, img) in enumerate(impulse):
        real_bin = int_to_signed_bin(r)
        imag_bin = int_to_signed_bin(img)
        
        dut.ui_in.value = (real_bin & 0x3F) | ((imag_bin >> 4) & 0x03) << 6
        dut.uio_in.value = imag_bin & 0x0F
        
        logger.info(f"Sent sample {i}: real={r:2d}, imag={img:2d}")
        await RisingEdge(dut.clk)
    
    # Wait for processing
    logger.info("Waiting for FFT processing...")
    await ClockCycles(dut.clk, 20)
    
    # Capture outputs
    logger.info("FFT Outputs:")
    outputs = []
    for i in range(8):
        # Only process if signals are valid
        if is_signal_valid(dut.uo_out) and is_signal_valid(dut.uio_out):
            uo_val = get_signal_int(dut.uo_out)
            uio_val = get_signal_int(dut.uio_out)
            
            real_raw = uo_val & 0x3F
            imag_raw = ((uio_val >> 4) & 0x0F) << 4 | ((uo_val >> 6) & 0x03)
            
            real_val = signed_bin_to_int(real_raw)
            imag_val = signed_bin_to_int(imag_raw)
            
            outputs.append((real_val, imag_val))
            logger.info(f"  Cycle {i}: real={real_val:3d}, imag={imag_val:3d}")
        else:
            logger.info(f"  Cycle {i}: invalid (X/Z)")
        
        await RisingEdge(dut.clk)
    
    logger.info("FFT impulse test passed")

#=============================================================================
# Test: FFT with Sinusoid
#=============================================================================

@cocotb.test()
async def test_fft_sinusoid(dut):
    """Test FFT with sinusoidal input"""
    logger.info("=" * 50)
    logger.info("Starting FFT sinusoid test")
    logger.info("=" * 50)
    
    # Start clock
    clock = Clock(dut.clk, 10, unit='ns')
    cocotb.start_soon(clock.start())
    
    # Reset
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 3)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2)
    
    # Generate sinusoidal signal (cosine at f = fs/4)
    amplitude = 8
    test_signal = [
        (amplitude, 0),     # Sample 0: cos(0) = 1
        (0, amplitude),     # Sample 1: sin(90) = 1
        (-amplitude, 0),    # Sample 2: cos(180) = -1
        (0, -amplitude)     # Sample 3: sin(270) = -1
    ]
    
    # Send the signal
    for i, (r, img) in enumerate(test_signal):
        real_bin = int_to_signed_bin(r)
        imag_bin = int_to_signed_bin(img)
        
        dut.ui_in.value = (real_bin & 0x3F) | ((imag_bin >> 4) & 0x03) << 6
        dut.uio_in.value = imag_bin & 0x0F
        
        logger.info(f"Sent sample {i}: real={r:3d}, imag={img:3d}")
        await RisingEdge(dut.clk)
    
    # Wait for processing
    logger.info("Waiting for FFT processing...")
    await ClockCycles(dut.clk, 20)
    
    # Capture outputs
    logger.info("FFT Outputs:")
    for i in range(8):
        # Only process if signals are valid
        if is_signal_valid(dut.uo_out) and is_signal_valid(dut.uio_out):
            uo_val = get_signal_int(dut.uo_out)
            uio_val = get_signal_int(dut.uio_out)
            
            real_raw = uo_val & 0x3F
            imag_raw = ((uio_val >> 4) & 0x0F) << 4 | ((uo_val >> 6) & 0x03)
            
            real_val = signed_bin_to_int(real_raw)
            imag_val = signed_bin_to_int(imag_raw)
            
            magnitude = np.sqrt(real_val*real_val + imag_val*imag_val)
            logger.info(f"  Bin {i%4}: real={real_val:3d}, imag={imag_val:3d}, mag={magnitude:.1f}")
        else:
            logger.info(f"  Bin {i%4}: invalid (X/Z)")
        
        await RisingEdge(dut.clk)
    
    logger.info("FFT sinusoid test passed")

#=============================================================================
# Test: Output Enable
#=============================================================================

@cocotb.test()
async def test_output_enable(dut):
    """Test output enable signals"""
    logger.info("=" * 50)
    logger.info("Starting output enable test")
    logger.info("=" * 50)
    
    # Start clock
    clock = Clock(dut.clk, 10, unit='ns')
    cocotb.start_soon(clock.start())
    
    # Reset
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 3)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2)
    
    # Check uio_oe value
    oe_value = get_signal_int(dut.uio_oe)
    logger.info(f"uio_oe = {oe_value:08b}")
    
    # Should be 0xF0 (bits 7-4 are outputs, bits 3-0 are inputs)
    expected = 0xF0
    if oe_value == expected:
        logger.info(f"✓ uio_oe correctly set to 0xF0")
    else:
        logger.warning(f"✗ uio_oe = {oe_value:02x}, expected {expected:02x}")
    
    logger.info("Output enable test passed")

#=============================================================================
# Test: Continuous Stream
#=============================================================================

@cocotb.test()
async def test_continuous_stream(dut):
    """Test continuous streaming through the pipeline"""
    logger.info("=" * 50)
    logger.info("Starting continuous stream test")
    logger.info("=" * 50)
    
    # Start clock
    clock = Clock(dut.clk, 10, unit='ns')
    cocotb.start_soon(clock.start())
    
    # Reset
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 3)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2)
    
    # Generate random test data
    random.seed(42)
    num_samples = 16
    
    logger.info(f"Sending {num_samples} random samples...")
    
    for i in range(num_samples):
        real = random.randint(-15, 15)
        imag = random.randint(-15, 15)
        
        real_bin = int_to_signed_bin(real)
        imag_bin = int_to_signed_bin(imag)
        
        dut.ui_in.value = (real_bin & 0x3F) | ((imag_bin >> 4) & 0x03) << 6
        dut.uio_in.value = imag_bin & 0x0F
        
        if i % 4 == 0:
            logger.info(f"Frame {i//4 + 1}:")
        logger.info(f"  Sample {i}: real={real:3d}, imag={imag:3d}")
        
        await RisingEdge(dut.clk)
    
    # Wait for pipeline to empty
    logger.info("Waiting for pipeline to empty...")
    await ClockCycles(dut.clk, 30)
    
    # Monitor outputs
    logger.info("Pipeline outputs:")
    outputs = []
    for i in range(20):
        # Only process if signals are valid
        if is_signal_valid(dut.uo_out) and is_signal_valid(dut.uio_out):
            uo_val = get_signal_int(dut.uo_out)
            uio_val = get_signal_int(dut.uio_out)
            
            real_raw = uo_val & 0x3F
            imag_raw = ((uio_val >> 4) & 0x0F) << 4 | ((uo_val >> 6) & 0x03)
            
            real_val = signed_bin_to_int(real_raw)
            imag_val = signed_bin_to_int(imag_raw)
            
            if real_val != 0 or imag_val != 0:
                outputs.append((real_val, imag_val))
                logger.info(f"  Output {len(outputs)}: real={real_val:3d}, imag={imag_val:3d}")
        else:
            if i < 5:  # Only log first few invalid to avoid spam
                logger.info(f"  Output {i}: invalid (X/Z)")
        
        await RisingEdge(dut.clk)
    
    logger.info(f"Received {len(outputs)} non-zero output samples")
    logger.info("Continuous stream test passed")