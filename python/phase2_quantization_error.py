import torch
import torch.nn as nn


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


# Load trained model
model = MNISTNet()

state_dict = torch.load(
    "python/mnist_model.pth",
    map_location="cpu"
)

model.load_state_dict(state_dict)
model.eval()


# Combine all weights
weights = torch.cat([
    model.fc1.weight.flatten(),
    model.fc2.weight.flatten()
])


print("Total weights:", weights.numel())
print()


for fractional_bits in [4, 5, 6, 7, 8, 9, 10]:

    scale = 2 ** fractional_bits

    # Quantize
    quantized = torch.round(weights * scale)

    # Dequantize
    dequantized = quantized / scale

    # Error
    error = dequantized - weights

    mae = error.abs().mean().item()
    max_error = error.abs().max().item()
    mse = (error ** 2).mean().item()

    print(
        f"Q fractional bits = {fractional_bits:2d} | "
        f"MAE = {mae:.8f} | "
        f"Max Error = {max_error:.8f} | "
        f"MSE = {mse:.10f}"
    )
