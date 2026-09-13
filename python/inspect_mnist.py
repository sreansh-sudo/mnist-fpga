import torch
from torchvision import datasets
import numpy as np
import matplotlib.pyplot as plt

print("PyTorch version:", torch.__version__)

dataset = datasets.MNIST(
    root="../data",
    train=True,
    download=True
)

print("Number of training samples:", len(dataset))

image, label = dataset[0]

print("\n--- Original sample ---")
print("Image type:", type(image))
print("Label:", label)
print("Image size:", image.size)


# Convert PIL image to NumPy array
image_array = np.array(image)

print("\n--- NumPy representation ---")
print("Array type:", type(image_array))
print("Data type:", image_array.dtype)
print("Shape:", image_array.shape)
print("Minimum pixel value:", image_array.min())
print("Maximum pixel value:", image_array.max())


# Flatten the 28 x 28 image
flattened = image_array.reshape(-1)

print("\n--- Flattened representation ---")
print("Flattened shape:", flattened.shape)
print("Number of pixels:", len(flattened))

print("\nFirst 20 pixel values:")
print(flattened[:20])

print("\n--- Flattening verification ---")

print("Top-left pixel:", image_array[0, 0])
print("Flattened[0]:", flattened[0])

print("Top-right pixel:", image_array[0, 27])
print("Flattened[27]:", flattened[27])

print("Bottom-left pixel:", image_array[27, 0])
print("Flattened[756]:", flattened[756])

print("Bottom-right pixel:", image_array[27, 27])
print("Flattened[783]:", flattened[783])

assert flattened[0] == image_array[0, 0]
assert flattened[27] == image_array[0, 27]
assert flattened[756] == image_array[27, 0]
assert flattened[783] == image_array[27, 27]

print("Flattening verification: PASS")

# Display the image
plt.imshow(image_array, cmap="gray")
plt.title(f"Label: {label}")
plt.axis("off")
plt.show()


# Normalize pixel values from [0, 255] to [0, 1]
normalized = image_array.astype(np.float32) / 255.0

print("\n--- Normalized representation ---")
print("Data type:", normalized.dtype)
print("Shape:", normalized.shape)
print("Minimum value:", normalized.min())
print("Maximum value:", normalized.max())

print("\nFirst 20 normalized pixel values:")
print(normalized.reshape(-1)[:20])

# Verify normalization
assert normalized.min() >= 0.0
assert normalized.max() <= 1.0

print("Normalization verification: PASS")


# Find non-zero pixels
nonzero_pixels = image_array[image_array > 0]
nonzero_normalized = normalized[image_array > 0]

print("\n--- Non-zero pixel inspection ---")

print("Number of non-zero pixels:", len(nonzero_pixels))

print("First 10 raw non-zero pixels:")
print(nonzero_pixels[:10])

print("First 10 normalized non-zero pixels:")
print(nonzero_normalized[:10])
