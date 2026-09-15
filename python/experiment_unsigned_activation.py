import torch
import torch.nn as nn
from torchvision import datasets, transforms
from torch.utils.data import DataLoader


# ============================================================
# Model
# ============================================================

class MNISTNet(nn.Module):
    def __init__(self):
        super().__init__()
        self.fc1 = nn.Linear(784, 32)
        self.relu = nn.ReLU()
        self.fc2 = nn.Linear(32, 10)

    def forward(self, x):
        x = x.view(x.size(0), -1)
        x = self.fc1(x)
        x = self.relu(x)
        x = self.fc2(x)
        return x


# ============================================================
# Load model
# ============================================================

model = MNISTNet()

model.load_state_dict(
    torch.load(
        "python/mnist_model.pth",
        map_location="cpu"
    )
)

model.eval()


# ============================================================
# Dataset
# ============================================================

transform = transforms.ToTensor()

test_dataset = datasets.MNIST(
    root="data",
    train=False,
    download=True,
    transform=transform
)

loader = DataLoader(
    test_dataset,
    batch_size=10000,
    shuffle=False
)

images, labels = next(iter(loader))

x = images.view(10000, 784)


# ============================================================
# Scales
# ============================================================

Sx = 128
Sw1 = 64
Sa1 = 8
Sw2 = 64

Sacc1 = Sx * Sw1
Sacc2 = Sa1 * Sw2


# ============================================================
# FLOAT32 reference
# ============================================================

with torch.no_grad():

    float_logits = model(x)

    float_predictions = float_logits.argmax(dim=1)

    float_accuracy = (
        (float_predictions == labels)
        .float()
        .mean()
        .item()
        * 100
    )


# ============================================================
# Quantize input
# ============================================================

x_q = torch.round(
    x * Sx
).to(torch.int32)


# ============================================================
# Quantize FC1
# ============================================================

W1_q = torch.round(
    model.fc1.weight.detach() * Sw1
).to(torch.int32)

b1_q = torch.round(
    model.fc1.bias.detach() * Sacc1
).to(torch.int32)


# ============================================================
# FC1 integer MAC
# ============================================================

acc1 = x_q @ W1_q.T

acc1 = acc1 + b1_q


# ============================================================
# ReLU
# ============================================================

acc1 = torch.relu(acc1)


# ============================================================
# Requantize to unsigned INT8 activation
#
# 8192 / 8 = 1024
# ============================================================

a1_q = torch.div(
    acc1 + 512,
    1024,
    rounding_mode="floor"
)


# ============================================================
# UNSIGNED INT8 saturation
# ============================================================

a1_q = torch.clamp(
    a1_q,
    0,
    255
).to(torch.int32)


# ============================================================
# Quantize FC2 weights
# ============================================================

W2_q = torch.round(
    model.fc2.weight.detach() * Sw2
).to(torch.int32)


# ============================================================
# FC2 bias
# ============================================================

b2_q = torch.round(
    model.fc2.bias.detach() * Sacc2
).to(torch.int32)


# ============================================================
# FC2 integer MAC
# ============================================================

acc2 = a1_q @ W2_q.T

acc2 = acc2 + b2_q


# ============================================================
# Integer ARGMAX
# ============================================================

quant_predictions = acc2.argmax(dim=1)


# ============================================================
# Accuracy
# ============================================================

quant_accuracy = (
    (quant_predictions == labels)
    .float()
    .mean()
    .item()
    * 100
)


# ============================================================
# Prediction agreement
# ============================================================

prediction_agreement = (
    (quant_predictions == float_predictions)
    .float()
    .mean()
    .item()
    * 100
)

disagreements = (
    quant_predictions != float_predictions
).sum().item()


# ============================================================
# Activation range
# ============================================================

activation_max = a1_q.max().item()


# ============================================================
# Real logit range
# ============================================================

logit_min = acc2.min().item() / Sacc2
logit_max = acc2.max().item() / Sacc2


# ============================================================
# Results
# ============================================================

print("\n========================================")
print("EXPERIMENT 2.13")
print("UNSIGNED INT8 FC1 ACTIVATION")
print("========================================")

print("\nScales:")
print(f"Input scale:              {Sx}")
print(f"FC1 weight scale:         {Sw1}")
print(f"FC1 accumulator scale:    {Sacc1}")
print(f"FC1 activation scale:     {Sa1}")
print(f"FC2 weight scale:         {Sw2}")
print(f"FC2 accumulator scale:    {Sacc2}")

print("\nClassification:")
print(f"Float32 accuracy:         {float_accuracy:.4f}%")
print(f"Quantized accuracy:       {quant_accuracy:.4f}%")
print(f"Prediction agreement:     {prediction_agreement:.4f}%")
print(f"Prediction disagreements: {disagreements}")

print("\nActivation:")
print(f"Unsigned INT8 range:      0 to {activation_max}")
print(f"Resolution:               {1/Sa1}")

print("\nFC2 logits:")
print(f"Real range:               {logit_min:.6f} to {logit_max:.6f}")

print("\n========================================")
