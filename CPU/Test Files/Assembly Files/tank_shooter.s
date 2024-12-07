# tank_shooter.s

_start:
    ##########################
    # Step 1: Initialization #
    ##########################
    # Initialize Sprite Memory Base Address in $r1 (0x50000000)
    addi $r1, $r0, 20480       # Load 20480 (0x5000) into $r1
    sll $r1, $r1, 16           # Shift left to set high bits (0x50000000)

    # Initialize Bullet Memory Base Address in $r3 (0x40000000)
    addi $r3, $r0, 16384       # Load 16384 (0x4000) into $r3
    sll $r3, $r3, 16           # Shift left to set high bits (0x40000000)

    # Initialize sprite1_x = 150
    addi $r2, $r0, 150         # Load 150 into $r2
    sw $r2, 0($r1)             # Store sprite1_x at SpriteMem[0]

    # Initialize sprite1_y = 200
    addi $r2, $r0, 200         # Load 200 into $r2
    sw $r2, 4($r1)             # Store sprite1_y at SpriteMem[1]

    # Initialize sprite2_x = 350
    addi $r2, $r0, 350         # Load 350 into $r2
    sw $r2, 8($r1)             # Store sprite2_x at SpriteMem[2]

    # Initialize sprite2_y = 200
    addi $r2, $r0, 200         # Load 200 into $r2
    sw $r2, 12($r1)            # Store sprite2_y at SpriteMem[3]

    #########################
    # Step 2: Main Loop     #
    #########################
    # Initialize MMIO Base Address in $r4 (0xFFFF0000)
    addi $r4, $r0, 65535       # Load 65535 (0xFFFF) into $r4
    sll $r4, $r4, 16           # Shift left to set high bits (0xFFFF0000)

    # Initialize BulletRAM index in $r5
    addi $r5, $r0, 0           # $r5 tracks the current index in BulletRAM

loop:
    #########################
    # Movement Processing   #
    #########################

    # Check Player 1 Controller Inputs (P1_CONTROLLER1)

check_p1_controller1_up:
    # P1_CONTROLLER1_UP
    lw $r6, 12($r4)            # Load P1_CONTROLLER1_UP into $r6
    bne $r6, $r0, p1_move_up   # If P1_CONTROLLER1_UP is active, move sprite1 up

check_p1_controller1_down:
    # P1_CONTROLLER1_DOWN
    lw $r6, 0($r4)             # Load P1_CONTROLLER1_DOWN into $r6
    bne $r6, $r0, p1_move_down # If P1_CONTROLLER1_DOWN is active, move sprite1 down

check_p1_controller1_left:
    # P1_CONTROLLER1_LEFT
    lw $r6, 8($r4)             # Load P1_CONTROLLER1_LEFT into $r6
    bne $r6, $r0, p1_move_left # If P1_CONTROLLER1_LEFT is active, move sprite1 left

check_p1_controller1_right:
    # P1_CONTROLLER1_RIGHT
    lw $r6, 4($r4)             # Load P1_CONTROLLER1_RIGHT into $r6
    bne $r6, $r0, p1_move_right # If P1_CONTROLLER1_RIGHT is active, move sprite1 right

    # Check Player 2 Controller Inputs (P2_CONTROLLER1)

check_p2_controller1_up:
    # P2_CONTROLLER1_UP
    lw $r6, 44($r4)            # Load P2_CONTROLLER1_UP into $r6
    bne $r6, $r0, p2_move_up   # If P2_CONTROLLER1_UP is active, move sprite2 up

check_p2_controller1_down:
    # P2_CONTROLLER1_DOWN
    lw $r6, 32($r4)            # Load P2_CONTROLLER1_DOWN into $r6
    bne $r6, $r0, p2_move_down # If P2_CONTROLLER1_DOWN is active, move sprite2 down

check_p2_controller1_left:
    # P2_CONTROLLER1_LEFT
    lw $r6, 40($r4)            # Load P2_CONTROLLER1_LEFT into $r6
    bne $r6, $r0, p2_move_left # If P2_CONTROLLER1_LEFT is active, move sprite2 left

