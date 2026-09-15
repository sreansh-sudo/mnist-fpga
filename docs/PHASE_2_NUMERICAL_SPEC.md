# Phase 2 — Numerical Representation & Quantization

## 1. Objective

Determine a hardware-friendly numerical representation for the MNIST neural network before RTL implementation.

The goal was to experimentally evaluate quantization choices rather than assuming that INT8 is automatically suitable.

---

## 2. Baseline Model

Neural network architecture:

```text
784 → 32 → 10

Input
  ↓
FC1 (784 → 32)
  ↓
ReLU
  ↓
FC2 (32 → 10)
  ↓
Argmax
```

The model contains:

* FC1 weights: 25,088
* FC2 weights: 320
* Total weights: 25,408
* Total trainable parameters including biases: 25,450

Float32 test accuracy:

**95.71%**

---

## 3. Quantization Fundamentals

Fixed-point quantization is performed using:

$$
q = round(x \times S)
$$

where:

* \(x\) = real-valued quantity
* \(S\) = scale
* \(q\) = stored integer

Dequantization:

$$
x \approx \frac{q}{S}
$$

Resolution:

$$
\frac{1}{S}
$$

Power-of-two scales are preferred for hardware because rescaling can often be implemented using bit shifts.

---

## 4. Input Quantization

MNIST input values are in the range:

$$
0 \leq x \leq 1
$$

Candidate:

* unsigned INT8
* scale = 128
* resolution = 0.0078125

Quantization:

$$
x_q = round(x \times 128)
$$

The measured input quantization experiment produced:

* MAE: 0.0003585223
* Float32 accuracy: 95.7100%
* Quantized-input accuracy: 95.7200%
* Prediction agreement: 99.9900%
* Prediction disagreements: 1 / 10,000

Scale 255 reconstructed the original MNIST values exactly, but scale 128 was selected as the more hardware-friendly power-of-two scale.

---

## 5. Weight Quantization

Weights were evaluated using signed INT8 and different power-of-two scales.

The selected scale was:

$$
S_w = 64
$$

Resolution:

$$
1/64 = 0.015625
$$

Weight quantization:

$$
w_q = round(w \times 64)
$$

Measured weight quantization errors:

| Fractional bits |        MAE | Maximum error |          MSE |
| --------------: | ---------: | ------------: | -----------: |
|               4 | 0.01580369 |    0.03124830 | 0.0003320194 |
|               5 | 0.00776515 |    0.01562314 | 0.0000808150 |
|               6 | 0.00388247 |    0.00781241 | 0.0000201482 |
|               7 | 0.00195672 |    0.00390621 | 0.0000051033 |
|               8 | 0.00097554 |    0.00195288 | 0.0000012706 |
|               9 | 0.00048684 |    0.00097656 | 0.0000003161 |
|              10 | 0.00024476 |    0.00048828 | 0.0000000797 |

Signed INT8 with scale 64 was selected because the maximum absolute FC2 weight was approximately 1.1294.

At scale 64:

$$
1.1294\times64\approx72.3
$$

which fits inside signed INT8.

At scale 128:

$$
1.1294\times128\approx144.6
$$

which does not fit inside signed INT8.

---

## 6. FC1 Scale Propagation

For:

$$
x_q=xS_x
$$

and:

$$
w_q=wS_w
$$

the integer product is:

$$
x_qw_q
$$

with product scale:

$$
S_xS_w
$$

For FC1:

$$
S_x=128
$$

$$
S_{w1}=64
$$

Therefore:

$$
S_{p1}=128\times64=\boxed{8192}
$$

The accumulator retains this scale because addition does not change the scale.

---

## 7. FC1 Bias

Because the FC1 accumulator has scale 8192, the FC1 bias must also be represented at scale 8192.

$$
b_{1q}=round(b_1\times8192)
$$

This allows the bias to be added directly to the integer accumulator.

---

## 8. FC1 Accumulator

Each FC1 neuron performs 784 multiply-accumulate operations.

An 8-bit × 8-bit multiplication requires approximately 16 bits for the product.

A conservative accumulator-width calculation gives:

$$
16+\lceil\log_2(784)\rceil
$$

$$
=16+10
$$

$$
=\boxed{26\text{ bits}}
$$

The proposed FC1 accumulator is therefore:

**signed 26-bit**

Observed test-set range:

$$
-176073\rightarrow146961
$$

Observed range required only 19 signed bits, but 26 bits was retained as a conservative hardware width based on theoretical operand bounds.

---

## 9. FC1 Activation Quantization

FC1 is followed by ReLU:

$$
a=max(0,y)
$$

Therefore FC1 activations are non-negative.

An experiment compared signed INT8 scale 4 against unsigned INT8 scale 8.

### Signed INT8, scale 4

* Accuracy: 95.6800%
* Prediction agreement: 99.6900%
* Disagreements: 31
* Resolution: 0.25

### Unsigned INT8, scale 8

* Accuracy: 95.7100%
* Prediction agreement: 99.7600%
* Disagreements: 24
* Resolution: 0.125
* Activation range: 0–144

The unsigned representation was selected because ReLU produces only non-negative values and unsigned INT8 provides the full range:

