import torch
import torch.nn as nn
from torch.utils.data import DataLoader
from torchvision import datasets, transforms


# ============================================================
# Configuration
# ============================================================

BATCH_SIZE = 64
LEARNING_RATE = 0.001
EPOCHS = 5
SEED = 42

MODEL_PATH = "python/mnist_model.pth"

torch.manual_seed(SEED)


# ============================================================
# Dataset
# ============================================================

transform = transforms.ToTensor()

train_dataset = datasets.MNIST(
    root="data",
    train=True,
    download=True,
    transform=transform
)

test_dataset = datasets.MNIST(
    root="data",
    train=False,
    download=True,
    transform=transform
)

train_loader = DataLoader(
    train_dataset,
    batch_size=BATCH_SIZE,
    shuffle=True
)

test_loader = DataLoader(
    test_dataset,
    batch_size=BATCH_SIZE,
    shuffle=False
)

print(f"Training samples: {len(train_dataset)}")
print(f"Test samples: {len(test_dataset)}")


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


model = MNISTNet()


# ============================================================
# Loss and optimizer
# ============================================================

criterion = nn.CrossEntropyLoss()

optimizer = torch.optim.Adam(
    model.parameters(),
    lr=LEARNING_RATE
)


# ============================================================
# Training
# ============================================================

def train_one_epoch(model, loader, criterion, optimizer):

    model.train()

    total_loss = 0.0
    correct = 0
    total = 0

    for images, labels in loader:

        # Clear old gradients
        optimizer.zero_grad()

        # Forward pass
        outputs = model(images)

        # Calculate loss
        loss = criterion(outputs, labels)

        # Backpropagation
        loss.backward()

        # Update weights
        optimizer.step()

        # Statistics
        total_loss += loss.item() * images.size(0)

        predictions = outputs.argmax(dim=1)

        correct += (predictions == labels).sum().item()

        total += labels.size(0)

    average_loss = total_loss / total
    accuracy = 100.0 * correct / total

    return average_loss, accuracy


# ============================================================
# Evaluation
# ============================================================

def evaluate(model, loader, criterion):

    model.eval()

    total_loss = 0.0
    correct = 0
    total = 0

    with torch.no_grad():

        for images, labels in loader:

            outputs = model(images)

            loss = criterion(outputs, labels)

            total_loss += loss.item() * images.size(0)

            predictions = outputs.argmax(dim=1)

            correct += (predictions == labels).sum().item()

            total += labels.size(0)

    average_loss = total_loss / total
    accuracy = 100.0 * correct / total

    return average_loss, accuracy


# ============================================================
# Parameter count verification
# ============================================================

total_parameters = sum(
    parameter.numel()
    for parameter in model.parameters()
)

print("\n--- Model Information ---")
print(f"Total trainable parameters: {total_parameters}")

assert total_parameters == 25450

print("Parameter count verification: PASS")


# ============================================================
# Train
# ============================================================

print("\n--- Training ---")

for epoch in range(EPOCHS):

    train_loss, train_accuracy = train_one_epoch(
        model,
        train_loader,
        criterion,
        optimizer
    )

    test_loss, test_accuracy = evaluate(
        model,
        test_loader,
        criterion
    )

    print(
        f"Epoch {epoch + 1}/{EPOCHS} | "
        f"Train Loss: {train_loss:.4f} | "
        f"Train Accuracy: {train_accuracy:.2f}% | "
        f"Test Loss: {test_loss:.4f} | "
        f"Test Accuracy: {test_accuracy:.2f}%"
    )


# ============================================================
# Final evaluation
# ============================================================

final_test_loss, final_test_accuracy = evaluate(
    model,
    test_loader,
    criterion
)

print("\n--- Final Results ---")
print(f"Final Test Loss: {final_test_loss:.4f}")
print(f"Final Test Accuracy: {final_test_accuracy:.2f}%")


# ============================================================
# Save trained model
# ============================================================

torch.save(model.state_dict(), MODEL_PATH)

print("\n--- Model Saving ---")
print(f"Model saved to: {MODEL_PATH}")


# ============================================================
# Reload model
# ============================================================

reloaded_model = MNISTNet()

reloaded_model.load_state_dict(
    torch.load(
        MODEL_PATH,
        map_location="cpu"
    )
)

reloaded_model.eval()

print("Model reloaded successfully.")


# ============================================================
# Verify original vs reloaded model
# ============================================================

test_image, test_label = test_dataset[0]

test_image_batch = test_image.unsqueeze(0)

with torch.no_grad():

    original_output = model(test_image_batch)

    reloaded_output = reloaded_model(test_image_batch)


outputs_match = torch.equal(
    original_output,
    reloaded_output
)

print(
    f"Saved/reloaded output verification: "
    f"{'PASS' if outputs_match else 'FAIL'}"
)

assert outputs_match


# ============================================================
# Golden reference
# ============================================================

print("\n--- Golden Reference ---")

with torch.no_grad():

    # Flattened input
    flattened = test_image.view(-1)

    # FC1
    fc1_output = reloaded_model.fc1(flattened)

    # ReLU
    relu_output = reloaded_model.relu(fc1_output)

    # FC2
    logits = reloaded_model.fc2(relu_output)

    # Prediction
    prediction = logits.argmax().item()


print(f"Test sample index: 0")
print(f"Actual label:      {test_label}")
print(f"Predicted label:   {prediction}")

print("\nInput shape:")
print(flattened.shape)

print("\nFC1 output shape:")
print(fc1_output.shape)

print("\nReLU output shape:")
print(relu_output.shape)

print("\nLogits shape:")
print(logits.shape)


# ============================================================
# Golden reference verification
# ============================================================

assert flattened.shape == torch.Size([784])
assert fc1_output.shape == torch.Size([32])
assert relu_output.shape == torch.Size([32])
assert logits.shape == torch.Size([10])

assert torch.all(relu_output >= 0)

assert prediction == logits.argmax().item()

print("\nGolden reference verification: PASS")


# ============================================================
# Print values needed later for hardware verification
# ============================================================

print("\n--- Golden Values ---")

print("\nFirst 20 input values:")
print(flattened[:20])

print("\nAll FC1 outputs:")
print(fc1_output)

print("\nAll ReLU outputs:")
print(relu_output)

print("\nAll final logits:")
print(logits)

print("\nFinal prediction:")
print(prediction)


print("\n========================================")
print("PHASE 1 GOLDEN MODEL VERIFICATION: PASS")
print("========================================")
