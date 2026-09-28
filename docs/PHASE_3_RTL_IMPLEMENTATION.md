# Phase 3 — RTL Implementation & Full MNIST Network Integration

## 1. Phase Objective

Phase 3 converts the verified integer numerical specification from Phase 2 into synthesizable Verilog RTL.

The objective was to implement and verify the complete MNIST inference pipeline:

```text
784 INT8 Inputs
       |
       v
+---------------+
|      FC1      |
|   784 -> 32   |
|  8 MAC lanes  |
+-------+-------+
        |
        v
  32 INT8 Activations
        |
        v
+---------------+
|      FC2      |
|    32 -> 10   |
| 10 MAC lanes  |
+-------+-------+
        |
        v
  10 INT21 Logits
        |
        v
      Argmax
        |
        v
 Predicted Digit
```

Phase 3 focused on:

- Verilog RTL implementation
- Parallel MAC architecture
- Weight and bias memory organization
- Signed and unsigned arithmetic
- Control FSMs
- Activation memory
- FC1 implementation
- FC2 implementation
- Argmax implementation
- FC1 -> FC2 integration
- Full MNIST top-level integration
- RTL verification against the Python golden reference

The final objective was to demonstrate that the complete RTL network produces the same result as the verified Phase 2 integer model.

---

# 2. Starting Point — Phase 2 Numerical Specification

The neural network architecture is:

```text
784 -> 32 -> ReLU -> 10 -> Argmax
```

The numerical specification established during Phase 2 is:

| Quantity | Representation |
|---|---|
| Input | Unsigned INT8 |
| Input scale | 128 |
| FC1 weights | Signed INT8 |
| FC1 weight scale | 64 |
| FC1 accumulator | Signed 26-bit |
| FC1 accumulator scale | 8192 |
| FC1 activation | Unsigned INT8 |
| FC1 activation scale | 8 |
| FC2 weights | Signed INT8 |
| FC2 weight scale | 64 |
| FC2 accumulator | Signed 21-bit |
| FC2 accumulator scale | 512 |
| FC2 logits | Signed 21-bit |

Phase 2 established:

```text
Float32 accuracy:       95.71%
Quantized accuracy:     95.71%
Prediction agreement:   99.76%
```

These values became the numerical reference for the RTL implementation.

---

# 3. Phase 3 Design Approach

The RTL was developed incrementally.

The verification flow was:

```text
Python numerical specification
             |
             v
       Individual RTL
             |
             v
    Standalone testbench
             |
             v
      Datapath integration
             |
             v
       Layer integration
             |
             v
     Full network integration
             |
             v
 Python golden-reference comparison
```

Each major hardware block was verified before moving to the next level.

The primary objective during Phase 3 was functional correctness, not FPGA optimization.

---

# 4. FC1 Hardware Architecture

## 4.1 FC1 Computation

FC1 performs:

```text
784 inputs x 32 output neurons
```

The selected architecture uses:

```text
8 parallel MAC lanes
```

The 32 output neurons are processed in four groups of eight.

Each group processes all 784 input values.

Therefore:

```text
784 MAC cycles/group
x 4 groups
= 3136 MAC iterations
```

---

## 4.2 FC1 Weight Organization

The 32 neurons are distributed across eight weight banks:

```text
Bank 0 -> neurons 0, 8, 16, 24
Bank 1 -> neurons 1, 9, 17, 25
Bank 2 -> neurons 2, 10, 18, 26
Bank 3 -> neurons 3, 11, 19, 27
Bank 4 -> neurons 4, 12, 20, 28
Bank 5 -> neurons 5, 13, 21, 29
Bank 6 -> neurons 6, 14, 22, 30
Bank 7 -> neurons 7, 15, 23, 31
```

Each bank contains:

```text
4 neurons x 784 weights
= 3136 weights
```

Total FC1 weights:

```text
32 x 784
= 25,088 weights
```

---

## 4.3 FC1 Weight Addressing

The weight address is generated as:

```text
address = group * 784 + input_index
```

Since:

```text
3136 < 4096
```

a 12-bit address is sufficient.

The generated FC1 memory files are:

