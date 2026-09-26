import torch
from pathlib import Path

MODEL_PATH = Path("python/mnist_model.pth")
OUTPUT_DIR = Path("data")

WEIGHT_SCALE = 64
NUM_NEURONS = 32
INPUT_SIZE = 784
NUM_LANES = 8
NUM_GROUPS = 4

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

weights = state["fc1.weight"].detach().cpu()

print(f"FC1 weight shape: {tuple(weights.shape)}")

assert weights.shape == (NUM_NEURONS, INPUT_SIZE)


# ------------------------------------------------------------
# Quantize FC1 weights
# ------------------------------------------------------------

quantized = torch.round(weights * WEIGHT_SCALE).to(torch.int32)

q_min = quantized.min().item()
q_max = quantized.max().item()

print("\nQuantized FC1 weight range:")
print(f"Min: {q_min}")
print(f"Max: {q_max}")

assert q_min >= INT8_MIN
assert q_max <= INT8_MAX

print("INT8 range check: PASS")


# ------------------------------------------------------------
# Create 8 logical memory banks
# ------------------------------------------------------------

BANK_DEPTH = NUM_GROUPS * INPUT_SIZE

banks = [
    [0] * BANK_DEPTH
    for _ in range(NUM_LANES)
]


# Mapping:
#
# group 0 → neurons 0..7
# group 1 → neurons 8..15
# group 2 → neurons 16..23
# group 3 → neurons 24..31
#
# bank/lane 0 → neuron group*8 + 0
# bank/lane 1 → neuron group*8 + 1
# ...
# bank/lane 7 → neuron group*8 + 7

for group in range(NUM_GROUPS):

    for input_idx in range(INPUT_SIZE):

        address = group * INPUT_SIZE + input_idx

        for lane in range(NUM_LANES):

            neuron = group * NUM_LANES + lane

            value = quantized[neuron, input_idx].item()

            banks[lane][address] = value


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

for lane in range(NUM_LANES):

    output_file = OUTPUT_DIR / f"fc1_bank{lane}.mem"

    with open(output_file, "w") as f:

        for value in banks[lane]:

            f.write(int8_to_hex(value) + "\n")

    print(f"Generated: {output_file}")


# ------------------------------------------------------------
# Verification
# ------------------------------------------------------------

print("\nVerification samples:")

for group in range(NUM_GROUPS):

    address = group * INPUT_SIZE

    print(f"\nGroup {group}, address {address}:")

    for lane in range(NUM_LANES):

        neuron = group * NUM_LANES + lane

        value = banks[lane][address]

        original = weights[neuron, 0].item()

        print(
            f"  Bank {lane}: "
            f"neuron={neuron:2d}, "
            f"float={original:+.8f}, "
            f"quantized={value:4d}, "
            f"hex={int8_to_hex(value)}"
        )


# ------------------------------------------------------------
# Memory depth verification
# ------------------------------------------------------------

for lane in range(NUM_LANES):

    assert len(banks[lane]) == BANK_DEPTH

print("\nMemory size check: PASS")
print(f"Each bank contains {BANK_DEPTH} weights.")

print("\nFC1 memory generation complete.")
