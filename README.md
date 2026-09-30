# MNIST-FPGA

A complete end-to-end FPGA implementation of a quantized MNIST neural-network accelerator, developed for the **Sipeed Tang Nano 20K**.

The project takes a small PyTorch MNIST model through numerical quantization, RTL implementation, simulation/verification, FPGA synthesis and place-and-route, and finally physical hardware validation.

---

## Overview

The implemented neural network is:

```text
784 input pixels
      |
      v
FC1: 784 -> 32
      |
      v
ReLU
      |
      v
FC2: 32 -> 10
      |
      v
Argmax
      |
      v
Predicted digit
```

The project uses an integer-only inference datapath suitable for FPGA implementation.

### Final architecture

- **Input:** 28 × 28 MNIST image = 784 pixels
- **FC1:** 784 → 32
- **Activation:** ReLU
- **FC2:** 32 → 10
- **Output:** Argmax over 10 logits
- **FPGA:** Sipeed Tang Nano 20K
- **FPGA device:** GW2AR-LV18QN88C8/I7
- **Board clock:** 27 MHz
- **Internal clock:** approximately 100 MHz using a Gowin PLL
- **HDL:** SystemVerilog/Verilog
- **Simulation:** Verilator
- **FPGA toolchain:** Gowin EDA
- **Reference model:** PyTorch

---

## Results

### Software / numerical validation

| Metric | Result |
|---|---:|
| PyTorch Float32 test accuracy | **95.71%** |
| Integer-network test accuracy | **95.68%** |
| Float32 ↔ integer prediction agreement | **99.69%** |

The quantized network preserves the classification behavior of the original model closely enough for FPGA deployment.

### Physical FPGA validation

A final known-good bitstream was programmed onto the Tang Nano 20K.

**Test #2**

- MNIST test index: `1`
- Ground-truth label: `2`
- Expected prediction: `2`
- Physical FPGA prediction: **2**
- Observed output: **LED1 ON**
- Result: **PASS**

Final verified bitstream SHA256:

```text
b3a5cf51840e20784da52ee57b791c2857b4c7177dafb0e938449381dccd75ce
```

The verified bitstream is preserved as:

```text
backups/final/mnist_fpga_phase6_known_good_test2.fs
```

---

## Quantization Specification

The deployed inference pipeline uses the following numerical representation.

### Input

- Unsigned INT8
- Scale = `128`

### Weights

- Signed INT8
- Scale = `64`

### FC1

- Signed 26-bit accumulator
- Requantization:

```text
(accumulator + 512) >>> 10
```

- ReLU
- Unsigned INT8 activation

### FC2

- Signed INT8 weights
- Signed 21-bit accumulator
- Logit scale = `512`

This specification was established experimentally during Phase 2 and then used as the basis for the RTL implementation.

---

## Project Phases

### Phase 1 — Golden Model

Created and trained the PyTorch MNIST reference model:

```text
784 -> 32 -> ReLU -> 10
```

Final Float32 test accuracy:

```text
95.71%
```

### Phase 2 — Quantization

Established the fixed-point/integer numerical specification.

Major outcomes included:

- Input quantization
- INT8 weight quantization
- Activation quantization
- Integer FC1
- Integer FC2
- Accumulator range analysis
- Full integer-network validation

Final integer-network result:

```text
95.68% accuracy
99.69% prediction agreement with Float32
```

### Phase 3 — RTL Implementation

Implemented and verified the hardware datapath, including:

- FC1 input memory
- FC1 weight memory
- FC1 bias memory
- FC1 MAC lanes
- FC1 controller
- FC1 requantization/ReLU
- FC1 activation memory
- FC2 weight memory
- FC2 bias memory
- FC2 MAC lanes
- FC2 controller
- FC2 integration
- Argmax10
- Full MNIST inference datapath

Python reference vectors were used to verify intermediate activations and final logits.

### Phase 4 — FPGA Integration

Integrated the complete inference pipeline for the Tang Nano 20K and prepared the Gowin FPGA project.

This phase included:

- FPGA top-level integration
- Gowin project setup
- Memory initialization
- PLL integration
- FPGA-oriented simulation
- Synthesis and place-and-route