check_p2_controller1_right:
    # P2_CONTROLLER1_RIGHT
    lw $r6, 36($r4)            # Load P2_CONTROLLER1_RIGHT into $r6
    bne $r6, $r0, p2_move_right # If P2_CONTROLLER1_RIGHT is active, move sprite2 right

process_shooting:

    #########################
    # Shooting Processing   #
    #########################

check_p1_shooting:
    # Player 1 Shooting (P1_CONTROLLER2)
    lw $r6, 16($r4)            # Load P1_CONTROLLER2_DOWN into $r6
    bne $r6, $r0, p1_shoot     # If active, branch to Player 1 shooting
    lw $r6, 20($r4)            # Load P1_CONTROLLER2_LEFT into $r6
    bne $r6, $r0, p1_shoot     # If active, branch to Player 1 shooting
    lw $r6, 24($r4)            # Load P1_CONTROLLER2_RIGHT into $r6
    bne $r6, $r0, p1_shoot     # If active, branch to Player 1 shooting
    lw $r6, 28($r4)            # Load P1_CONTROLLER2_UP into $r6
    bne $r6, $r0, p1_shoot     # If active, branch to Player 1 shooting

check_p2_shooting:
    # Player 2 Shooting (P2_CONTROLLER2)
    lw $r6, 48($r4)            # Load P2_CONTROLLER2_DOWN into $r6
    bne $r6, $r0, p2_shoot     # If active, branch to Player 2 shooting
    lw $r6, 52($r4)            # Load P2_CONTROLLER2_LEFT into $r6
    bne $r6, $r0, p2_shoot     # If active, branch to Player 2 shooting
    lw $r6, 56($r4)            # Load P2_CONTROLLER2_RIGHT into $r6
    bne $r6, $r0, p2_shoot     # If active, branch to Player 2 shooting
    lw $r6, 60($r4)            # Load P2_CONTROLLER2_UP into $r6
    bne $r6, $r0, p2_shoot     # If active, branch to Player 2 shooting

temp_label:
    # Sleep to slow down execution
    j sleep                    # Jump to sleep before looping back

    #############################
    # Player 1 Movement Handlers
    #############################
p1_move_up:
    lw $r6, 4($r1)             # Load sprite1_y into $r6
    addi $r6, $r6, -1          # Decrement y-coordinate
    addi $r7, $r0, 6           # Lowest possible y-coordinate is 6
    blt $r6, $r7, fix_p1_move_up_bounds
    sw $r6, 4($r1)             # Store updated y back to SpriteMem[1]
    j check_p1_controller1_down

fix_p1_move_up_bounds:
    addi $r6, $r7, 0              
    sw $r6, 4($r1)             # Store updated y back to SpriteMem[1]
    j check_p1_controller1_down

p1_move_down:
    lw $r6, 4($r1)             # Load sprite1_y into $r6
    addi $r6, $r6, 1           # Increment y-coordinate
    addi $r7, $r0, 415         # Highest possible y-coordinate is 415
    blt $r7, $r6, fix_p1_move_down_bounds
    sw $r6, 4($r1)             # Store updated y back to SpriteMem[1]
    j check_p1_controller1_left

fix_p1_move_down_bounds:
    addi $r6, $r7, 0
    sw $r6, 4($r1)             # Store updated y back to SpriteMem[1]
    j check_p1_controller1_left

p1_move_left:
    lw $r6, 0($r1)             # Load sprite1_x into $r6
    addi $r6, $r6, -1          # Decrement x-coordinate by 1
    addi $r7, $r0, 1           # Lowest possible x-coordinate is 1
    blt $r6, $r7, fix_p1_move_left_bounds
    sw $r6, 0($r1)             # Store updated x back to SpriteMem[0]
    j check_p1_controller1_right

fix_p1_move_left_bounds:
    addi $r6, $r7, 0
    sw $r6, 0($r1)             # Store updated x back to SpriteMem[0]
    j check_p1_controller1_right

