import torch
from pathlib import Path

MODEL_PATH = Path("python/mnist_model.pth")
OUTPUT_DIR = Path("data")

WEIGHT_SCALE = 64

NUM_NEURONS = 10
INPUT_SIZE = 32
NUM_BANKS = 10

INT8_MIN = -128
INT8_MAX = 127


# ------------------------------------------------------------
# Load trained parameters
# ------------------------------------------------------------

print("Loading model parameters...")

state = torch.load(
    MODEL_PATH,
    map_location="cpu",
    weights_only=False
)

weights = state["fc2.weight"].detach().cpu()

print(f"FC2 weight shape: {tuple(weights.shape)}")

assert weights.shape == (NUM_NEURONS, INPUT_SIZE)


# ------------------------------------------------------------
# Quantize FC2 weights
# ------------------------------------------------------------

quantized = torch.round(weights * WEIGHT_SCALE).to(torch.int32)

q_min = quantized.min().item()
q_max = quantized.max().item()

print("\nQuantized FC2 weight range:")
print(f"Min: {q_min}")
print(f"Max: {q_max}")

assert q_min >= INT8_MIN
assert q_max <= INT8_MAX

print("INT8 range check: PASS")


# ------------------------------------------------------------
# Create 10 logical memory banks
# ------------------------------------------------------------
#
# One bank corresponds to one FC2 output neuron:
#
# bank 0 -> neuron 0 -> W[0][0..31]
# bank 1 -> neuron 1 -> W[1][0..31]
# ...
# bank 9 -> neuron 9 -> W[9][0..31]
#
# Address = input index
#
# address 0  -> weight for activation 0
# address 1  -> weight for activation 1
# ...
# address 31 -> weight for activation 31
# ------------------------------------------------------------

BANK_DEPTH = INPUT_SIZE

banks = [
    [0] * BANK_DEPTH
    for _ in range(NUM_BANKS)
]


for neuron in range(NUM_NEURONS):

    for input_idx in range(INPUT_SIZE):

        value = quantized[neuron, input_idx].item()

        banks[neuron][input_idx] = value


# ------------------------------------------------------------
# Convert signed INT8 to two's-complement hex
# ------------------------------------------------------------

def int8_to_hex(value):

    assert INT8_MIN <= value <= INT8_MAX

    return f"{value & 0xFF:02X}"


# ------------------------------------------------------------
# Write .mem files
# ------------------------------------------------------------

OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

for neuron in range(NUM_BANKS):

    output_file = OUTPUT_DIR / f"fc2_bank{neuron}.mem"

    with open(output_file, "w") as f:

        for value in banks[neuron]:

            f.write(int8_to_hex(value) + "\n")

    print(f"Generated: {output_file}")


# ------------------------------------------------------------
# Verification samples
# ------------------------------------------------------------

print("\nVerification samples:")

for neuron in range(NUM_NEURONS):

    print(f"\nNeuron {neuron}:")

    for input_idx in [0, 1, 2, 31]:

        value = banks[neuron][input_idx]
        original = weights[neuron, input_idx].item()

        print(
            f"  input={input_idx:2d}, "
            f"float={original:+.8f}, "
            f"quantized={value:4d}, "
            f"hex={int8_to_hex(value)}"
        )


# ------------------------------------------------------------
# Memory depth verification
# ------------------------------------------------------------

for neuron in range(NUM_BANKS):

    assert len(banks[neuron]) == BANK_DEPTH

print("\nMemory size check: PASS")
print(f"Each bank contains {BANK_DEPTH} weights.")
print(f"Total weights: {NUM_BANKS * BANK_DEPTH}")

print("\nFC2 memory generation complete.")
