# Phase 5 — FC1 Resource Optimization and Timing Recovery

## Objective

Phase 5 reduced FPGA resource usage in the MNIST accelerator while recovering timing performance for approximately 100 MHz operation.

The optimization targeted FC1:

1. Reduce FC1 parallelism from 8 lanes to 4 lanes.
2. Pipeline the FC1 MAC input/weight path.
3. Verify functional equivalence.
4. Re-synthesize and perform full-network place-and-route.
5. Verify the complete network with Verilator.

## Starting Point

Architecture:

```text
784 inputs → FC1 784→32 → ReLU/requantization → FC2 32→10 → Argmax
```

Integer specification:

- Input: unsigned INT8, scale 128
- FC1 weights: signed INT8, scale 64
- FC1 accumulator: signed 26-bit
- FC1 activation: unsigned INT8
- FC2 weights: signed INT8, scale 64
- FC2 accumulator: signed 21-bit
- Output: direct argmax

Known-good reference logits:

```text
logit0 = -98
logit1 = -5615
logit2 = 122
logit3 = 1592
logit4 = -6785
logit5 = -1238
logit6 = -7236
logit7 = 4401
logit8 = -632
logit9 = -1021

Predicted digit = 7
```

## 8-Lane FC1 Baseline

The 8-lane BRAM FC1 implementation processed eight neurons in parallel.

Full-network post-P&R result:

- Total DSP usage: 18
- Post-P&R Fmax: approximately 87.967 MHz
- Worst setup slack: approximately -1.396 ns
- Approximately 100 MHz timing target: failed

This motivated reducing FC1 parallelism.

## Four-Lane FC1 Architecture

FC1 was changed from eight parallel MAC lanes to four.

Each group of eight neurons is processed in two phases:

```text
Phase 0: lower 4 neurons
Phase 1: upper 4 neurons
```

Groups:

```text
Group 0: neurons  0–7
Group 1: neurons  8–15
Group 2: neurons 16–23
Group 3: neurons 24–31
```

The complete FC1 still produces all 32 outputs while using four parallel MAC lanes.

Measured FC1 latency:

```text
6336 clock cycles
63.36 us @ 100 MHz
```

## Four-Lane Functional Verification

All 32 FC1 activation values matched the expected reference.

Expected vector:

```text
[0,33,21,0,0,41,37,46,
 40,40,14,0,42,21,27,7,
 34,39,0,34,31,17,5,0,
 2,1,25,0,24,0,0,3]
```

Result:

```text
FC1 4-LANE TEST PASS
```

## MAC Pipelining

The four-lane implementation was then pipelined.

Main experimental files:

```text
rtl/fc1_mac4_pipe.v
rtl/fc1_controller_bram4_pipe.v
rtl/fc1_bram4_pipe.v
```

The pipelined FC1 simulation produced the same 32 activation values as the reference.

Measured latency remained:

```text
6336 cycles
```

## Standalone Synthesis Comparison

### Four-Lane Baseline

| Resource | Usage |
|---|---:|
| Registers | 86 |
| LUT | 355 |
| ALU | 14 |
| DSP | 4 |
| BSRAM | 17 |
| SSRAM | 4 |
| Synthesis Fmax | 110.120 MHz |

### Four-Lane Pipelined

| Resource | Usage |
|---|---:|
| Registers | 123 |
| LUT | 340 |
| ALU | 14 |
| DSP | 4 |
| BSRAM | 17 |
| SSRAM | 4 |
| Synthesis Fmax | 124.502 MHz |

The pipeline added 37 registers and reduced LUT usage by 15.

DSP, BSRAM, ALU, and SSRAM usage remained unchanged.

Synthesis Fmax increased from 110.120 MHz to 124.502 MHz.

## Full-Network Synthesis

Full-network pipelined four-lane FC1:

| Resource | Usage |
|---|---:|
| Registers | 374 |
| LUT | 1343 |
| ALU | 47 |
| SSRAM | 4 |
| DSP | 14 |
| BSRAM | 21 |
| I/O | 7 |

Synthesis Fmax:

```text
124.502 MHz
```

PLL output clock:

```text
100.286 MHz
```

## Full-Network Place and Route

The complete board-level Gowin design successfully completed:

- Placement
- Routing
- Timing
- Bitstream generation
- Power analysis

Worst post-P&R setup path:

```text
Arrival = 17.529 ns
Required = 17.537 ns
Slack = +0.008 ns
```

