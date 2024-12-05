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
    sll $r3, $r3, 6             # Shift left by 6 bits for TTL
    addi $r4, $r0, 20           # Load TTL=20 into $r4
    or $r3, $r3, $r4            # Combine TTL with x and y in $r3
    sll $r3, $r3, 3             # Shift left by 3 bits for direction
    addi $r4, $r0, 3            # Load direction=3 into $r4
    or $r3, $r3, $r4            # Combine direction with the rest into $r3
    sll $r3, $r3, 1             # Shift left by 1 bit for active bit
    addi $r4, $r0, 1            # Load active=1 into $r4
    or $r3, $r3, $r4            # Combine active bit with the rest into $r3
    sll $r3, $r3, 3             # Add 3 bits of padding

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

    # Extract x_coordinate (bits 31:22) from bullet data in $r6 into $r11
    sra $r11, $r6, 22           # Shift right by 22 bits
    addi $r7, $r0, 1023         # Mask for 10 bits (0b1111111111)
    and $r11, $r11, $r7         # Mask x-coordinate

    # Extract y_coordinate (bits 21:13) into $r12
    sra $r12, $r6, 13           # Shift right by 13 bits
    addi $r7, $r0, 511          # Mask for 9 bits (0b111111111)
    and $r12, $r12, $r7         # Mask y-coordinate

    # Extract TTL (bits 12:7) into $r13
    sra $r13, $r6, 7            # Shift right by 7 bits
    addi $r7, $r0, 63           # Mask for 6 bits (0b111111)
    and $r13, $r13, $r7         # Mask TTL

    # Extract direction (bits 6:4) into $r14
    sra $r14, $r6, 4            # Shift right by 4 bits
    addi $r7, $r0, 7            # Mask for 3 bits (0b111)
    and $r14, $r14, $r7         # Mask direction

    # Extract active (bit 3) into $r15
    sra $r15, $r6, 3            # Shift right by 3 bits
    addi $r7, $r0, 1            # Mask for 1 bit (0b1)
    and $r15, $r15, $r7         # Mask active bit

    # Zero out temporary registers
    addi $r7, $r0, 0            # Zero out $r7
    addi $r5, $r0, 0            # Zero out $r5
    addi $r6, $r0, 0            # Zero out $r6
    addi $r2, $r0, 0
    addi $r1, $r0, 0