$$
0\rightarrow255
$$

Selected activation representation:

**unsigned INT8, scale 8**

---

## 10. FC1 Requantization

The FC1 accumulator has scale:

$$
8192
$$

The activation has scale:

$$
8
$$

Therefore:

$$
\frac{8192}{8}=1024
$$

The accumulator can be converted to activation representation using:

$$
a_q=round\left(\frac{acc}{1024}\right)
$$

Since:

$$
1024=2^{10}
$$

this can be implemented efficiently using a right shift with appropriate rounding.

ReLU is applied before the final unsigned activation representation.

---

## 11. FC2 Scale Propagation

FC1 activation scale:

$$
S_{a1}=8
$$

FC2 weight scale:

$$
S_{w2}=64
$$

Therefore:

$$
S_{p2}=8\times64=\boxed{512}
$$

The FC2 accumulator therefore also has scale 512.

---

## 12. FC2 Bias

The FC2 bias must use the accumulator scale:

$$
b_{2q}=round(b_2\times512)
$$

This allows direct integer addition to the FC2 accumulator.

---

## 13. FC2 Accumulator

FC2 has 32 inputs.

Using approximately 16-bit products:

$$
16+\lceil\log_2(32)\rceil
$$

$$
=16+5
$$

$$
=\boxed{21\text{ bits}}
$$

Selected FC2 accumulator:

**signed 21-bit**

Observed test-set range:

$$
-7927\rightarrow5418
$$

Only 14 signed bits were required for the observed test-set range, but 21 bits was retained as a conservative hardware width.

---

## 14. Argmax

The FC2 logits all have the same scale:

$$
S_{logit}=512
$$

Therefore dequantization is unnecessary before classification.

The predicted digit can be obtained directly from:

$$
prediction=\operatorname{argmax}(acc_2)
$$

because multiplying or dividing every value by the same positive scale does not change their ordering.

---

## 15. Saturation Policy

Finite-width values must not wrap around.

For unsigned INT8 activation:

$$
0\leq a_q\leq255
$$

Values above 255 should saturate to 255 rather than wrap around.

Values below 0 should saturate to 0.

The measured activation range was:

$$
0\rightarrow144
$$

so no activation saturation occurred on the 10,000-image MNIST test set.

Accumulator widths were selected to provide sufficient theoretical headroom, so overflow should not occur during normal operation.

---

## 16. Full Integer Network Validation

The complete quantized network was evaluated on all 10,000 MNIST test images.

Final results:

| Metric                   |  Float32 |       Quantized |
| ------------------------ | -------: | --------------: |
| Accuracy                 | 95.7100% |    **95.7100%** |
| Prediction agreement     |        — |    **99.7600%** |
| Prediction disagreements |        — | **24 / 10,000** |

The quantized network therefore preserved the measured float32 classification accuracy.

---

## 17. Final Numerical Architecture

| Stage           | Representation    | Scale |                  Width |
| --------------- | ----------------- | ----: | ---------------------: |
| Input           | Unsigned INT8     |   128 |                 8 bits |
| FC1 weights     | Signed INT8       |    64 |                 8 bits |
| FC1 product     | Signed integer    |  8192 |               ~16 bits |
| FC1 accumulator | Signed integer    |  8192 |            **26 bits** |
| FC1 bias        | Signed integer    |  8192 | accumulator-compatible |
| FC1 activation  | **Unsigned INT8** | **8** |             **8 bits** |
| FC2 weights     | Signed INT8       |    64 |                 8 bits |
| FC2 product     | Signed integer    |   512 |               ~16 bits |
| FC2 accumulator | Signed integer    |   512 |            **21 bits** |
| FC2 bias        | Signed integer    |   512 | accumulator-compatible |
| Output          | Integer argmax    |     — |                      — |

---

## 18. Complete Numerical Datapath

```text
MNIST input
    │
    ▼
Unsigned INT8
Scale = 128
    │
    │ ×
    ▼
Signed INT8 FC1 weight
Scale = 64
    │
    ▼
16-bit product
Scale = 8192
    │
    ▼
26-bit accumulator
Scale = 8192
    │
    + FC1 bias
    │
    ▼
ReLU
    │
    ▼
Unsigned INT8 activation
Scale = 8
    │
    │ ×
    ▼
Signed INT8 FC2 weight
Scale = 64
    │
    ▼
16-bit product
Scale = 512
    │
    ▼
21-bit accumulator
Scale = 512
    │
    + FC2 bias
    │
    ▼
10 integer logits
    │
    ▼
ARGMAX
    │
    ▼
Predicted digit
```

---

## 19. Phase 2 Conclusion

The numerical representation was determined experimentally rather than assumed.

The final candidate uses INT8 operands with wider accumulators:

* unsigned INT8 input
* signed INT8 weights
* unsigned INT8 FC1 activation
* 26-bit FC1 accumulator
* 21-bit FC2 accumulator
* power-of-two scaling
* integer argmax
* saturation for finite-width activation outputs

The complete integer implementation achieved **95.71% test accuracy**, matching the measured float32 baseline.

**Phase 2 — Numerical Representation & Quantization: COMPLETE.**
