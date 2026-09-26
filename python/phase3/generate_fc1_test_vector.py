import struct
from pathlib import Path

import torch


# ---------------------------------------------------------
# Paths
# ---------------------------------------------------------

PROJECT_ROOT = Path(__file__).resolve().parent.parent

IMAGE_FILE = PROJECT_ROOT / "data" / "raw" / "t10k-images-idx3-ubyte"
LABEL_FILE = PROJECT_ROOT / "data" / "raw" / "t10k-labels-idx1-ubyte"

MODEL_FILE = PROJECT_ROOT / "python" / "mnist_model.pth"

INPUT_MEM_FILE = PROJECT_ROOT / "data" / "test_input.mem"
EXPECTED_MEM_FILE = PROJECT_ROOT / "data" / "fc1_expected_activation.mem"


# ---------------------------------------------------------
# Quantization scales from Phase 2
# ---------------------------------------------------------

INPUT_SCALE = 128
WEIGHT_SCALE = 64
ACCUM_SCALE = 8192
ACTIVATION_SCALE = 8


# ---------------------------------------------------------
# Read one MNIST image directly from IDX file
# ---------------------------------------------------------

def read_mnist_image(filename, index):
    with open(filename, "rb") as f:

        magic, num_images, rows, cols = struct.unpack(
            ">IIII",
            f.read(16)
        )

        if magic != 2051:
            raise ValueError(
                f"Invalid MNIST image file. Magic number = {magic}"
            )

        if index >= num_images:
            raise ValueError(
                f"Image index {index} out of range. "
                f"Dataset contains {num_images} images."
            )

        image_size = rows * cols

        f.seek(16 + index * image_size)

        image = list(f.read(image_size))

        if len(image) != image_size:
            raise ValueError("Could not read complete image.")

        return image, rows, cols


# ---------------------------------------------------------
# Read MNIST label
# ---------------------------------------------------------

def read_mnist_label(filename, index):
    with open(filename, "rb") as f:

        magic, num_labels = struct.unpack(
            ">II",
            f.read(8)
        )

        if magic != 2049:
            raise ValueError(
                f"Invalid MNIST label file. Magic number = {magic}"
            )

        if index >= num_labels:
            raise ValueError(
                f"Label index {index} out of range."
            )

        f.seek(8 + index)

        return f.read(1)[0]


# ---------------------------------------------------------
# Main
# ---------------------------------------------------------

def main():

    # Use the first test image
    TEST_INDEX = 0

    print("Loading MNIST image...")

    pixels, rows, cols = read_mnist_image(
        IMAGE_FILE,
        TEST_INDEX
    )

    label = read_mnist_label(
        LABEL_FILE,
        TEST_INDEX
    )

    print(f"Image index : {TEST_INDEX}")
    print(f"Image size  : {rows} x {cols}")
    print(f"Label       : {label}")

    # -----------------------------------------------------
    # Convert raw pixel 0..255 to the same 0..1 range
    # used by ToTensor() during Phase 1 training.
    #
    # Then quantize using Input Scale = 128.
    #
    # input_q = round((pixel / 255) * 128)
    # -----------------------------------------------------

    input_q = []

    for pixel in pixels:

        value = pixel / 255.0

        q = int(torch.round(
            torch.tensor(value * INPUT_SCALE)
        ).item())

        q = max(0, min(255, q))

        input_q.append(q)

    # -----------------------------------------------------
    # Load trained model
    # -----------------------------------------------------

    print("Loading trained model...")

    state_dict = torch.load(
        MODEL_FILE,
        map_location="cpu"
    )

    fc1_weight = state_dict["fc1.weight"]
    fc1_bias = state_dict["fc1.bias"]

    print(f"FC1 weight shape : {tuple(fc1_weight.shape)}")
    print(f"FC1 bias shape   : {tuple(fc1_bias.shape)}")

    # -----------------------------------------------------
    # Quantize FC1 weights
    # -----------------------------------------------------

    weight_q = torch.round(
        fc1_weight * WEIGHT_SCALE
    ).to(torch.int64)

    # -----------------------------------------------------
    # Quantize FC1 biases
    #
    # Bias is stored at accumulator scale:
    #
    # bias_q = round(bias * 8192)
    # -----------------------------------------------------

    bias_q = torch.round(
        fc1_bias * ACCUM_SCALE
    ).to(torch.int64)

    # -----------------------------------------------------
    # Integer FC1 reference
    #
    # acc = bias_q + sum(input_q * weight_q)
    #
    # activation:
    #
    #   if acc < 0:
    #       0
    #
    #   else:
    #       round(acc / 1024)
    #
    # because:
    #
    #   ACCUM_SCALE / ACTIVATION_SCALE
    #   = 8192 / 8
    #   = 1024
    # -----------------------------------------------------

    expected_activation = []

    accumulators = []

    for neuron in range(32):

        acc = int(bias_q[neuron].item())

        for i in range(784):

            acc += (
                input_q[i]
                * int(weight_q[neuron, i].item())
            )

        accumulators.append(acc)

        if acc < 0:

            activation = 0

        else:

            # Hardware rounding:
            # (acc + 512) >>> 10
            activation = (acc + 512) // 1024

            # Unsigned INT8 saturation
            activation = min(255, activation)

        expected_activation.append(activation)

    # -----------------------------------------------------
    # Write input memory
    # -----------------------------------------------------

    with open(INPUT_MEM_FILE, "w") as f:

        for value in input_q:
            f.write(f"{value:02X}\n")

    # -----------------------------------------------------
    # Write expected activation memory
    # -----------------------------------------------------

    with open(EXPECTED_MEM_FILE, "w") as f:

        for value in expected_activation:
            f.write(f"{value:02X}\n")

    # -----------------------------------------------------
    # Verification information
    # -----------------------------------------------------

    print()
    print("========================================")
    print("FC1 TEST VECTOR GENERATED")
    print("========================================")

    print(f"Input file      : {INPUT_MEM_FILE}")
    print(f"Expected file   : {EXPECTED_MEM_FILE}")

    print()
    print("First 16 quantized input values:")

    print(input_q[:16])

    print()
    print("FC1 accumulators:")

    for i, acc in enumerate(accumulators):
        print(f"Neuron {i:2d}: {acc:8d}")

    print()
    print("Expected activations:")

    print(expected_activation)

    print()
    print("Files generated successfully.")


if __name__ == "__main__":
    main()