```text
data/fc1_bank0.mem
data/fc1_bank1.mem
data/fc1_bank2.mem
data/fc1_bank3.mem
data/fc1_bank4.mem
data/fc1_bank5.mem
data/fc1_bank6.mem
data/fc1_bank7.mem
```

---

# 5. FC1 RTL Modules

The following modules were implemented:

```text
rtl/fc1.v
rtl/fc1_activation_mem.v
rtl/fc1_bias_mem.v
rtl/fc1_controller.v
rtl/fc1_input_mem.v
rtl/fc1_mac8.v
rtl/fc1_mac_lane.v
rtl/fc1_requant_relu.v
rtl/fc1_weight_mem.v
```

### fc1.v

Top-level FC1 module connecting the controller, datapath, memories and activation memory.

### fc1_controller.v

Controls:

- Input addressing
- Group selection
- MAC enable
- Accumulation
- Requantization
- Activation-memory writes
- FC1 completion

### fc1_mac_lane.v

Implements one signed multiply-accumulate lane.

### fc1_mac8.v

Instantiates eight parallel MAC lanes.

### fc1_weight_mem.v

Stores the eight FC1 weight banks.

### fc1_bias_mem.v

Stores the quantized FC1 biases.

### fc1_input_mem.v

Stores the 784 quantized input pixels.

### fc1_requant_relu.v

Performs:

1. Requantization
2. ReLU
3. Saturation to unsigned INT8

### fc1_activation_mem.v

Stores the 32 FC1 output activations for use by FC2.

---

# 6. FC1 Verification

Each FC1 module was tested independently before complete FC1 integration.

Verification included:

- MAC lane arithmetic
- 8-lane MAC datapath
- Weight memory
- Bias memory
- Input memory
- Activation memory
- Requantization and ReLU
- Controller
- Complete FC1 datapath

The RTL output was compared against the Python integer reference.

For MNIST test image #0, the expected FC1 activation vector was:

```text
[0, 33, 21, 0, 0, 41, 37, 46,
 40, 40, 14, 0, 42, 21, 27, 7,
 34, 39, 0, 34, 31, 17, 5, 0,
 2, 1, 25, 0, 24, 0, 0, 3]
```

The RTL produced:

```text
32 / 32 activations matched
```

FC1 verification result:

```text
FC1 TEST: PASS
```

The complete FC1 operation required:

```text
3184 cycles
```

including control/setup cycles.

---

# 7. FC2 Hardware Architecture

## 7.1 FC2 Computation

FC2 performs:

```text
32 input activations x 10 output neurons
```

The selected architecture uses:

```text
10 parallel MAC lanes
```

There is one physical MAC lane for each output neuron.

All ten lanes receive the same activation at each cycle while reading their respective weights.

Therefore:

```text
32 activation cycles
```

are required for the MAC operation.

---

## 7.2 FC2 Parallelism

The architecture is:

```text
                 Activation
                     |
        +------------+------------+
        |            |            |
        v            v            v
      MAC 0        MAC 1       ... MAC 9
        |            |              |
        v            v              v
     Logit 0      Logit 1        Logit 9
```

This requires:

```text
10 physical MAC lanes
```

for FC2.

---

# 8. FC2 Weight Memory

FC2 contains:

```text
10 x 32 = 320 weights
```

Each output neuron has its own weight bank:

```text
Bank 0 -> neuron 0 -> 32 weights
Bank 1 -> neuron 1 -> 32 weights
Bank 2 -> neuron 2 -> 32 weights
Bank 3 -> neuron 3 -> 32 weights
Bank 4 -> neuron 4 -> 32 weights
Bank 5 -> neuron 5 -> 32 weights
Bank 6 -> neuron 6 -> 32 weights
Bank 7 -> neuron 7 -> 32 weights
Bank 8 -> neuron 8 -> 32 weights
Bank 9 -> neuron 9 -> 32 weights
```

Generated files:

```text
data/fc2_bank0.mem
data/fc2_bank1.mem
data/fc2_bank2.mem
data/fc2_bank3.mem
data/fc2_bank4.mem
data/fc2_bank5.mem
data/fc2_bank6.mem
data/fc2_bank7.mem
data/fc2_bank8.mem
data/fc2_bank9.mem
```

The weights are generated using:

```text
q_weight = round(weight * 64)
```

