# Phase 4B — FPGA Optimization Experiments

## 1. Objective

Phase 4B focuses on measured optimization of the Phase 4A MNIST FPGA implementation.

The goal is not to optimize RTL blindly. The methodology is:

1. Establish the known-good Phase 4A baseline.
2. Inspect synthesis/resource/timing reports.
3. Identify the actual bottleneck.
4. Make one small optimization experiment at a time.
5. Verify functional correctness with Verilator.
6. Re-synthesize with Gowin EDA.
7. Compare LUT, FF, BSRAM, SSRAM, DSP, ALU, Fmax, slack, and critical path.
8. Keep an optimization only if the measured improvement justifies its cost.

A rejected optimization experiment is considered a valid engineering result.

---

## 2. Phase 4A Baseline

Phase 4A replaced the original FC1 weight ROM implementation with a packed synchronous BRAM implementation.

### Phase 4A functional status

- FC1 weight memory: 3136 packed 64-bit words
- 8 weight banks packed into one BRAM word
- 32 FC1 neurons
- 8 parallel MAC lanes
- FC1 E2E verification: **32/32 activations correct**
- FC1 latency: **3184 cycles**
- Full FC1 + FC2 image #0:
  - logits: `[-98, -5615, 122, 1592, -6785, -1238, -7236, 4401, -632, -1021]`
  - predicted digit: **7**

### Phase 4A synthesis baseline

| Resource / Metric | Phase 4A |
|---|---:|
| LUT | 597 |
| FF | 154 |
| BSRAM | 17 |
| SSRAM | 4 |
| DSP | 8 |
| ALU | 14 |
| Fmax | 124.193 MHz |
| Worst slack | +1.948 ns |
| Arrival data path delay | 7.348 ns |

The original pre-Phase-4 implementation used approximately 18,332 LUTs and achieved only 78.054 MHz, with -2.812 ns worst slack at the 100 MHz target.

Phase 4A therefore provided a major resource and timing improvement.

---

## 3. Bottleneck Identification

The Phase 4A timing report showed that the critical path had moved away from the controller and into the FC1 MAC datapath.

The critical destination was:

```text
dut/mac8/lane7/accumulator_25_s1
```

The path passed through the Gowin `MULTADDALU18X18` DSP primitive used for the FC1 multiply-accumulate operation.

Important timing observations:

- The FC1 controller was no longer the critical timing bottleneck.
- The BRAM implementation successfully removed the original large LUT-based weight-memory bottleneck.
- The remaining critical path was associated with the DSP/MAC datapath.

Therefore, Phase 4B concentrated on determining whether the MAC datapath could be improved without breaking the cycle-accurate FC1 architecture.

---

## 4. Experiment A — Requantizer Width Reduction

The FC1 requantizer performs:

```text
(accumulator + 512) >>> 10
```

followed by saturation to the unsigned 8-bit activation range.

The original implementation used a 27-bit intermediate:

```verilog
reg signed [26:0] rounded_value;
```

A smaller intermediate width was investigated as a possible LUT optimization.

### Result

The experiment was abandoned.

Synthesis/netlist inspection showed that Gowin was already reducing the relevant logic to the required accumulator bits and implementing the requantization as compact LUT logic. The manual RTL width reduction therefore did not provide a meaningful additional optimization.

The original Phase 4A requantizer was restored unchanged.

### Decision

**Rejected — no measured benefit.**

---

## 5. Experiment B — FC1 Controller Optimization

The FC1 controller contains the address-generation logic:

```text
group * 784 + input_index
```

and generates the MAC, drain, requantization, and store control signals.

A controller simplification was considered because the original Phase 4A timing path had previously involved controller/address-generation logic.

After Phase 4A BRAM conversion, however, the controller was no longer the critical path.

The synthesized controller was approximately:

- 76 LUT
- 18 FF
- 14 ALU

The generated constant multiplication/address logic was already optimized by synthesis.

### Decision

**Rejected for Phase 4B — not currently the timing bottleneck.**

Further controller changes would add functional risk without evidence of meaningful timing improvement.

---

## 6. Experiment C — Pipeline FC1 MAC Inputs

The most relevant remaining bottleneck was the DSP/MAC path.

An experimental version of the FC1 MAC lane was created with registers for:

- input value
- weight value

before multiplication.

Experimental modules:

```text
rtl/fc1_mac_lane_pipe.v
rtl/fc1_mac8_pipe.v
rtl/fc1_bram_pipe.v
tb/tb_fc1_bram_pipe.v
```

A separate Gowin project was also created so that the experiment could be synthesized without modifying the known-good Phase 4A project.

### Experimental datapath

The experimental MAC lane registered the input and weight before multiplication:

```text
input_value
     |
 input register
     |
     +------> DSP
     |
weight register
     |
     +------> DSP
```

This added pipeline registers while keeping the original accumulator feedback structure.

---

## 7. Functional Verification

The experimental design was compiled and simulated with Verilator.

Command used:

```bash
verilator --binary --timing   --top-module tb_fc1_bram_pipe   tb/tb_fc1_bram_pipe.v   rtl/fc1_bram_pipe.v   rtl/fc1_mac8_pipe.v   rtl/fc1_mac_lane_pipe.v   rtl/fc1_controller_bram.v   rtl/fc1_weight_mem_bram.v   rtl/fc1_input_mem.v   rtl/fc1_bias_mem.v   rtl/fc1_requant_relu.v   rtl/fc1_activation_mem.v   --Mdir obj_dir_pipe   -o sim_fc1_pipe
```

