from pathlib import Path

# ------------------------------------------------------------
# Configuration
# ------------------------------------------------------------

DATA_DIR = Path("data")

FC2_INPUTS = 32
FC2_OUTPUTS = 10

# Testbench activation vector:
# activation[i] = i
activations = list(range(FC2_INPUTS))


# ------------------------------------------------------------
# Helpers
# ------------------------------------------------------------

def read_signed_hex_file(path, bits):
    values = []

    with open(path, "r") as f:
        for line in f:
            line = line.strip()

            if not line:
                continue

            value = int(line, 16)

            # Convert two's complement to signed integer.
            if value & (1 << (bits - 1)):
                value -= (1 << bits)

            values.append(value)

    return values


# ------------------------------------------------------------
# Load FC2 weights
# ------------------------------------------------------------

weights = []

for neuron in range(FC2_OUTPUTS):

    path = DATA_DIR / f"fc2_bank{neuron}.mem"

    bank = read_signed_hex_file(path, 8)

    if len(bank) != FC2_INPUTS:
        raise ValueError(
            f"{path}: expected {FC2_INPUTS} weights, "
            f"got {len(bank)}"
        )

    weights.append(bank)


# ------------------------------------------------------------
# Load FC2 biases
# ------------------------------------------------------------

biases = read_signed_hex_file(
    DATA_DIR / "fc2_bias.mem",
    21
)

if len(biases) != FC2_OUTPUTS:
    raise ValueError(
        f"Expected {FC2_OUTPUTS} biases, got {len(biases)}"
    )


# ------------------------------------------------------------
# Calculate reference logits
# ------------------------------------------------------------

logits = []

for neuron in range(FC2_OUTPUTS):

    accumulator = biases[neuron]

    for i in range(FC2_INPUTS):
        accumulator += activations[i] * weights[neuron][i]

    logits.append(accumulator)


# ------------------------------------------------------------
# Argmax
# ------------------------------------------------------------

predicted_digit = max(
    range(FC2_OUTPUTS),
    key=lambda n: logits[n]
)


# ------------------------------------------------------------
# Print results
# ------------------------------------------------------------

print("========================================")
print("FC2 PYTHON REFERENCE")
print("========================================")

for neuron, logit in enumerate(logits):
    print(f"logit{neuron} = {logit}")

print()
print(f"Predicted digit = {predicted_digit}")
print("========================================")
