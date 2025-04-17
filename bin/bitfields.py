#!/usr/bin/env python3

import sys

assert len(sys.argv) == 2
try:
    n = int(sys.argv[1])
except ValueError:
    print("Invalid integer")
    exit()

binary_str = bin(n)[2:]
print(binary_str)
#  print("\nBits (LSB first):")
for i, bit in enumerate(reversed(binary_str)):
    print(f"Bit #{i}: {bit}")