The quantized FC2 weight range was:

```text
minimum = -72
maximum = 38
```

---

# 9. FC2 Bias Memory

FC2 biases use a scale of 512:

```text
q_bias = round(bias * 512)
```

The biases are stored as signed 21-bit two's-complement values.

Generated file:

```text
data/fc2_bias.mem
```

The quantized bias values are:

| Neuron | Bias |
|---:|---:|
| 0 | -79 |
| 1 | 134 |
| 2 | 12 |
| 3 | -181 |
| 4 | 50 |
| 5 | 118 |
| 6 | -15 |
| 7 | -33 |
| 8 | -96 |
| 9 | 61 |

All ten bias-memory entries were verified.

---

# 10. FC2 RTL Modules

The following FC2 modules were implemented:

```text
rtl/fc2.v
rtl/fc2_controller.v
rtl/fc2_weight_mem.v
rtl/fc2_bias_mem.v
rtl/fc2_mac_lane.v
rtl/fc2_mac10.v
rtl/argmax10.v
```

### fc2.v

Top-level FC2 module.

It connects:

- FC2 controller
- FC2 weight memory
- FC2 bias memory
- Ten MAC lanes
- Argmax
- FC1 activation memory interface

### fc2_controller.v

Controls:

```text
IDLE
  |
  v
INIT
  |
  v
MAC
  |
  v
DONE
```

The controller:

- Loads all ten biases
- Generates activation addresses
- Enables MAC operations
- Counts 32 activation cycles
- Generates the done signal

### fc2_mac_lane.v

Implements one signed FC2 multiply-accumulate lane.

### fc2_mac10.v

Instantiates ten FC2 MAC lanes.

### fc2_weight_mem.v

Contains ten 32-entry signed INT8 weight banks.

### fc2_bias_mem.v

Contains ten signed 21-bit biases.

### argmax10.v

Compares the ten signed logits and produces the predicted digit.

---

# 11. FC2 MAC Arithmetic

FC2 activation values are unsigned INT8.

The activation is extended before multiplication:

```text
unsigned 8-bit activation
        |
        v
signed 9-bit activation extension
```

The FC2 weight is signed INT8.

The product is therefore signed 16-bit:

```text
9-bit activation x 8-bit weight
= 16-bit product
```

The product is then sign-extended to the signed 21-bit accumulator width.

The accumulator performs:

```text
accumulator = accumulator + product
```

The bias is loaded before the MAC loop.

---

# 12. FC2 MAC Lane Verification

The standalone FC2 MAC lane testbench verified:

### Reset

```text
Accumulator -> 0
```

### Positive multiplication

```text
10 x 5 + 100 = 150
```

### Negative multiplication

```text
10 x (-5) + 100 = 50
```

### Maximum positive product

```text
255 x 127 = 32385
```

### Maximum negative product

```text
255 x (-128) = -32640
```

### Repeated MAC

Repeated multiply-accumulate operation was also verified.

Result:

```text
FC2 MAC LANE TEST: PASS
```

---

# 13. FC2 Controller Verification

The controller was verified for the expected sequence:

```text
IDLE
  |
  v
INIT
  |
  v
MAC address 0
  |
  v
MAC address 1
  |
  v
...
  |
  v
MAC address 31
  |
  v
DONE
  |
  v
IDLE
```

The testbench confirmed:

```text
MAC count = 32
```

Result:

```text
FC2 CONTROLLER TEST: PASS
```

---

# 14. FC2 Weight Memory Verification

The ten FC2 weight banks were loaded from:

```text
data/fc2_bank0.mem
...
data/fc2_bank9.mem
```

Sample addresses were checked against the Python-generated quantized weights.

Verified samples included:

```text
Address 0:
[-24, 24, -6, 2, -17, -2, 10, -15, 13, -29]

Address 1:
[10, -19, 19, 11, 19, -21, 3, -23, 9, 6]

Address 2:
[11, 4, 33, 17, -29, 2, -43, -3, -11, -16]

Address 31:
[9, -25, 8, -13, -4, 0, 20, -18, 7, -9]
```

Result:

```text
FC2 WEIGHT MEMORY TEST: PASS
```

---

# 15. FC2 Bias Memory Verification

