import torch
import torch.nn as nn
from torchvision import datasets, transforms
from torch.utils.data import DataLoader


class MNISTNet(nn.Module):
    def __init__(self):
        super().__init__()
        self.fc1 = nn.Linear(784, 32)
        self.fc2 = nn.Linear(32, 10)


# --------------------------------------------------
# Load trained model
# --------------------------------------------------

model = MNISTNet()

state_dict = torch.load(
    "python/mnist_model.pth",
    map_location="cpu"
)

model.load_state_dict(state_dict)
model.eval()


# --------------------------------------------------
# Load MNIST test set
# --------------------------------------------------

transform = transforms.ToTensor()

dataset = datasets.MNIST(
    root="./data",
    train=False,
    download=True,
    transform=transform
)

loader = DataLoader(
    dataset,
    batch_size=256,
    shuffle=False
)


# --------------------------------------------------
# Activation quantization parameters
# --------------------------------------------------

scale = 4

float_correct = 0
quant_correct = 0
agreement = 0
total = 0

activation_min = float("inf")
activation_max = float("-inf")

quantized_min = float("inf")
quantized_max = float("-inf")


# --------------------------------------------------
# Run inference
# --------------------------------------------------

with torch.no_grad():

    for images, labels in loader:

        # Flatten
        x = images.view(-1, 784)

        # FC1
        fc1_out = model.fc1(x)

        # ReLU
        activation = torch.relu(fc1_out)

        # Track actual activation range
        activation_min = min(
            activation_min,
            activation.min().item()
        )

        activation_max = max(
            activation_max,
            activation.max().item()
        )

        # ------------------------------------------
        # Quantize activation
        # ------------------------------------------

        q = torch.round(activation * scale)

        # Check signed INT8 range
        if q.min() < -128 or q.max() > 127:
            raise RuntimeError(
                "Activation does not fit in signed INT8"
            )

        # Track quantized integer range
        quantized_min = min(
            quantized_min,
            q.min().item()
        )

        quantized_max = max(
            quantized_max,
            q.max().item()
        )

        # ------------------------------------------
        # Dequantize
        # ------------------------------------------

        dequantized_activation = q / scale

        # ------------------------------------------
        # FC2
        # ------------------------------------------

        float_logits = model.fc2(activation)

        quant_logits = model.fc2(
            dequantized_activation
        )

        # ------------------------------------------
        # Predictions
        # ------------------------------------------

        float_predictions = float_logits.argmax(dim=1)
        quant_predictions = quant_logits.argmax(dim=1)

        float_correct += (
            float_predictions == labels
        ).sum().item()

        quant_correct += (
            quant_predictions == labels
        ).sum().item()

        agreement += (
            float_predictions == quant_predictions
        ).sum().item()

        total += labels.size(0)


# --------------------------------------------------
# Results
# --------------------------------------------------

float_accuracy = 100.0 * float_correct / total
quant_accuracy = 100.0 * quant_correct / total
prediction_agreement = 100.0 * agreement / total

print("======================================")
print("INT8 ACTIVATION QUANTIZATION TEST")
print("======================================")

print(f"Scale: {scale}")
print("Activation format: signed INT8")
print("Fractional bits: 2")

print()

print("Activation range:")
print(f"Minimum: {activation_min}")
print(f"Maximum: {activation_max}")

print()

print("Quantized activation range:")
print(f"Minimum: {quantized_min}")
print(f"Maximum: {quantized_max}")

print()

print(f"Float32 accuracy:          {float_accuracy:.4f}%")
print(f"Quantized-activation accuracy: {quant_accuracy:.4f}%")
print(f"Prediction agreement:      {prediction_agreement:.4f}%")
print(f"Prediction disagreements:  {total - agreement}")
