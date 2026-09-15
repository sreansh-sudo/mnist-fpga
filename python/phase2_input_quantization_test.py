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
# Test one input scale
# --------------------------------------------------

def test_scale(scale):

    float_correct = 0
    quant_correct = 0
    agreement = 0
    total = 0

    input_min = float("inf")
    input_max = float("-inf")

    quant_min = float("inf")
    quant_max = float("-inf")

    total_abs_error = 0.0
    total_values = 0

    with torch.no_grad():

        for images, labels in loader:

            # Float32 reference
            float_logits = model(images)

            # --------------------------------------
            # Quantize input
            # --------------------------------------

            q = torch.round(images * scale)

            # Unsigned 8-bit range check
            if q.min() < 0 or q.max() > 255:
                raise RuntimeError(
                    "Input does not fit unsigned INT8"
                )

            # Dequantize
            quantized_images = q / scale

            # Track input ranges
            input_min = min(
                input_min,
                images.min().item()
            )

            input_max = max(
                input_max,
                images.max().item()
            )

            quant_min = min(
                quant_min,
                q.min().item()
            )

            quant_max = max(
                quant_max,
                q.max().item()
            )

            # Quantization error
            error = quantized_images - images

            total_abs_error += error.abs().sum().item()
            total_values += error.numel()

            # --------------------------------------
            # Run network with quantized input
            # --------------------------------------

            quant_logits = model(quantized_images)

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

    float_accuracy = 100.0 * float_correct / total
    quant_accuracy = 100.0 * quant_correct / total
    prediction_agreement = 100.0 * agreement / total
    mae = total_abs_error / total_values

    print("--------------------------------------")
    print(f"Scale: {scale}")
    print(f"Resolution: {1.0 / scale:.10f}")

    print()
    print("Original input range:")
    print(f"Minimum: {input_min}")
    print(f"Maximum: {input_max}")

    print()
    print("Quantized integer range:")
    print(f"Minimum: {quant_min}")
    print(f"Maximum: {quant_max}")

    print()
    print(f"Input quantization MAE:   {mae:.10f}")
    print(f"Float32 accuracy:         {float_accuracy:.4f}%")
    print(f"Quantized-input accuracy: {quant_accuracy:.4f}%")
    print(f"Prediction agreement:     {prediction_agreement:.4f}%")
    print(f"Prediction disagreements: {total - agreement}")


# --------------------------------------------------
# Run both candidates
# --------------------------------------------------

print("======================================")
print("INPUT QUANTIZATION TEST")
print("======================================")

print()
print("Candidate A: unsigned 8-bit, scale 128")
test_scale(128)

print()
print("Candidate B: unsigned 8-bit, scale 255")
test_scale(255)
