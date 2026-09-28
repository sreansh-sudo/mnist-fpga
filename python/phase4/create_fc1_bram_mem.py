from pathlib import Path

DATA_DIR = Path("data")

DEPTH = 3136
BANKS = 8

bank_files = [
    DATA_DIR / f"fc1_bank{i}.mem"
    for i in range(BANKS)
]

banks = []

for filename in bank_files:
    with open(filename, "r") as f:
        values = [line.strip() for line in f if line.strip()]

    if len(values) != DEPTH:
        raise ValueError(
            f"{filename}: expected {DEPTH} values, "
            f"found {len(values)}"
        )

    banks.append(values)


output_file = DATA_DIR / "fc1_bram.mem"

with open(output_file, "w") as f:

    for addr in range(DEPTH):

        # Bank 7 becomes the most-significant byte.
        # Bank 0 becomes the least-significant byte.
        packed = ""

        for bank in range(BANKS - 1, -1, -1):
            packed += banks[bank][addr]

        f.write(packed + "\n")


print("FC1 BRAM memory generated successfully")
print(f"Output : {output_file}")
print(f"Depth  : {DEPTH}")
print(f"Width  : {BANKS * 8} bits")
print("Entries:", DEPTH)
