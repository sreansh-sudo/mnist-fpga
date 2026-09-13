import torch
from torchvision import datasets
from torchvision.transforms import ToTensor

# Load MNIST training dataset
train_dataset = datasets.MNIST(
    root="../data",
    train=True,
    download=True,
    transform=ToTensor()
)


# Load MNIST test dataset
test_dataset = datasets.MNIST(
    root="../data",
    train=False,
    download=True,
    transform=ToTensor()
)

print("Training samples:", len(train_dataset))
print("Test samples:", len(test_dataset))


# Inspect one training sample
image, label = train_dataset[0]

print("\n--- One training sample ---")
print("Image shape:", image.shape)
print("Image dtype:", image.dtype)
print("Minimum:", image.min().item())
print("Maximum:", image.max().item())
print("Label:", label)


# Flatten the image
flattened = image.view(-1)

print("\n--- Flattened tensor ---")
print("Flattened shape:", flattened.shape)
print("Number of values:", flattened.numel())
print("Data type:", flattened.dtype)
print("Minimum:", flattened.min().item())
print("Maximum:", flattened.max().item())

assert flattened.shape == torch.Size([784])
assert flattened.numel() == 784

print("PyTorch flattening verification: PASS")
