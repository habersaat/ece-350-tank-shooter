_start:
    # Initialize BulletRAM base address in $r2 (0x40000000 in decimal is 1073741824)
    addi $r2, $r0, 16384        # Load 16384 (0x4000) into $r2
    sll $r2, $r2, 16            # Shift left to set the high bits (1073741824)

    # Initialize aggregation registers
    addi $r10, $r0, 0           # $r10 = 0 (aggregated x-coordinates)
    addi $r11, $r0, 0           # $r11 = 0 (aggregated y-coordinates)
    addi $r12, $r0, 0           # $r12 = 0 (aggregated active count)

    # Write 64 bullets to BulletRAM
    addi $r3, $r0, 1            # Initialize x and y to 1 in $r3
    addi $r6, $r0, 1            # Active bit = 1
    addi $r7, $r0, 0            # Initialize BulletRAM index in $r7 (0-based index)
    addi $r8, $r0, 64           # Number of bullets (loop limit)

write_bullets:
    # Pack bullet data into $r4
    sll $r4, $r3, 9             # Shift x left by 9 bits
    or $r4, $r4, $r3            # Combine x and y
    sll $r4, $r4, 5             # Shift left by 5 bits for TTL
    addi $r9, $r0, 20           # TTL = 20
    or $r4, $r4, $r9            # Combine TTL
    sll $r4, $r4, 3             # Shift left by 3 bits for direction
    addi $r9, $r0, 3            # Direction = 3
    or $r4, $r4, $r9            # Combine direction
    sll $r4, $r4, 1             # Shift left by 1 bit for active
    or $r4, $r4, $r6            # Combine active
    sll $r4, $r4, 5             # Add 5 bits of padding

    # Write the packed bullet data to BulletRAM
    sw $r4, 0($r2)              # Store to BulletRAM[$r7]
    addi $r2, $r2, 4            # Increment address to the next BulletRAM entry

    # Increment x, y, and index
    addi $r3, $r3, 1            # Increment x and y by 1
    addi $r7, $r7, 1            # Increment index
    bne $r7, $r8, write_bullets # Repeat until $r7 == $r8

    # Reset BulletRAM base address in $r2
    addi $r2, $r0, 16384        # Reload 16384 (0x4000) into $r2
    sll $r2, $r2, 16            # Shift left to set the high bits (1073741824)

    # Read 64 bullets and aggregate their values
    addi $r7, $r0, 0            # Reset BulletRAM index in $r7 (0-based index)

read_bullets:
    # Read bullet data from BulletRAM
    lw $r4, 0($r2)              # Load from BulletRAM[$r7]
    addi $r2, $r2, 4            # Increment address to the next BulletRAM entry

    # Extract x-coordinate (bits 31:23) and aggregate into $r10
    sra $r5, $r4, 23            # Align x-coordinate to the least significant bits
    addi $r6, $r0, 511          # Mask for 9 bits (511 = 0b111111111)
    and $r5, $r5, $r6           # Isolate x-coordinate
    add $r10, $r10, $r5         # Aggregate x-coordinate into $r10

    # Extract y-coordinate (bits 22:14) and aggregate into $r11
    sra $r5, $r4, 14            # Align y-coordinate to the least significant bits
    and $r5, $r5, $r6           # Isolate y-coordinate
    add $r11, $r11, $r5         # Aggregate y-coordinate into $r11

    # Extract active (bit 5) and aggregate into $r12
    sra $r5, $r4, 5             # Align active bit to the least significant bit
    addi $r6, $r0, 1            # Mask for 1 bit (1 = 0b1)
    and $r5, $r5, $r6           # Isolate active bit
    add $r12, $r12, $r5         # Aggregate active count into $r12

    # Increment index
    addi $r7, $r7, 1            # Increment index
    bne $r7, $r8, read_bullets  # Repeat until $r7 == $r8

    # Zero out temporary registers
    addi $r2, $r0, 0            # Zero out $r2
    addi $r3, $r0, 0            # Zero out $r3
    addi $r4, $r0, 0            # Zero out $r4
    addi $r5, $r0, 0            # Zero out $r5
    addi $r6, $r0, 0            # Zero out $r6
    addi $r7, $r0, 0            # Zero out $r7
    addi $r8, $r0, 0            # Zero out $r8
    addi $r9, $r0, 0            # Zero out $r9
