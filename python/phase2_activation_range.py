import torch
from torchvision import datasets, transforms
from torch.utils.data import DataLoader
import torch.nn as nn


class MNISTNet(nn.Module):
    def __init__(self):
        super().__init__()

        self.fc1 = nn.Linear(784, 32)
        self.fc2 = nn.Linear(32, 10)

    def forward(self, x):
        x = x.view(-1, 784)

        fc1_out = self.fc1(x)
        relu_out = torch.relu(fc1_out)
        logits = self.fc2(relu_out)

        return fc1_out, relu_out, logits


# Load dataset
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


# Load trained model
model = MNISTNet()

state_dict = torch.load(
    "python/mnist_model.pth",
    map_location="cpu"
)

model.load_state_dict(state_dict)
model.eval()


# Track global ranges
fc1_min = float("inf")
fc1_max = float("-inf")

relu_min = float("inf")
relu_max = float("-inf")

logits_min = float("inf")
logits_max = float("-inf")


with torch.no_grad():

    for images, labels in loader:

        fc1_out, relu_out, logits = model(images)

        fc1_min = min(fc1_min, fc1_out.min().item())
        fc1_max = max(fc1_max, fc1_out.max().item())

        relu_min = min(relu_min, relu_out.min().item())
        relu_max = max(relu_max, relu_out.max().item())

        logits_min = min(logits_min, logits.min().item())
        logits_max = max(logits_max, logits.max().item())


print("FC1 pre-activation")
print("Min:", fc1_min)
print("Max:", fc1_max)

print()

print("FC1 ReLU activation")
print("Min:", relu_min)
print("Max:", relu_max)

print()

print("FC2 logits")
print("Min:", logits_min)
print("Max:", logits_max)
