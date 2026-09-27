import torch

MODEL_PATH = "python/mnist_model.pth"

# Exact FC1 activations used by the RTL integration test
activations = [
    0, 33, 21, 0, 0, 41, 37, 46,
    40, 40, 14, 0, 42, 21, 27, 7,
    34, 39, 0, 34, 31, 17, 5, 0,
    2, 1, 25, 0, 24, 0, 0, 3
]

# Phase 2 numerical specification
WEIGHT_SCALE = 64
BIAS_SCALE = 512
ACC_WIDTH = 21


def signed_nbit(value, bits):
    """
    Convert an integer into signed two's-complement interpretation.
    """
    mask = (1 << bits) - 1
    value &= mask

    if value & (1 << (bits - 1)):
        value -= (1 << bits)

    return value


# Load trained model
state = torch.load(
    MODEL_PATH,
    map_location="cpu",
    weights_only=True
)

fc2_weight = state["fc2.weight"]
fc2_bias = state["fc2.bias"]

# Quantize exactly as Phase 2
q_weight = torch.round(fc2_weight * WEIGHT_SCALE).to(torch.int64)
q_bias = torch.round(fc2_bias * BIAS_SCALE).to(torch.int64)

print("========================================")
print("PYTHON FC2 INTEGER REFERENCE")
print("========================================")

print()
print("FC2 weights:")
print(q_weight)

print()
print("FC2 biases:")
print(q_bias)

# Calculate integer FC2 logits
logits = []

for neuron in range(10):

    accumulator = int(q_bias[neuron])

    for i in range(32):
        activation = int(activations[i])
        weight = int(q_weight[neuron, i])

        accumulator += activation * weight

    # RTL accumulator is signed 21-bit.
    accumulator = signed_nbit(accumulator, ACC_WIDTH)

    logits.append(accumulator)


print()
print("========================================")
print("PYTHON FC2 LOGITS")
print("========================================")

for i, value in enumerate(logits):
    print(f"logit{i} = {value}")

prediction = max(range(10), key=lambda i: logits[i])

print()
print(f"Predicted digit = {prediction}")
print("Expected digit  = 7")

print()
print("========================================")

if prediction == 7:
    print("PYTHON FC2 REFERENCE: PASS")
else:
    print("PYTHON FC2 REFERENCE: FAIL")

print("========================================")