### Phase 5 — Resource Optimization

Optimized the FC1 hardware implementation to reduce FPGA resource usage while maintaining the required numerical behavior.

### Phase 6 — Hardware Validation

Validated the complete design on the physical Tang Nano 20K.

The final hardware-validation workflow included:

```text
PyTorch
   |
   v
Quantization
   |
   v
Integer reference
   |
   v
RTL
   |
   v
Verilator verification
   |
   v
Gowin synthesis / P&R
   |
   v
Tang Nano 20K
   |
   v
Physical MNIST inference
```

---

## Repository Structure

```text
mnist-fpga/
│
├── data/
│   ├── raw/
│   ├── fc1_expected_activation.mem
│   └── test_input.mem
│
├── docs/
│   ├── PHASE_2_NUMERICAL_SPEC.md
│   └── PHASE_6_HARDWARE_VALIDATION.md
│
├── gowin/
│   └── mnist_fpga_phase4/
│       └── mnist_fpga_phase4/
│
├── python/
│   └── phase3/
│       └── generate_fc1_test_vector.py
│
├── rtl/
│   ├── fc1/
│   ├── fc2/
│   └── ...
│
├── tb/
│   └── ...
│
├── backups/
│   └── final/
│
└── README.md
```

Generated Gowin implementation output is excluded from Git tracking where appropriate.

---

## Verification

RTL verification was performed with **Verilator 5.038**.

The verification flow checks:

- Memory initialization
- MAC operations
- FC1 computation
- Requantization
- ReLU
- FC2 computation
- Argmax
- Full-network inference
- Tang Nano 20K wrapper behavior

The FPGA wrapper was also simulated with a PLL simulation stub to verify:

- Reset sequencing
- Input-image loading
- Memory write control
- Inference start
- Inference completion
- Predicted digit output
- LED encoding

---

## Hardware

### Board

**Sipeed Tang Nano 20K**

Target FPGA:

```text
GW2AR-LV18QN88C8/I7
```

Board oscillator:

```text
27 MHz
```

The design uses a Gowin PLL to generate an internal clock of approximately:

```text
100 MHz
```

The predicted digit is displayed using the onboard LEDs with active-low encoding.

---

## Running the Python Test Vector Generator

The FC1 test-vector generator accepts an optional MNIST test index.

Example:

```bash
python python/phase3/generate_fc1_test_vector.py 1
```

If no index is supplied, the script uses its default test index.

The generated vectors can then be used for RTL verification and FPGA memory initialization.

---

## FPGA Build

The Gowin project is located at:

```text
gowin/mnist_fpga_phase4/mnist_fpga_phase4/
```

Open the project in **Gowin EDA**, select the configured top-level module, and run synthesis followed by place-and-route to generate a new FPGA bitstream.

The production wrapper is:

```text
mnist_tang_nano20k
```

---

## Known Limitation

During Phase 6, an additional hardware test vector was validated successfully in RTL simulation but did not reproduce the expected output on physical hardware.

The discrepancy was associated with the synthesized FPGA memory/input-loading path under the tested configuration and was not fully resolved during Phase 6.

Rather than deleting the investigation artifacts, they were preserved locally.

The **known-good Test #2 bitstream** remains the reproducible physical hardware demonstration.

See:

```text
docs/PHASE_6_HARDWARE_VALIDATION.md
```

for the complete Phase 6 record.

---

## Final Status

**Project implementation and hardware-validation workflow complete.**

The project demonstrates the complete path:

```text
Neural Network
      ↓
Quantization
      ↓
Integer Numerical Model
      ↓
RTL Hardware
      ↓
Simulation / Verification
      ↓
Resource Optimization
      ↓
FPGA Synthesis
      ↓
Place & Route
      ↓
Bitstream
      ↓
Tang Nano 20K
      ↓
Physical MNIST Inference
```

The final GitHub `main` branch contains the completed Phase 6 implementation.

---

## Author

**Sreansh Verma**

Project: **MNIST-FPGA**

Target platform: **Sipeed Tang Nano 20K**
