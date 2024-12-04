_start:
    # Initialize BulletRAM base address in $r2 (0x40000000 in decimal is 1073741824)
    addi $r2, $r0, 16384        # Load 16384 (0x4000) into $r2
    sll $r2, $r2, 16            # Shift left to set the high bits (1073741824)

    # Prepare bullet data in $r3
    # Bullet format: {x[8:0], y[8:0], TTL[4:0], direction[2:0], active[0], padding[5]}
    # Data = {padding[5], x[8:0], y[8:0], TTL[4:0], direction[2:0], active[0]}
    addi $r3, $r0, 200          # Load x=200 (low 9 bits) into $r3
    sll $r3, $r3, 9             # Shift left by 9 bits to make space for y
    addi $r4, $r0, 200          # Load y=200 (low 9 bits) into $r4
    or $r3, $r3, $r4            # Combine x and y into $r3
    sll $r3, $r3, 5             # Shift left by 5 bits to make space for TTL
    addi $r4, $r0, 20           # Load TTL=20 into $r4
    or $r3, $r3, $r4            # Combine TTL with x and y in $r3
    sll $r3, $r3, 3             # Shift left by 3 bits to make space for direction
    addi $r4, $r0, 3            # Load direction=3 into $r4
    or $r3, $r3, $r4            # Combine direction with the rest into $r3
    sll $r3, $r3, 1             # Shift left by 1 bit to make space for active bit
    addi $r4, $r0, 1            # Load active=1 into $r4
    or $r3, $r3, $r4            # Combine active bit with the rest into $r3
    sll $r3, $r3, 5             # Add 5 bits of padding at the least significant end

    # Write the bullet to BulletRAM at position 0
    sw $r3, 0($r2)              # Store bullet data into BulletRAM[0]

    # Zero out temporary registers
    addi $r3, $r0, 0            # Zero out $r3
    addi $r4, $r0, 0            # Zero out $r4

    # NOP for a few cycles (idle)
    nop
    nop
    nop

    # Read the bullet back from BulletRAM
    lw $r5, 0($r2)              # Load bullet data from BulletRAM[0] into $r5

    # Extract x_coordinate (bits 31:23) into $r10
    sra $r10, $r5, 23           # Arithmetic shift right by 23 to align x_coordinate
    addi $r6, $r0, 511          # Load mask for 9 bits (511 = 0b111111111) into $r6
    and $r10, $r10, $r6         # Mask to keep only 9 bits

    # Extract y_coordinate (bits 22:14) into $r11
    sra $r11, $r5, 14           # Arithmetic shift right by 14 to align y_coordinate
    and $r11, $r11, $r6         # Mask to keep only 9 bits (reuse $r6)

    # Extract TTL (bits 13:9) into $r12
    sra $r12, $r5, 9            # Arithmetic shift right by 9 to align TTL
    addi $r6, $r0, 31           # Load mask for 5 bits (31 = 0b11111) into $r6
    and $r12, $r12, $r6         # Mask to keep only 5 bits

    # Extract direction (bits 8:6) into $r13
    sra $r13, $r5, 6            # Arithmetic shift right by 6 to align direction
    addi $r6, $r0, 7            # Load mask for 3 bits (7 = 0b111) into $r6
    and $r13, $r13, $r6         # Mask to keep only 3 bits

    # Extract active (bit 5) into $r14
    sra $r14, $r5, 5            # Arithmetic shift right by 5 to align active bit
    addi $r6, $r0, 1            # Load mask for 1 bit (1 = 0b1) into $r6
    and $r14, $r14, $r6         # Mask to isolate the active bit

    # Zero out remaining temporary registers
    addi $r5, $r0, 0            # Zero out $r5
    addi $r6, $r0, 0            # Zero out $r6