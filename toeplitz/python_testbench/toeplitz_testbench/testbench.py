from pathlib import Path

BS = 64
N = 256
L = 128


# ------------------------------------------------------------
# Helpers
# ------------------------------------------------------------

def read_hex_words(filename, bits=64):
    """
    Read Verilog-style $readmemh file.

    Each line contains one hexadecimal word.
    Returns list of integers.
    """
    out = []
    with open(filename, "r") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            out.append(int(line, 16))
    return out



def concat_words(words, word_bits=64):
    """
    Concatenate words exactly like Verilog:

        { w0, w1, w2, ... }

    where w0 becomes the most-significant chunk.
    """
    value = 0
    for w in words:
        value = (value << word_bits) | w
    return value



def int_to_bits(x, width):
    """
    Convert integer -> bit list (LSB-first).
    """
    return [(x >> i) & 1 for i in range(width)]



def bits_to_int(bits):
    """
    Convert LSB-first bit list -> integer.
    """
    out = 0
    for i, b in enumerate(bits):
        out |= (b & 1) << i
    return out


# ------------------------------------------------------------
# Read Toeplitz seed files
# ------------------------------------------------------------

r_words = read_hex_words("/home/szymon/Desktop/magister/toeplitz/python_testbench/toeplitz_testbench/r64-hex.dat")
c_words = read_hex_words("/home/szymon/Desktop/magister/toeplitz/python_testbench/toeplitz_testbench/c64-hex.dat")

# Verilog:
# row0 <= { r[0], r[1], r[2], r[3] } << 1;
# col0 <= { c[0], c[1] };

row0 = concat_words(r_words) << 1
col0 = concat_words(c_words)

# Keep widths bounded
row0 &= (1 << N) - 1
col0 &= (1 << L) - 1


# ------------------------------------------------------------
# Reverse row bits
# ------------------------------------------------------------
# Verilog:
# rrow0[i] = row0[N-1-i]
# ------------------------------------------------------------

rrow0_bits = []
for i in range(N):
    bit = (row0 >> (N - 1 - i)) & 1
    rrow0_bits.append(bit)

rrow0 = bits_to_int(rrow0_bits)


# ------------------------------------------------------------
# Generate full Toeplitz matrix
# ------------------------------------------------------------


def generate_columns(rrow0, col0, N=256, L=128):
    """
    Reproduce gencol.v behavior.

    Returns list of columns.
    Each column is represented as L-bit integer.
    """

    cols = []

    col = col0
    rrow = rrow0

    for _ in range(N):
        cols.append(col)

        # Verilog:
        # col <= { rrow[0], col[L-1:1] }

        topbit = rrow & 1
        col = ((col >> 1) | (topbit << (L - 1))) & ((1 << L) - 1)

        # Verilog:
        # rrow <= {1'b0, rrow[N-1:1]}

        rrow >>= 1

    return cols


columns = generate_columns(rrow0, col0, N, L)


# ------------------------------------------------------------
# Build explicit Toeplitz matrix
# ------------------------------------------------------------

T = [[0 for _ in range(N)] for _ in range(L)]

for j in range(N):
    col = columns[j]
    for i in range(L):
        T[i][j] = (col >> i) & 1


# ------------------------------------------------------------
# Toeplitz extraction
# ------------------------------------------------------------


def toeplitz_extract(input_bits, columns, N=256, L=128):
    """
    Reproduce toeplitz.v logic.

    input_bits:
        iterable of 256 bits

    returns:
        128-bit output vector (LSB-first)
    """

    y = [0] * L

    for j in range(N):
        x = input_bits[j]
        col = columns[j]

        for i in range(L):
            colbit = (col >> i) & 1
            y[i] ^= (x & colbit)

    return y


# ------------------------------------------------------------
# Example usage
# ------------------------------------------------------------

# Example 256-bit input
hex_str = "0xA5A5A5A5B1B2B3B4C1C2C3C4D1D2D3D4E1E2E3E4F1F2F3F40102030405060708"
expected = "0x6743ABD32AF0540CCEAF400958CD8550"

# Consume input
byte_data = bytes.fromhex(hex_str[2:])

x = []
for byte in byte_data:
    for i in range(7, -1, -1):
        x.append((byte >> i) & 1)

# Calc output
q = toeplitz_extract(x, columns)


# Output formating
x_int = bits_to_int(list(reversed(x)))
q_int = bits_to_int(q)
print()
print("Input as hex:")
print(f"0x{x_int:0{N//4}X}")

print()
print("Output as hex:")
print(f"0x{q_int:0{L//4}X}")


# ------------------------------------------------------------
# Compare
# ------------------------------------------------------------
q_hex = f"0x{q_int:0{L//4}X}"

if q_hex.upper() == expected.upper():
    print()
    print("PASS: Output matches expected value")
else:
    print()
    print("FAIL: Output does NOT match expected value")