All ten FC2 bias values were loaded and compared with the generated memory file.

The memory representation uses six hexadecimal digits to represent the 21-bit two's-complement values.

Verified values included:

```text
Neuron 0  -> -79
Neuron 1  -> 134
Neuron 2  -> 12
Neuron 3  -> -181
Neuron 4  -> 50
Neuron 5  -> 118
Neuron 6  -> -15
Neuron 7  -> -33
Neuron 8  -> -96
Neuron 9  -> 61
```

Result:

```text
FC2 BIAS MEMORY TEST: PASS
```

---

# 16. Argmax Hardware

The final FC2 output consists of ten signed 21-bit logits:

```text
logit0 ... logit9
```

The `argmax10` module performs a combinational signed comparison.

The comparison uses a strict:

```text
>
```

operation.

Therefore, if two digits have equal logits, the lower digit index is selected.

Example:

```text
logit2 = 100
logit5 = 100
```

Result:

```text
predicted_digit = 2
```

This provides deterministic tie-breaking.

---

# 17. Argmax Verification

The argmax module was tested with:

- Digit 0 as maximum
- Digit 7 as maximum
- All logits negative
- Tie between digits 2 and 5
- Digit 9 as maximum

All test cases passed.

Result:

```text
ARGMAX TEST: PASS
```

---

# 18. FC2 Synthetic Integration Test

Before connecting FC2 to FC1, FC2 was tested with synthetic activation data.

The test activation vector was:

```text
activation[i] = i
```

for:

```text
i = 0 ... 31
```

The RTL produced:

```text
logit0 = -2322
logit1 = -559
logit2 = -1380
logit3 = -2667
logit4 = -1235
logit5 = -424
logit6 = -1578
logit7 = -253
logit8 = -2312
logit9 = -3392

Predicted digit = 7
```

An independent Python integer reference produced exactly the same values.

Result:

```text
FC2 SYNTHETIC INTEGRATION TEST: PASS
```

---

# 19. FC2 Python Golden Reference

A dedicated Python reference was created:

```text
python/phase3/fc2_reference_test.py
```

The reference implements the same integer arithmetic as the RTL:

```text
q_weight = round(weight * 64)

q_bias = round(bias * 512)

logit =
    q_bias
    + sum(activation[i] * q_weight[i])
```

The result is represented using signed 21-bit arithmetic.

The Python implementation also performs the same argmax operation as the RTL.

For the real MNIST test vector, the expected logits are:

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

Expected prediction:

```text
7
```

---

# 20. FC1 -> FC2 Integration

After FC1 was independently verified and FC2 was independently verified, both layers were connected.

The data flow is:

```text
FC1
 |
 | 32 INT8 activations
 v
FC1 Activation Memory
 |
 v
FC2 Activation Interface
 |
 v
10 FC2 MAC lanes
 |
 v
10 logits
 |
 v
Argmax
```

FC2 directly reads the FC1 activation memory.

No additional activation-memory copy is required.

---

# 21. Initial FC1 -> FC2 Integration Failure

The first FC1 -> FC2 integration test produced incorrect FC2 outputs.

The observed logits were effectively equal to the FC2 biases.

This indicated that FC2 was not receiving the FC1 activations.

The issue was traced to the activation-memory interface.

The activation memory had originally been controlled using the `start` pulse.

However, `start` is only asserted for one clock cycle.

After the start pulse ended, FC2 still needed to control the activation-memory read address for the entire inference operation.

Therefore, using the one-cycle `start` pulse as the ownership signal was incorrect.

---

# 22. FC1 -> FC2 Integration Fix

A persistent FC2-active signal was introduced.

The activation-memory read-address ownership became:

```verilog
assign mem_read_addr = fc2_active
                     ? activation_addr
                     : mem_read_addr_tb;
```

The important design change was:

```text
start pulse
    |
    X
    |
persistent fc2_active
    |
    v
activation-memory ownership
```

This ensures that FC2 retains control of the activation-memory read address throughout the FC2 operation.

After the fix, the FC1 -> FC2 integration passed.

---

# 23. FC1 -> FC2 Final Verification

The final integrated result was:

