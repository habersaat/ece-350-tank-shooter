_start:
    # Write to normal memory address 0
    addi $r1, $r0, 42           # Store value 42 in $r1
    sw $r1, 0($r0)              # Write 42 to normal memory at address 0

    # Initialize BulletRAM base address in $r2 (0x40000000 in decimal is 1073741824)
    addi $r2, $r0, 16384        # Load 16384 (0x4000) into $r2
    sll $r2, $r2, 16            # Shift left to set the high bits (1073741824)

    # Prepare bullet data in $r3
    addi $r3, $r0, 200          # Load x=200 into $r3
    sll $r3, $r3, 9             # Shift left by 9 bits for y position
    addi $r4, $r0, 200          # Load y=200 into $r4
    or $r3, $r3, $r4            # Combine x and y into $r3
    sll $r3, $r3, 5             # Shift left by 5 bits for TTL
    addi $r4, $r0, 20           # Load TTL=20 into $r4
    or $r3, $r3, $r4            # Combine TTL with x and y in $r3
    sll $r3, $r3, 3             # Shift left by 3 bits for direction
    addi $r4, $r0, 3            # Load direction=3 into $r4
    or $r3, $r3, $r4            # Combine direction with the rest into $r3
    sll $r3, $r3, 1             # Shift left by 1 bit for active bit
    addi $r4, $r0, 1            # Load active=1 into $r4
    or $r3, $r3, $r4            # Combine active bit with the rest into $r3
    sll $r3, $r3, 5             # Add 5 bits of padding

    # Write the bullet data to BulletRAM at position 0
    sw $r3, 0($r2)              # Store bullet data into BulletRAM[0]

    # Zero out temporary registers
    addi $r3, $r0, 0            # Zero out $r3
    addi $r4, $r0, 0            # Zero out $r4

    # NOP for a few cycles
    nop
    nop
    nop

    # Read from normal memory address 0
    lw $r5, 0($r0)              # Load normal memory[0] into $r5

    # Read the bullet data from BulletRAM address 0
    lw $r6, 0($r2)              # Load BulletRAM[0] into $r6

    # Verify contents
    # Check normal memory value in $r5 (should be 42)
    addi $r10, $r5, 0           # Copy normal memory value to $r10 for testing

    # Extract x_coordinate (bits 31:23) from bullet data in $r6 into $r11
    sra $r11, $r6, 23           # Shift right by 23 bits
    addi $r7, $r0, 511          # Mask for 9 bits (0b111111111)
    and $r11, $r11, $r7         # Mask x-coordinate

    # Extract y_coordinate (bits 22:14) into $r12
    sra $r12, $r6, 14           # Shift right by 14 bits
    and $r12, $r12, $r7         # Mask y-coordinate

    # Extract TTL (bits 13:9) into $r13
    sra $r13, $r6, 9            # Shift right by 9 bits
    addi $r7, $r0, 31           # Mask for 5 bits (0b11111)
    and $r13, $r13, $r7         # Mask TTL

    # Extract direction (bits 8:6) into $r14
    sra $r14, $r6, 6            # Shift right by 6 bits
    addi $r7, $r0, 7            # Mask for 3 bits (0b111)
    and $r14, $r14, $r7         # Mask direction

    # Extract active (bit 5) into $r15
    sra $r15, $r6, 5            # Shift right by 5 bits
    addi $r7, $r0, 1            # Mask for 1 bit (0b1)
    and $r15, $r15, $r7         # Mask active bit

    # Zero out temporary registers
    addi $r7, $r0, 0            # Zero out $r7
    addi $r5, $r0, 0            # Zero out $r5
    addi $r6, $r0, 0            # Zero out $r6
    addi $r2, $r0, 0
    addi $r1, $r0, 0
