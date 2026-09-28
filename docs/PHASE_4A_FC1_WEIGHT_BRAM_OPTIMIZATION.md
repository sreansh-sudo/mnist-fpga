# Phase 4A — FC1 Weight Memory BRAM Optimization

## 1. Overview

Phase 4A focuses on optimizing the memory implementation of the FC1 layer of the MNIST FPGA accelerator.

The Phase 3 implementation was functionally correct, but the FC1 weight memory consumed a very large number of LUTs because the weights were implemented as asynchronous LUT-based ROMs.

The objective of Phase 4A was:

> Replace the LUT-based FC1 weight memory with FPGA Block RAM (BRAM/BSRAM) while preserving the exact FC1 functionality and execution latency.

The optimization was implemented and verified using Verilator and synthesized using Gowin EDA for the Tang Nano 20K target FPGA.

## 2. Starting Point — Phase 3 FC1

The Phase 3 FC1 architecture used:

- 784 input pixels
- 32 output neurons
- 8 parallel MAC lanes
- 4 groups of 8 neurons
- 8 independent weight banks
- 3136 weights per bank
- INT8 weights
- 26-bit accumulators
- Requantization + ReLU
- 32 output activations

The weight memory was implemented as eight asynchronous ROM arrays. This resulted in a very large LUT utilization.

## 3. Phase 3 Baseline Synthesis

| Resource | Phase 3 FC1 |
|---|---:|
| LUT | 17,320 |
| Registers | 154 |
| DSP | 9 |
| BSRAM | 1 |
| SSRAM | 4 |
| ALU | 20 |
| Fmax | 78.054 MHz |
| Clock Constraint | 100 MHz |
| Timing | FAIL |

The critical path passed through the FC1 controller, weight memory, MAC datapath and accumulator.

## 4. Optimization Objective

The goal of Phase 4A was to move the FC1 weight storage from LUT-based ROM into FPGA Block RAM.

The original organization was:

```text
8 × 3136 × 8-bit LUT ROMs
```

The optimized organization became:

```text
1 × 3136 × 64-bit BRAM
        ↓
8 weights available per read
```

Each 64-bit word contains eight 8-bit weights.

## 5. Packed BRAM Memory Format

Generated memory file:

```text
data/fc1_bram.mem
```

Configuration:

- Depth: 3136 entries
- Width: 64 bits
- 8 weights per entry
- 8 bits per weight

Packing order:

```text
bits  7:0   = bank0
bits 15:8   = bank1
bits 23:16  = bank2
bits 31:24  = bank3
bits 39:32  = bank4
bits 47:40  = bank5
bits 55:48  = bank6
bits 63:56  = bank7
```

Generator:

```text
python/phase4/create_fc1_bram_mem.py
```

Generator output:

```text
FC1 BRAM memory generated successfully
Output : data/fc1_bram.mem
Depth  : 3136
Width  : 64 bits
Entries: 3136
```

## 6. BRAM Weight Memory RTL

New module:

```text
rtl/fc1_weight_mem_bram.v
```

The memory uses a synchronous read. The packed 64-bit word is split into eight signed INT8 weights and supplied to the eight MAC lanes.

## 7. Functional Verification of Weight Memory

The new BRAM memory was compared against the original eight-bank FC1 weight memory.

Verification coverage:

```text
3136 addresses × 8 weights per address = 25,088 weights
```

Result:

```text
FC1 BRAM WEIGHT MEMORY FUNCTIONAL TEST PASS
Compared all 3136 addresses
All 8 weights matched reference memory
```

Therefore the packed BRAM representation is functionally equivalent to the original weight memory.

## 8. BRAM Read Latency

The original LUT-based memory had asynchronous reads. The new BRAM memory has a synchronous read, introducing a one-cycle memory read latency.

The controller was modified to account for this latency while maintaining one MAC operation per cycle.

New controller:

```text
rtl/fc1_controller_bram.v
```

## 9. Optimized FC1 Architecture

```text
                    +-------------------+
                    |  FC1 Controller   |
                    +---------+---------+
                              |
                +-------------+-------------+
                |             |             |
                v             v             v
        Input Memory     Weight BRAM    Bias Memory
                              |
                         64-bit word
                              |
                      8 × INT8 weights
                              |
                              v
                       +-------------+
                       |   8 MACs    |
                       +------+------+ 
                              |
                       26-bit accumulators
                              |
                              v
                       Requantization
                              |
                              v
                            ReLU
                              |
                              v
                       Activation Memory
```

Top-level optimized module:

```text
rtl/fc1_bram.v
```

Synthesis wrapper:

```text
rtl/fc1_bram_top.v
```

## 10. End-to-End Functional Verification

Testbench:

```text
tb/tb_fc1_bram.v
```

Final result:

```text
FC1 BRAM END-TO-END RESULT
========================================
Passed: 32 / 32
Failed: 0 / 32
Cycles: 3184
```

All 32 FC1 activations matched the expected reference and execution latency remained 3184 cycles.

## 11. Bias Memory Verification

During Phase 4A, a Gowin warning was observed concerning the FC1 bias memory. The memory file uses a 7-hex-digit textual representation for 26-bit signed values.

The bias memory was modified to use a 28-bit loading width while retaining 26-bit outputs.

Equivalence test:

```text
FC1 BIAS MEMORY EQUIVALENCE TEST
Passed: 32 / 32
Failed: 0 / 32
FC1 BIAS MEMORY EQUIVALENCE: PASS
```

The complete FC1 BRAM test was rerun:

```text
Measured FC1 cycles: 3184
Passed: 32 / 32
Failed: 0 / 32
Cycles: 3184
FC1 BRAM END-TO-END TEST: PASS
```

No functional change was introduced.

## 12. Gowin BRAM Inference

