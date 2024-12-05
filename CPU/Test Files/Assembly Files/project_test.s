_start:
    #############################
    # Step 1: Initialize MMIO and BulletRAM Base Addresses
    #############################
    # MMIO base address in $r2 (0xFFFF0000)
    addi $r2, $r0, 65535       # Load 65535 (0xFFFF) into $r2
    sll $r2, $r2, 16           # Shift left to set high bits (0xFFFF0000)

    # BulletRAM base address in $r3 (0x40000000)
    addi $r3, $r0, 16384       # Load 16384 (0x4000) into $r3
    sll $r3, $r3, 16           # Shift left to set high bits (0x40000000)

    # MMIO offset for controller 2 signals
    addi $r4, $r0, 4           # Offset for controller 2 (CONTROLLER2_BASE_ADDR)

    # BulletRAM offset for first bullet
    addi $r5, $r0, 0           # First bullet index (0 offset)

    #############################
    # Step 2: Wait for Controller 2 Input
    #############################
check_controller2:
    # Load MMIO value into $r6
    add $r6, $r2, $r4          # $r6 = MMIO address of controller 2
    lw $r7, 0($r6)             # Load value of controller 2 signals into $r7

    # Check if controller_2_DOWN is active
    addi $r8, $r0, 15                   # $r8 = 15
    bne $r7, $r8, check_controller2     # If != 15, loop back and check again

    #############################
    # Step 3: Create Bullet in BulletRAM
    #############################
    # Set x-coordinate to 200
    addi $r10, $r0, 200        # $r10 = x-coordinate (200)

    # Set y-coordinate to 150
    addi $r11, $r0, 150        # $r11 = y-coordinate (150)

    # Set TTL to 30
    addi $r12, $r0, 30         # $r12 = TTL (30)

    # Set direction to 5
    addi $r13, $r0, 5          # $r13 = direction (5)

    # Set active to 1
    addi $r14, $r0, 1          # $r14 = active (1)

    # Pack bullet data into $r15
    sll $r15, $r10, 22         # Shift x-coordinate left by 22 bits
    sll $r16, $r11, 13         # Shift y-coordinate left by 13 bits
    or $r15, $r15, $r16        # Combine x and y
    sll $r15, $r15, 6          # Shift left by 6 bits for TTL
    or $r15, $r15, $r12        # Combine TTL
    sll $r15, $r15, 3          # Shift left by 3 bits for direction
    or $r15, $r15, $r13        # Combine direction
    sll $r15, $r15, 1          # Shift left by 1 bit for active
    or $r15, $r15, $r14        # Combine active
    sll $r15, $r15, 3          # Add 3 bits of padding

    # Store packed bullet data into BulletRAM
    add $r16, $r3, $r5         # Calculate BulletRAM[0] address
    sw $r15, 0($r16)           # Store packed bullet data at BulletRAM[0]

    #############################
    # Step 4: Halt Program
    #############################
halt:
    j halt                     # Infinite loop (halt program)
