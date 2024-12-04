_start:
    # Initialize MMIO base address in $r1 (0xFFFF0000)
    addi $r1, $r0, 0xFFFF    # Load 0xFFFF into $r1
    sll $r1, $r1, 16         # Shift left to set the high bits (0xFFFF0000)

    # Initialize BulletRAM base address in $r2 (0x40000000)
    addi $r2, $r0, 0x4000    # Load 0x4000 into $r2
    sll $r2, $r2, 16         # Shift left to set the high bits (0x40000000)

    # Prepare bullet data in $r3
    # Bullet format: x=200 (9 bits), y=200 (9 bits), TTL=20 (5 bits), direction=0 (3 bits), active=1 (1 bit)
    # Data = {x[8:0], y[8:0], TTL[4:0], direction[2:0], active[0]}
    addi $r3, $r0, 200       # Load x=200 (low 9 bits) into $r3
    sll $r3, $r3, 9          # Shift left by 9 bits to make space for y
    addi $r4, $r0, 200       # Load y=200 (low 9 bits) into $r4
    or $r3, $r3, $r4         # Combine x and y into $r3
    sll $r3, $r3, 5          # Shift left by 5 bits to make space for TTL
    addi $r4, $r0, 20        # Load TTL=20 into $r4
    or $r3, $r3, $r4         # Combine TTL with x and y in $r3
    sll $r3, $r3, 3          # Shift left by 3 bits to make space for direction
    addi $r4, $r0, 1         # Load active=1 into $r4
    or $r3, $r3, $r4         # Combine active bit with the rest into $r3

poll_input:
    lw $r4, 0($r1)           # Load controller input from MMIO
    and $r5, $r4, $r4        # Mask all bits (self AND)
    sra $r5, $r5, 4          # Shift DOWN button (bit 4) to LSB (arithmetic shift works since input is positive)
    and $r5, $r5, 1          # Mask the LSB to isolate the DOWN state
    beq $r5, $r0, poll_input # If DOWN not pressed, keep polling

    # DOWN is pressed; write bullet data
    sw $r3, 0($r2)           # Write bullet data to the first entry of BulletRAM

halt:
    j halt                   # Infinite loop (halt simulation)