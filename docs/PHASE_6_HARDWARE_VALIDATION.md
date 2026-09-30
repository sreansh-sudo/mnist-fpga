# Phase 6 — Hardware Validation

## 1. Objective

Phase 6 validates the MNIST FPGA inference system on the physical Sipeed Tang Nano 20K after completion of the RTL, numerical validation, resource optimization, synthesis, and place-and-route phases.

The goal is to demonstrate that the synthesized FPGA implementation can perform an end-to-end MNIST inference and produce the predicted digit through the onboard LEDs.

## 2. Hardware Target

- FPGA board: Sipeed Tang Nano 20K
- FPGA device: GW2AR-LV18QN88C8/I7
- Board oscillator: 27 MHz
- Internal FPGA clock: approximately 100 MHz using Gowin PLL
- Output: onboard LEDs
- LED encoding: active-low digit representation
- Production top-level wrapper: `mnist_tang_nano20k`

## 3. Network Architecture

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

Golden-model test accuracy: **95.71%**

## 4. Integer Numerical Specification

### Input
- Unsigned INT8
- Scale = 128

### Weights
- Signed INT8
- Scale = 64

### FC1
- Signed 26-bit accumulator
- Requantization: `(accumulator + 512) >>> 10`
- ReLU
- Unsigned INT8 activation

### FC2
- Signed INT8 weights
- Signed 21-bit accumulator
- Logit scale = 512

### Numerical validation

- Integer-network accuracy: **95.68%**
- Float32 prediction agreement: **99.69%**

## 5. RTL Verification

The following major RTL blocks were implemented and verified:

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
- Tang Nano 20K production wrapper

Python reference vectors were used to verify intermediate FC1 activations and final FC2 logits.

## 6. Phase 6 Wrapper Validation

The Gowin-specific wrapper was verified using a Verilator simulation with a PLL simulation stub.

The wrapper simulation validates:

- reset sequencing
- input-image loading
- input memory write control
- inference start
- inference completion
- predicted digit output
- LED encoding

The wrapper required investigation of FPGA-inferred memory read timing because FPGA memory primitives can behave differently from simple behavioral Verilog memories.

A PROM-alignment modification was introduced and successfully passed the wrapper simulation.

## 7. Physical Hardware Validation

### Test #1

An earlier known-good FPGA configuration successfully performed an end-to-end inference and produced digit **7**.

### Test #2 — Known-good final hardware validation

- MNIST index: **1**
- Ground-truth label: **2**
- Expected prediction: **2**
- Physical FPGA prediction: **2**
- Observed LED state: **LED1 ON**
- Result: **PASS**

The verified bitstream was preserved at:

`backups/final/mnist_fpga_phase6_known_good_test2.fs`

SHA256:

`b3a5cf51840e20784da52ee57b791c2857b4c7177dafb0e938449381dccd75ce`

### Test #3

- MNIST index: **3**
- Ground-truth label: **0**
- RTL wrapper simulation: **PASS**
- Physical FPGA result: **No digit LEDs observed**
- Result: **Physical validation not passing**

Generated FC1 activation vector:

```text
[0,45,26,0,0,0,15,86,53,33,31,0,0,28,14,50,
 30,34,0,37,20,14,0,55,0,0,0,32,0,12,0,56]
```

RTL simulation produced:

```text
LED[5:0] = 111111
Decoded predicted digit = 0
GOWIN WRAPPER TEST: PASS
```

The corresponding physical FPGA test did not reproduce the expected digit-0 output.

## 8. Known Limitation

The remaining discrepancy was not resolved during Phase 6. It is associated with the synthesized FPGA memory/input-loading path under the tested configuration.

The project contains diagnostic and experimental artifacts from the investigation. These are preserved rather than deleted.

The known-good Test #2 bitstream is retained as the reproducible physical hardware demonstration.

## 9. Final Phase 6 Result

Phase 6 successfully demonstrated:

1. End-to-end synthesis of the MNIST accelerator for the Tang Nano 20K.
2. Successful Gowin place-and-route and bitstream generation.
3. Successful physical FPGA programming.
4. Successful physical inference for a known MNIST test vector.
5. Agreement between the Python reference, RTL simulation, and physical FPGA for the validated Test #2 vector.

The remaining Test #3 discrepancy is documented explicitly as a known hardware-validation limitation.

## 10. Preserved Final Hardware Artifact

`backups/final/mnist_fpga_phase6_known_good_test2.fs`

SHA256:

`b3a5cf51840e20784da52ee57b791c2857b4c7177dafb0e938449381dccd75ce`

This is the physically verified Phase 6 bitstream and should be used when demonstrating the working FPGA implementation.

## 11. Project Completion

The planned implementation and hardware-validation workflow is complete to the extent demonstrated by the validated hardware configuration.

```text
PyTorch training
      |
      v
Quantization
      |
      v
Integer numerical reference
      |
      v
RTL implementation
      |
      v
RTL verification
      |
      v
Resource optimization
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
