import random

# Function to generate a random 32-bit hexadecimal value
def generate_random_32bit_hex():
    return "32'h{:08X}".format(random.randint(0, 0xFFFFFFFF))

# Create a 4x32 array with random 32-bit values
q_array_32bit = [[generate_random_32bit_hex() for _ in range(32)] for _ in range(4)]

# Open the file in write mode
with open('hash_init.txt', 'w') as file:
    # Write the Verilog code to initialize the array to the file
    for i in range(4):
        for j in range(32):
            file.write(f"q_array_32bit[{i}][{j}] = {q_array_32bit[i][j]};\n")