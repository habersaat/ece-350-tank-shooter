_start:
    #############################
    # Step 1: Write to Normal RAM
    #############################
    addi $r1, $r0, 42           # Load value 42 into $r1
    sw $r1, 0($r0)              # Write 42 to normal memory at address 0

    #############################
    # Step 2: Write to BulletRAM
    #############################
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
    sw $r3, 0($r2)              # Write bullet data into BulletRAM[0]

    # Zero out temporary registers
    addi $r1, $r0, 0            # Zero out $r1
    addi $r3, $r0, 0            # Zero out $r3
    addi $r4, $r0, 0            # Zero out $r4

    #############################
    # Step 3: Read from MMIO
    #############################
    # Initialize MMIO base address for controller 1 (0xFFFF0000) in $r5
    addi $r5, $r0, -65536       # Load -65536 (0xFFFF0000) into $r5
    lw $r6, 0($r5)              # Read MMIO controller 1 state into $r6

    #############################
    # Step 4: Verify Values
    #############################
    # Check normal memory value
    lw $r7, 0($r0)              # Load normal memory[0] into $r7

    # Check BulletRAM value
    lw $r8, 0($r2)              # Load BulletRAM[0] into $r8

    #############################
    # Validation Logic
    #############################
    # Check if MMIO value is 0 (expected default)
    addi $r9, $r0, 0            # Load expected MMIO default value (0) into $r9
    bne $r6, $r9, _mmio_fail    # Branch to _mmio_fail if MMIO value is NOT 0

    # If MMIO is correct, load success indicator
    addi $r10, $r0, 0           # Load success (0) into $r10
    j _end                      # Skip failure

_mmio_fail:
    addi $r10, $r0, 1           # Load failure (1) into $r10

_end:
    # End of program
    nop
    nop
    nop
