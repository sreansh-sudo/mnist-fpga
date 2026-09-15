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
# Extract FC1
# ============================================================

W = model.fc1.weight.detach()
b = model.fc1.bias.detach()


# ============================================================
# Scales
# ============================================================

Sx = 128
Sw = 64
Sacc = Sx * Sw
Sa = 4


# ============================================================
# FLOAT32 reference
# ============================================================

with torch.no_grad():
    fc1_float = model.fc1(x)
    relu_float = torch.relu(fc1_float)


# ============================================================
# Quantize input and weights
# ============================================================

x_q = torch.round(x * Sx)
W_q = torch.round(W * Sw)


# ============================================================
# Dequantize them back to FLOAT
# ============================================================

x_dequant = x_q / Sx
W_dequant = W_q / Sw


# ============================================================
# FLOAT calculation using quantized operands
# ============================================================

fc1_quantized_operands = (
    x_dequant @ W_dequant.T + b
)

relu_quantized_operands = torch.relu(
    fc1_quantized_operands
)


# ============================================================
# Compare against original FLOAT32 FC1
# ============================================================

error = (
    relu_quantized_operands
    - relu_float
)

mae = torch.mean(
    torch.abs(error)
).item()

max_error = torch.max(
    torch.abs(error)
).item()

mse = torch.mean(
    error ** 2
).item()


# ============================================================
# Activation agreement
# ============================================================

q_reference = torch.round(
    relu_float * Sa
)

q_test = torch.round(
    relu_quantized_operands * Sa
)

agreement = torch.mean(
    (q_reference == q_test).float()
).item() * 100


# ============================================================
# Results
# ============================================================

print("\n========================================")
print("EXPERIMENT 2.10")
print("Quantized operands + FLOAT accumulation")
print("========================================")

print(f"\nInput scale:       {Sx}")
print(f"Weight scale:      {Sw}")
print(f"Activation scale:  {Sa}")

print("\nError:")
print(f"MAE:               {mae:.8f}")
print(f"Maximum error:     {max_error:.8f}")
print(f"MSE:               {mse:.8f}")
print(f"Activation agreement: {agreement:.4f}%")

print("\nRanges:")

print(
    f"Float ReLU:        "
    f"{relu_float.min().item():.6f} to "
    f"{relu_float.max().item():.6f}"
)

print(
    f"Quantized operands:"
    f"{relu_quantized_operands.min().item():.6f} to "
    f"{relu_quantized_operands.max().item():.6f}"
)

print("\n========================================")