### Results

- FC1 activations: **32/32 correct**
- Failures: **0**
- FC1 latency: **3184 cycles**
- Expected activation vector matched exactly

Expected FC1 activations for image #0:

```text
[0, 33, 21, 0, 0, 41, 37, 46,
 40, 40, 14, 0, 42, 21, 27, 7,
 34, 39, 0, 34, 31, 17, 5, 0,
 2, 1, 25, 0, 24, 0, 0, 3]
```

The downstream FC2 check also remained correct:

```text
FC2 logits:
[-98, -5615, 122, 1592, -6785, -1238, -7236, 4401, -632, -1021]

Predicted digit = 7
Expected digit  = 7

FC1 -> FC2 TEST: PASS
```

---

## 8. Experimental Gowin Synthesis

The experimental design was synthesized using Gowin EDA with the same 100 MHz timing constraint.

### Resource comparison

| Metric | Phase 4A | Pipeline Experiment | Change |
|---|---:|---:|---:|
| LUT | 597 | 582 | -15 |
| FF | 154 | 226 | +72 |
| BSRAM | 17 | 17 | 0 |
| SSRAM | 4 | 4 | 0 |
| DSP | 8 | 8 | 0 |
| ALU | 14 | 14 | 0 |
| Fmax | 124.193 MHz | 124.502 MHz | +0.309 MHz |
| Worst slack | +1.948 ns | +1.968 ns | +0.020 ns |

### Timing result

The pipeline experiment achieved:

```text
Fmax = 124.502 MHz
Worst slack = +1.968 ns
```

Compared with Phase 4A:

```text
Fmax improvement = +0.309 MHz
Slack improvement = +0.020 ns
```

This is a very small timing improvement relative to the additional register cost.

The experimental hierarchy used:

```text
fc1_bram_top
└── fc1_bram_pipe
    └── fc1_mac8_pipe
        ├── fc1_mac_lane_pipe
        ├── ...
        └── fc1_mac_lane_pipe
```

The experimental MAC block increased from approximately 136 registers to 208 registers.

---

## 9. Optimization Decision

The input/weight pipeline experiment is **rejected as the final Phase 4B implementation**.

Reason:

- LUTs decreased by only 15.
- Fmax increased by only 0.309 MHz.
- Worst slack improved by only 0.020 ns.
- FF usage increased by 72.
- DSP usage did not change.
- The critical path remained in the DSP/MAC datapath.
- Functional correctness was preserved, but the timing/resource tradeoff was not sufficiently valuable.

Therefore, the known-good Phase 4A implementation remains the final implementation.

This is an important result: Phase 4B demonstrated that adding pipeline registers around the DSP inputs does not provide a meaningful improvement for this particular design and device mapping.

---

## 10. Final Phase 4B State

No experimental pipeline RTL was retained in the final design.

The final project continues to use:

```text
rtl/fc1_bram.v
rtl/fc1_weight_mem_bram.v
rtl/fc1_controller_bram.v
rtl/fc1_mac8.v
rtl/fc1_mac_lane.v
rtl/fc1_requant_relu.v
rtl/fc1_activation_mem.v
rtl/fc1_bias_mem.v
```

The Phase 4A implementation remains the known-good baseline.

### Final measured implementation

```text
LUT  : 597
FF   : 154
BSRAM: 17
SSRAM: 4
DSP  : 8
ALU  : 14

Fmax : 124.193 MHz
Slack: +1.948 ns
```

The 100 MHz timing target is met with positive slack.

---

## 11. Reproducibility

### Check repository state

```bash
cd /mnt/c/mnist-fpga
git status --short
```

The final working tree should contain no experimental Phase 4B pipeline files.

### Verify FC1

Run the Phase 4A FC1 Verilator testbench using the known-good FC1 BRAM implementation.

Expected:

```text
32/32 activations correct
3184 cycles
0 failures
```

### Verify FC2 integration

The FC2 verification should produce:

```text
FC2 logits:
[-98, -5615, 122, 1592, -6785, -1238, -7236, 4401, -632, -1021]

Predicted digit = 7
```

### Synthesis

The final Gowin project is:

```text
gowin/mnist_fpga_phase4/mnist_fpga_phase4/
```

Project file:

```text
mnist_fpga_phase4.gprj
```

The correct top module is:

```text
fc1_bram_top
```

---

## 12. Phase 4B Conclusion

Phase 4B followed a measurement-driven optimization methodology.

The Phase 4A timing report identified the FC1 DSP/MAC datapath as the remaining critical region. Several possible optimizations were investigated. Requantizer width reduction and controller changes were rejected because synthesis had already optimized those regions or they were no longer the timing bottleneck.

A concrete DSP input/weight pipelining experiment was implemented, functionally verified, and synthesized.

The experiment produced:

```text
Fmax: 124.193 MHz → 124.502 MHz
Slack: +1.948 ns → +1.968 ns
FF: 154 → 226
LUT: 597 → 582
```

The timing gain was too small to justify the additional register usage and design complexity.

Therefore:

> **Phase 4B optimization experiment: measured, verified, and rejected.**

The Phase 4A implementation remains the final known-good implementation, with a measured **124.193 MHz Fmax** and **+1.948 ns worst slack** against the 100 MHz target.
