_start:
    # Initialize MMIO base address in $r2 (0xFFFF0000)
    addi $r2, $r0, 65535       # Load 65535 (0xFFFF) into $r2
    sll $r2, $r2, 16           # Shift left to set high bits (0xFFFF0000)

    # Initialize BulletRAM base address in $r3 (0x40000000)
    addi $r3, $r0, 16384       # Load 16384 (0x4000) into $r3
    sll $r3, $r3, 16           # Shift left to set high bits (0x40000000)

    # Load MMIO offset for controller 2 down signal into $r4
    addi $r4, $r0, 4           # Offset for JD[4] (controller 2 down signal)

    # Load BulletRAM offset for first bullet into $r5
    addi $r5, $r0, 0           # First bullet index (0 offset)

    # Main loop to check for down signal
check_down:
    # Load MMIO value into $r6
    add $r6, $r2, $r4          # $r6 = MMIO address of JD[4]
    lw $r7, 0($r6)             # Load value of JD[4] into $r7

    # Check if JD[4] (controller 1 down signal) is active (value 1)
    addi $r8, $r0, 1           # $r8 = 1
    bne $r7, $r8, check_down   # If JD[4] != 1, loop back and check again

    # Create bullet in BulletRAM
    # Set x-coordinate to 200
    addi $r9, $r0, 200         # $r9 = x-coordinate (200)

    # Set y-coordinate to 200
    addi $r10, $r0, 200        # $r10 = y-coordinate (200)

    # Set TTL to 20
    addi $r11, $r0, 20         # $r11 = TTL (20)

    # Set direction to 3
    addi $r12, $r0, 3          # $r12 = direction (3)

    # Set active to 1
    addi $r13, $r0, 1          # $r13 = active (1)

   # Pack bullet data into $r14
    sll $r14, $r9, 9           # Shift x-coordinate left by 9 bits
    or $r14, $r14, $r10        # Combine x and y
    sll $r14, $r14, 5          # Shift left by 5 bits for TTL
    or $r14, $r14, $r11        # Combine TTL
    sll $r14, $r14, 3          # Shift left by 3 bits for direction
    or $r14, $r14, $r12        # Combine direction
    sll $r14, $r14, 1          # Shift left by 1 bit for active
    or $r14, $r14, $r13        # Combine active
    sll $r14, $r14, 5          # Add 5 bits of padding at the least significant end

    # Store packed bullet data into BulletRAM
    add $r15, $r3, $r5         # Calculate BulletRAM[0] address
    sw $r14, 0($r15)           # Store packed bullet data at BulletRAM[0]

    # Infinite loop (halt program)
halt:
    j halt