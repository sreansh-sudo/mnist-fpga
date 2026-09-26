import torch
from pathlib import Path

MODEL_PATH = Path("python/mnist_model.pth")
OUTPUT_FILE = Path("data/fc1_bias.mem")

BIAS_SCALE = 8192
NUM_NEURONS = 32

INT26_MIN = -(1 << 25)
INT26_MAX = (1 << 25) - 1


print("Loading model parameters...")

state = torch.load(
    MODEL_PATH,
    map_location="cpu",
    weights_only=False
)

bias = state["fc1.bias"].detach().cpu()

print(f"FC1 bias shape: {tuple(bias.shape)}")

assert bias.shape == (NUM_NEURONS,)


# ------------------------------------------------------------
# Quantize
#
# b1_q = round(b1 × 8192)
# ------------------------------------------------------------

quantized = torch.round(bias * BIAS_SCALE).to(torch.int64)

q_min = quantized.min().item()
q_max = quantized.max().item()

print("\nQuantized FC1 bias range:")
print(f"Min: {q_min}")
print(f"Max: {q_max}")

assert q_min >= INT26_MIN
assert q_max <= INT26_MAX

print("26-bit signed range check: PASS")


# ------------------------------------------------------------
# Convert signed integer to 26-bit two's complement hex
# ------------------------------------------------------------

def int26_to_hex(value):
    assert INT26_MIN <= value <= INT26_MAX

    if value < 0:
        value = (1 << 26) + value

    return f"{value:07X}"


# ------------------------------------------------------------
# Write memory file
# ------------------------------------------------------------

OUTPUT_FILE.parent.mkdir(parents=True, exist_ok=True)

with open(OUTPUT_FILE, "w") as f:
    for value in quantized.tolist():
        f.write(int26_to_hex(value) + "\n")


# ------------------------------------------------------------
# Print verification
# ------------------------------------------------------------

print("\nFC1 bias values:")

for neuron in range(NUM_NEURONS):
    original = bias[neuron].item()
    q_value = quantized[neuron].item()

    print(
        f"Neuron {neuron:2d}: "
        f"float={original:+.8f}  "
        f"quantized={q_value:7d}  "
        f"hex={int26_to_hex(q_value)}"
    )


print("\nMemory size check:")

with open(OUTPUT_FILE, "r") as f:
    lines = f.readlines()

assert len(lines) == NUM_NEURONS

print(f"Entries: {len(lines)}")
print("Memory size check: PASS")

print(f"\nGenerated: {OUTPUT_FILE}")
print("FC1 bias memory generation complete.")
