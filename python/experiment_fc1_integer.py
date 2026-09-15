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
    torch.load(
        MODEL_PATH,
        map_location="cpu"
    )
)

model.eval()

print("Model loaded successfully.")


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

test_loader = DataLoader(
    test_dataset,
    batch_size=10000,
    shuffle=False
)

images, labels = next(iter(test_loader))

# [10000, 1, 28, 28] -> [10000, 784]
x = images.view(10000, 784)


# ============================================================
# Extract FC1 parameters
# ============================================================

W = model.fc1.weight.detach()
b = model.fc1.bias.detach()


# ============================================================
# Numerical representation
# ============================================================

Sx = 128       # input scale
Sw = 64        # weight scale
Sa = 4         # activation scale

Sacc = Sx * Sw       # 8192
Srequant = Sacc // Sa  # 2048


# ============================================================
# FLOAT32 reference
# ============================================================

with torch.no_grad():

    fc1_float = model.fc1(x)

    relu_float = torch.relu(fc1_float)


# ============================================================
# Quantize input
# ============================================================

x_q = torch.round(
    x * Sx
).to(torch.int32)


# ============================================================
# Quantize FC1 weights
# ============================================================

W_q = torch.round(
    W * Sw
).to(torch.int32)


# ============================================================
# Quantize bias
# ============================================================

b_q = torch.round(
    b * Sacc
).to(torch.int32)


# ============================================================
# Integer FC1 MAC
# ============================================================

acc = x_q @ W_q.T

acc = acc + b_q


# ============================================================
# ReLU
# ============================================================

acc_relu = torch.relu(acc)


# ============================================================
# Requantize accumulator -> activation
# ============================================================

activation_q = torch.div(
    acc_relu + (Srequant // 2),
    Srequant,
    rounding_mode="floor"
)


# ============================================================
# INT8 saturation
# ============================================================

activation_q = torch.clamp(
    activation_q,
    -128,
    127
)

activation_q = activation_q.to(torch.int8)


# ============================================================
# Dequantize
# ============================================================

relu_integer = (
    activation_q.to(torch.float32) / Sa
)


# ============================================================
# Error analysis
# ============================================================

error = relu_integer - relu_float

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

float_activation_q = torch.round(
    relu_float * Sa
).to(torch.int32)

agreement = torch.mean(
    (
        activation_q.to(torch.int32)
        == float_activation_q
    ).float()
).item() * 100


# ============================================================
# Results
# ============================================================

print("\n========================================")
print("EXPERIMENT 2.9 — FULL INTEGER FC1")
print("========================================")

print("\nNumerical representation:")
print(f"Input scale:              {Sx}")
print(f"Weight scale:             {Sw}")
print(f"Accumulator scale:        {Sacc}")
print(f"Activation scale:         {Sa}")
print(f"Activation resolution:    {1/Sa}")

print("\nFC1 activation error:")
print(f"MAE:                      {mae:.8f}")
print(f"Maximum absolute error:   {max_error:.8f}")
print(f"MSE:                      {mse:.8f}")
print(f"Activation agreement:     {agreement:.4f}%")

print("\nActivation ranges:")

print(
    f"Float ReLU:               "
    f"{relu_float.min().item():.6f} to "
    f"{relu_float.max().item():.6f}"
)

print(
    f"Integer/dequantized:      "
    f"{relu_integer.min().item():.6f} to "
    f"{relu_integer.max().item():.6f}"
)

print(
    f"INT8 activation:          "
    f"{activation_q.min().item()} to "
    f"{activation_q.max().item()}"
)

print("\n========================================")