```text
FC1 ACTIVATION MEMORY TEST: PASS

FC2 FINAL LOGITS

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
Expected digit  = 7

FC1 -> FC2 TEST: PASS
```

The RTL results matched the Python golden reference.

---

# 24. Full MNIST Top-Level Architecture

The complete network was then integrated using:

```text
rtl/mnist_top.v
```

The top-level structure is:

```text
                Input Interface
                      |
                      v
              +---------------+
              |      FC1      |
              | 784 -> 32     |
              | 8 MAC lanes   |
              +-------+-------+
                      |
                      v
             32 INT8 Activations
                      |
                      v
              +---------------+
              |      FC2      |
              | 32 -> 10      |
              | 10 MAC lanes  |
              +-------+-------+
                      |
                      v
               10 INT21 logits
                      |
                      v
                   Argmax
                      |
                      v
                Digit 0-9
```

---

# 25. Top-Level Control

The top-level controller uses:

```text
IDLE -> FC1 -> FC2 -> DONE
```

The external `start` signal is treated as a one-cycle request.

The top-level generates:

```text
fc1_start
fc2_start
```

as one-cycle control pulses.

The FC2 activation interface is directly connected to the FC1 activation memory.

The top-level exposes:

- `done`
- `predicted_digit`
- `logit0`
- `logit1`
- `logit2`
- `logit3`
- `logit4`
- `logit5`
- `logit6`
- `logit7`
- `logit8`
- `logit9`

---

# 26. Full MNIST Testbench

The complete testbench is:

```text
tb/tb_mnist_top.v
```

The testbench:

1. Loads the quantized MNIST input vector.
2. Writes all 784 input pixels through the top-level interface.
3. Starts the network.
4. Waits for the `done` signal.
5. Prints the final FC2 logits.
6. Prints the predicted digit.
7. Compares against the expected label.

The input vector is stored in:

```text
data/test_input.mem
```

The test image is MNIST test image #0.

Expected label:

```text
7
```

---

# 27. Full Network Simulation Result

The final FC2 logits produced by the complete RTL network were:

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

The maximum logit is:

```text
logit7 = 4401
```

Therefore:

```text
Predicted digit = 7
Expected digit  = 7
```

Final result:

```text
MNIST FULL NETWORK TEST: PASS
```

---

# 28. Full Network Timing

The complete RTL simulation reported:

```text
Inference simulation time = 32210 ns
```

The clock period is:

```text
10 ns
```

Therefore:

```text
32210 ns / 10 ns
= 3221 clock periods
```

The complete inference therefore required approximately:

```text
3221 clock cycles
```

from the start of inference to completion.

The cycle count is consistent with the FC1 and FC2 architectures plus the additional control/setup cycles.

---

# 29. Final RTL Architecture

The final Phase 3 architecture is:

```text
                       784 INT8 Inputs
                              |
                              v
                 +------------------------+
                 |          FC1           |
                 |                        |
                 |  8 parallel MAC lanes  |
                 |                        |
                 |      784 -> 32         |
                 +-----------+------------+
                             |
                             v
                    32 INT8 Activations
                             |
                             v
                 +------------------------+
                 |          FC2           |
                 |                        |
                 | 10 parallel MAC lanes  |
                 |                        |
                 |       32 -> 10         |
                 +-----------+------------+
                             |
                             v
                     10 INT21 logits
                             |
                             v
                       +-----------+
                       |  Argmax10 |
                       +-----+-----+
                             |
                             v
                       Digit 0-9
```

Physical MAC datapaths:

```text
FC1 = 8 MAC lanes
FC2 = 10 MAC lanes

Total = 18 physical MAC lanes
```

---

# 30. Memory Organization

## FC1

```text
FC1 weights:
8 banks × 3136 entries
= 25,088 INT8 weights
```

```text
FC1 biases:
32 signed bias values
```

```text
Input memory:
784 × 8-bit
```

```text
Activation memory:
32 × 8-bit
```

## FC2

```text
FC2 weights:
10 banks × 32 entries
= 320 INT8 weights
```

```text
FC2 biases:
10 signed 21-bit values
```

FC2 does not require a separate output memory because the ten accumulators directly contain the final logits.

---

# 31. Phase 3 Files

## RTL

