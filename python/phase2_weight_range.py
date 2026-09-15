import torch
import torch.nn as nn


# Recreate the architecture from Phase 1
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


# Load trained parameters
model = MNISTNet()

state_dict = torch.load(
    "python/mnist_model.pth",
    map_location="cpu"
)

model.load_state_dict(state_dict)
model.eval()


# Extract parameters
fc1_weights = model.fc1.weight
fc1_bias = model.fc1.bias

fc2_weights = model.fc2.weight
fc2_bias = model.fc2.bias


# Print statistics
print("FC1 weights")
print("Shape:", fc1_weights.shape)
print("Min:", fc1_weights.min().item())
print("Max:", fc1_weights.max().item())
print("Mean:", fc1_weights.mean().item())
print("Std:", fc1_weights.std().item())

print()

print("FC1 bias")
print("Shape:", fc1_bias.shape)
print("Min:", fc1_bias.min().item())
print("Max:", fc1_bias.max().item())
print("Mean:", fc1_bias.mean().item())
print("Std:", fc1_bias.std().item())

print()

print("FC2 weights")
print("Shape:", fc2_weights.shape)
print("Min:", fc2_weights.min().item())
print("Max:", fc2_weights.max().item())
print("Mean:", fc2_weights.mean().item())
print("Std:", fc2_weights.std().item())

print()

print("FC2 bias")
print("Shape:", fc2_bias.shape)
print("Min:", fc2_bias.min().item())
print("Max:", fc2_bias.max().item())
print("Mean:", fc2_bias.mean().item())
print("Std:", fc2_bias.std().item())