The approximately 100.286 MHz target was therefore met by approximately 8 ps.

The critical path moved to FC2:

```text
u_mnist/fc2_inst/controller/input_addr_2_s1
→ u_mnist/fc1_inst/activation_memory/memory_memory_0_1_s
→ u_mnist/fc1_inst/activation_memory/memory_DOL_5_G[0]_s0
→ u_mnist/fc2_inst/mac_units/lane0/n73_s2
→ u_mnist/fc2_inst/mac_units/lane0/n80_s4
→ u_mnist/fc2_inst/mac_units/lane0/accumulator_14_s3
```

The timing result is a marginal pass because the available setup margin is only approximately 8 ps.

## Full-Network Verilator Regression

The complete pipelined network passed the existing full-network MNIST testbench.

Final logits:

```text
logit0 = -98
logit1 = -5615
logit2 = 122
logit3 = 1592
logit4 = -6785
logit5 = -1238
logit6 = -7236
logit7 = 4401
logit8 = -632
logit9 = -1021
```

Prediction:

```text
Predicted digit = 7
Expected digit  = 7
```

Result:

```text
MNIST FULL NETWORK TEST: PASS
```

Simulation time:

```text
63730 ns
```

The logits exactly match the known-good reference.

## Resource Reduction

Previous 8-lane BRAM FC1 full-network implementation:

```text
18 DSPs
```

Final four-lane pipelined implementation:

```text
14 DSPs
```

Reduction:

```text
4 DSPs
≈22.2% of the previous total DSP usage
```

The reduction was achieved while preserving the exact output logits for the verified test vector.

## Final Phase 5 Architecture

```text
                 ┌─────────────────────┐
Input Image ────►│ FC1 Input Memory     │
                 └──────────┬──────────┘
                            │
                            ▼
                 ┌─────────────────────┐
                 │ 4-Lane Pipelined    │
                 │ FC1 MAC Engine      │
                 └──────────┬──────────┘
                            │
                            ▼
                 ┌─────────────────────┐
                 │ Requantize + ReLU   │
                 └──────────┬──────────┘
                            │
                            ▼
                 ┌─────────────────────┐
                 │ FC1 Activation RAM  │
                 └──────────┬──────────┘
                            │
                            ▼
                 ┌─────────────────────┐
                 │ FC2 — 10 MAC Lanes │
                 └──────────┬──────────┘
                            │
                            ▼
                 ┌─────────────────────┐
                 │     Argmax 10       │
                 └──────────┬──────────┘
                            │
                            ▼
                       Digit 7
```

## Phase 5 Verification Summary

| Verification | Result |
|---|---|
| Four-lane FC1 simulation | PASS |
| Pipelined MAC simulation | PASS |
| Pipelined FC1 simulation | PASS |
| Full-network Verilator | PASS |
| Exact FC2 logits | MATCH |
| Predicted digit | 7 |
| Full-network synthesis | PASS |
| Full-network P&R | PASS |
| Bitstream generation | PASS |
| Target timing | PASS by 0.008 ns |

## Important Timing Qualification

Post-P&R setup slack:

```text
+0.008 ns
```

This is only an approximately 8 ps margin.

The implementation should therefore be described as:

```text
Nominal 100 MHz timing pass with marginal setup margin
```

rather than as comfortable timing closure.

## Phase 5 Conclusion

Phase 5 successfully demonstrated a resource/timing trade-off in the MNIST FPGA accelerator.

FC1 was changed from eight parallel MAC lanes to four pipelined MAC lanes.

The final implementation:

- Reduces total DSP usage from 18 to 14.
- Preserves exact inference results for the verified test vector.
- Passes the complete Verilator full-network regression.
- Synthesizes successfully.
- Completes full board-level place-and-route.
- Generates a bitstream.
- Meets the approximately 100 MHz post-P&R timing target with +0.008 ns setup slack.

The remaining limitation is the very small timing margin. Physical-board validation is still required before treating the accelerator as hardware-validated.

## Next Phase

The natural next step is physical validation on the Sipeed Tang Nano 20K:

```text
Generated bitstream
       ↓
Program Tang Nano 20K
       ↓
Verify FPGA boots
       ↓
Verify clock/reset behavior
       ↓
Run MNIST inference
       ↓
Observe predicted digit
       ↓
Compare hardware result with Verilator
```

Phase 5 establishes the optimized RTL and implementation candidate for hardware validation.
