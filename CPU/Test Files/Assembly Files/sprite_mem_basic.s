_start:
    #############################
    # Step 1: Write to Normal RAM
    #############################
    addi $r1, $r0, 42           # Load value 42 into $r1
    sw $r1, 0($r0)              # Write 42 to normal memory at address 0

    #############################
    # Step 2: Write to SpriteRAM
    #############################
    # Initialize SpriteRAM base address in $r2 (0x50000000)
    addi $r2, $r0, 20480        # Load 20480 (0x5000) into $r2
    sll $r2, $r2, 16            # Shift left to set high bits (0x50000000)

    # Write sprite1_x = 100
    addi $r3, $r0, 100          # Load 100 into $r3
    sw $r3, 0($r2)              # Write sprite1_x to SpriteRAM[0]

    # Write sprite1_y = 150
    addi $r3, $r0, 150          # Load 150 into $r3
    sw $r3, 4($r2)              # Write sprite1_y to SpriteRAM[1]

    # Write sprite2_x = 200
    addi $r3, $r0, 200          # Load 200 into $r3
    sw $r3, 8($r2)              # Write sprite2_x to SpriteRAM[2]

    # Write sprite2_y = 250
    addi $r3, $r0, 250          # Load 250 into $r3
    sw $r3, 12($r2)             # Write sprite2_y to SpriteRAM[3]

    #############################
    # Step 3: Verify Values
    #############################
    # Verify normal memory value
    lw $r4, 0($r0)              # Load normal memory[0] into $r4
    addi $r5, $r0, 42           # Expected value = 42
    bne $r4, $r5, _fail         # If $r4 != $r5, jump to failure

    # Verify sprite1_x
    lw $r4, 0($r2)              # Load SpriteRAM[0] (sprite1_x) into $r4
    addi $r5, $r0, 100          # Expected value = 100
    bne $r4, $r5, _fail         # If $r4 != $r5, jump to failure

    # Verify sprite1_y
    lw $r4, 4($r2)              # Load SpriteRAM[1] (sprite1_y) into $r4
    addi $r5, $r0, 150          # Expected value = 150
    bne $r4, $r5, _fail         # If $r4 != $r5, jump to failure

    # Verify sprite2_x
    lw $r4, 8($r2)              # Load SpriteRAM[2] (sprite2_x) into $r4
    addi $r5, $r0, 200          # Expected value = 200
    bne $r4, $r5, _fail         # If $r4 != $r5, jump to failure

    # Verify sprite2_y
    lw $r4, 12($r2)             # Load SpriteRAM[3] (sprite2_y) into $r4
    addi $r5, $r0, 250          # Expected value = 250
    bne $r4, $r5, _fail         # If $r4 != $r5, jump to failure

    #############################
    # Success Path
    #############################
    addi $r6, $r0, 0            # Load 0 into $r6 to indicate success
    j _end                      # Jump to end

_fail:
    #############################
    # Failure Path
    #############################
    addi $r6, $r0, 1            # Load 1 into $r6 to indicate failure
    addi $r10, $r4, 0

_end:
    #############################
    # Zero out temp registers
    #############################
    addi $r1, $r0, 0
    addi $r2, $r0, 0
    addi $r3, $r0, 0
    addi $r4, $r0, 0
    addi $r5, $r0, 0

    #############################
    # End of Program
    #############################
    nop
    nop
    nop
