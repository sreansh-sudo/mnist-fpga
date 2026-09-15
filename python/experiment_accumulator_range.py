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
# Scales
# ============================================================

Sx = 128
Sw1 = 64
Sa1 = 4
Sw2 = 64

Sacc1 = Sx * Sw1       # 8192
Sacc2 = Sa1 * Sw2      # 256


# ============================================================
# Quantize parameters
# ============================================================

W1_q = torch.round(
    model.fc1.weight.detach() * Sw1
).to(torch.int32)

b1_q = torch.round(
    model.fc1.bias.detach() * Sacc1
).to(torch.int32)

W2_q = torch.round(
    model.fc2.weight.detach() * Sw2
).to(torch.int32)

b2_q = torch.round(
    model.fc2.bias.detach() * Sacc2
).to(torch.int32)


# ============================================================
# Quantize input
# ============================================================

x_q = torch.round(
    x * Sx
).to(torch.int32)


# ============================================================
# FC1 accumulator
# ============================================================

acc1 = x_q @ W1_q.T

acc1 = acc1 + b1_q


# ============================================================
# FC1 range
# ============================================================

fc1_min = acc1.min().item()
fc1_max = acc1.max().item()


# ============================================================
# FC1 width check
# ============================================================

FC1_BITS = 26

fc1_min_limit = -(2 ** (FC1_BITS - 1))
fc1_max_limit = (2 ** (FC1_BITS - 1)) - 1

fc1_overflow = (
    fc1_min < fc1_min_limit
    or fc1_max > fc1_max_limit
)


# ============================================================
# Requantize FC1
# ============================================================

acc1_relu = torch.relu(acc1)

a1_q = torch.div(
    acc1_relu + 1024,
    2048,
    rounding_mode="floor"
)

a1_q = torch.clamp(
    a1_q,
    -128,
    127
).to(torch.int32)


# ============================================================
# FC2 accumulator
# ============================================================

acc2 = a1_q @ W2_q.T

acc2 = acc2 + b2_q


# ============================================================
# FC2 range
# ============================================================

fc2_min = acc2.min().item()
fc2_max = acc2.max().item()


# ============================================================
# FC2 width check
# ============================================================

FC2_BITS = 21

fc2_min_limit = -(2 ** (FC2_BITS - 1))
fc2_max_limit = (2 ** (FC2_BITS - 1)) - 1

fc2_overflow = (
    fc2_min < fc2_min_limit
    or fc2_max > fc2_max_limit
)


# ============================================================
# Calculate required bits from observed range
# ============================================================

def required_signed_bits(min_value, max_value):

    for bits in range(1, 64):

        min_limit = -(2 ** (bits - 1))
        max_limit = (2 ** (bits - 1)) - 1

        if min_value >= min_limit and max_value <= max_limit:
            return bits

    return None


fc1_required_bits = required_signed_bits(
    fc1_min,
    fc1_max
)

fc2_required_bits = required_signed_bits(
    fc2_min,
    fc2_max
)


# ============================================================
# Results
# ============================================================

print("\n========================================")
print("EXPERIMENT 2.12 — ACCUMULATOR RANGE")
print("========================================")

print("\nFC1 accumulator:")
print(f"Minimum:                 {fc1_min}")
print(f"Maximum:                 {fc1_max}")
print(f"Proposed width:          {FC1_BITS} bits")
print(f"Allowed minimum:         {fc1_min_limit}")
print(f"Allowed maximum:         {fc1_max_limit}")
print(f"Required observed bits:  {fc1_required_bits}")
print(
    f"Overflow detected:       "
    f"{'YES' if fc1_overflow else 'NO'}"
)

print("\nFC2 accumulator:")
print(f"Minimum:                 {fc2_min}")
print(f"Maximum:                 {fc2_max}")
print(f"Proposed width:          {FC2_BITS} bits")
print(f"Allowed minimum:         {fc2_min_limit}")
print(f"Allowed maximum:         {fc2_max_limit}")
print(f"Required observed bits:  {fc2_required_bits}")
print(
    f"Overflow detected:       "
    f"{'YES' if fc2_overflow else 'NO'}"
)

print("\n========================================")
