import torch
from pathlib import Path

# ------------------------------------------------------------
# Configuration
# ------------------------------------------------------------

MODEL_PATH = Path("python/mnist_model.pth")
OUTPUT_DIR = Path("data")

BIAS_SCALE = 512
FC2_OUTPUTS = 10

INT21_MIN = -(1 << 20)
INT21_MAX = (1 << 20) - 1


# ------------------------------------------------------------
# Load model
# ------------------------------------------------------------

print("Loading model parameters...")

checkpoint = torch.load(
    MODEL_PATH,
    map_location="cpu",
    weights_only=True
)

state = checkpoint["model_state_dict"] if "model_state_dict" in checkpoint else checkpoint

fc2_bias = state["fc2.bias"]

print(f"FC2 bias shape: {tuple(fc2_bias.shape)}")


# ------------------------------------------------------------
# Verify shape
# ------------------------------------------------------------

if fc2_bias.shape != (FC2_OUTPUTS,):
    raise ValueError(
        f"Expected FC2 bias shape ({FC2_OUTPUTS},), "
        f"got {tuple(fc2_bias.shape)}"
    )


# ------------------------------------------------------------
# Quantize
#
# FC2 bias scale = 512
# ------------------------------------------------------------

quantized_bias = torch.round(fc2_bias * BIAS_SCALE).to(torch.int32)


# ------------------------------------------------------------
# Range check
# ------------------------------------------------------------

bias_min = int(quantized_bias.min().item())
bias_max = int(quantized_bias.max().item())

print("\nQuantized FC2 bias range:")
print(f"Min: {bias_min}")
print(f"Max: {bias_max}")

if bias_min < INT21_MIN or bias_max > INT21_MAX:
    raise ValueError("FC2 bias does not fit in signed 21-bit range.")

print("21-bit range check: PASS")


# ------------------------------------------------------------
# Output directory
# ------------------------------------------------------------

OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

output_file = OUTPUT_DIR / "fc2_bias.mem"


# ------------------------------------------------------------
# Write signed 21-bit two's-complement hexadecimal values
#
# 21 bits require 6 hexadecimal digits.
# ------------------------------------------------------------

with open(output_file, "w") as f:

    for neuron in range(FC2_OUTPUTS):

        value = int(quantized_bias[neuron].item())

        # Convert signed integer to 21-bit two's complement.
        hex_value = f"{value & 0x1FFFFF:06X}"

        f.write(hex_value + "\n")


# ------------------------------------------------------------
# Verification printout
# ------------------------------------------------------------

print(f"\nGenerated: {output_file}")

print("\nVerification:")
print("Neuron | Float Bias      | Quantized | Hex")
print("---------------------------------------------")

for neuron in range(FC2_OUTPUTS):

    float_value = float(fc2_bias[neuron].item())
    int_value = int(quantized_bias[neuron].item())
    hex_value = f"{int_value & 0x1FFFFF:06X}"

    print(
        f"{neuron:6d} | "
        f"{float_value:+.8f} | "
        f"{int_value:9d} | "
        f"{hex_value}"
    )


# ------------------------------------------------------------
# Memory size check
# ------------------------------------------------------------

with open(output_file, "r") as f:
    lines = [line.strip() for line in f if line.strip()]

if len(lines) != FC2_OUTPUTS:
    raise ValueError(
        f"Expected {FC2_OUTPUTS} bias entries, got {len(lines)}"
    )

print("\nMemory size check: PASS")
print(f"Bias entries: {len(lines)}")

print("\nFC2 bias memory generation complete.")