p1_move_right:
    lw $r6, 0($r1)             # Load sprite1_x into $r6
    addi $r6, $r6, 1           # Increment x-coordinate by 1
    addi $r7, $r0, 575
    blt $r7, $r6, fix_p1_move_right_bounds
    sw $r6, 0($r1)             # Store updated x back to SpriteMem[0]
    j check_p2_controller1_up

fix_p1_move_right_bounds:
    addi $r6, $r7, 0
    sw $r6, 0($r1)             # Store updated x back to SpriteMem[0]
    j check_p2_controller1_up

    #############################
    # Player 2 Movement Handlers
    #############################
p2_move_up:
    lw $r6, 12($r1)            # Load sprite2_y into $r6
    addi $r6, $r6, -1          # Decrement y-coordinate by 1
    addi $r7, $r0, 6           # Lowest possible y-coordinate is 6
    blt $r6, $r7, fix_p2_move_up_bounds
    sw $r6, 12($r1)            # Store updated y back to SpriteMem[3]
    j check_p2_controller1_down

fix_p2_move_up_bounds:
    addi $r6, $r7, 0  
    sw $r6, 12($r1)            # Store updated y back to SpriteMem[3]
    j check_p2_controller1_down

p2_move_down:
    lw $r6, 12($r1)            # Load sprite2_y into $r6
    addi $r6, $r6, 1           # Increment y-coordinate by 1
    addi $r7, $r0, 415         # Highest possible y-coordinate is 415
    blt $r7, $r6, fix_p2_move_down_bounds
    sw $r6, 12($r1)            # Store updated y back to SpriteMem[3]
    j check_p2_controller1_left

fix_p2_move_down_bounds:
    addi $r6, $r7, 0
    sw $r6, 12($r1)            # Store updated y back to SpriteMem[3]
    j check_p2_controller1_left

p2_move_left:
    lw $r6, 8($r1)             # Load sprite2_x into $r6
    addi $r6, $r6, -1          # Decrement x-coordinate by 1
    addi $r7, $r0, 1           # Lowest possible x-coordinate is 1
    blt $r6, $r7, fix_p2_move_left_bounds
    sw $r6, 8($r1)             # Store updated x back to SpriteMem[2]
    j check_p2_controller1_right

fix_p2_move_left_bounds:
    addi $r6, $r7, 0
    sw $r6, 8($r1)             # Store updated x back to SpriteMem[2]
    j check_p2_controller1_right

p2_move_right:
    lw $r6, 8($r1)             # Load sprite2_x into $r6
    addi $r6, $r6, 1           # Increment x-coordinate by 1
    addi $r7, $r0, 575
    blt $r7, $r6, fix_p2_move_right_bounds
    sw $r6, 8($r1)             # Store updated x back to SpriteMem[2]
    j process_shooting

fix_p2_move_right_bounds:
    addi $r6, $r7, 0
    sw $r6, 8($r1)             # Store updated x back to SpriteMem[2]
    j process_shooting

    #############################
    # Player 1 Shooting Handler
    #############################
p1_shoot:
    # Load sprite1_x and sprite1_y into $r9 and $r10
    lw $r9, 0($r1)             # sprite1_x
    lw $r10, 4($r1)            # sprite1_y

    # Set TTL = 64
    addi $r11, $r0, 64         # $r11 = TTL

    # Initialize direction to 0
    addi $r12, $r0, 0       # $r12 holds the direction (4 bits)

    #############################
    # Check Controller Inputs
    #############################

    # Check DOWN (1st bit)
    lw $r6, 0($r4)          # Load P1_CONTROLLER2_DOWN into $r6
    bne $r6, $r0, p1_set_down_bit
    j p1_check_right_bit        # Skip if not DOWN
p1_set_down_bit:
    addi $r12, $r12, 1       # Set 1st bit (binary: 0001)

    # Check RIGHT (2nd bit)
p1_check_right_bit:
    lw $r6, 4($r4)          # Load P1_CONTROLLER2_RIGHT into $r6
    bne $r6, $r0, p1_set_right_bit
    j p1_check_left_bit         # Skip if not RIGHT
p1_set_right_bit:
    addi $r12, $r12, 2       # Set 2nd bit (binary: 0010)

    # Check LEFT (3rd bit)