```text
rtl/
├── argmax10.v
├── fc1.v
├── fc1_activation_mem.v
├── fc1_bias_mem.v
├── fc1_controller.v
├── fc1_input_mem.v
├── fc1_mac8.v
├── fc1_mac_lane.v
├── fc1_requant_relu.v
├── fc1_weight_mem.v
├── fc2.v
├── fc2_bias_mem.v
├── fc2_controller.v
├── fc2_mac10.v
├── fc2_mac_lane.v
├── fc2_weight_mem.v
└── mnist_top.v
```

## Testbenches

```text
tb/
├── tb_argmax10.v
├── tb_fc1.v
├── tb_fc1_activation_mem.v
├── tb_fc1_bias_mem.v
├── tb_fc1_controller.v
├── tb_fc1_datapath.v
├── tb_fc1_fc2.v
├── tb_fc1_input_mem.v
├── tb_fc1_mac8.v
├── tb_fc1_mac_lane.v
├── tb_fc1_requant_relu.v
├── tb_fc1_weight_mem.v
├── tb_fc2.v
├── tb_fc2_bias_mem.v
├── tb_fc2_controller.v
├── tb_fc2_mac10.v
├── tb_fc2_mac_lane.v
├── tb_fc2_weight_mem.v
└── tb_mnist_top.v
```

## Phase 3 Python scripts

```text
python/phase3/
├── fc2_reference_test.py
├── generate_fc1_bias_mem.py
├── generate_fc1_mem.py
├── generate_fc1_test_vector.py
├── generate_fc2_bias_mem.py
├── generate_fc2_mem.py
└── verify_fc2_test_vector.py
```

## Memory files

```text
data/
├── fc1_bank0.mem
├── fc1_bank1.mem
├── fc1_bank2.mem
├── fc1_bank3.mem
├── fc1_bank4.mem
├── fc1_bank5.mem
├── fc1_bank6.mem
├── fc1_bank7.mem
├── fc1_bias.mem
├── fc1_expected_activation.mem
├── fc2_bank0.mem
├── fc2_bank1.mem
├── fc2_bank2.mem
├── fc2_bank3.mem
├── fc2_bank4.mem
├── fc2_bank5.mem
├── fc2_bank6.mem
├── fc2_bank7.mem
├── fc2_bank8.mem
├── fc2_bank9.mem
├── fc2_bias.mem
└── test_input.mem
```

---

# 32. Verification Summary

The major verification stages were:

| Test | Result |
|---|---|
| FC1 MAC lane | PASS |
| FC1 8-lane MAC | PASS |
| FC1 weight memory | PASS |
| FC1 bias memory | PASS |
| FC1 input memory | PASS |
| FC1 activation memory | PASS |
| FC1 controller | PASS |
| FC1 datapath | PASS |
| FC1 complete inference | PASS |
| FC2 MAC lane | PASS |
| FC2 10-lane MAC | PASS |
| FC2 weight memory | PASS |
| FC2 bias memory | PASS |
| FC2 controller | PASS |
| Argmax | PASS |
| FC2 synthetic integration | PASS |
| Python FC2 reference comparison | PASS |
| FC1 -> FC2 integration | PASS |
| Full MNIST RTL inference | PASS |

---

# 33. Final Verification Result

The complete hardware inference produced:

```text
FINAL FC2 LOGITS

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
Expected digit  = 7

Inference simulation time = 32210 ns

MNIST FULL NETWORK TEST: PASS
```

The RTL output matches the Python integer reference for the tested MNIST sample.

---

# 34. Phase 3 Key Results

The Phase 3 implementation successfully transformed the Phase 2 numerical model into a complete RTL neural-network accelerator.

Key results:

```text
Network:
784 -> 32 -> ReLU -> 10 -> Argmax
```

```text
FC1:
8 parallel MAC lanes
3136 MAC iterations
32 INT8 activations
```

```text
FC2:
10 parallel MAC lanes
32 MAC cycles
10 INT21 logits
```

```text
Total physical MAC lanes:
18
```

```text
Full inference:
3221 clock periods
```

```text
Expected digit:
7
```

```text
Predicted digit:
7
```

```text
Final verification:
PASS
```

---

# 35. Important Design Lessons

## 35.1 Numerical specification must precede RTL

