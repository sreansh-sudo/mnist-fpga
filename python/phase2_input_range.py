import torch
from torchvision import datasets, transforms


# Same normalization used by the trained model
transform = transforms.ToTensor()

dataset = datasets.MNIST(
    root="./data",
    train=False,
    download=True,
    transform=transform
)

all_pixels = torch.stack([image for image, label in dataset])

print("Dataset shape:", all_pixels.shape)

print("Minimum pixel value:", all_pixels.min().item())
print("Maximum pixel value:", all_pixels.max().item())
print("Mean pixel value:", all_pixels.mean().item())
print("Standard deviation:", all_pixels.std().item())