An isolated synthesis confirmed successful Block RAM inference for the packed weight memory.

Isolated result:

```text
BSRAM: 16
Logic: 0
Registers: 0
```

## 13. Full FC1 BRAM Synthesis

Target:

```text
Tang Nano 20K
GW2AR-LV18QN88C8/I7
```

Clock constraint:

```text
100 MHz
```

Current synthesis results:

| Resource | FC1 BRAM |
|---|---:|
| LUT | 596 |
| Registers | 154 |
| ALU | 14 |
| SSRAM | 4 |
| DSP | 8 |
| BSRAM | 17 |

The report showed approximately 635 combined logic resources, 154 registers, and 17/46 BSRAM.

## 14. Timing Results

Gowin synthesis reported:

```text
Clock Constraint : 100.000 MHz
Actual Fmax      : 124.193 MHz
```

Therefore the optimized FC1 meets the 100 MHz target.

Reported critical-path slack:

```text
1.948 ns
```

Reported arrival data-path delay:

```text
7.348 ns
```

The critical path still involved the FC1 MAC datapath, particularly the lane 7 accumulator path.

## 15. Before vs After

| Metric | Phase 3 FC1 | Phase 4A FC1 BRAM |
|---|---:|---:|
| LUT | 17,320 | 596 |
| Registers | 154 | 154 |
| DSP | 9 | 8 |
| BSRAM | 1 | 17 |
| SSRAM | 4 | 4 |
| Fmax | 78.054 MHz | 124.193 MHz |
| Clock Target | 100 MHz | 100 MHz |
| Timing | FAIL | PASS |
| Functional Test | PASS | PASS |
| Activation Test | 32/32 | 32/32 |
| Cycles | 3,184 | 3,184 |

## 16. LUT Reduction

LUT count:

```text
17,320 → 596
```

Reduction:

```text
16,724 LUTs
```

Percentage reduction:

```text
≈ 96.6%
```

## 17. Frequency Improvement

Maximum frequency:

```text
78.054 MHz → 124.193 MHz
```

Increase:

```text
46.139 MHz
```

Relative increase:

```text
≈ 59.1%
```

Frequency headroom over the 100 MHz target:

```text
24.193 MHz
```

## 18. Functional Equivalence Summary

Verified properties:

- Same quantized weights
- Same weight values at every address
- Same eight weights presented to the eight MAC lanes
- Same bias values
- Same FC1 activation outputs
- Same 3184-cycle execution
- 32/32 activation checks passed

The optimization changed the hardware implementation of weight storage, not the numerical behavior of the FC1 layer.

## 19. Files Added or Modified

### New files

```text
rtl/fc1_weight_mem_bram.v
rtl/fc1_weight_mem_bram_top.v
rtl/fc1_controller_bram.v
rtl/fc1_bram.v
rtl/fc1_bram_top.v

python/phase4/create_fc1_bram_mem.py

data/fc1_bram.mem

tb/tb_fc1_bram.v
```

### Modified file

```text
rtl/fc1_bias_mem.v
```

### Backup used during verification

```text
rtl/fc1_bias_mem_original.v
```

The backup was used only for equivalence checking and should not remain as a duplicate module in the Gowin synthesis project.

## 20. Important Design Lessons

### 20.1 Memory architecture matters

The original FC1 weight storage consumed a very large amount of LUT resources. Moving the weights into FPGA BSRAM dramatically reduced logic utilization.

### 20.2 BRAM introduces latency

Replacing an asynchronous LUT ROM with synchronous BRAM introduces read latency. The controller must be designed around the BRAM timing.

### 20.3 Packed memory can preserve parallelism

The eight FC1 weight banks were packed into one 64-bit memory word:

```text
64-bit BRAM read
       ↓
8 × 8-bit weights
       ↓
8 parallel MAC lanes
```

The memory architecture therefore changed without reducing datapath parallelism.

### 20.4 Functional verification comes before optimization claims

The BRAM implementation was first checked against the original memory:

```text
25,088 weights compared
25,088 matched
```

Then the complete FC1 datapath was verified:

```text
32 / 32 activations passed
3184 cycles
```

Only after functional verification was the synthesized resource improvement recorded.

## 21. Phase 4A Status

## COMPLETE

Phase 4A successfully achieved its objective:

> Replace the LUT-heavy FC1 weight memory with FPGA BRAM while preserving functionality and execution latency.

Final verified state:

```text
Functional verification : PASS
Weight memory comparison : PASS
Bias memory comparison   : PASS
FC1 end-to-end test      : PASS
Activations              : 32 / 32
Execution cycles         : 3184
Target frequency         : 100 MHz
Actual Fmax              : 124.193 MHz
Timing                   : PASS
```

Major hardware improvement:

```text
FC1 LUT usage:
17,320 → 596

≈ 96.6% reduction
```

## 22. Phase 4A Checkpoint

Treat the Phase 4A RTL as a verified baseline.

Before making further RTL changes, rerun as appropriate:

1. Weight-memory equivalence test
2. Bias-memory equivalence test if bias RTL changes
3. Full FC1 end-to-end test
4. Gowin synthesis
5. Timing analysis

The measured Phase 4A results should be preserved before beginning the next optimization.

## 23. Next Step

Phase 4B has **not yet been defined**.

The next optimization target should be selected only after examining the remaining synthesized resource usage and identifying a measurable hardware bottleneck.

Project flow:

```text
Phase 3
Functional MNIST FPGA
        ↓
Phase 4A
FC1 Weight Memory → BRAM
        ↓
Verified
        ↓
Document + Git checkpoint
        ↓
Resource analysis
        ↓
Phase 4B
Next optimization target
```

No specific Phase 4B optimization should be assumed until the remaining hardware cost has been measured.
