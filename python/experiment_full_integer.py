import torch
import torch.nn as nn
from torchvision import datasets, transforms
from torch.utils.data import DataLoader


# ============================================================
# Model definition — identical to train.py
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
# Load trained model
# ============================================================

MODEL_PATH = "python/mnist_model.pth"

model = MNISTNet()

model.load_state_dict(
    torch.load(MODEL_PATH, map_location="cpu")
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
# Quantization scales
# ============================================================

Sx = 128
Sw1 = 64
Sa1 = 4
Sw2 = 64

Sacc1 = Sx * Sw1       # 8192
Sprod2 = Sa1 * Sw2     # 256
Sacc2 = Sprod2         # 256


# ============================================================
# Extract parameters
# ============================================================

W1 = model.fc1.weight.detach()
b1 = model.fc1.bias.detach()

W2 = model.fc2.weight.detach()
b2 = model.fc2.bias.detach()


# ============================================================
# FLOAT32 reference network
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
# QUANTIZE INPUT
# ============================================================

x_q = torch.round(
    x * Sx
).to(torch.int32)


# ============================================================
# QUANTIZE FC1 WEIGHTS
# ============================================================

W1_q = torch.round(
    W1 * Sw1
).to(torch.int32)


# ============================================================
# QUANTIZE FC1 BIAS
# ============================================================

b1_q = torch.round(
    b1 * Sacc1
).to(torch.int32)


# ============================================================
# FC1 INTEGER MAC
# ============================================================

acc1 = x_q @ W1_q.T

acc1 = acc1 + b1_q


# ============================================================
# FC1 ReLU
# ============================================================

acc1 = torch.relu(acc1)


# ============================================================
# FC1 REQUANTIZATION
#
# Accumulator scale = 8192
# Activation scale  = 4
#
# 8192 / 4 = 2048
# ============================================================

a1_q = torch.div(
    acc1 + 1024,
    2048,
    rounding_mode="floor"
)


# ============================================================
# INT8 saturation
# ============================================================

a1_q = torch.clamp(
    a1_q,
    -128,
    127
).to(torch.int32)


# ============================================================
# QUANTIZE FC2 WEIGHTS
# ============================================================

W2_q = torch.round(
    W2 * Sw2
).to(torch.int32)


# ============================================================
# QUANTIZE FC2 BIAS
#
# FC2 accumulator scale = 256
# ============================================================

b2_q = torch.round(
    b2 * Sacc2
).to(torch.int32)


# ============================================================
# FC2 INTEGER MAC
# ============================================================

acc2 = a1_q @ W2_q.T

acc2 = acc2 + b2_q


# ============================================================
# INTEGER ARGMAX
#
# No need to dequantize logits.
# All logits have the same scale.
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


# ============================================================
# Prediction disagreements
# ============================================================

disagreements = (
    quant_predictions != float_predictions
).sum().item()


# ============================================================
# Logit range
# ============================================================

logit_min = acc2.min().item() / Sacc2
logit_max = acc2.max().item() / Sacc2


# ============================================================
# Activation range
# ============================================================

activation_min = a1_q.min().item()
activation_max = a1_q.max().item()


# ============================================================
# Results
# ============================================================

print("\n========================================")
print("EXPERIMENT 2.11 — FULL INTEGER NETWORK")
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

print("\nRanges:")
print(
    f"FC1 INT8 activation:      "
    f"{activation_min} to {activation_max}"
)

print(
    f"FC2 logits (real):        "
    f"{logit_min:.6f} to {logit_max:.6f}"
)

print("\n========================================")
