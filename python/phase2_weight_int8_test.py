import torch
import torch.nn as nn
from torchvision import datasets, transforms
from torch.utils.data import DataLoader


class MNISTNet(nn.Module):
    def __init__(self):
        super().__init__()
        self.fc1 = nn.Linear(784, 32)
        self.fc2 = nn.Linear(32, 10)

    def forward(self, x):
        x = x.view(-1, 784)
        x = self.fc1(x)
        x = torch.relu(x)
        x = self.fc2(x)
        return x


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
# Create quantized-weight model
# --------------------------------------------------

quantized_model = MNISTNet()

scale = 64

with torch.no_grad():

    for original_param, quantized_param in zip(
        model.parameters(),
        quantized_model.parameters()
    ):

        # Quantize to signed INT8 range
        q = torch.round(original_param * scale)

        # Check INT8 range
        if q.min() < -128 or q.max() > 127:
            raise RuntimeError(
                "Parameter does not fit in signed INT8"
            )

        # Dequantize back to float
        dequantized = q / scale

        quantized_param.copy_(dequantized)


quantized_model.eval()


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
# Evaluate both models
# --------------------------------------------------

float_correct = 0
quant_correct = 0
agreement = 0
total = 0

with torch.no_grad():

    for images, labels in loader:

        float_logits = model(images)
        quant_logits = quantized_model(images)

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
print("INT8 WEIGHT QUANTIZATION TEST")
print("======================================")

print(f"Scale: {scale}")
print("Weight format: signed INT8")
print("Fractional bits: 6")

print()

print(f"Float32 accuracy:          {float_accuracy:.4f}%")
print(f"Quantized-weight accuracy: {quant_accuracy:.4f}%")
print(f"Prediction agreement:      {prediction_agreement:.4f}%")
print(f"Prediction disagreements:  {total - agreement}")