The exact integer scales and accumulator widths were established in Phase 2 before writing the hardware.

This prevented ambiguity in:

- signed arithmetic
- scaling
- overflow handling
- requantization
- memory representation

---

## 35.2 Memory organization strongly affects architecture

The FC1 weights were reorganized into eight banks to support eight parallel MAC lanes.

The FC2 weights were organized into ten banks to support one MAC lane per output neuron.

The memory layout was therefore designed around the desired hardware parallelism.

---

## 35.3 Signedness must be explicit

The design contains both:

```text
unsigned INT8 activations
```

and:

```text
signed INT8 weights
```

The activation is explicitly extended before multiplication.

The product is explicitly sign-extended before entering the accumulator.

This prevents incorrect interpretation of values with bit 7 set.

---

## 35.4 Control ownership matters during integration

The first FC1 -> FC2 integration exposed an important control issue.

A one-cycle `start` pulse cannot be used as a persistent ownership signal for a multi-cycle memory operation.

The solution was to maintain a persistent `fc2_active` state.

This ensured that FC2 retained control of the activation-memory read address throughout its operation.

---

## 35.5 Verify layers independently before integration

The final successful integration was possible because:

```text
FC1 was verified independently
        +
FC2 was verified independently
        +
memory blocks were verified independently
        +
argmax was verified independently
```

Only after these blocks passed were they combined into the full network.

---

# 36. Phase 3 Completion Criteria

Phase 3 is considered complete because:

- [x] FC1 RTL implemented
- [x] FC1 datapath verified
- [x] FC1 memory system verified
- [x] FC1 controller verified
- [x] FC1 output verified against Python
- [x] FC2 RTL implemented
- [x] FC2 MAC lanes verified
- [x] FC2 memory system verified
- [x] FC2 controller verified
- [x] Argmax verified
- [x] FC2 verified against Python reference
- [x] FC1 -> FC2 integration verified
- [x] Full MNIST top-level implemented
- [x] Full MNIST simulation passed
- [x] Final prediction matched expected label
- [x] Phase 3 changes committed to Git
- [x] Working tree clean

---

# 37. Git Checkpoint

Phase 3 was committed with:

```text
31b2665 Complete Phase 3 FC2 and full MNIST integration
```

Previous Phase 3 checkpoint:

```text
59843d5 Complete Phase 3 FC1 RTL and organize project
```

Previous phases:

```text
494b07c Complete Phase 2 numerical quantization
bd2b680 phase-1-complete
c4bed3c Complete Phase 1 golden model
```

The repository was pushed to GitHub.

Final Git status after the Phase 3 checkpoint:

```text
nothing to commit, working tree clean
```

---

# 38. Phase 3 Conclusion

Phase 3 successfully converted the trained and quantized MNIST neural network into a verified Verilog RTL implementation.

The final architecture contains:

```text
FC1:
8 parallel MAC lanes

FC2:
10 parallel MAC lanes

Total:
18 physical MAC lanes
```

The complete RTL network:

```text
784 INT8 input
      ↓
FC1
      ↓
32 INT8 activations
      ↓
FC2
      ↓
10 signed 21-bit logits
      ↓
Argmax
      ↓
Predicted digit
```

was simulated end-to-end using an actual MNIST test vector.

The final result was:

```text
Predicted digit = 7
Expected digit  = 7

MNIST FULL NETWORK TEST: PASS
```

Therefore, the functional RTL implementation is complete and ready for the next stage: FPGA synthesis, resource utilization analysis, timing analysis, and eventual deployment to the target FPGA.

---

# 39. Next Phase

The next phase is **Phase 4 — FPGA Synthesis and Baseline Hardware Analysis**.

The starting point for Phase 4 is the known-good Phase 3 RTL.

The Phase 4 workflow should be:

```text
Known-good RTL
      ↓
Toolchain verification
      ↓
Baseline synthesis
      ↓
Resource utilization
      ↓
Timing analysis
      ↓
Memory inference analysis
      ↓
DSP / multiplier mapping
      ↓
Identify bottlenecks
      ↓
Optimization if required
      ↓
Re-synthesis
      ↓
Compare against baseline
```

Optimization should not begin until the baseline synthesis results are understood.