p1_check_left_bit:
    lw $r6, 8($r4)          # Load P1_CONTROLLER2_LEFT into $r6
    bne $r6, $r0, p1_set_left_bit
    j p1_check_up_bit           # Skip if not LEFT
p1_set_left_bit:
    addi $r12, $r12, 4       # Set 3rd bit (binary: 0100)

    # Check UP (4th bit)
p1_check_up_bit:
    lw $r6, 12($r4)         # Load P1_CONTROLLER2_UP into $r6
    bne $r6, $r0, p1_set_up_bit
    j p1_finalize_direction     # Skip if not UP
p1_set_up_bit:
    addi $r12, $r12, 8       # Set 4th bit (binary: 1000)

    #############################
    # Finalize Direction
    #############################

p1_finalize_direction:
    # $r12 now contains the direction with the 4 bits set as:
    # 0001 = DOWN
    # 0010 = RIGHT
    # 0100 = LEFT
    # 1000 = UP
    # 1100 = UP + LEFT
    # 1010 = UP + RIGHT
    # 0101 = DOWN + LEFT
    # 0011 = DOWN + RIGHT

    # Set active bit
    addi $r13, $r0, 1          # $r13 = active

    # Pack bullet data into $r14
    sll $r14, $r9, 9           # Shift x-coordinate left by 9 bits
    or $r14, $r14, $r10        # Combine x and y
    sll $r14, $r14, 6          # Shift left by 6 bits for TTL
    or $r14, $r14, $r11        # Combine TTL
    sll $r14, $r14, 4          # Shift left by 4 bits for direction
    or $r14, $r14, $r12        # Combine direction
    sll $r14, $r14, 1          # Shift left by 1 bit for active
    or $r14, $r14, $r13        # Combine active
    sll $r14, $r14, 2          # Add 2 bits of padding at the least significant end

    # Store packed bullet data into BulletRAM
    add $r15, $r3, $r5         # Calculate address for BulletRAM[$r5]
    sw $r14, 0($r15)           # Store bullet at BulletRAM[$r5]

    # Increment bullet index
    addi $r5, $r5, 1           # Move to the next bullet index

    j check_p2_shooting        # Move to p2 shooting

    #############################
    # Player 2 Shooting Handler
    #############################
p2_shoot:
    # Load sprite2_x and sprite2_y into $r9 and $r10
    lw $r9, 8($r1)             # sprite2_x
    lw $r10, 12($r1)           # sprite2_y

    # Set TTL = 64
    addi $r11, $r0, 64         # $r11 = TTL

    # Set direction (Assume direction is always up for simplicity)
    addi $r12, $r0, 0          # $r12 = direction (000 = up)

    # Set active bit
    addi $r13, $r0, 1          # $r13 = active

    # Pack bullet data into $r14
    sll $r14, $r9, 9           # Shift x-coordinate left by 9 bits
    or $r14, $r14, $r10        # Combine x and y
    sll $r14, $r14, 6          # Shift left by 6 bits for TTL
    or $r14, $r14, $r11        # Combine TTL
    sll $r14, $r14, 4          # Shift left by 4 bits for direction
    or $r14, $r14, $r12        # Combine direction
    sll $r14, $r14, 1          # Shift left by 1 bit for active
    or $r14, $r14, $r13        # Combine active
    sll $r14, $r14, 2          # Add 2 bits of padding at the least significant end

    # Store packed bullet data into BulletRAM
    add $r15, $r3, $r5         # Calculate address for BulletRAM[$r5]
    sw $r14, 0($r15)           # Store bullet at BulletRAM[$r5]

    # Increment bullet index
    addi $r5, $r5, 1           # Move to the next bullet index

    j temp_label               # Move to next label


    #############################
    # Sleep Section
    #############################
sleep:
    addi $r6, $r0, 0           # Initialize counter in $r6
    addi $r7, $r0, 32768       # Load dely value into $r7

sleep_loop:
    addi $r6, $r6, 1           # Increment counter
    bne $r6, $r7, sleep_loop   # Loop until counter reaches delay
    j loop                     # Return to main loop
