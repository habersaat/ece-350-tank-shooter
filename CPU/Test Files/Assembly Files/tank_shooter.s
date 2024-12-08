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

    # Initialize Health Memory Base Address in $r30 (0x60000000)
    addi $r30, $r0, 24576       # Load 24576 (0x6000) into $r30
    sll $r30, $r30, 16           # Shift left to set high bits (0x60000000)

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

    # Initialize player health in HealthRAM
    addi $r2, $r0, 100         # Load 100 (initial health value) into $r2
    sw $r2, 0($r30)             # Store Player 1 health at HealthRAM[0]
    sw $r2, 4($r30)             # Store Player 2 health at HealthRAM[1]

    #########################
    # Step 2: Main Loop     #
    #########################
    # Initialize MMIO Base Address in $r4 (0xFFFF0000)
    addi $r4, $r0, 65535       # Load 65535 (0xFFFF) into $r4
    sll $r4, $r4, 16           # Shift left to set high bits (0xFFFF0000)

    # Initialize BulletRAM index in $r5
    addi $r5, $r0, 0           # $r5 tracks the current index in BulletRAM

    j initialize_arena_ram

loop:
    ########################
    #  Update Cooldowns    #
    ########################

update_cooldowns:
    # Decrement Player 1 Cooldown
    addi $r18, $r0, 2001      # Load address of Player 1 cooldown
    lw $r20, 0($r18)          # Load Player 1 cooldown into $r20
    bne $r20, $r0, p1_decrement_cooldown # If cooldown > 0, decrement
    j update_p2_cooldown      # Skip to Player 2 if cooldown is 0

p1_decrement_cooldown:
    addi $r20, $r20, -1       # Decrement Player 1 cooldown
    sw $r20, 0($r18)          # Store updated cooldown back to RAM

update_p2_cooldown:
    # Decrement Player 2 Cooldown
    addi $r18, $r0, 2002      # Load address of Player 2 cooldown
    lw $r20, 0($r18)          # Load Player 2 cooldown into $r20
    bne $r20, $r0, p2_decrement_cooldown # If cooldown > 0, decrement
    j check_p1_controller1_up # Skip to next processing step

p2_decrement_cooldown:
    addi $r20, $r20, -1       # Decrement Player 2 cooldown
    sw $r20, 0($r18)          # Store updated cooldown back to RAM
    j check_p1_controller1_up




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

    # Check Player 1 health
    lw $r19, 0($r30)           # Load Player 1 health into $r19
    addi $r20, $r0, 1          # Set $r20 to 1
    blt $r19, $r20, check_p2_shooting # Branch if $r19 < 1 (health <= 0)

    # Check Player 1 cooldown
    addi $r19, $r0, 2001             # Load address of Player 1 cooldown
    lw $r20, 0($r19)                 # Load Player 1 cooldown into $r20
    bne $r20, $r0, check_p2_shooting # Skip if cooldown > 0

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

    # Check Player 2 health
    lw $r19, 4($r30)           # Load Player 2 health into $r19
    addi $r20, $r0, 1          # Set $r20 to 1
    blt $r19, $r20, bullet_state_updates # Skip to bullet processing if $r19 < 1 (health <= 0)


    # Check Player 2 cooldown
    addi $r19, $r0, 2002                # Load address of Player 2 cooldown
    lw $r20, 0($r19)                    # Load Player 2 cooldown into $r20
    bne $r20, $r0, bullet_state_updates # Skip if cooldown > 0

    lw $r6, 48($r4)            # Load P2_CONTROLLER2_DOWN into $r6
    bne $r6, $r0, p2_shoot     # If active, branch to Player 2 shooting
    lw $r6, 52($r4)            # Load P2_CONTROLLER2_LEFT into $r6
    bne $r6, $r0, p2_shoot     # If active, branch to Player 2 shooting
    lw $r6, 56($r4)            # Load P2_CONTROLLER2_RIGHT into $r6
    bne $r6, $r0, p2_shoot     # If active, branch to Player 2 shooting
    lw $r6, 60($r4)            # Load P2_CONTROLLER2_UP into $r6
    bne $r6, $r0, p2_shoot     # If active, branch to Player 2 shooting

    #########################
    # Bullet State Processing
    #########################

bullet_state_updates:
    j process_bullets

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
    # Reset Player 1 Cooldown
    addi $r19, $r0, 2001       # Address for Player 1 cooldown
    addi $r20, $r0, 100        # Set cooldown to 100 frames
    sw $r20, 0($r19)           # Store cooldown back to RAM

    # Load sprite1_x and sprite1_y into $r9 and $r10. 
    # This (x,y) is not final. Will change based on direction
    lw $r9, 0($r1)             # sprite1_x
    lw $r10, 4($r1)            # sprite1_y

    # Set TTL = 63
    addi $r11, $r0, 63         # $r11 = TTL

    # Initialize direction to 0
    addi $r12, $r0, 0       # $r12 holds the direction (4 bits)

    #############################
    # Check Controller Inputs
    #############################

    # Check DOWN (1st bit)
    lw $r6, 16($r4)          # Load P1_CONTROLLER2_DOWN into $r6
    bne $r6, $r0, p1_set_down_bit
    j p1_check_right_bit        # Skip if not DOWN
p1_set_down_bit:
    addi $r12, $r12, 1       # Set 1st bit (binary: 0001)

    # Check RIGHT (2nd bit)
p1_check_right_bit:
    lw $r6, 20($r4)          # Load P1_CONTROLLER2_RIGHT into $r6
    bne $r6, $r0, p1_set_right_bit
    j p1_check_left_bit         # Skip if not RIGHT
p1_set_right_bit:
    addi $r12, $r12, 2       # Set 2nd bit (binary: 0010)

    # Check LEFT (3rd bit)
p1_check_left_bit:
    lw $r6, 24($r4)          # Load P1_CONTROLLER2_LEFT into $r6
    bne $r6, $r0, p1_set_left_bit
    j p1_check_up_bit           # Skip if not LEFT
p1_set_left_bit:
    addi $r12, $r12, 4       # Set 3rd bit (binary: 0100)

    # Check UP (4th bit)
p1_check_up_bit:
    lw $r6, 28($r4)         # Load P1_CONTROLLER2_UP into $r6
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

    #####################################
    # Finalize (x,y) based on direction #
    #####################################

    # If direction is DOWN + RIGHT, (x+66, y+66)
    addi $r6, $r0, 3
    bne $r12, $r6, p1_skip_down_right_adjustment
    addi $r9, $r9, 66           # Increment x by 66
    addi $r10, $r10, 66         # Increment y by 66
    j p1_direction_finalized

p1_skip_down_right_adjustment:
    # If direction is DOWN + LEFT, (x-14, y+66)
    addi $r6, $r0, 5
    bne $r12, $r6, p1_skip_down_left_adjustment
    addi $r9, $r9, -14          # Decrement x by 14
    addi $r10, $r10, 66         # Increment y by 66
    j p1_direction_finalized

p1_skip_down_left_adjustment:
    # If direction is UP + RIGHT (x+66, y-14)
    addi $r6, $r0, 10
    bne $r12, $r6, p1_skip_up_right_adjustment
    addi $r9, $r9, 66           # Increment x by 66
    addi $r10, $r10, -14        # Decrement y by 14
    j p1_direction_finalized

p1_skip_up_right_adjustment:
    # If direction is UP + LEFT (x-14, y-14)
    addi $r6, $r0, 12
    bne $r12, $r6, p1_skip_up_left_adjustment
    addi $r9, $r9, -14          # Decrement x by 14
    addi $r10, $r10, -14        # Decrement y by 14
    j p1_direction_finalized

p1_skip_up_left_adjustment:
    # If direction is DOWN (x+26, y+66)
    addi $r6, $r0, 1
    bne $r12, $r6, p1_skip_down_adjustment
    addi $r9, $r9, 26           # Increment x by 26
    addi $r10, $r10, 66         # Increment y by 66
    j p1_direction_finalized

p1_skip_down_adjustment:
    # If direction is UP (x+26, y-14)
    addi $r6, $r0, 8
    bne $r12, $r6, p1_skip_up_adjustment
    addi $r9, $r9, 26           # Increment x by 26
    addi $r10, $r10, -14        # Decrement y by 14
    j p1_direction_finalized

p1_skip_up_adjustment:
    # If direction is RIGHT (x+66, y+26)
    addi $r6, $r0, 2
    bne $r12, $r6, p1_skip_right_adjustment
    addi $r9, $r9, 66           # Increment x by 66
    addi $r10, $r10, 26         # Increment y by 26
    j p1_direction_finalized

p1_skip_right_adjustment:
    # If direction is LEFT (x-14, y+26)
    addi $r6, $r0, 4
    bne $r12, $r6, p1_direction_finalized
    addi $r9, $r9, -14          # Decrement x by 14
    addi $r10, $r10, 26         # Increment y by 26
    j p1_direction_finalized


p1_direction_finalized:
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

    # Check if $r5 >= 64
    addi $r6, $r0, 64          # Load 64 into $r6
    blt $r5, $r6,  skip_reset     # If $r5 < 64, skip reset
    addi $r5, $r0, 0           # Reset $r5 to 0 if it reaches 64

skip_reset:
    j check_p2_shooting        # Move to p2 shooting

    #############################
    # Player 2 Shooting Handler
    #############################
p2_shoot:
    # Reset Player 2 Cooldown
    addi $r19, $r0, 2002       # Address for Player 2 cooldown
    addi $r20, $r0, 100        # Set cooldown to 100 frames
    sw $r20, 0($r19)           # Store cooldown back to RAM

    # Load sprite2_x and sprite2_y into $r9 and $r10
    lw $r9, 8($r1)             # sprite2_x
    lw $r10, 12($r1)           # sprite2_y

    # Set TTL = 63
    addi $r11, $r0, 63         # $r11 = TTL

    # Initialize direction to 0
    addi $r12, $r0, 0       # $r12 holds the direction (4 bits)

    #############################
    # Check Controller Inputs
    #############################

    # Check DOWN (1st bit)
    lw $r6, 48($r4)          # Load P2_CONTROLLER2_DOWN into $r6
    bne $r6, $r0, p2_set_down_bit
    j p2_check_right_bit        # Skip if not DOWN
p2_set_down_bit:
    addi $r12, $r12, 1       # Set 1st bit (binary: 0001)

    # Check RIGHT (2nd bit)
p2_check_right_bit:
    lw $r6, 52($r4)          # Load P2_CONTROLLER2_RIGHT into $r6
    bne $r6, $r0, p2_set_right_bit
    j p2_check_left_bit         # Skip if not RIGHT
p2_set_right_bit:
    addi $r12, $r12, 2       # Set 2nd bit (binary: 0010)

    # Check LEFT (3rd bit)
p2_check_left_bit:
    lw $r6, 56($r4)          # Load P2_CONTROLLER2_LEFT into $r6
    bne $r6, $r0, p2_set_left_bit
    j p2_check_up_bit           # Skip if not LEFT
p2_set_left_bit:
    addi $r12, $r12, 4       # Set 3rd bit (binary: 0100)

    # Check UP (4th bit)
p2_check_up_bit:
    lw $r6, 60($r4)         # Load P2_CONTROLLER2_UP into $r6
    bne $r6, $r0, p2_set_up_bit
    j p2_finalize_direction     # Skip if not UP
p2_set_up_bit:
    addi $r12, $r12, 8       # Set 4th bit (binary: 1000)

    #############################
    # Finalize Direction
    #############################

p2_finalize_direction:
    # $r12 now contains the direction with the 4 bits set as:
    # 0001 = DOWN
    # 0010 = RIGHT
    # 0100 = LEFT
    # 1000 = UP
    # 1100 = UP + LEFT
    # 1010 = UP + RIGHT
    # 0101 = DOWN + LEFT
    # 0011 = DOWN + RIGHT

    #####################################
    # Finalize (x,y) based on direction #
    #####################################

    # If direction is DOWN + RIGHT, (x+66, y+66)
    addi $r6, $r0, 3
    bne $r12, $r6, p2_skip_down_right_adjustment
    addi $r9, $r9, 66           # Increment x by 66
    addi $r10, $r10, 66         # Increment y by 66
    j p2_direction_finalized

p2_skip_down_right_adjustment:
    # If direction is DOWN + LEFT, (x-14, y+66)
    addi $r6, $r0, 5
    bne $r12, $r6, p2_skip_down_left_adjustment
    addi $r9, $r9, -14          # Decrement x by 14
    addi $r10, $r10, 66         # Increment y by 66
    j p2_direction_finalized

p2_skip_down_left_adjustment:
    # If direction is UP + RIGHT (x+66, y-14)
    addi $r6, $r0, 10
    bne $r12, $r6, p2_skip_up_right_adjustment
    addi $r9, $r9, 66           # Increment x by 66
    addi $r10, $r10, -14        # Decrement y by 14
    j p2_direction_finalized

p2_skip_up_right_adjustment:
    # If direction is UP + LEFT (x-14, y-14)
    addi $r6, $r0, 12
    bne $r12, $r6, p2_skip_up_left_adjustment
    addi $r9, $r9, -14          # Decrement x by 14
    addi $r10, $r10, -14        # Decrement y by 14
    j p2_direction_finalized

p2_skip_up_left_adjustment:
    # If direction is DOWN (x+26, y+66)
    addi $r6, $r0, 1
    bne $r12, $r6, p2_skip_down_adjustment
    addi $r9, $r9, 26           # Increment x by 26
    addi $r10, $r10, 66         # Increment y by 66
    j p2_direction_finalized

p2_skip_down_adjustment:
    # If direction is UP (x+26, y-14)
    addi $r6, $r0, 8
    bne $r12, $r6, p2_skip_up_adjustment
    addi $r9, $r9, 26           # Increment x by 26
    addi $r10, $r10, -14        # Decrement y by 14
    j p2_direction_finalized

p2_skip_up_adjustment:
    # If direction is RIGHT (x+66, y+26)
    addi $r6, $r0, 2
    bne $r12, $r6, p2_skip_right_adjustment
    addi $r9, $r9, 66           # Increment x by 66
    addi $r10, $r10, 26         # Increment y by 26
    j p2_direction_finalized

p2_skip_right_adjustment:
    # If direction is LEFT (x-14, y+26)
    addi $r6, $r0, 4
    bne $r12, $r6, p2_direction_finalized
    addi $r9, $r9, -14          # Decrement x by 14
    addi $r10, $r10, 26         # Increment y by 26
    j p2_direction_finalized

p2_direction_finalized:
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

    j bullet_state_updates     # Move to next label

process_bullets:
    addi $r6, $r0, 0           # Initialize bullet index in $r6

bullet_loop:
    # Calculate current bullet address
    add $r7, $r3, $r6          # $r7 = BulletRAM[$r6]

    # Load bullet data
    lw $r8, 0($r7)             # Load bullet data into $r8

    # Check if bullet is active
    sra $r9, $r8, 2            # Shift right to isolate the active bit (3rd LSB)
    addi $r16, $r0, 1
    and $r9, $r9, $16          # Isolate the active bit
    bne $r9, $r0, process_active_bullet # Process if active
    j next_bullet              # Skip processing if inactive

process_active_bullet:
    # Extract x-coordinate (10 bits)
    sra $r10, $r8, 22          # Shift right to isolate x-coordinate
    addi $r16, $r0, 1023
    and $r10, $r10, $r16       # Mask x-coordinate (10 bits)

    # Extract y-coordinate (9 bits)
    sra $r11, $r8, 13          # Shift right to isolate y-coordinate
    addi $r16, $r0, 511
    and $r11, $r11, $r16       # Mask y-coordinate (9 bits)

    # Extract TTL (6 bits)
    sra $r12, $r8, 7           # Shift right to isolate TTL
    addi $r16, $r0, 63
    and $r12, $r12, $r16       # Mask TTL (6 bits)

    # Extract direction (4 bits)
    sra $r13, $r8, 3           # Shift right to isolate direction
    addi $r16, $r0, 15
    and $r13, $r13, $16        # Mask direction (4 bits)

    # Load the counter from memory address 800 (this is for TTL decrement logic)
    addi $r15, $r0, 800       # Address for counter
    lw $r16, 0($r15)          # Load counter into $r16

    # Check if the counter is 8
    addi $r17, $r0, 8        # Load 8 into $r17
    bne $r16, $r17, skip_ttl_update # If counter != 8, skip TTL update

    # Decrement TTL
    addi $r12, $r12, -1       # Decrement TTL
    blt $r0, $r12, skip_deactivate_bullet # If TTL < 0, deactivate bullet
    addi $r9, $r0, 0          # deactive bullet

skip_deactivate_bullet:
    # Reset counter to 0 after TTL update
    addi $r16, $r0, 0         # Reset counter
    sw $r16, 0($r15)          # Store updated counter back to memory
    j update_coordinates      # Skip to coordinate update

skip_ttl_update:
    # Increment counter if TTL is not updated
    addi $r16, $r16, 1        # Increment counter
    sw $r16, 0($r15)          # Store updated counter back to memory

update_coordinates:

    ##########################
    # Update Coordinates Based on Direction
    ##########################

    # Update x-coordinate
    addi $r16, $r0, 2
    and $r14, $r13, $r16       # Check RIGHT bit (2nd bit)
    bne $r14, $r0, bullet_move_right

    addi $r16, $r0, 4
    and $r14, $r13, $r16        # Check LEFT bit (3rd bit)
    bne $r14, $r0, bullet_move_left
    j bullet_update_y                 # Skip to y-coordinate update

bullet_move_right:
    addi $r10, $r10, 1         # Increment x-coordinate
    j bullet_update_y

bullet_move_left:
    addi $r10, $r10, -1        # Decrement x-coordinate

bullet_update_y:
    # Update y-coordinate
    addi $r16, $r0, 1
    and $r14, $r13, $r16       # Check DOWN bit (1st bit)
    bne $r14, $r0, bullet_move_down

    addi $r16, $r0, 8
    and $r14, $r13, $r16        # Check UP bit (4th bit)
    bne $r14, $r0, bullet_move_up
    j bullet_collsion_check              # Skip to collision check

bullet_move_down:
    addi $r11, $r11, 1         # Increment y-coordinate
    j bullet_collsion_check

bullet_move_up:
    addi $r11, $r11, -1        # Decrement y-coordinate

bullet_collsion_check:
    # Check collision with Player 1
    lw $r17, 0($r1)            # Load Player 1 x-coordinate
    addi $r18, $r17, 64        # Calculate Player 1 x+64
    blt $r10, $r17, check_p2_collision # If bullet x < sprite1_x, skip to Player 2 check
    blt $r18, $r10, check_p2_collision # If bullet x > sprite1_x+64, skip to Player 2 check

    lw $r17, 4($r1)            # Load Player 1 y-coordinate
    addi $r18, $r17, 64        # Calculate Player 1 y+64
    blt $r11, $r17, check_p2_collision # If bullet y < sprite1_y, skip to Player 2 check
    blt $r18, $r11, check_p2_collision # If bullet y > sprite1_y+64, skip to Player 2 check

    j handle_p1_collision      # If all conditions pass, handle Player 1 collision

# Handle collision with Player 1
handle_p1_collision:
    # Deactivate bullet
    addi $r9, $r0, 0           # Set active bit to 0

    # Decrement Player 1 health
    lw $r17, 0($r30)            # Load Player 1 health
    addi $r29, $r0, 1           # Load in 1 to r29
    blt $r17, $r29, pack_bullet # If player health is already 0, don't decrement
    addi $r17, $r17, -5         # Decrement health by 5
    sw $r17, 0($r30)            # Store updated health back in HealthRAM
    j pack_bullet               # Skip further checks and pack bullet

# Check collision with Player 2
check_p2_collision:
    lw $r17, 8($r1)            # Load Player 2 x-coordinate
    addi $r18, $r17, 64        # Calculate Player 2 x+64
    blt $r10, $r17, skip_collision_checks # If bullet x < sprite2_x, skip collision checks
    blt $r18, $r10, skip_collision_checks # If bullet x > sprite2_x+64, skip collision checks

    lw $r17, 12($r1)           # Load Player 2 y-coordinate
    addi $r18, $r17, 64        # Calculate Player 2 y+64
    blt $r11, $r17, skip_collision_checks # If bullet y < sprite2_y, skip collision checks
    blt $r18, $r11, skip_collision_checks # If bullet y > sprite2_y+64, skip collision checks

    j handle_p2_collision      # If all conditions pass, handle Player 2 collision

# Handle collision with Player 2
handle_p2_collision:
    # Deactivate bullet
    addi $r9, $r0, 0           # Set active bit to 0

    # Decrement Player 2 health
    lw $r17, 4($r30)           # Load Player 2 health
    addi $r29, $r0, 1           # Load in 1 to r29
    blt $r17, $r29, pack_bullet # If player health is already 0, don't decrement
    addi $r17, $r17, -5        # Decrement health by 5
    sw $r17, 4($r30)           # Store updated health back in HealthRAM
    j pack_bullet              # Skip further checks and pack bullet

# Skip collision checks if no match
skip_collision_checks:

pack_bullet:
    ##########################
    # Repack Bullet Data
    ##########################
    sll $r8, $r10, 9           # Shift x-coordinate 9 bits for y-coordinate
    or $r8, $r8, $r11          # Combine with y-coordinate
    sll $r8, $r8, 6            # Shift left 6 bits for TTL
    or $r8, $r8, $r12          # Combine with TTL
    sll $r8, $r8, 4            # Shift left for direction
    or $r8, $r8, $r13          # Combine with direction
    sll $r8, $r8, 1            # Shift left for active bit
    or $r8, $r8, $r9           # Combine active bit
    sll $r8, $r8, 2            # Add 2 bits of padding at the least significant end

    # Store updated bullet data
    sw $r8, 0($r7)
    j next_bullet


next_bullet:
    addi $r6, $r6, 1           # Increment bullet index
    addi $r14, $r0, 64         # Max number of bullets
    blt $r6, $r14, bullet_loop # Loop until all bullets processed

    # Return to main loop
    j temp_label




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


    ############################
    # Initialize Arena RAM     #
    ############################

initialize_arena_ram:
    # Initialize Arena RAM Base Address in $r28 (0x7000_0000)
    addi $r28, $r0, 28672         # Load upper part of base address (28672)
    sll $r28, $r28, 16            # Shift left by 16 bits to construct full address
    
    addi $r10, $r0, 318
    sll $r10, $r10, 9
    addi $r11, $r0, 28
    or $r10, $r10, $r11
    sw $r10, 0($r28)
    addi $r10, $r0, 321
    sll $r10, $r10, 9
    addi $r11, $r0, 28
    or $r10, $r10, $r11
    sw $r10, 1($r28)
    addi $r10, $r0, 316
    sll $r10, $r10, 9
    addi $r11, $r0, 29
    or $r10, $r10, $r11
    sw $r10, 2($r28)
    addi $r10, $r0, 323
    sll $r10, $r10, 9
    addi $r11, $r0, 29
    or $r10, $r10, $r11
    sw $r10, 3($r28)
    addi $r10, $r0, 315
    sll $r10, $r10, 9
    addi $r11, $r0, 30
    or $r10, $r10, $r11
    sw $r10, 4($r28)
    addi $r10, $r0, 324
    sll $r10, $r10, 9
    addi $r11, $r0, 30
    or $r10, $r10, $r11
    sw $r10, 5($r28)
    addi $r10, $r0, 313
    sll $r10, $r10, 9
    addi $r11, $r0, 31
    or $r10, $r10, $r11
    sw $r10, 6($r28)
    addi $r10, $r0, 314
    sll $r10, $r10, 9
    addi $r11, $r0, 31
    or $r10, $r10, $r11
    sw $r10, 7($r28)
    addi $r10, $r0, 325
    sll $r10, $r10, 9
    addi $r11, $r0, 31
    or $r10, $r10, $r11
    sw $r10, 8($r28)
    addi $r10, $r0, 326
    sll $r10, $r10, 9
    addi $r11, $r0, 31
    or $r10, $r10, $r11
    sw $r10, 9($r28)
    addi $r10, $r0, 312
    sll $r10, $r10, 9
    addi $r11, $r0, 32
    or $r10, $r10, $r11
    sw $r10, 10($r28)
    addi $r10, $r0, 327
    sll $r10, $r10, 9
    addi $r11, $r0, 32
    or $r10, $r10, $r11
    sw $r10, 11($r28)
    addi $r10, $r0, 311
    sll $r10, $r10, 9
    addi $r11, $r0, 33
    or $r10, $r10, $r11
    sw $r10, 12($r28)
    addi $r10, $r0, 328
    sll $r10, $r10, 9
    addi $r11, $r0, 33
    or $r10, $r10, $r11
    sw $r10, 13($r28)
    addi $r10, $r0, 309
    sll $r10, $r10, 9
    addi $r11, $r0, 34
    or $r10, $r10, $r11
    sw $r10, 14($r28)
    addi $r10, $r0, 329
    sll $r10, $r10, 9
    addi $r11, $r0, 34
    or $r10, $r10, $r11
    sw $r10, 15($r28)
    addi $r10, $r0, 330
    sll $r10, $r10, 9
    addi $r11, $r0, 34
    or $r10, $r10, $r11
    sw $r10, 16($r28)
    addi $r10, $r0, 308
    sll $r10, $r10, 9
    addi $r11, $r0, 35
    or $r10, $r10, $r11
    sw $r10, 17($r28)
    addi $r10, $r0, 331
    sll $r10, $r10, 9
    addi $r11, $r0, 35
    or $r10, $r10, $r11
    sw $r10, 18($r28)
    addi $r10, $r0, 307
    sll $r10, $r10, 9
    addi $r11, $r0, 36
    or $r10, $r10, $r11
    sw $r10, 19($r28)
    addi $r10, $r0, 332
    sll $r10, $r10, 9
    addi $r11, $r0, 36
    or $r10, $r10, $r11
    sw $r10, 20($r28)
    addi $r10, $r0, 305
    sll $r10, $r10, 9
    addi $r11, $r0, 37
    or $r10, $r10, $r11
    sw $r10, 21($r28)
    addi $r10, $r0, 334
    sll $r10, $r10, 9
    addi $r11, $r0, 37
    or $r10, $r10, $r11
    sw $r10, 22($r28)
    addi $r10, $r0, 304
    sll $r10, $r10, 9
    addi $r11, $r0, 38
    or $r10, $r10, $r11
    sw $r10, 23($r28)
    addi $r10, $r0, 335
    sll $r10, $r10, 9
    addi $r11, $r0, 38
    or $r10, $r10, $r11
    sw $r10, 24($r28)
    addi $r10, $r0, 303
    sll $r10, $r10, 9
    addi $r11, $r0, 39
    or $r10, $r10, $r11
    sw $r10, 25($r28)
    addi $r10, $r0, 336
    sll $r10, $r10, 9
    addi $r11, $r0, 39
    or $r10, $r10, $r11
    sw $r10, 26($r28)
    addi $r10, $r0, 301
    sll $r10, $r10, 9
    addi $r11, $r0, 40
    or $r10, $r10, $r11
    sw $r10, 27($r28)
    addi $r10, $r0, 338
    sll $r10, $r10, 9
    addi $r11, $r0, 40
    or $r10, $r10, $r11
    sw $r10, 28($r28)
    addi $r10, $r0, 300
    sll $r10, $r10, 9
    addi $r11, $r0, 41
    or $r10, $r10, $r11
    sw $r10, 29($r28)
    addi $r10, $r0, 339
    sll $r10, $r10, 9
    addi $r11, $r0, 41
    or $r10, $r10, $r11
    sw $r10, 30($r28)
    addi $r10, $r0, 298
    sll $r10, $r10, 9
    addi $r11, $r0, 42
    or $r10, $r10, $r11
    sw $r10, 31($r28)
    addi $r10, $r0, 340
    sll $r10, $r10, 9
    addi $r11, $r0, 42
    or $r10, $r10, $r11
    sw $r10, 32($r28)
    addi $r10, $r0, 341
    sll $r10, $r10, 9
    addi $r11, $r0, 42
    or $r10, $r10, $r11
    sw $r10, 33($r28)
    addi $r10, $r0, 297
    sll $r10, $r10, 9
    addi $r11, $r0, 43
    or $r10, $r10, $r11
    sw $r10, 34($r28)
    addi $r10, $r0, 342
    sll $r10, $r10, 9
    addi $r11, $r0, 43
    or $r10, $r10, $r11
    sw $r10, 35($r28)
    addi $r10, $r0, 295
    sll $r10, $r10, 9
    addi $r11, $r0, 44
    or $r10, $r10, $r11
    sw $r10, 36($r28)
    addi $r10, $r0, 296
    sll $r10, $r10, 9
    addi $r11, $r0, 44
    or $r10, $r10, $r11
    sw $r10, 37($r28)
    addi $r10, $r0, 343
    sll $r10, $r10, 9
    addi $r11, $r0, 44
    or $r10, $r10, $r11
    sw $r10, 38($r28)
    addi $r10, $r0, 294
    sll $r10, $r10, 9
    addi $r11, $r0, 45
    or $r10, $r10, $r11
    sw $r10, 39($r28)
    addi $r10, $r0, 345
    sll $r10, $r10, 9
    addi $r11, $r0, 45
    or $r10, $r10, $r11
    sw $r10, 40($r28)
    addi $r10, $r0, 293
    sll $r10, $r10, 9
    addi $r11, $r0, 46
    or $r10, $r10, $r11
    sw $r10, 41($r28)
    addi $r10, $r0, 346
    sll $r10, $r10, 9
    addi $r11, $r0, 46
    or $r10, $r10, $r11
    sw $r10, 42($r28)
    addi $r10, $r0, 291
    sll $r10, $r10, 9
    addi $r11, $r0, 47
    or $r10, $r10, $r11
    sw $r10, 43($r28)
    addi $r10, $r0, 292
    sll $r10, $r10, 9
    addi $r11, $r0, 47
    or $r10, $r10, $r11
    sw $r10, 44($r28)
    addi $r10, $r0, 347
    sll $r10, $r10, 9
    addi $r11, $r0, 47
    or $r10, $r10, $r11
    sw $r10, 45($r28)
    addi $r10, $r0, 290
    sll $r10, $r10, 9
    addi $r11, $r0, 48
    or $r10, $r10, $r11
    sw $r10, 46($r28)
    addi $r10, $r0, 349
    sll $r10, $r10, 9
    addi $r11, $r0, 48
    or $r10, $r10, $r11
    sw $r10, 47($r28)
    addi $r10, $r0, 289
    sll $r10, $r10, 9
    addi $r11, $r0, 49
    or $r10, $r10, $r11
    sw $r10, 48($r28)
    addi $r10, $r0, 350
    sll $r10, $r10, 9
    addi $r11, $r0, 49
    or $r10, $r10, $r11
    sw $r10, 49($r28)
    addi $r10, $r0, 287
    sll $r10, $r10, 9
    addi $r11, $r0, 50
    or $r10, $r10, $r11
    sw $r10, 50($r28)
    addi $r10, $r0, 351
    sll $r10, $r10, 9
    addi $r11, $r0, 50
    or $r10, $r10, $r11
    sw $r10, 51($r28)
    addi $r10, $r0, 352
    sll $r10, $r10, 9
    addi $r11, $r0, 50
    or $r10, $r10, $r11
    sw $r10, 52($r28)
    addi $r10, $r0, 286
    sll $r10, $r10, 9
    addi $r11, $r0, 51
    or $r10, $r10, $r11
    sw $r10, 53($r28)
    addi $r10, $r0, 353
    sll $r10, $r10, 9
    addi $r11, $r0, 51
    or $r10, $r10, $r11
    sw $r10, 54($r28)
    addi $r10, $r0, 284
    sll $r10, $r10, 9
    addi $r11, $r0, 52
    or $r10, $r10, $r11
    sw $r10, 55($r28)
    addi $r10, $r0, 285
    sll $r10, $r10, 9
    addi $r11, $r0, 52
    or $r10, $r10, $r11
    sw $r10, 56($r28)
    addi $r10, $r0, 354
    sll $r10, $r10, 9
    addi $r11, $r0, 52
    or $r10, $r10, $r11
    sw $r10, 57($r28)
    addi $r10, $r0, 283
    sll $r10, $r10, 9
    addi $r11, $r0, 53
    or $r10, $r10, $r11
    sw $r10, 58($r28)
    addi $r10, $r0, 355
    sll $r10, $r10, 9
    addi $r11, $r0, 53
    or $r10, $r10, $r11
    sw $r10, 59($r28)
    addi $r10, $r0, 356
    sll $r10, $r10, 9
    addi $r11, $r0, 53
    or $r10, $r10, $r11
    sw $r10, 60($r28)
    addi $r10, $r0, 282
    sll $r10, $r10, 9
    addi $r11, $r0, 54
    or $r10, $r10, $r11
    sw $r10, 61($r28)
    addi $r10, $r0, 357
    sll $r10, $r10, 9
    addi $r11, $r0, 54
    or $r10, $r10, $r11
    sw $r10, 62($r28)
    addi $r10, $r0, 280
    sll $r10, $r10, 9
    addi $r11, $r0, 55
    or $r10, $r10, $r11
    sw $r10, 63($r28)
    addi $r10, $r0, 358
    sll $r10, $r10, 9
    addi $r11, $r0, 55
    or $r10, $r10, $r11
    sw $r10, 64($r28)
    addi $r10, $r0, 279
    sll $r10, $r10, 9
    addi $r11, $r0, 56
    or $r10, $r10, $r11
    sw $r10, 65($r28)
    addi $r10, $r0, 360
    sll $r10, $r10, 9
    addi $r11, $r0, 56
    or $r10, $r10, $r11
    sw $r10, 66($r28)
    addi $r10, $r0, 278
    sll $r10, $r10, 9
    addi $r11, $r0, 57
    or $r10, $r10, $r11
    sw $r10, 67($r28)
    addi $r10, $r0, 361
    sll $r10, $r10, 9
    addi $r11, $r0, 57
    or $r10, $r10, $r11
    sw $r10, 68($r28)
    addi $r10, $r0, 276
    sll $r10, $r10, 9
    addi $r11, $r0, 58
    or $r10, $r10, $r11
    sw $r10, 69($r28)
    addi $r10, $r0, 362
    sll $r10, $r10, 9
    addi $r11, $r0, 58
    or $r10, $r10, $r11
    sw $r10, 70($r28)
    addi $r10, $r0, 275
    sll $r10, $r10, 9
    addi $r11, $r0, 59
    or $r10, $r10, $r11
    sw $r10, 71($r28)
    addi $r10, $r0, 364
    sll $r10, $r10, 9
    addi $r11, $r0, 59
    or $r10, $r10, $r11
    sw $r10, 72($r28)
    addi $r10, $r0, 274
    sll $r10, $r10, 9
    addi $r11, $r0, 60
    or $r10, $r10, $r11
    sw $r10, 73($r28)
    addi $r10, $r0, 365
    sll $r10, $r10, 9
    addi $r11, $r0, 60
    or $r10, $r10, $r11
    sw $r10, 74($r28)
    addi $r10, $r0, 272
    sll $r10, $r10, 9
    addi $r11, $r0, 61
    or $r10, $r10, $r11
    sw $r10, 75($r28)
    addi $r10, $r0, 366
    sll $r10, $r10, 9
    addi $r11, $r0, 61
    or $r10, $r10, $r11
    sw $r10, 76($r28)
    addi $r10, $r0, 367
    sll $r10, $r10, 9
    addi $r11, $r0, 61
    or $r10, $r10, $r11
    sw $r10, 77($r28)
    addi $r10, $r0, 271
    sll $r10, $r10, 9
    addi $r11, $r0, 62
    or $r10, $r10, $r11
    sw $r10, 78($r28)
    addi $r10, $r0, 368
    sll $r10, $r10, 9
    addi $r11, $r0, 62
    or $r10, $r10, $r11
    sw $r10, 79($r28)
    addi $r10, $r0, 269
    sll $r10, $r10, 9
    addi $r11, $r0, 63
    or $r10, $r10, $r11
    sw $r10, 80($r28)
    addi $r10, $r0, 270
    sll $r10, $r10, 9
    addi $r11, $r0, 63
    or $r10, $r10, $r11
    sw $r10, 81($r28)
    addi $r10, $r0, 369
    sll $r10, $r10, 9
    addi $r11, $r0, 63
    or $r10, $r10, $r11
    sw $r10, 82($r28)
    addi $r10, $r0, 268
    sll $r10, $r10, 9
    addi $r11, $r0, 64
    or $r10, $r10, $r11
    sw $r10, 83($r28)
    addi $r10, $r0, 370
    sll $r10, $r10, 9
    addi $r11, $r0, 64
    or $r10, $r10, $r11
    sw $r10, 84($r28)
    addi $r10, $r0, 371
    sll $r10, $r10, 9
    addi $r11, $r0, 64
    or $r10, $r10, $r11
    sw $r10, 85($r28)
    addi $r10, $r0, 267
    sll $r10, $r10, 9
    addi $r11, $r0, 65
    or $r10, $r10, $r11
    sw $r10, 86($r28)
    addi $r10, $r0, 372
    sll $r10, $r10, 9
    addi $r11, $r0, 65
    or $r10, $r10, $r11
    sw $r10, 87($r28)
    addi $r10, $r0, 265
    sll $r10, $r10, 9
    addi $r11, $r0, 66
    or $r10, $r10, $r11
    sw $r10, 88($r28)
    addi $r10, $r0, 373
    sll $r10, $r10, 9
    addi $r11, $r0, 66
    or $r10, $r10, $r11
    sw $r10, 89($r28)
    addi $r10, $r0, 264
    sll $r10, $r10, 9
    addi $r11, $r0, 67
    or $r10, $r10, $r11
    sw $r10, 90($r28)
    addi $r10, $r0, 375
    sll $r10, $r10, 9
    addi $r11, $r0, 67
    or $r10, $r10, $r11
    sw $r10, 91($r28)
    addi $r10, $r0, 263
    sll $r10, $r10, 9
    addi $r11, $r0, 68
    or $r10, $r10, $r11
    sw $r10, 92($r28)
    addi $r10, $r0, 376
    sll $r10, $r10, 9
    addi $r11, $r0, 68
    or $r10, $r10, $r11
    sw $r10, 93($r28)
    addi $r10, $r0, 261
    sll $r10, $r10, 9
    addi $r11, $r0, 69
    or $r10, $r10, $r11
    sw $r10, 94($r28)
    addi $r10, $r0, 377
    sll $r10, $r10, 9
    addi $r11, $r0, 69
    or $r10, $r10, $r11
    sw $r10, 95($r28)
    addi $r10, $r0, 378
    sll $r10, $r10, 9
    addi $r11, $r0, 69
    or $r10, $r10, $r11
    sw $r10, 96($r28)
    addi $r10, $r0, 260
    sll $r10, $r10, 9
    addi $r11, $r0, 70
    or $r10, $r10, $r11
    sw $r10, 97($r28)
    addi $r10, $r0, 379
    sll $r10, $r10, 9
    addi $r11, $r0, 70
    or $r10, $r10, $r11
    sw $r10, 98($r28)
    addi $r10, $r0, 258
    sll $r10, $r10, 9
    addi $r11, $r0, 71
    or $r10, $r10, $r11
    sw $r10, 99($r28)
    addi $r10, $r0, 259
    sll $r10, $r10, 9
    addi $r11, $r0, 71
    or $r10, $r10, $r11
    sw $r10, 100($r28)
    addi $r10, $r0, 380
    sll $r10, $r10, 9
    addi $r11, $r0, 71
    or $r10, $r10, $r11
    sw $r10, 101($r28)
    addi $r10, $r0, 257
    sll $r10, $r10, 9
    addi $r11, $r0, 72
    or $r10, $r10, $r11
    sw $r10, 102($r28)
    addi $r10, $r0, 381
    sll $r10, $r10, 9
    addi $r11, $r0, 72
    or $r10, $r10, $r11
    sw $r10, 103($r28)
    addi $r10, $r0, 382
    sll $r10, $r10, 9
    addi $r11, $r0, 72
    or $r10, $r10, $r11
    sw $r10, 104($r28)
    addi $r10, $r0, 256
    sll $r10, $r10, 9
    addi $r11, $r0, 73
    or $r10, $r10, $r11
    sw $r10, 105($r28)
    addi $r10, $r0, 383
    sll $r10, $r10, 9
    addi $r11, $r0, 73
    or $r10, $r10, $r11
    sw $r10, 106($r28)
    addi $r10, $r0, 254
    sll $r10, $r10, 9
    addi $r11, $r0, 74
    or $r10, $r10, $r11
    sw $r10, 107($r28)
    addi $r10, $r0, 384
    sll $r10, $r10, 9
    addi $r11, $r0, 74
    or $r10, $r10, $r11
    sw $r10, 108($r28)
    addi $r10, $r0, 253
    sll $r10, $r10, 9
    addi $r11, $r0, 75
    or $r10, $r10, $r11
    sw $r10, 109($r28)
    addi $r10, $r0, 386
    sll $r10, $r10, 9
    addi $r11, $r0, 75
    or $r10, $r10, $r11
    sw $r10, 110($r28)
    addi $r10, $r0, 251
    sll $r10, $r10, 9
    addi $r11, $r0, 76
    or $r10, $r10, $r11
    sw $r10, 111($r28)
    addi $r10, $r0, 252
    sll $r10, $r10, 9
    addi $r11, $r0, 76
    or $r10, $r10, $r11
    sw $r10, 112($r28)
    addi $r10, $r0, 387
    sll $r10, $r10, 9
    addi $r11, $r0, 76
    or $r10, $r10, $r11
    sw $r10, 113($r28)
    addi $r10, $r0, 250
    sll $r10, $r10, 9
    addi $r11, $r0, 77
    or $r10, $r10, $r11
    sw $r10, 114($r28)
    addi $r10, $r0, 388
    sll $r10, $r10, 9
    addi $r11, $r0, 77
    or $r10, $r10, $r11
    sw $r10, 115($r28)
    addi $r10, $r0, 249
    sll $r10, $r10, 9
    addi $r11, $r0, 78
    or $r10, $r10, $r11
    sw $r10, 116($r28)
    addi $r10, $r0, 390
    sll $r10, $r10, 9
    addi $r11, $r0, 78
    or $r10, $r10, $r11
    sw $r10, 117($r28)
    addi $r10, $r0, 247
    sll $r10, $r10, 9
    addi $r11, $r0, 79
    or $r10, $r10, $r11
    sw $r10, 118($r28)
    addi $r10, $r0, 248
    sll $r10, $r10, 9
    addi $r11, $r0, 79
    or $r10, $r10, $r11
    sw $r10, 119($r28)
    addi $r10, $r0, 391
    sll $r10, $r10, 9
    addi $r11, $r0, 79
    or $r10, $r10, $r11
    sw $r10, 120($r28)
    addi $r10, $r0, 246
    sll $r10, $r10, 9
    addi $r11, $r0, 80
    or $r10, $r10, $r11
    sw $r10, 121($r28)
    addi $r10, $r0, 392
    sll $r10, $r10, 9
    addi $r11, $r0, 80
    or $r10, $r10, $r11
    sw $r10, 122($r28)
    addi $r10, $r0, 245
    sll $r10, $r10, 9
    addi $r11, $r0, 81
    or $r10, $r10, $r11
    sw $r10, 123($r28)
    addi $r10, $r0, 394
    sll $r10, $r10, 9
    addi $r11, $r0, 81
    or $r10, $r10, $r11
    sw $r10, 124($r28)
    addi $r10, $r0, 243
    sll $r10, $r10, 9
    addi $r11, $r0, 82
    or $r10, $r10, $r11
    sw $r10, 125($r28)
    addi $r10, $r0, 395
    sll $r10, $r10, 9
    addi $r11, $r0, 82
    or $r10, $r10, $r11
    sw $r10, 126($r28)
    addi $r10, $r0, 242
    sll $r10, $r10, 9
    addi $r11, $r0, 83
    or $r10, $r10, $r11
    sw $r10, 127($r28)
    addi $r10, $r0, 397
    sll $r10, $r10, 9
    addi $r11, $r0, 83
    or $r10, $r10, $r11
    sw $r10, 128($r28)
    addi $r10, $r0, 240
    sll $r10, $r10, 9
    addi $r11, $r0, 84
    or $r10, $r10, $r11
    sw $r10, 129($r28)
    addi $r10, $r0, 241
    sll $r10, $r10, 9
    addi $r11, $r0, 84
    or $r10, $r10, $r11
    sw $r10, 130($r28)
    addi $r10, $r0, 398
    sll $r10, $r10, 9
    addi $r11, $r0, 84
    or $r10, $r10, $r11
    sw $r10, 131($r28)
    addi $r10, $r0, 239
    sll $r10, $r10, 9
    addi $r11, $r0, 85
    or $r10, $r10, $r11
    sw $r10, 132($r28)
    addi $r10, $r0, 399
    sll $r10, $r10, 9
    addi $r11, $r0, 85
    or $r10, $r10, $r11
    sw $r10, 133($r28)
    addi $r10, $r0, 238
    sll $r10, $r10, 9
    addi $r11, $r0, 86
    or $r10, $r10, $r11
    sw $r10, 134($r28)
    addi $r10, $r0, 401
    sll $r10, $r10, 9
    addi $r11, $r0, 86
    or $r10, $r10, $r11
    sw $r10, 135($r28)
    addi $r10, $r0, 236
    sll $r10, $r10, 9
    addi $r11, $r0, 87
    or $r10, $r10, $r11
    sw $r10, 136($r28)
    addi $r10, $r0, 402
    sll $r10, $r10, 9
    addi $r11, $r0, 87
    or $r10, $r10, $r11
    sw $r10, 137($r28)
    addi $r10, $r0, 235
    sll $r10, $r10, 9
    addi $r11, $r0, 88
    or $r10, $r10, $r11
    sw $r10, 138($r28)
    addi $r10, $r0, 403
    sll $r10, $r10, 9
    addi $r11, $r0, 88
    or $r10, $r10, $r11
    sw $r10, 139($r28)
    addi $r10, $r0, 404
    sll $r10, $r10, 9
    addi $r11, $r0, 88
    or $r10, $r10, $r11
    sw $r10, 140($r28)
    addi $r10, $r0, 234
    sll $r10, $r10, 9
    addi $r11, $r0, 89
    or $r10, $r10, $r11
    sw $r10, 141($r28)
    addi $r10, $r0, 405
    sll $r10, $r10, 9
    addi $r11, $r0, 89
    or $r10, $r10, $r11
    sw $r10, 142($r28)
    addi $r10, $r0, 232
    sll $r10, $r10, 9
    addi $r11, $r0, 90
    or $r10, $r10, $r11
    sw $r10, 143($r28)
    addi $r10, $r0, 406
    sll $r10, $r10, 9
    addi $r11, $r0, 90
    or $r10, $r10, $r11
    sw $r10, 144($r28)
    addi $r10, $r0, 231
    sll $r10, $r10, 9
    addi $r11, $r0, 91
    or $r10, $r10, $r11
    sw $r10, 145($r28)
    addi $r10, $r0, 407
    sll $r10, $r10, 9
    addi $r11, $r0, 91
    or $r10, $r10, $r11
    sw $r10, 146($r28)
    addi $r10, $r0, 408
    sll $r10, $r10, 9
    addi $r11, $r0, 91
    or $r10, $r10, $r11
    sw $r10, 147($r28)
    addi $r10, $r0, 229
    sll $r10, $r10, 9
    addi $r11, $r0, 92
    or $r10, $r10, $r11
    sw $r10, 148($r28)
    addi $r10, $r0, 230
    sll $r10, $r10, 9
    addi $r11, $r0, 92
    or $r10, $r10, $r11
    sw $r10, 149($r28)
    addi $r10, $r0, 409
    sll $r10, $r10, 9
    addi $r11, $r0, 92
    or $r10, $r10, $r11
    sw $r10, 150($r28)
    addi $r10, $r0, 228
    sll $r10, $r10, 9
    addi $r11, $r0, 93
    or $r10, $r10, $r11
    sw $r10, 151($r28)
    addi $r10, $r0, 410
    sll $r10, $r10, 9
    addi $r11, $r0, 93
    or $r10, $r10, $r11
    sw $r10, 152($r28)
    addi $r10, $r0, 227
    sll $r10, $r10, 9
    addi $r11, $r0, 94
    or $r10, $r10, $r11
    sw $r10, 153($r28)
    addi $r10, $r0, 412
    sll $r10, $r10, 9
    addi $r11, $r0, 94
    or $r10, $r10, $r11
    sw $r10, 154($r28)
    addi $r10, $r0, 225
    sll $r10, $r10, 9
    addi $r11, $r0, 95
    or $r10, $r10, $r11
    sw $r10, 155($r28)
    addi $r10, $r0, 413
    sll $r10, $r10, 9
    addi $r11, $r0, 95
    or $r10, $r10, $r11
    sw $r10, 156($r28)
    addi $r10, $r0, 224
    sll $r10, $r10, 9
    addi $r11, $r0, 96
    or $r10, $r10, $r11
    sw $r10, 157($r28)
    addi $r10, $r0, 415
    sll $r10, $r10, 9
    addi $r11, $r0, 96
    or $r10, $r10, $r11
    sw $r10, 158($r28)
    addi $r10, $r0, 223
    sll $r10, $r10, 9
    addi $r11, $r0, 97
    or $r10, $r10, $r11
    sw $r10, 159($r28)
    addi $r10, $r0, 416
    sll $r10, $r10, 9
    addi $r11, $r0, 97
    or $r10, $r10, $r11
    sw $r10, 160($r28)
    addi $r10, $r0, 221
    sll $r10, $r10, 9
    addi $r11, $r0, 98
    or $r10, $r10, $r11
    sw $r10, 161($r28)
    addi $r10, $r0, 417
    sll $r10, $r10, 9
    addi $r11, $r0, 98
    or $r10, $r10, $r11
    sw $r10, 162($r28)
    addi $r10, $r0, 220
    sll $r10, $r10, 9
    addi $r11, $r0, 99
    or $r10, $r10, $r11
    sw $r10, 163($r28)
    addi $r10, $r0, 418
    sll $r10, $r10, 9
    addi $r11, $r0, 99
    or $r10, $r10, $r11
    sw $r10, 164($r28)
    addi $r10, $r0, 419
    sll $r10, $r10, 9
    addi $r11, $r0, 99
    or $r10, $r10, $r11
    sw $r10, 165($r28)
    addi $r10, $r0, 218
    sll $r10, $r10, 9
    addi $r11, $r0, 100
    or $r10, $r10, $r11
    sw $r10, 166($r28)
    addi $r10, $r0, 219
    sll $r10, $r10, 9
    addi $r11, $r0, 100
    or $r10, $r10, $r11
    sw $r10, 167($r28)
    addi $r10, $r0, 420
    sll $r10, $r10, 9
    addi $r11, $r0, 100
    or $r10, $r10, $r11
    sw $r10, 168($r28)
    addi $r10, $r0, 217
    sll $r10, $r10, 9
    addi $r11, $r0, 101
    or $r10, $r10, $r11
    sw $r10, 169($r28)
    addi $r10, $r0, 421
    sll $r10, $r10, 9
    addi $r11, $r0, 101
    or $r10, $r10, $r11
    sw $r10, 170($r28)
    addi $r10, $r0, 216
    sll $r10, $r10, 9
    addi $r11, $r0, 102
    or $r10, $r10, $r11
    sw $r10, 171($r28)
    addi $r10, $r0, 423
    sll $r10, $r10, 9
    addi $r11, $r0, 102
    or $r10, $r10, $r11
    sw $r10, 172($r28)
    addi $r10, $r0, 215
    sll $r10, $r10, 9
    addi $r11, $r0, 103
    or $r10, $r10, $r11
    sw $r10, 173($r28)
    addi $r10, $r0, 424
    sll $r10, $r10, 9
    addi $r11, $r0, 103
    or $r10, $r10, $r11
    sw $r10, 174($r28)
    addi $r10, $r0, 213
    sll $r10, $r10, 9
    addi $r11, $r0, 104
    or $r10, $r10, $r11
    sw $r10, 175($r28)
    addi $r10, $r0, 425
    sll $r10, $r10, 9
    addi $r11, $r0, 104
    or $r10, $r10, $r11
    sw $r10, 176($r28)
    addi $r10, $r0, 212
    sll $r10, $r10, 9
    addi $r11, $r0, 105
    or $r10, $r10, $r11
    sw $r10, 177($r28)
    addi $r10, $r0, 427
    sll $r10, $r10, 9
    addi $r11, $r0, 105
    or $r10, $r10, $r11
    sw $r10, 178($r28)
    addi $r10, $r0, 210
    sll $r10, $r10, 9
    addi $r11, $r0, 106
    or $r10, $r10, $r11
    sw $r10, 179($r28)
    addi $r10, $r0, 428
    sll $r10, $r10, 9
    addi $r11, $r0, 106
    or $r10, $r10, $r11
    sw $r10, 180($r28)
    addi $r10, $r0, 209
    sll $r10, $r10, 9
    addi $r11, $r0, 107
    or $r10, $r10, $r11
    sw $r10, 181($r28)
    addi $r10, $r0, 429
    sll $r10, $r10, 9
    addi $r11, $r0, 107
    or $r10, $r10, $r11
    sw $r10, 182($r28)
    addi $r10, $r0, 430
    sll $r10, $r10, 9
    addi $r11, $r0, 107
    or $r10, $r10, $r11
    sw $r10, 183($r28)
    addi $r10, $r0, 207
    sll $r10, $r10, 9
    addi $r11, $r0, 108
    or $r10, $r10, $r11
    sw $r10, 184($r28)
    addi $r10, $r0, 208
    sll $r10, $r10, 9
    addi $r11, $r0, 108
    or $r10, $r10, $r11
    sw $r10, 185($r28)
    addi $r10, $r0, 431
    sll $r10, $r10, 9
    addi $r11, $r0, 108
    or $r10, $r10, $r11
    sw $r10, 186($r28)
    addi $r10, $r0, 206
    sll $r10, $r10, 9
    addi $r11, $r0, 109
    or $r10, $r10, $r11
    sw $r10, 187($r28)
    addi $r10, $r0, 432
    sll $r10, $r10, 9
    addi $r11, $r0, 109
    or $r10, $r10, $r11
    sw $r10, 188($r28)
    addi $r10, $r0, 205
    sll $r10, $r10, 9
    addi $r11, $r0, 110
    or $r10, $r10, $r11
    sw $r10, 189($r28)
    addi $r10, $r0, 433
    sll $r10, $r10, 9
    addi $r11, $r0, 110
    or $r10, $r10, $r11
    sw $r10, 190($r28)
    addi $r10, $r0, 434
    sll $r10, $r10, 9
    addi $r11, $r0, 110
    or $r10, $r10, $r11
    sw $r10, 191($r28)
    addi $r10, $r0, 203
    sll $r10, $r10, 9
    addi $r11, $r0, 111
    or $r10, $r10, $r11
    sw $r10, 192($r28)
    addi $r10, $r0, 435
    sll $r10, $r10, 9
    addi $r11, $r0, 111
    or $r10, $r10, $r11
    sw $r10, 193($r28)
    addi $r10, $r0, 202
    sll $r10, $r10, 9
    addi $r11, $r0, 112
    or $r10, $r10, $r11
    sw $r10, 194($r28)
    addi $r10, $r0, 436
    sll $r10, $r10, 9
    addi $r11, $r0, 112
    or $r10, $r10, $r11
    sw $r10, 195($r28)
    addi $r10, $r0, 438
    sll $r10, $r10, 9
    addi $r11, $r0, 113
    or $r10, $r10, $r11
    sw $r10, 196($r28)
    addi $r10, $r0, 199
    sll $r10, $r10, 9
    addi $r11, $r0, 114
    or $r10, $r10, $r11
    sw $r10, 197($r28)
    addi $r10, $r0, 439
    sll $r10, $r10, 9
    addi $r11, $r0, 114
    or $r10, $r10, $r11
    sw $r10, 198($r28)
    addi $r10, $r0, 198
    sll $r10, $r10, 9
    addi $r11, $r0, 115
    or $r10, $r10, $r11
    sw $r10, 199($r28)
    addi $r10, $r0, 440
    sll $r10, $r10, 9
    addi $r11, $r0, 115
    or $r10, $r10, $r11
    sw $r10, 200($r28)
    addi $r10, $r0, 196
    sll $r10, $r10, 9
    addi $r11, $r0, 116
    or $r10, $r10, $r11
    sw $r10, 201($r28)
    addi $r10, $r0, 197
    sll $r10, $r10, 9
    addi $r11, $r0, 116
    or $r10, $r10, $r11
    sw $r10, 202($r28)
    addi $r10, $r0, 442
    sll $r10, $r10, 9
    addi $r11, $r0, 116
    or $r10, $r10, $r11
    sw $r10, 203($r28)
    addi $r10, $r0, 195
    sll $r10, $r10, 9
    addi $r11, $r0, 117
    or $r10, $r10, $r11
    sw $r10, 204($r28)
    addi $r10, $r0, 443
    sll $r10, $r10, 9
    addi $r11, $r0, 117
    or $r10, $r10, $r11
    sw $r10, 205($r28)
    addi $r10, $r0, 194
    sll $r10, $r10, 9
    addi $r11, $r0, 118
    or $r10, $r10, $r11
    sw $r10, 206($r28)
    addi $r10, $r0, 444
    sll $r10, $r10, 9
    addi $r11, $r0, 118
    or $r10, $r10, $r11
    sw $r10, 207($r28)
    addi $r10, $r0, 445
    sll $r10, $r10, 9
    addi $r11, $r0, 118
    or $r10, $r10, $r11
    sw $r10, 208($r28)
    addi $r10, $r0, 192
    sll $r10, $r10, 9
    addi $r11, $r0, 119
    or $r10, $r10, $r11
    sw $r10, 209($r28)
    addi $r10, $r0, 446
    sll $r10, $r10, 9
    addi $r11, $r0, 119
    or $r10, $r10, $r11
    sw $r10, 210($r28)
    addi $r10, $r0, 191
    sll $r10, $r10, 9
    addi $r11, $r0, 120
    or $r10, $r10, $r11
    sw $r10, 211($r28)
    addi $r10, $r0, 447
    sll $r10, $r10, 9
    addi $r11, $r0, 120
    or $r10, $r10, $r11
    sw $r10, 212($r28)
    addi $r10, $r0, 190
    sll $r10, $r10, 9
    addi $r11, $r0, 121
    or $r10, $r10, $r11
    sw $r10, 213($r28)
    addi $r10, $r0, 448
    sll $r10, $r10, 9
    addi $r11, $r0, 121
    or $r10, $r10, $r11
    sw $r10, 214($r28)
    addi $r10, $r0, 449
    sll $r10, $r10, 9
    addi $r11, $r0, 121
    or $r10, $r10, $r11
    sw $r10, 215($r28)
    addi $r10, $r0, 188
    sll $r10, $r10, 9
    addi $r11, $r0, 122
    or $r10, $r10, $r11
    sw $r10, 216($r28)
    addi $r10, $r0, 450
    sll $r10, $r10, 9
    addi $r11, $r0, 122
    or $r10, $r10, $r11
    sw $r10, 217($r28)
    addi $r10, $r0, 187
    sll $r10, $r10, 9
    addi $r11, $r0, 123
    or $r10, $r10, $r11
    sw $r10, 218($r28)
    addi $r10, $r0, 451
    sll $r10, $r10, 9
    addi $r11, $r0, 123
    or $r10, $r10, $r11
    sw $r10, 219($r28)
    addi $r10, $r0, 185
    sll $r10, $r10, 9
    addi $r11, $r0, 124
    or $r10, $r10, $r11
    sw $r10, 220($r28)
    addi $r10, $r0, 186
    sll $r10, $r10, 9
    addi $r11, $r0, 124
    or $r10, $r10, $r11
    sw $r10, 221($r28)
    addi $r10, $r0, 453
    sll $r10, $r10, 9
    addi $r11, $r0, 124
    or $r10, $r10, $r11
    sw $r10, 222($r28)
    addi $r10, $r0, 184
    sll $r10, $r10, 9
    addi $r11, $r0, 125
    or $r10, $r10, $r11
    sw $r10, 223($r28)
    addi $r10, $r0, 454
    sll $r10, $r10, 9
    addi $r11, $r0, 125
    or $r10, $r10, $r11
    sw $r10, 224($r28)
    addi $r10, $r0, 183
    sll $r10, $r10, 9
    addi $r11, $r0, 126
    or $r10, $r10, $r11
    sw $r10, 225($r28)
    addi $r10, $r0, 455
    sll $r10, $r10, 9
    addi $r11, $r0, 126
    or $r10, $r10, $r11
    sw $r10, 226($r28)
    addi $r10, $r0, 181
    sll $r10, $r10, 9
    addi $r11, $r0, 127
    or $r10, $r10, $r11
    sw $r10, 227($r28)
    addi $r10, $r0, 457
    sll $r10, $r10, 9
    addi $r11, $r0, 127
    or $r10, $r10, $r11
    sw $r10, 228($r28)
    addi $r10, $r0, 180
    sll $r10, $r10, 9
    addi $r11, $r0, 128
    or $r10, $r10, $r11
    sw $r10, 229($r28)
    addi $r10, $r0, 458
    sll $r10, $r10, 9
    addi $r11, $r0, 128
    or $r10, $r10, $r11
    sw $r10, 230($r28)
    addi $r10, $r0, 179
    sll $r10, $r10, 9
    addi $r11, $r0, 129
    or $r10, $r10, $r11
    sw $r10, 231($r28)
    addi $r10, $r0, 459
    sll $r10, $r10, 9
    addi $r11, $r0, 129
    or $r10, $r10, $r11
    sw $r10, 232($r28)
    addi $r10, $r0, 460
    sll $r10, $r10, 9
    addi $r11, $r0, 129
    or $r10, $r10, $r11
    sw $r10, 233($r28)
    addi $r10, $r0, 177
    sll $r10, $r10, 9
    addi $r11, $r0, 130
    or $r10, $r10, $r11
    sw $r10, 234($r28)
    addi $r10, $r0, 461
    sll $r10, $r10, 9
    addi $r11, $r0, 130
    or $r10, $r10, $r11
    sw $r10, 235($r28)
    addi $r10, $r0, 176
    sll $r10, $r10, 9
    addi $r11, $r0, 131
    or $r10, $r10, $r11
    sw $r10, 236($r28)
    addi $r10, $r0, 462
    sll $r10, $r10, 9
    addi $r11, $r0, 131
    or $r10, $r10, $r11
    sw $r10, 237($r28)
    addi $r10, $r0, 174
    sll $r10, $r10, 9
    addi $r11, $r0, 132
    or $r10, $r10, $r11
    sw $r10, 238($r28)
    addi $r10, $r0, 175
    sll $r10, $r10, 9
    addi $r11, $r0, 132
    or $r10, $r10, $r11
    sw $r10, 239($r28)
    addi $r10, $r0, 464
    sll $r10, $r10, 9
    addi $r11, $r0, 132
    or $r10, $r10, $r11
    sw $r10, 240($r28)
    addi $r10, $r0, 173
    sll $r10, $r10, 9
    addi $r11, $r0, 133
    or $r10, $r10, $r11
    sw $r10, 241($r28)
    addi $r10, $r0, 465
    sll $r10, $r10, 9
    addi $r11, $r0, 133
    or $r10, $r10, $r11
    sw $r10, 242($r28)
    addi $r10, $r0, 172
    sll $r10, $r10, 9
    addi $r11, $r0, 134
    or $r10, $r10, $r11
    sw $r10, 243($r28)
    addi $r10, $r0, 466
    sll $r10, $r10, 9
    addi $r11, $r0, 134
    or $r10, $r10, $r11
    sw $r10, 244($r28)
    addi $r10, $r0, 170
    sll $r10, $r10, 9
    addi $r11, $r0, 135
    or $r10, $r10, $r11
    sw $r10, 245($r28)
    addi $r10, $r0, 468
    sll $r10, $r10, 9
    addi $r11, $r0, 135
    or $r10, $r10, $r11
    sw $r10, 246($r28)
    addi $r10, $r0, 169
    sll $r10, $r10, 9
    addi $r11, $r0, 136
    or $r10, $r10, $r11
    sw $r10, 247($r28)
    addi $r10, $r0, 469
    sll $r10, $r10, 9
    addi $r11, $r0, 136
    or $r10, $r10, $r11
    sw $r10, 248($r28)
    addi $r10, $r0, 167
    sll $r10, $r10, 9
    addi $r11, $r0, 137
    or $r10, $r10, $r11
    sw $r10, 249($r28)
    addi $r10, $r0, 168
    sll $r10, $r10, 9
    addi $r11, $r0, 137
    or $r10, $r10, $r11
    sw $r10, 250($r28)
    addi $r10, $r0, 471
    sll $r10, $r10, 9
    addi $r11, $r0, 137
    or $r10, $r10, $r11
    sw $r10, 251($r28)
    addi $r10, $r0, 166
    sll $r10, $r10, 9
    addi $r11, $r0, 138
    or $r10, $r10, $r11
    sw $r10, 252($r28)
    addi $r10, $r0, 472
    sll $r10, $r10, 9
    addi $r11, $r0, 138
    or $r10, $r10, $r11
    sw $r10, 253($r28)
    addi $r10, $r0, 165
    sll $r10, $r10, 9
    addi $r11, $r0, 139
    or $r10, $r10, $r11
    sw $r10, 254($r28)
    addi $r10, $r0, 473
    sll $r10, $r10, 9
    addi $r11, $r0, 139
    or $r10, $r10, $r11
    sw $r10, 255($r28)
    addi $r10, $r0, 163
    sll $r10, $r10, 9
    addi $r11, $r0, 140
    or $r10, $r10, $r11
    sw $r10, 256($r28)
    addi $r10, $r0, 164
    sll $r10, $r10, 9
    addi $r11, $r0, 140
    or $r10, $r10, $r11
    sw $r10, 257($r28)
    addi $r10, $r0, 474
    sll $r10, $r10, 9
    addi $r11, $r0, 140
    or $r10, $r10, $r11
    sw $r10, 258($r28)
    addi $r10, $r0, 475
    sll $r10, $r10, 9
    addi $r11, $r0, 140
    or $r10, $r10, $r11
    sw $r10, 259($r28)
    addi $r10, $r0, 162
    sll $r10, $r10, 9
    addi $r11, $r0, 141
    or $r10, $r10, $r11
    sw $r10, 260($r28)
    addi $r10, $r0, 476
    sll $r10, $r10, 9
    addi $r11, $r0, 141
    or $r10, $r10, $r11
    sw $r10, 261($r28)
    addi $r10, $r0, 161
    sll $r10, $r10, 9
    addi $r11, $r0, 142
    or $r10, $r10, $r11
    sw $r10, 262($r28)
    addi $r10, $r0, 477
    sll $r10, $r10, 9
    addi $r11, $r0, 142
    or $r10, $r10, $r11
    sw $r10, 263($r28)
    addi $r10, $r0, 159
    sll $r10, $r10, 9
    addi $r11, $r0, 143
    or $r10, $r10, $r11
    sw $r10, 264($r28)
    addi $r10, $r0, 479
    sll $r10, $r10, 9
    addi $r11, $r0, 143
    or $r10, $r10, $r11
    sw $r10, 265($r28)
    addi $r10, $r0, 158
    sll $r10, $r10, 9
    addi $r11, $r0, 144
    or $r10, $r10, $r11
    sw $r10, 266($r28)
    addi $r10, $r0, 480
    sll $r10, $r10, 9
    addi $r11, $r0, 144
    or $r10, $r10, $r11
    sw $r10, 267($r28)
    addi $r10, $r0, 156
    sll $r10, $r10, 9
    addi $r11, $r0, 145
    or $r10, $r10, $r11
    sw $r10, 268($r28)
    addi $r10, $r0, 157
    sll $r10, $r10, 9
    addi $r11, $r0, 145
    or $r10, $r10, $r11
    sw $r10, 269($r28)
    addi $r10, $r0, 481
    sll $r10, $r10, 9
    addi $r11, $r0, 145
    or $r10, $r10, $r11
    sw $r10, 270($r28)
    addi $r10, $r0, 155
    sll $r10, $r10, 9
    addi $r11, $r0, 146
    or $r10, $r10, $r11
    sw $r10, 271($r28)
    addi $r10, $r0, 483
    sll $r10, $r10, 9
    addi $r11, $r0, 146
    or $r10, $r10, $r11
    sw $r10, 272($r28)
    addi $r10, $r0, 154
    sll $r10, $r10, 9
    addi $r11, $r0, 147
    or $r10, $r10, $r11
    sw $r10, 273($r28)
    addi $r10, $r0, 484
    sll $r10, $r10, 9
    addi $r11, $r0, 147
    or $r10, $r10, $r11
    sw $r10, 274($r28)
    addi $r10, $r0, 152
    sll $r10, $r10, 9
    addi $r11, $r0, 148
    or $r10, $r10, $r11
    sw $r10, 275($r28)
    addi $r10, $r0, 485
    sll $r10, $r10, 9
    addi $r11, $r0, 148
    or $r10, $r10, $r11
    sw $r10, 276($r28)
    addi $r10, $r0, 486
    sll $r10, $r10, 9
    addi $r11, $r0, 148
    or $r10, $r10, $r11
    sw $r10, 277($r28)
    addi $r10, $r0, 151
    sll $r10, $r10, 9
    addi $r11, $r0, 149
    or $r10, $r10, $r11
    sw $r10, 278($r28)
    addi $r10, $r0, 487
    sll $r10, $r10, 9
    addi $r11, $r0, 149
    or $r10, $r10, $r11
    sw $r10, 279($r28)
    addi $r10, $r0, 150
    sll $r10, $r10, 9
    addi $r11, $r0, 150
    or $r10, $r10, $r11
    sw $r10, 280($r28)
    addi $r10, $r0, 488
    sll $r10, $r10, 9
    addi $r11, $r0, 150
    or $r10, $r10, $r11
    sw $r10, 281($r28)
    addi $r10, $r0, 148
    sll $r10, $r10, 9
    addi $r11, $r0, 151
    or $r10, $r10, $r11
    sw $r10, 282($r28)
    addi $r10, $r0, 490
    sll $r10, $r10, 9
    addi $r11, $r0, 151
    or $r10, $r10, $r11
    sw $r10, 283($r28)
    addi $r10, $r0, 147
    sll $r10, $r10, 9
    addi $r11, $r0, 152
    or $r10, $r10, $r11
    sw $r10, 284($r28)
    addi $r10, $r0, 491
    sll $r10, $r10, 9
    addi $r11, $r0, 152
    or $r10, $r10, $r11
    sw $r10, 285($r28)
    addi $r10, $r0, 145
    sll $r10, $r10, 9
    addi $r11, $r0, 153
    or $r10, $r10, $r11
    sw $r10, 286($r28)
    addi $r10, $r0, 146
    sll $r10, $r10, 9
    addi $r11, $r0, 153
    or $r10, $r10, $r11
    sw $r10, 287($r28)
    addi $r10, $r0, 492
    sll $r10, $r10, 9
    addi $r11, $r0, 153
    or $r10, $r10, $r11
    sw $r10, 288($r28)
    addi $r10, $r0, 144
    sll $r10, $r10, 9
    addi $r11, $r0, 154
    or $r10, $r10, $r11
    sw $r10, 289($r28)
    addi $r10, $r0, 494
    sll $r10, $r10, 9
    addi $r11, $r0, 154
    or $r10, $r10, $r11
    sw $r10, 290($r28)
    addi $r10, $r0, 143
    sll $r10, $r10, 9
    addi $r11, $r0, 155
    or $r10, $r10, $r11
    sw $r10, 291($r28)
    addi $r10, $r0, 495
    sll $r10, $r10, 9
    addi $r11, $r0, 155
    or $r10, $r10, $r11
    sw $r10, 292($r28)
    addi $r10, $r0, 141
    sll $r10, $r10, 9
    addi $r11, $r0, 156
    or $r10, $r10, $r11
    sw $r10, 293($r28)
    addi $r10, $r0, 142
    sll $r10, $r10, 9
    addi $r11, $r0, 156
    or $r10, $r10, $r11
    sw $r10, 294($r28)
    addi $r10, $r0, 496
    sll $r10, $r10, 9
    addi $r11, $r0, 156
    or $r10, $r10, $r11
    sw $r10, 295($r28)
    addi $r10, $r0, 497
    sll $r10, $r10, 9
    addi $r11, $r0, 156
    or $r10, $r10, $r11
    sw $r10, 296($r28)
    addi $r10, $r0, 140
    sll $r10, $r10, 9
    addi $r11, $r0, 157
    or $r10, $r10, $r11
    sw $r10, 297($r28)
    addi $r10, $r0, 498
    sll $r10, $r10, 9
    addi $r11, $r0, 157
    or $r10, $r10, $r11
    sw $r10, 298($r28)
    addi $r10, $r0, 139
    sll $r10, $r10, 9
    addi $r11, $r0, 158
    or $r10, $r10, $r11
    sw $r10, 299($r28)
    addi $r10, $r0, 499
    sll $r10, $r10, 9
    addi $r11, $r0, 158
    or $r10, $r10, $r11
    sw $r10, 300($r28)
    addi $r10, $r0, 137
    sll $r10, $r10, 9
    addi $r11, $r0, 159
    or $r10, $r10, $r11
    sw $r10, 301($r28)
    addi $r10, $r0, 500
    sll $r10, $r10, 9
    addi $r11, $r0, 159
    or $r10, $r10, $r11
    sw $r10, 302($r28)
    addi $r10, $r0, 501
    sll $r10, $r10, 9
    addi $r11, $r0, 159
    or $r10, $r10, $r11
    sw $r10, 303($r28)
    addi $r10, $r0, 136
    sll $r10, $r10, 9
    addi $r11, $r0, 160
    or $r10, $r10, $r11
    sw $r10, 304($r28)
    addi $r10, $r0, 502
    sll $r10, $r10, 9
    addi $r11, $r0, 160
    or $r10, $r10, $r11
    sw $r10, 305($r28)
    addi $r10, $r0, 134
    sll $r10, $r10, 9
    addi $r11, $r0, 161
    or $r10, $r10, $r11
    sw $r10, 306($r28)
    addi $r10, $r0, 135
    sll $r10, $r10, 9
    addi $r11, $r0, 161
    or $r10, $r10, $r11
    sw $r10, 307($r28)
    addi $r10, $r0, 503
    sll $r10, $r10, 9
    addi $r11, $r0, 161
    or $r10, $r10, $r11
    sw $r10, 308($r28)
    addi $r10, $r0, 133
    sll $r10, $r10, 9
    addi $r11, $r0, 162
    or $r10, $r10, $r11
    sw $r10, 309($r28)
    addi $r10, $r0, 505
    sll $r10, $r10, 9
    addi $r11, $r0, 162
    or $r10, $r10, $r11
    sw $r10, 310($r28)
    addi $r10, $r0, 132
    sll $r10, $r10, 9
    addi $r11, $r0, 163
    or $r10, $r10, $r11
    sw $r10, 311($r28)
    addi $r10, $r0, 506
    sll $r10, $r10, 9
    addi $r11, $r0, 163
    or $r10, $r10, $r11
    sw $r10, 312($r28)
    addi $r10, $r0, 130
    sll $r10, $r10, 9
    addi $r11, $r0, 164
    or $r10, $r10, $r11
    sw $r10, 313($r28)
    addi $r10, $r0, 131
    sll $r10, $r10, 9
    addi $r11, $r0, 164
    or $r10, $r10, $r11
    sw $r10, 314($r28)
    addi $r10, $r0, 507
    sll $r10, $r10, 9
    addi $r11, $r0, 164
    or $r10, $r10, $r11
    sw $r10, 315($r28)
    addi $r10, $r0, 508
    sll $r10, $r10, 9
    addi $r11, $r0, 164
    or $r10, $r10, $r11
    sw $r10, 316($r28)
    addi $r10, $r0, 129
    sll $r10, $r10, 9
    addi $r11, $r0, 165
    or $r10, $r10, $r11
    sw $r10, 317($r28)
    addi $r10, $r0, 509
    sll $r10, $r10, 9
    addi $r11, $r0, 165
    or $r10, $r10, $r11
    sw $r10, 318($r28)
    addi $r10, $r0, 128
    sll $r10, $r10, 9
    addi $r11, $r0, 166
    or $r10, $r10, $r11
    sw $r10, 319($r28)
    addi $r10, $r0, 510
    sll $r10, $r10, 9
    addi $r11, $r0, 166
    or $r10, $r10, $r11
    sw $r10, 320($r28)
    addi $r10, $r0, 126
    sll $r10, $r10, 9
    addi $r11, $r0, 167
    or $r10, $r10, $r11
    sw $r10, 321($r28)
    addi $r10, $r0, 511
    sll $r10, $r10, 9
    addi $r11, $r0, 167
    or $r10, $r10, $r11
    sw $r10, 322($r28)
    addi $r10, $r0, 125
    sll $r10, $r10, 9
    addi $r11, $r0, 168
    or $r10, $r10, $r11
    sw $r10, 323($r28)
    addi $r10, $r0, 513
    sll $r10, $r10, 9
    addi $r11, $r0, 168
    or $r10, $r10, $r11
    sw $r10, 324($r28)
    addi $r10, $r0, 123
    sll $r10, $r10, 9
    addi $r11, $r0, 169
    or $r10, $r10, $r11
    sw $r10, 325($r28)
    addi $r10, $r0, 124
    sll $r10, $r10, 9
    addi $r11, $r0, 169
    or $r10, $r10, $r11
    sw $r10, 326($r28)
    addi $r10, $r0, 514
    sll $r10, $r10, 9
    addi $r11, $r0, 169
    or $r10, $r10, $r11
    sw $r10, 327($r28)
    addi $r10, $r0, 122
    sll $r10, $r10, 9
    addi $r11, $r0, 170
    or $r10, $r10, $r11
    sw $r10, 328($r28)
    addi $r10, $r0, 516
    sll $r10, $r10, 9
    addi $r11, $r0, 170
    or $r10, $r10, $r11
    sw $r10, 329($r28)
    addi $r10, $r0, 121
    sll $r10, $r10, 9
    addi $r11, $r0, 171
    or $r10, $r10, $r11
    sw $r10, 330($r28)
    addi $r10, $r0, 517
    sll $r10, $r10, 9
    addi $r11, $r0, 171
    or $r10, $r10, $r11
    sw $r10, 331($r28)
    addi $r10, $r0, 119
    sll $r10, $r10, 9
    addi $r11, $r0, 172
    or $r10, $r10, $r11
    sw $r10, 332($r28)
    addi $r10, $r0, 518
    sll $r10, $r10, 9
    addi $r11, $r0, 172
    or $r10, $r10, $r11
    sw $r10, 333($r28)
    addi $r10, $r0, 118
    sll $r10, $r10, 9
    addi $r11, $r0, 173
    or $r10, $r10, $r11
    sw $r10, 334($r28)
    addi $r10, $r0, 520
    sll $r10, $r10, 9
    addi $r11, $r0, 173
    or $r10, $r10, $r11
    sw $r10, 335($r28)
    addi $r10, $r0, 117
    sll $r10, $r10, 9
    addi $r11, $r0, 174
    or $r10, $r10, $r11
    sw $r10, 336($r28)
    addi $r10, $r0, 521
    sll $r10, $r10, 9
    addi $r11, $r0, 174
    or $r10, $r10, $r11
    sw $r10, 337($r28)
    addi $r10, $r0, 115
    sll $r10, $r10, 9
    addi $r11, $r0, 175
    or $r10, $r10, $r11
    sw $r10, 338($r28)
    addi $r10, $r0, 522
    sll $r10, $r10, 9
    addi $r11, $r0, 175
    or $r10, $r10, $r11
    sw $r10, 339($r28)
    addi $r10, $r0, 523
    sll $r10, $r10, 9
    addi $r11, $r0, 175
    or $r10, $r10, $r11
    sw $r10, 340($r28)
    addi $r10, $r0, 114
    sll $r10, $r10, 9
    addi $r11, $r0, 176
    or $r10, $r10, $r11
    sw $r10, 341($r28)
    addi $r10, $r0, 524
    sll $r10, $r10, 9
    addi $r11, $r0, 176
    or $r10, $r10, $r11
    sw $r10, 342($r28)
    addi $r10, $r0, 112
    sll $r10, $r10, 9
    addi $r11, $r0, 177
    or $r10, $r10, $r11
    sw $r10, 343($r28)
    addi $r10, $r0, 525
    sll $r10, $r10, 9
    addi $r11, $r0, 177
    or $r10, $r10, $r11
    sw $r10, 344($r28)
    addi $r10, $r0, 111
    sll $r10, $r10, 9
    addi $r11, $r0, 178
    or $r10, $r10, $r11
    sw $r10, 345($r28)
    addi $r10, $r0, 527
    sll $r10, $r10, 9
    addi $r11, $r0, 178
    or $r10, $r10, $r11
    sw $r10, 346($r28)
    addi $r10, $r0, 110
    sll $r10, $r10, 9
    addi $r11, $r0, 179
    or $r10, $r10, $r11
    sw $r10, 347($r28)
    addi $r10, $r0, 528
    sll $r10, $r10, 9
    addi $r11, $r0, 179
    or $r10, $r10, $r11
    sw $r10, 348($r28)
    addi $r10, $r0, 108
    sll $r10, $r10, 9
    addi $r11, $r0, 180
    or $r10, $r10, $r11
    sw $r10, 349($r28)
    addi $r10, $r0, 109
    sll $r10, $r10, 9
    addi $r11, $r0, 180
    or $r10, $r10, $r11
    sw $r10, 350($r28)
    addi $r10, $r0, 529
    sll $r10, $r10, 9
    addi $r11, $r0, 180
    or $r10, $r10, $r11
    sw $r10, 351($r28)
    addi $r10, $r0, 107
    sll $r10, $r10, 9
    addi $r11, $r0, 181
    or $r10, $r10, $r11
    sw $r10, 352($r28)
    addi $r10, $r0, 531
    sll $r10, $r10, 9
    addi $r11, $r0, 181
    or $r10, $r10, $r11
    sw $r10, 353($r28)
    addi $r10, $r0, 106
    sll $r10, $r10, 9
    addi $r11, $r0, 182
    or $r10, $r10, $r11
    sw $r10, 354($r28)
    addi $r10, $r0, 532
    sll $r10, $r10, 9
    addi $r11, $r0, 182
    or $r10, $r10, $r11
    sw $r10, 355($r28)
    addi $r10, $r0, 104
    sll $r10, $r10, 9
    addi $r11, $r0, 183
    or $r10, $r10, $r11
    sw $r10, 356($r28)
    addi $r10, $r0, 533
    sll $r10, $r10, 9
    addi $r11, $r0, 183
    or $r10, $r10, $r11
    sw $r10, 357($r28)
    addi $r10, $r0, 534
    sll $r10, $r10, 9
    addi $r11, $r0, 183
    or $r10, $r10, $r11
    sw $r10, 358($r28)
    addi $r10, $r0, 103
    sll $r10, $r10, 9
    addi $r11, $r0, 184
    or $r10, $r10, $r11
    sw $r10, 359($r28)
    addi $r10, $r0, 535
    sll $r10, $r10, 9
    addi $r11, $r0, 184
    or $r10, $r10, $r11
    sw $r10, 360($r28)
    addi $r10, $r0, 101
    sll $r10, $r10, 9
    addi $r11, $r0, 185
    or $r10, $r10, $r11
    sw $r10, 361($r28)
    addi $r10, $r0, 102
    sll $r10, $r10, 9
    addi $r11, $r0, 185
    or $r10, $r10, $r11
    sw $r10, 362($r28)
    addi $r10, $r0, 536
    sll $r10, $r10, 9
    addi $r11, $r0, 185
    or $r10, $r10, $r11
    sw $r10, 363($r28)
    addi $r10, $r0, 100
    sll $r10, $r10, 9
    addi $r11, $r0, 186
    or $r10, $r10, $r11
    sw $r10, 364($r28)
    addi $r10, $r0, 537
    sll $r10, $r10, 9
    addi $r11, $r0, 186
    or $r10, $r10, $r11
    sw $r10, 365($r28)
    addi $r10, $r0, 538
    sll $r10, $r10, 9
    addi $r11, $r0, 186
    or $r10, $r10, $r11
    sw $r10, 366($r28)
    addi $r10, $r0, 99
    sll $r10, $r10, 9
    addi $r11, $r0, 187
    or $r10, $r10, $r11
    sw $r10, 367($r28)
    addi $r10, $r0, 539
    sll $r10, $r10, 9
    addi $r11, $r0, 187
    or $r10, $r10, $r11
    sw $r10, 368($r28)
    addi $r10, $r0, 97
    sll $r10, $r10, 9
    addi $r11, $r0, 188
    or $r10, $r10, $r11
    sw $r10, 369($r28)
    addi $r10, $r0, 540
    sll $r10, $r10, 9
    addi $r11, $r0, 188
    or $r10, $r10, $r11
    sw $r10, 370($r28)
    addi $r10, $r0, 542
    sll $r10, $r10, 9
    addi $r11, $r0, 189
    or $r10, $r10, $r11
    sw $r10, 371($r28)
    addi $r10, $r0, 97
    sll $r10, $r10, 9
    addi $r11, $r0, 193
    or $r10, $r10, $r11
    sw $r10, 372($r28)
    addi $r10, $r0, 97
    sll $r10, $r10, 9
    addi $r11, $r0, 194
    or $r10, $r10, $r11
    sw $r10, 373($r28)
    addi $r10, $r0, 542
    sll $r10, $r10, 9
    addi $r11, $r0, 194
    or $r10, $r10, $r11
    sw $r10, 374($r28)
    addi $r10, $r0, 542
    sll $r10, $r10, 9
    addi $r11, $r0, 195
    or $r10, $r10, $r11
    sw $r10, 375($r28)
    addi $r10, $r0, 98
    sll $r10, $r10, 9
    addi $r11, $r0, 196
    or $r10, $r10, $r11
    sw $r10, 376($r28)
    addi $r10, $r0, 98
    sll $r10, $r10, 9
    addi $r11, $r0, 197
    or $r10, $r10, $r11
    sw $r10, 377($r28)
    addi $r10, $r0, 541
    sll $r10, $r10, 9
    addi $r11, $r0, 197
    or $r10, $r10, $r11
    sw $r10, 378($r28)
    addi $r10, $r0, 99
    sll $r10, $r10, 9
    addi $r11, $r0, 199
    or $r10, $r10, $r11
    sw $r10, 379($r28)
    addi $r10, $r0, 99
    sll $r10, $r10, 9
    addi $r11, $r0, 200
    or $r10, $r10, $r11
    sw $r10, 380($r28)
    addi $r10, $r0, 540
    sll $r10, $r10, 9
    addi $r11, $r0, 200
    or $r10, $r10, $r11
    sw $r10, 381($r28)
    addi $r10, $r0, 100
    sll $r10, $r10, 9
    addi $r11, $r0, 202
    or $r10, $r10, $r11
    sw $r10, 382($r28)
    addi $r10, $r0, 100
    sll $r10, $r10, 9
    addi $r11, $r0, 203
    or $r10, $r10, $r11
    sw $r10, 383($r28)
    addi $r10, $r0, 539
    sll $r10, $r10, 9
    addi $r11, $r0, 203
    or $r10, $r10, $r11
    sw $r10, 384($r28)
    addi $r10, $r0, 539
    sll $r10, $r10, 9
    addi $r11, $r0, 204
    or $r10, $r10, $r11
    sw $r10, 385($r28)
    addi $r10, $r0, 101
    sll $r10, $r10, 9
    addi $r11, $r0, 205
    or $r10, $r10, $r11
    sw $r10, 386($r28)
    addi $r10, $r0, 101
    sll $r10, $r10, 9
    addi $r11, $r0, 206
    or $r10, $r10, $r11
    sw $r10, 387($r28)
    addi $r10, $r0, 538
    sll $r10, $r10, 9
    addi $r11, $r0, 206
    or $r10, $r10, $r11
    sw $r10, 388($r28)
    addi $r10, $r0, 538
    sll $r10, $r10, 9
    addi $r11, $r0, 207
    or $r10, $r10, $r11
    sw $r10, 389($r28)
    addi $r10, $r0, 102
    sll $r10, $r10, 9
    addi $r11, $r0, 208
    or $r10, $r10, $r11
    sw $r10, 390($r28)
    addi $r10, $r0, 102
    sll $r10, $r10, 9
    addi $r11, $r0, 209
    or $r10, $r10, $r11
    sw $r10, 391($r28)
    addi $r10, $r0, 537
    sll $r10, $r10, 9
    addi $r11, $r0, 209
    or $r10, $r10, $r11
    sw $r10, 392($r28)
    addi $r10, $r0, 537
    sll $r10, $r10, 9
    addi $r11, $r0, 210
    or $r10, $r10, $r11
    sw $r10, 393($r28)
    addi $r10, $r0, 103
    sll $r10, $r10, 9
    addi $r11, $r0, 211
    or $r10, $r10, $r11
    sw $r10, 394($r28)
    addi $r10, $r0, 103
    sll $r10, $r10, 9
    addi $r11, $r0, 212
    or $r10, $r10, $r11
    sw $r10, 395($r28)
    addi $r10, $r0, 536
    sll $r10, $r10, 9
    addi $r11, $r0, 212
    or $r10, $r10, $r11
    sw $r10, 396($r28)
    addi $r10, $r0, 536
    sll $r10, $r10, 9
    addi $r11, $r0, 213
    or $r10, $r10, $r11
    sw $r10, 397($r28)
    addi $r10, $r0, 104
    sll $r10, $r10, 9
    addi $r11, $r0, 214
    or $r10, $r10, $r11
    sw $r10, 398($r28)
    addi $r10, $r0, 104
    sll $r10, $r10, 9
    addi $r11, $r0, 215
    or $r10, $r10, $r11
    sw $r10, 399($r28)
    addi $r10, $r0, 535
    sll $r10, $r10, 9
    addi $r11, $r0, 215
    or $r10, $r10, $r11
    sw $r10, 400($r28)
    addi $r10, $r0, 535
    sll $r10, $r10, 9
    addi $r11, $r0, 216
    or $r10, $r10, $r11
    sw $r10, 401($r28)
    addi $r10, $r0, 105
    sll $r10, $r10, 9
    addi $r11, $r0, 217
    or $r10, $r10, $r11
    sw $r10, 402($r28)
    addi $r10, $r0, 105
    sll $r10, $r10, 9
    addi $r11, $r0, 218
    or $r10, $r10, $r11
    sw $r10, 403($r28)
    addi $r10, $r0, 534
    sll $r10, $r10, 9
    addi $r11, $r0, 218
    or $r10, $r10, $r11
    sw $r10, 404($r28)
    addi $r10, $r0, 534
    sll $r10, $r10, 9
    addi $r11, $r0, 219
    or $r10, $r10, $r11
    sw $r10, 405($r28)
    addi $r10, $r0, 106
    sll $r10, $r10, 9
    addi $r11, $r0, 220
    or $r10, $r10, $r11
    sw $r10, 406($r28)
    addi $r10, $r0, 106
    sll $r10, $r10, 9
    addi $r11, $r0, 221
    or $r10, $r10, $r11
    sw $r10, 407($r28)
    addi $r10, $r0, 533
    sll $r10, $r10, 9
    addi $r11, $r0, 221
    or $r10, $r10, $r11
    sw $r10, 408($r28)
    addi $r10, $r0, 533
    sll $r10, $r10, 9
    addi $r11, $r0, 222
    or $r10, $r10, $r11
    sw $r10, 409($r28)
    addi $r10, $r0, 107
    sll $r10, $r10, 9
    addi $r11, $r0, 224
    or $r10, $r10, $r11
    sw $r10, 410($r28)
    addi $r10, $r0, 532
    sll $r10, $r10, 9
    addi $r11, $r0, 224
    or $r10, $r10, $r11
    sw $r10, 411($r28)
    addi $r10, $r0, 532
    sll $r10, $r10, 9
    addi $r11, $r0, 225
    or $r10, $r10, $r11
    sw $r10, 412($r28)
    addi $r10, $r0, 108
    sll $r10, $r10, 9
    addi $r11, $r0, 227
    or $r10, $r10, $r11
    sw $r10, 413($r28)
    addi $r10, $r0, 531
    sll $r10, $r10, 9
    addi $r11, $r0, 227
    or $r10, $r10, $r11
    sw $r10, 414($r28)
    addi $r10, $r0, 531
    sll $r10, $r10, 9
    addi $r11, $r0, 228
    or $r10, $r10, $r11
    sw $r10, 415($r28)
    addi $r10, $r0, 109
    sll $r10, $r10, 9
    addi $r11, $r0, 230
    or $r10, $r10, $r11
    sw $r10, 416($r28)
    addi $r10, $r0, 109
    sll $r10, $r10, 9
    addi $r11, $r0, 231
    or $r10, $r10, $r11
    sw $r10, 417($r28)
    addi $r10, $r0, 530
    sll $r10, $r10, 9
    addi $r11, $r0, 231
    or $r10, $r10, $r11
    sw $r10, 418($r28)
    addi $r10, $r0, 110
    sll $r10, $r10, 9
    addi $r11, $r0, 233
    or $r10, $r10, $r11
    sw $r10, 419($r28)
    addi $r10, $r0, 110
    sll $r10, $r10, 9
    addi $r11, $r0, 234
    or $r10, $r10, $r11
    sw $r10, 420($r28)
    addi $r10, $r0, 529
    sll $r10, $r10, 9
    addi $r11, $r0, 234
    or $r10, $r10, $r11
    sw $r10, 421($r28)
    addi $r10, $r0, 111
    sll $r10, $r10, 9
    addi $r11, $r0, 236
    or $r10, $r10, $r11
    sw $r10, 422($r28)
    addi $r10, $r0, 111
    sll $r10, $r10, 9
    addi $r11, $r0, 237
    or $r10, $r10, $r11
    sw $r10, 423($r28)
    addi $r10, $r0, 528
    sll $r10, $r10, 9
    addi $r11, $r0, 237
    or $r10, $r10, $r11
    sw $r10, 424($r28)
    addi $r10, $r0, 112
    sll $r10, $r10, 9
    addi $r11, $r0, 239
    or $r10, $r10, $r11
    sw $r10, 425($r28)
    addi $r10, $r0, 112
    sll $r10, $r10, 9
    addi $r11, $r0, 240
    or $r10, $r10, $r11
    sw $r10, 426($r28)
    addi $r10, $r0, 527
    sll $r10, $r10, 9
    addi $r11, $r0, 240
    or $r10, $r10, $r11
    sw $r10, 427($r28)
    addi $r10, $r0, 113
    sll $r10, $r10, 9
    addi $r11, $r0, 242
    or $r10, $r10, $r11
    sw $r10, 428($r28)
    addi $r10, $r0, 113
    sll $r10, $r10, 9
    addi $r11, $r0, 243
    or $r10, $r10, $r11
    sw $r10, 429($r28)
    addi $r10, $r0, 526
    sll $r10, $r10, 9
    addi $r11, $r0, 243
    or $r10, $r10, $r11
    sw $r10, 430($r28)
    addi $r10, $r0, 526
    sll $r10, $r10, 9
    addi $r11, $r0, 244
    or $r10, $r10, $r11
    sw $r10, 431($r28)
    addi $r10, $r0, 114
    sll $r10, $r10, 9
    addi $r11, $r0, 245
    or $r10, $r10, $r11
    sw $r10, 432($r28)
    addi $r10, $r0, 114
    sll $r10, $r10, 9
    addi $r11, $r0, 246
    or $r10, $r10, $r11
    sw $r10, 433($r28)
    addi $r10, $r0, 525
    sll $r10, $r10, 9
    addi $r11, $r0, 246
    or $r10, $r10, $r11
    sw $r10, 434($r28)
    addi $r10, $r0, 525
    sll $r10, $r10, 9
    addi $r11, $r0, 247
    or $r10, $r10, $r11
    sw $r10, 435($r28)
    addi $r10, $r0, 115
    sll $r10, $r10, 9
    addi $r11, $r0, 248
    or $r10, $r10, $r11
    sw $r10, 436($r28)
    addi $r10, $r0, 115
    sll $r10, $r10, 9
    addi $r11, $r0, 249
    or $r10, $r10, $r11
    sw $r10, 437($r28)
    addi $r10, $r0, 524
    sll $r10, $r10, 9
    addi $r11, $r0, 249
    or $r10, $r10, $r11
    sw $r10, 438($r28)
    addi $r10, $r0, 524
    sll $r10, $r10, 9
    addi $r11, $r0, 250
    or $r10, $r10, $r11
    sw $r10, 439($r28)
    addi $r10, $r0, 116
    sll $r10, $r10, 9
    addi $r11, $r0, 251
    or $r10, $r10, $r11
    sw $r10, 440($r28)
    addi $r10, $r0, 116
    sll $r10, $r10, 9
    addi $r11, $r0, 252
    or $r10, $r10, $r11
    sw $r10, 441($r28)
    addi $r10, $r0, 523
    sll $r10, $r10, 9
    addi $r11, $r0, 252
    or $r10, $r10, $r11
    sw $r10, 442($r28)
    addi $r10, $r0, 523
    sll $r10, $r10, 9
    addi $r11, $r0, 253
    or $r10, $r10, $r11
    sw $r10, 443($r28)
    addi $r10, $r0, 117
    sll $r10, $r10, 9
    addi $r11, $r0, 254
    or $r10, $r10, $r11
    sw $r10, 444($r28)
    addi $r10, $r0, 117
    sll $r10, $r10, 9
    addi $r11, $r0, 255
    or $r10, $r10, $r11
    sw $r10, 445($r28)
    addi $r10, $r0, 522
    sll $r10, $r10, 9
    addi $r11, $r0, 255
    or $r10, $r10, $r11
    sw $r10, 446($r28)
    addi $r10, $r0, 522
    sll $r10, $r10, 9
    addi $r11, $r0, 256
    or $r10, $r10, $r11
    sw $r10, 447($r28)
    addi $r10, $r0, 118
    sll $r10, $r10, 9
    addi $r11, $r0, 257
    or $r10, $r10, $r11
    sw $r10, 448($r28)
    addi $r10, $r0, 118
    sll $r10, $r10, 9
    addi $r11, $r0, 258
    or $r10, $r10, $r11
    sw $r10, 449($r28)
    addi $r10, $r0, 521
    sll $r10, $r10, 9
    addi $r11, $r0, 258
    or $r10, $r10, $r11
    sw $r10, 450($r28)
    addi $r10, $r0, 521
    sll $r10, $r10, 9
    addi $r11, $r0, 259
    or $r10, $r10, $r11
    sw $r10, 451($r28)
    addi $r10, $r0, 119
    sll $r10, $r10, 9
    addi $r11, $r0, 260
    or $r10, $r10, $r11
    sw $r10, 452($r28)
    addi $r10, $r0, 119
    sll $r10, $r10, 9
    addi $r11, $r0, 261
    or $r10, $r10, $r11
    sw $r10, 453($r28)
    addi $r10, $r0, 520
    sll $r10, $r10, 9
    addi $r11, $r0, 261
    or $r10, $r10, $r11
    sw $r10, 454($r28)
    addi $r10, $r0, 520
    sll $r10, $r10, 9
    addi $r11, $r0, 262
    or $r10, $r10, $r11
    sw $r10, 455($r28)
    addi $r10, $r0, 120
    sll $r10, $r10, 9
    addi $r11, $r0, 264
    or $r10, $r10, $r11
    sw $r10, 456($r28)
    addi $r10, $r0, 519
    sll $r10, $r10, 9
    addi $r11, $r0, 264
    or $r10, $r10, $r11
    sw $r10, 457($r28)
    addi $r10, $r0, 519
    sll $r10, $r10, 9
    addi $r11, $r0, 265
    or $r10, $r10, $r11
    sw $r10, 458($r28)
    addi $r10, $r0, 121
    sll $r10, $r10, 9
    addi $r11, $r0, 267
    or $r10, $r10, $r11
    sw $r10, 459($r28)
    addi $r10, $r0, 518
    sll $r10, $r10, 9
    addi $r11, $r0, 267
    or $r10, $r10, $r11
    sw $r10, 460($r28)
    addi $r10, $r0, 121
    sll $r10, $r10, 9
    addi $r11, $r0, 268
    or $r10, $r10, $r11
    sw $r10, 461($r28)
    addi $r10, $r0, 518
    sll $r10, $r10, 9
    addi $r11, $r0, 268
    or $r10, $r10, $r11
    sw $r10, 462($r28)
    addi $r10, $r0, 122
    sll $r10, $r10, 9
    addi $r11, $r0, 270
    or $r10, $r10, $r11
    sw $r10, 463($r28)
    addi $r10, $r0, 122
    sll $r10, $r10, 9
    addi $r11, $r0, 271
    or $r10, $r10, $r11
    sw $r10, 464($r28)
    addi $r10, $r0, 517
    sll $r10, $r10, 9
    addi $r11, $r0, 271
    or $r10, $r10, $r11
    sw $r10, 465($r28)
    addi $r10, $r0, 123
    sll $r10, $r10, 9
    addi $r11, $r0, 273
    or $r10, $r10, $r11
    sw $r10, 466($r28)
    addi $r10, $r0, 123
    sll $r10, $r10, 9
    addi $r11, $r0, 274
    or $r10, $r10, $r11
    sw $r10, 467($r28)
    addi $r10, $r0, 516
    sll $r10, $r10, 9
    addi $r11, $r0, 274
    or $r10, $r10, $r11
    sw $r10, 468($r28)
    addi $r10, $r0, 124
    sll $r10, $r10, 9
    addi $r11, $r0, 276
    or $r10, $r10, $r11
    sw $r10, 469($r28)
    addi $r10, $r0, 124
    sll $r10, $r10, 9
    addi $r11, $r0, 277
    or $r10, $r10, $r11
    sw $r10, 470($r28)
    addi $r10, $r0, 515
    sll $r10, $r10, 9
    addi $r11, $r0, 277
    or $r10, $r10, $r11
    sw $r10, 471($r28)
    addi $r10, $r0, 125
    sll $r10, $r10, 9
    addi $r11, $r0, 279
    or $r10, $r10, $r11
    sw $r10, 472($r28)
    addi $r10, $r0, 125
    sll $r10, $r10, 9
    addi $r11, $r0, 280
    or $r10, $r10, $r11
    sw $r10, 473($r28)
    addi $r10, $r0, 514
    sll $r10, $r10, 9
    addi $r11, $r0, 280
    or $r10, $r10, $r11
    sw $r10, 474($r28)
    addi $r10, $r0, 126
    sll $r10, $r10, 9
    addi $r11, $r0, 282
    or $r10, $r10, $r11
    sw $r10, 475($r28)
    addi $r10, $r0, 126
    sll $r10, $r10, 9
    addi $r11, $r0, 283
    or $r10, $r10, $r11
    sw $r10, 476($r28)
    addi $r10, $r0, 513
    sll $r10, $r10, 9
    addi $r11, $r0, 283
    or $r10, $r10, $r11
    sw $r10, 477($r28)
    addi $r10, $r0, 513
    sll $r10, $r10, 9
    addi $r11, $r0, 284
    or $r10, $r10, $r11
    sw $r10, 478($r28)
    addi $r10, $r0, 127
    sll $r10, $r10, 9
    addi $r11, $r0, 285
    or $r10, $r10, $r11
    sw $r10, 479($r28)
    addi $r10, $r0, 127
    sll $r10, $r10, 9
    addi $r11, $r0, 286
    or $r10, $r10, $r11
    sw $r10, 480($r28)
    addi $r10, $r0, 512
    sll $r10, $r10, 9
    addi $r11, $r0, 286
    or $r10, $r10, $r11
    sw $r10, 481($r28)
    addi $r10, $r0, 512
    sll $r10, $r10, 9
    addi $r11, $r0, 287
    or $r10, $r10, $r11
    sw $r10, 482($r28)
    addi $r10, $r0, 128
    sll $r10, $r10, 9
    addi $r11, $r0, 288
    or $r10, $r10, $r11
    sw $r10, 483($r28)
    addi $r10, $r0, 128
    sll $r10, $r10, 9
    addi $r11, $r0, 289
    or $r10, $r10, $r11
    sw $r10, 484($r28)
    addi $r10, $r0, 511
    sll $r10, $r10, 9
    addi $r11, $r0, 289
    or $r10, $r10, $r11
    sw $r10, 485($r28)
    addi $r10, $r0, 511
    sll $r10, $r10, 9
    addi $r11, $r0, 290
    or $r10, $r10, $r11
    sw $r10, 486($r28)
    addi $r10, $r0, 129
    sll $r10, $r10, 9
    addi $r11, $r0, 291
    or $r10, $r10, $r11
    sw $r10, 487($r28)
    addi $r10, $r0, 129
    sll $r10, $r10, 9
    addi $r11, $r0, 292
    or $r10, $r10, $r11
    sw $r10, 488($r28)
    addi $r10, $r0, 510
    sll $r10, $r10, 9
    addi $r11, $r0, 292
    or $r10, $r10, $r11
    sw $r10, 489($r28)
    addi $r10, $r0, 510
    sll $r10, $r10, 9
    addi $r11, $r0, 293
    or $r10, $r10, $r11
    sw $r10, 490($r28)
    addi $r10, $r0, 130
    sll $r10, $r10, 9
    addi $r11, $r0, 295
    or $r10, $r10, $r11
    sw $r10, 491($r28)
    addi $r10, $r0, 509
    sll $r10, $r10, 9
    addi $r11, $r0, 295
    or $r10, $r10, $r11
    sw $r10, 492($r28)
    addi $r10, $r0, 509
    sll $r10, $r10, 9
    addi $r11, $r0, 296
    or $r10, $r10, $r11
    sw $r10, 493($r28)
    addi $r10, $r0, 131
    sll $r10, $r10, 9
    addi $r11, $r0, 298
    or $r10, $r10, $r11
    sw $r10, 494($r28)
    addi $r10, $r0, 508
    sll $r10, $r10, 9
    addi $r11, $r0, 298
    or $r10, $r10, $r11
    sw $r10, 495($r28)
    addi $r10, $r0, 508
    sll $r10, $r10, 9
    addi $r11, $r0, 299
    or $r10, $r10, $r11
    sw $r10, 496($r28)
    addi $r10, $r0, 132
    sll $r10, $r10, 9
    addi $r11, $r0, 301
    or $r10, $r10, $r11
    sw $r10, 497($r28)
    addi $r10, $r0, 507
    sll $r10, $r10, 9
    addi $r11, $r0, 301
    or $r10, $r10, $r11
    sw $r10, 498($r28)
    addi $r10, $r0, 507
    sll $r10, $r10, 9
    addi $r11, $r0, 302
    or $r10, $r10, $r11
    sw $r10, 499($r28)
    addi $r10, $r0, 133
    sll $r10, $r10, 9
    addi $r11, $r0, 304
    or $r10, $r10, $r11
    sw $r10, 500($r28)
    addi $r10, $r0, 506
    sll $r10, $r10, 9
    addi $r11, $r0, 304
    or $r10, $r10, $r11
    sw $r10, 501($r28)
    addi $r10, $r0, 506
    sll $r10, $r10, 9
    addi $r11, $r0, 305
    or $r10, $r10, $r11
    sw $r10, 502($r28)
    addi $r10, $r0, 134
    sll $r10, $r10, 9
    addi $r11, $r0, 307
    or $r10, $r10, $r11
    sw $r10, 503($r28)
    addi $r10, $r0, 505
    sll $r10, $r10, 9
    addi $r11, $r0, 307
    or $r10, $r10, $r11
    sw $r10, 504($r28)
    addi $r10, $r0, 505
    sll $r10, $r10, 9
    addi $r11, $r0, 308
    or $r10, $r10, $r11
    sw $r10, 505($r28)
    addi $r10, $r0, 135
    sll $r10, $r10, 9
    addi $r11, $r0, 310
    or $r10, $r10, $r11
    sw $r10, 506($r28)
    addi $r10, $r0, 504
    sll $r10, $r10, 9
    addi $r11, $r0, 310
    or $r10, $r10, $r11
    sw $r10, 507($r28)
    addi $r10, $r0, 135
    sll $r10, $r10, 9
    addi $r11, $r0, 311
    or $r10, $r10, $r11
    sw $r10, 508($r28)
    addi $r10, $r0, 504
    sll $r10, $r10, 9
    addi $r11, $r0, 311
    or $r10, $r10, $r11
    sw $r10, 509($r28)
    addi $r10, $r0, 136
    sll $r10, $r10, 9
    addi $r11, $r0, 313
    or $r10, $r10, $r11
    sw $r10, 510($r28)
    addi $r10, $r0, 503
    sll $r10, $r10, 9
    addi $r11, $r0, 313
    or $r10, $r10, $r11
    sw $r10, 511($r28)
    addi $r10, $r0, 136
    sll $r10, $r10, 9
    addi $r11, $r0, 314
    or $r10, $r10, $r11
    sw $r10, 512($r28)
    addi $r10, $r0, 503
    sll $r10, $r10, 9
    addi $r11, $r0, 314
    or $r10, $r10, $r11
    sw $r10, 513($r28)
    addi $r10, $r0, 137
    sll $r10, $r10, 9
    addi $r11, $r0, 316
    or $r10, $r10, $r11
    sw $r10, 514($r28)
    addi $r10, $r0, 502
    sll $r10, $r10, 9
    addi $r11, $r0, 316
    or $r10, $r10, $r11
    sw $r10, 515($r28)
    addi $r10, $r0, 137
    sll $r10, $r10, 9
    addi $r11, $r0, 317
    or $r10, $r10, $r11
    sw $r10, 516($r28)
    addi $r10, $r0, 502
    sll $r10, $r10, 9
    addi $r11, $r0, 317
    or $r10, $r10, $r11
    sw $r10, 517($r28)
    addi $r10, $r0, 138
    sll $r10, $r10, 9
    addi $r11, $r0, 319
    or $r10, $r10, $r11
    sw $r10, 518($r28)
    addi $r10, $r0, 138
    sll $r10, $r10, 9
    addi $r11, $r0, 320
    or $r10, $r10, $r11
    sw $r10, 519($r28)
    addi $r10, $r0, 501
    sll $r10, $r10, 9
    addi $r11, $r0, 320
    or $r10, $r10, $r11
    sw $r10, 520($r28)
    addi $r10, $r0, 139
    sll $r10, $r10, 9
    addi $r11, $r0, 322
    or $r10, $r10, $r11
    sw $r10, 521($r28)
    addi $r10, $r0, 139
    sll $r10, $r10, 9
    addi $r11, $r0, 323
    or $r10, $r10, $r11
    sw $r10, 522($r28)
    addi $r10, $r0, 500
    sll $r10, $r10, 9
    addi $r11, $r0, 323
    or $r10, $r10, $r11
    sw $r10, 523($r28)
    addi $r10, $r0, 140
    sll $r10, $r10, 9
    addi $r11, $r0, 325
    or $r10, $r10, $r11
    sw $r10, 524($r28)
    addi $r10, $r0, 140
    sll $r10, $r10, 9
    addi $r11, $r0, 326
    or $r10, $r10, $r11
    sw $r10, 525($r28)
    addi $r10, $r0, 499
    sll $r10, $r10, 9
    addi $r11, $r0, 326
    or $r10, $r10, $r11
    sw $r10, 526($r28)
    addi $r10, $r0, 499
    sll $r10, $r10, 9
    addi $r11, $r0, 327
    or $r10, $r10, $r11
    sw $r10, 527($r28)
    addi $r10, $r0, 141
    sll $r10, $r10, 9
    addi $r11, $r0, 328
    or $r10, $r10, $r11
    sw $r10, 528($r28)
    addi $r10, $r0, 141
    sll $r10, $r10, 9
    addi $r11, $r0, 329
    or $r10, $r10, $r11
    sw $r10, 529($r28)
    addi $r10, $r0, 498
    sll $r10, $r10, 9
    addi $r11, $r0, 329
    or $r10, $r10, $r11
    sw $r10, 530($r28)
    addi $r10, $r0, 498
    sll $r10, $r10, 9
    addi $r11, $r0, 330
    or $r10, $r10, $r11
    sw $r10, 531($r28)
    addi $r10, $r0, 142
    sll $r10, $r10, 9
    addi $r11, $r0, 331
    or $r10, $r10, $r11
    sw $r10, 532($r28)
    addi $r10, $r0, 142
    sll $r10, $r10, 9
    addi $r11, $r0, 332
    or $r10, $r10, $r11
    sw $r10, 533($r28)
    addi $r10, $r0, 497
    sll $r10, $r10, 9
    addi $r11, $r0, 332
    or $r10, $r10, $r11
    sw $r10, 534($r28)
    addi $r10, $r0, 497
    sll $r10, $r10, 9
    addi $r11, $r0, 333
    or $r10, $r10, $r11
    sw $r10, 535($r28)
    addi $r10, $r0, 143
    sll $r10, $r10, 9
    addi $r11, $r0, 335
    or $r10, $r10, $r11
    sw $r10, 536($r28)
    addi $r10, $r0, 496
    sll $r10, $r10, 9
    addi $r11, $r0, 335
    or $r10, $r10, $r11
    sw $r10, 537($r28)
    addi $r10, $r0, 496
    sll $r10, $r10, 9
    addi $r11, $r0, 336
    or $r10, $r10, $r11
    sw $r10, 538($r28)
    addi $r10, $r0, 144
    sll $r10, $r10, 9
    addi $r11, $r0, 338
    or $r10, $r10, $r11
    sw $r10, 539($r28)
    addi $r10, $r0, 495
    sll $r10, $r10, 9
    addi $r11, $r0, 338
    or $r10, $r10, $r11
    sw $r10, 540($r28)
    addi $r10, $r0, 495
    sll $r10, $r10, 9
    addi $r11, $r0, 339
    or $r10, $r10, $r11
    sw $r10, 541($r28)
    addi $r10, $r0, 145
    sll $r10, $r10, 9
    addi $r11, $r0, 341
    or $r10, $r10, $r11
    sw $r10, 542($r28)
    addi $r10, $r0, 494
    sll $r10, $r10, 9
    addi $r11, $r0, 341
    or $r10, $r10, $r11
    sw $r10, 543($r28)
    addi $r10, $r0, 494
    sll $r10, $r10, 9
    addi $r11, $r0, 342
    or $r10, $r10, $r11
    sw $r10, 544($r28)
    addi $r10, $r0, 146
    sll $r10, $r10, 9
    addi $r11, $r0, 344
    or $r10, $r10, $r11
    sw $r10, 545($r28)
    addi $r10, $r0, 493
    sll $r10, $r10, 9
    addi $r11, $r0, 344
    or $r10, $r10, $r11
    sw $r10, 546($r28)
    addi $r10, $r0, 493
    sll $r10, $r10, 9
    addi $r11, $r0, 345
    or $r10, $r10, $r11
    sw $r10, 547($r28)
    addi $r10, $r0, 147
    sll $r10, $r10, 9
    addi $r11, $r0, 347
    or $r10, $r10, $r11
    sw $r10, 548($r28)
    addi $r10, $r0, 492
    sll $r10, $r10, 9
    addi $r11, $r0, 347
    or $r10, $r10, $r11
    sw $r10, 549($r28)
    addi $r10, $r0, 147
    sll $r10, $r10, 9
    addi $r11, $r0, 348
    or $r10, $r10, $r11
    sw $r10, 550($r28)
    addi $r10, $r0, 492
    sll $r10, $r10, 9
    addi $r11, $r0, 348
    or $r10, $r10, $r11
    sw $r10, 551($r28)
    addi $r10, $r0, 148
    sll $r10, $r10, 9
    addi $r11, $r0, 350
    or $r10, $r10, $r11
    sw $r10, 552($r28)
    addi $r10, $r0, 491
    sll $r10, $r10, 9
    addi $r11, $r0, 350
    or $r10, $r10, $r11
    sw $r10, 553($r28)
    addi $r10, $r0, 148
    sll $r10, $r10, 9
    addi $r11, $r0, 351
    or $r10, $r10, $r11
    sw $r10, 554($r28)
    addi $r10, $r0, 491
    sll $r10, $r10, 9
    addi $r11, $r0, 351
    or $r10, $r10, $r11
    sw $r10, 555($r28)
    addi $r10, $r0, 149
    sll $r10, $r10, 9
    addi $r11, $r0, 353
    or $r10, $r10, $r11
    sw $r10, 556($r28)
    addi $r10, $r0, 490
    sll $r10, $r10, 9
    addi $r11, $r0, 353
    or $r10, $r10, $r11
    sw $r10, 557($r28)
    addi $r10, $r0, 149
    sll $r10, $r10, 9
    addi $r11, $r0, 354
    or $r10, $r10, $r11
    sw $r10, 558($r28)
    addi $r10, $r0, 490
    sll $r10, $r10, 9
    addi $r11, $r0, 354
    or $r10, $r10, $r11
    sw $r10, 559($r28)
    addi $r10, $r0, 150
    sll $r10, $r10, 9
    addi $r11, $r0, 356
    or $r10, $r10, $r11
    sw $r10, 560($r28)
    addi $r10, $r0, 489
    sll $r10, $r10, 9
    addi $r11, $r0, 356
    or $r10, $r10, $r11
    sw $r10, 561($r28)
    addi $r10, $r0, 150
    sll $r10, $r10, 9
    addi $r11, $r0, 357
    or $r10, $r10, $r11
    sw $r10, 562($r28)
    addi $r10, $r0, 489
    sll $r10, $r10, 9
    addi $r11, $r0, 357
    or $r10, $r10, $r11
    sw $r10, 563($r28)
    addi $r10, $r0, 151
    sll $r10, $r10, 9
    addi $r11, $r0, 359
    or $r10, $r10, $r11
    sw $r10, 564($r28)
    addi $r10, $r0, 151
    sll $r10, $r10, 9
    addi $r11, $r0, 360
    or $r10, $r10, $r11
    sw $r10, 565($r28)
    addi $r10, $r0, 488
    sll $r10, $r10, 9
    addi $r11, $r0, 360
    or $r10, $r10, $r11
    sw $r10, 566($r28)
    addi $r10, $r0, 152
    sll $r10, $r10, 9
    addi $r11, $r0, 362
    or $r10, $r10, $r11
    sw $r10, 567($r28)
    addi $r10, $r0, 152
    sll $r10, $r10, 9
    addi $r11, $r0, 363
    or $r10, $r10, $r11
    sw $r10, 568($r28)
    addi $r10, $r0, 487
    sll $r10, $r10, 9
    addi $r11, $r0, 363
    or $r10, $r10, $r11
    sw $r10, 569($r28)
    addi $r10, $r0, 153
    sll $r10, $r10, 9
    addi $r11, $r0, 365
    or $r10, $r10, $r11
    sw $r10, 570($r28)
    addi $r10, $r0, 153
    sll $r10, $r10, 9
    addi $r11, $r0, 366
    or $r10, $r10, $r11
    sw $r10, 571($r28)
    addi $r10, $r0, 486
    sll $r10, $r10, 9
    addi $r11, $r0, 366
    or $r10, $r10, $r11
    sw $r10, 572($r28)
    addi $r10, $r0, 154
    sll $r10, $r10, 9
    addi $r11, $r0, 368
    or $r10, $r10, $r11
    sw $r10, 573($r28)
    addi $r10, $r0, 154
    sll $r10, $r10, 9
    addi $r11, $r0, 369
    or $r10, $r10, $r11
    sw $r10, 574($r28)
    addi $r10, $r0, 485
    sll $r10, $r10, 9
    addi $r11, $r0, 369
    or $r10, $r10, $r11
    sw $r10, 575($r28)
    addi $r10, $r0, 155
    sll $r10, $r10, 9
    addi $r11, $r0, 371
    or $r10, $r10, $r11
    sw $r10, 576($r28)
    addi $r10, $r0, 155
    sll $r10, $r10, 9
    addi $r11, $r0, 372
    or $r10, $r10, $r11
    sw $r10, 577($r28)
    addi $r10, $r0, 484
    sll $r10, $r10, 9
    addi $r11, $r0, 372
    or $r10, $r10, $r11
    sw $r10, 578($r28)
    addi $r10, $r0, 484
    sll $r10, $r10, 9
    addi $r11, $r0, 373
    or $r10, $r10, $r11
    sw $r10, 579($r28)
    addi $r10, $r0, 156
    sll $r10, $r10, 9
    addi $r11, $r0, 375
    or $r10, $r10, $r11
    sw $r10, 580($r28)
    addi $r10, $r0, 483
    sll $r10, $r10, 9
    addi $r11, $r0, 375
    or $r10, $r10, $r11
    sw $r10, 581($r28)
    addi $r10, $r0, 483
    sll $r10, $r10, 9
    addi $r11, $r0, 376
    or $r10, $r10, $r11
    sw $r10, 582($r28)
    addi $r10, $r0, 157
    sll $r10, $r10, 9
    addi $r11, $r0, 378
    or $r10, $r10, $r11
    sw $r10, 583($r28)
    addi $r10, $r0, 482
    sll $r10, $r10, 9
    addi $r11, $r0, 378
    or $r10, $r10, $r11
    sw $r10, 584($r28)
    addi $r10, $r0, 482
    sll $r10, $r10, 9
    addi $r11, $r0, 379
    or $r10, $r10, $r11
    sw $r10, 585($r28)
    addi $r10, $r0, 158
    sll $r10, $r10, 9
    addi $r11, $r0, 381
    or $r10, $r10, $r11
    sw $r10, 586($r28)
    addi $r10, $r0, 481
    sll $r10, $r10, 9
    addi $r11, $r0, 381
    or $r10, $r10, $r11
    sw $r10, 587($r28)
    addi $r10, $r0, 481
    sll $r10, $r10, 9
    addi $r11, $r0, 382
    or $r10, $r10, $r11
    sw $r10, 588($r28)
    addi $r10, $r0, 159
    sll $r10, $r10, 9
    addi $r11, $r0, 384
    or $r10, $r10, $r11
    sw $r10, 589($r28)
    addi $r10, $r0, 480
    sll $r10, $r10, 9
    addi $r11, $r0, 384
    or $r10, $r10, $r11
    sw $r10, 590($r28)
    addi $r10, $r0, 480
    sll $r10, $r10, 9
    addi $r11, $r0, 385
    or $r10, $r10, $r11
    sw $r10, 591($r28)
    addi $r10, $r0, 160
    sll $r10, $r10, 9
    addi $r11, $r0, 387
    or $r10, $r10, $r11
    sw $r10, 592($r28)
    addi $r10, $r0, 479
    sll $r10, $r10, 9
    addi $r11, $r0, 387
    or $r10, $r10, $r11
    sw $r10, 593($r28)
    addi $r10, $r0, 160
    sll $r10, $r10, 9
    addi $r11, $r0, 388
    or $r10, $r10, $r11
    sw $r10, 594($r28)
    addi $r10, $r0, 479
    sll $r10, $r10, 9
    addi $r11, $r0, 388
    or $r10, $r10, $r11
    sw $r10, 595($r28)
    addi $r10, $r0, 161
    sll $r10, $r10, 9
    addi $r11, $r0, 390
    or $r10, $r10, $r11
    sw $r10, 596($r28)
    addi $r10, $r0, 478
    sll $r10, $r10, 9
    addi $r11, $r0, 390
    or $r10, $r10, $r11
    sw $r10, 597($r28)
    addi $r10, $r0, 161
    sll $r10, $r10, 9
    addi $r11, $r0, 391
    or $r10, $r10, $r11
    sw $r10, 598($r28)
    addi $r10, $r0, 478
    sll $r10, $r10, 9
    addi $r11, $r0, 391
    or $r10, $r10, $r11
    sw $r10, 599($r28)
    addi $r10, $r0, 162
    sll $r10, $r10, 9
    addi $r11, $r0, 393
    or $r10, $r10, $r11
    sw $r10, 600($r28)
    addi $r10, $r0, 477
    sll $r10, $r10, 9
    addi $r11, $r0, 393
    or $r10, $r10, $r11
    sw $r10, 601($r28)
    addi $r10, $r0, 162
    sll $r10, $r10, 9
    addi $r11, $r0, 394
    or $r10, $r10, $r11
    sw $r10, 602($r28)
    addi $r10, $r0, 477
    sll $r10, $r10, 9
    addi $r11, $r0, 394
    or $r10, $r10, $r11
    sw $r10, 603($r28)
    addi $r10, $r0, 163
    sll $r10, $r10, 9
    addi $r11, $r0, 396
    or $r10, $r10, $r11
    sw $r10, 604($r28)
    addi $r10, $r0, 476
    sll $r10, $r10, 9
    addi $r11, $r0, 396
    or $r10, $r10, $r11
    sw $r10, 605($r28)
    addi $r10, $r0, 163
    sll $r10, $r10, 9
    addi $r11, $r0, 397
    or $r10, $r10, $r11
    sw $r10, 606($r28)
    addi $r10, $r0, 476
    sll $r10, $r10, 9
    addi $r11, $r0, 397
    or $r10, $r10, $r11
    sw $r10, 607($r28)
    addi $r10, $r0, 164
    sll $r10, $r10, 9
    addi $r11, $r0, 399
    or $r10, $r10, $r11
    sw $r10, 608($r28)
    addi $r10, $r0, 475
    sll $r10, $r10, 9
    addi $r11, $r0, 399
    or $r10, $r10, $r11
    sw $r10, 609($r28)
    addi $r10, $r0, 164
    sll $r10, $r10, 9
    addi $r11, $r0, 400
    or $r10, $r10, $r11
    sw $r10, 610($r28)
    addi $r10, $r0, 475
    sll $r10, $r10, 9
    addi $r11, $r0, 400
    or $r10, $r10, $r11
    sw $r10, 611($r28)
    addi $r10, $r0, 165
    sll $r10, $r10, 9
    addi $r11, $r0, 402
    or $r10, $r10, $r11
    sw $r10, 612($r28)
    addi $r10, $r0, 474
    sll $r10, $r10, 9
    addi $r11, $r0, 402
    or $r10, $r10, $r11
    sw $r10, 613($r28)
    addi $r10, $r0, 165
    sll $r10, $r10, 9
    addi $r11, $r0, 403
    or $r10, $r10, $r11
    sw $r10, 614($r28)
    addi $r10, $r0, 474
    sll $r10, $r10, 9
    addi $r11, $r0, 403
    or $r10, $r10, $r11
    sw $r10, 615($r28)
    addi $r10, $r0, 166
    sll $r10, $r10, 9
    addi $r11, $r0, 405
    or $r10, $r10, $r11
    sw $r10, 616($r28)
    addi $r10, $r0, 166
    sll $r10, $r10, 9
    addi $r11, $r0, 406
    or $r10, $r10, $r11
    sw $r10, 617($r28)
    addi $r10, $r0, 473
    sll $r10, $r10, 9
    addi $r11, $r0, 406
    or $r10, $r10, $r11
    sw $r10, 618($r28)
    addi $r10, $r0, 167
    sll $r10, $r10, 9
    addi $r11, $r0, 408
    or $r10, $r10, $r11
    sw $r10, 619($r28)
    addi $r10, $r0, 167
    sll $r10, $r10, 9
    addi $r11, $r0, 409
    or $r10, $r10, $r11
    sw $r10, 620($r28)
    addi $r10, $r0, 472
    sll $r10, $r10, 9
    addi $r11, $r0, 409
    or $r10, $r10, $r11
    sw $r10, 621($r28)
    addi $r10, $r0, 168
    sll $r10, $r10, 9
    addi $r11, $r0, 411
    or $r10, $r10, $r11
    sw $r10, 622($r28)
    addi $r10, $r0, 168
    sll $r10, $r10, 9
    addi $r11, $r0, 412
    or $r10, $r10, $r11
    sw $r10, 623($r28)
    addi $r10, $r0, 471
    sll $r10, $r10, 9
    addi $r11, $r0, 412
    or $r10, $r10, $r11
    sw $r10, 624($r28)
    addi $r10, $r0, 169
    sll $r10, $r10, 9
    addi $r11, $r0, 415
    or $r10, $r10, $r11
    sw $r10, 625($r28)
    addi $r10, $r0, 470
    sll $r10, $r10, 9
    addi $r11, $r0, 415
    or $r10, $r10, $r11
    sw $r10, 626($r28)
    addi $r10, $r0, 470
    sll $r10, $r10, 9
    addi $r11, $r0, 416
    or $r10, $r10, $r11
    sw $r10, 627($r28)
    addi $r10, $r0, 170
    sll $r10, $r10, 9
    addi $r11, $r0, 418
    or $r10, $r10, $r11
    sw $r10, 628($r28)
    addi $r10, $r0, 469
    sll $r10, $r10, 9
    addi $r11, $r0, 418
    or $r10, $r10, $r11
    sw $r10, 629($r28)
    addi $r10, $r0, 170
    sll $r10, $r10, 9
    addi $r11, $r0, 419
    or $r10, $r10, $r11
    sw $r10, 630($r28)
    addi $r10, $r0, 469
    sll $r10, $r10, 9
    addi $r11, $r0, 419
    or $r10, $r10, $r11
    sw $r10, 631($r28)
    addi $r10, $r0, 171
    sll $r10, $r10, 9
    addi $r11, $r0, 421
    or $r10, $r10, $r11
    sw $r10, 632($r28)
    addi $r10, $r0, 468
    sll $r10, $r10, 9
    addi $r11, $r0, 421
    or $r10, $r10, $r11
    sw $r10, 633($r28)
    addi $r10, $r0, 468
    sll $r10, $r10, 9
    addi $r11, $r0, 422
    or $r10, $r10, $r11
    sw $r10, 634($r28)
    addi $r10, $r0, 172
    sll $r10, $r10, 9
    addi $r11, $r0, 424
    or $r10, $r10, $r11
    sw $r10, 635($r28)
    addi $r10, $r0, 467
    sll $r10, $r10, 9
    addi $r11, $r0, 424
    or $r10, $r10, $r11
    sw $r10, 636($r28)
    addi $r10, $r0, 172
    sll $r10, $r10, 9
    addi $r11, $r0, 425
    or $r10, $r10, $r11
    sw $r10, 637($r28)
    addi $r10, $r0, 467
    sll $r10, $r10, 9
    addi $r11, $r0, 425
    or $r10, $r10, $r11
    sw $r10, 638($r28)
    addi $r10, $r0, 173
    sll $r10, $r10, 9
    addi $r11, $r0, 427
    or $r10, $r10, $r11
    sw $r10, 639($r28)
    addi $r10, $r0, 466
    sll $r10, $r10, 9
    addi $r11, $r0, 427
    or $r10, $r10, $r11
    sw $r10, 640($r28)
    addi $r10, $r0, 173
    sll $r10, $r10, 9
    addi $r11, $r0, 428
    or $r10, $r10, $r11
    sw $r10, 641($r28)
    addi $r10, $r0, 466
    sll $r10, $r10, 9
    addi $r11, $r0, 428
    or $r10, $r10, $r11
    sw $r10, 642($r28)
    addi $r10, $r0, 174
    sll $r10, $r10, 9
    addi $r11, $r0, 430
    or $r10, $r10, $r11
    sw $r10, 643($r28)
    addi $r10, $r0, 465
    sll $r10, $r10, 9
    addi $r11, $r0, 430
    or $r10, $r10, $r11
    sw $r10, 644($r28)
    addi $r10, $r0, 174
    sll $r10, $r10, 9
    addi $r11, $r0, 431
    or $r10, $r10, $r11
    sw $r10, 645($r28)
    addi $r10, $r0, 465
    sll $r10, $r10, 9
    addi $r11, $r0, 431
    or $r10, $r10, $r11
    sw $r10, 646($r28)
    addi $r10, $r0, 175
    sll $r10, $r10, 9
    addi $r11, $r0, 433
    or $r10, $r10, $r11
    sw $r10, 647($r28)
    addi $r10, $r0, 464
    sll $r10, $r10, 9
    addi $r11, $r0, 433
    or $r10, $r10, $r11
    sw $r10, 648($r28)
    addi $r10, $r0, 175
    sll $r10, $r10, 9
    addi $r11, $r0, 434
    or $r10, $r10, $r11
    sw $r10, 649($r28)
    addi $r10, $r0, 464
    sll $r10, $r10, 9
    addi $r11, $r0, 434
    or $r10, $r10, $r11
    sw $r10, 650($r28)
    addi $r10, $r0, 176
    sll $r10, $r10, 9
    addi $r11, $r0, 436
    or $r10, $r10, $r11
    sw $r10, 651($r28)
    addi $r10, $r0, 463
    sll $r10, $r10, 9
    addi $r11, $r0, 436
    or $r10, $r10, $r11
    sw $r10, 652($r28)
    addi $r10, $r0, 176
    sll $r10, $r10, 9
    addi $r11, $r0, 437
    or $r10, $r10, $r11
    sw $r10, 653($r28)
    addi $r10, $r0, 463
    sll $r10, $r10, 9
    addi $r11, $r0, 437
    or $r10, $r10, $r11
    sw $r10, 654($r28)
    addi $r10, $r0, 177
    sll $r10, $r10, 9
    addi $r11, $r0, 439
    or $r10, $r10, $r11
    sw $r10, 655($r28)
    addi $r10, $r0, 462
    sll $r10, $r10, 9
    addi $r11, $r0, 439
    or $r10, $r10, $r11
    sw $r10, 656($r28)
    addi $r10, $r0, 177
    sll $r10, $r10, 9
    addi $r11, $r0, 440
    or $r10, $r10, $r11
    sw $r10, 657($r28)
    addi $r10, $r0, 462
    sll $r10, $r10, 9
    addi $r11, $r0, 440
    or $r10, $r10, $r11
    sw $r10, 658($r28)
    addi $r10, $r0, 178
    sll $r10, $r10, 9
    addi $r11, $r0, 442
    or $r10, $r10, $r11
    sw $r10, 659($r28)
    addi $r10, $r0, 461
    sll $r10, $r10, 9
    addi $r11, $r0, 442
    or $r10, $r10, $r11
    sw $r10, 660($r28)
    addi $r10, $r0, 178
    sll $r10, $r10, 9
    addi $r11, $r0, 443
    or $r10, $r10, $r11
    sw $r10, 661($r28)
    addi $r10, $r0, 461
    sll $r10, $r10, 9
    addi $r11, $r0, 443
    or $r10, $r10, $r11
    sw $r10, 662($r28)
    addi $r10, $r0, 179
    sll $r10, $r10, 9
    addi $r11, $r0, 446
    or $r10, $r10, $r11
    sw $r10, 663($r28)
    addi $r10, $r0, 460
    sll $r10, $r10, 9
    addi $r11, $r0, 446
    or $r10, $r10, $r11
    sw $r10, 664($r28)
    addi $r10, $r0, 180
    sll $r10, $r10, 9
    addi $r11, $r0, 449
    or $r10, $r10, $r11
    sw $r10, 665($r28)
    addi $r10, $r0, 459
    sll $r10, $r10, 9
    addi $r11, $r0, 449
    or $r10, $r10, $r11
    sw $r10, 666($r28)
    addi $r10, $r0, 181
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 667($r28)
    addi $r10, $r0, 182
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 668($r28)
    addi $r10, $r0, 183
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 669($r28)
    addi $r10, $r0, 184
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 670($r28)
    addi $r10, $r0, 185
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 671($r28)
    addi $r10, $r0, 186
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 672($r28)
    addi $r10, $r0, 187
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 673($r28)
    addi $r10, $r0, 188
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 674($r28)
    addi $r10, $r0, 189
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 675($r28)
    addi $r10, $r0, 190
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 676($r28)
    addi $r10, $r0, 191
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 677($r28)
    addi $r10, $r0, 192
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 678($r28)
    addi $r10, $r0, 193
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 679($r28)
    addi $r10, $r0, 194
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 680($r28)
    addi $r10, $r0, 195
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 681($r28)
    addi $r10, $r0, 196
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 682($r28)
    addi $r10, $r0, 197
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 683($r28)
    addi $r10, $r0, 198
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 684($r28)
    addi $r10, $r0, 199
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 685($r28)
    addi $r10, $r0, 200
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 686($r28)
    addi $r10, $r0, 201
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 687($r28)
    addi $r10, $r0, 202
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 688($r28)
    addi $r10, $r0, 203
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 689($r28)
    addi $r10, $r0, 204
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 690($r28)
    addi $r10, $r0, 205
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 691($r28)
    addi $r10, $r0, 206
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 692($r28)
    addi $r10, $r0, 207
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 693($r28)
    addi $r10, $r0, 208
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 694($r28)
    addi $r10, $r0, 209
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 695($r28)
    addi $r10, $r0, 210
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 696($r28)
    addi $r10, $r0, 211
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 697($r28)
    addi $r10, $r0, 212
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 698($r28)
    addi $r10, $r0, 213
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 699($r28)
    addi $r10, $r0, 214
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 700($r28)
    addi $r10, $r0, 215
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 701($r28)
    addi $r10, $r0, 216
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 702($r28)
    addi $r10, $r0, 217
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 703($r28)
    addi $r10, $r0, 218
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 704($r28)
    addi $r10, $r0, 219
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 705($r28)
    addi $r10, $r0, 220
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 706($r28)
    addi $r10, $r0, 221
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 707($r28)
    addi $r10, $r0, 222
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 708($r28)
    addi $r10, $r0, 223
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 709($r28)
    addi $r10, $r0, 224
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 710($r28)
    addi $r10, $r0, 225
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 711($r28)
    addi $r10, $r0, 226
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 712($r28)
    addi $r10, $r0, 227
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 713($r28)
    addi $r10, $r0, 228
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 714($r28)
    addi $r10, $r0, 229
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 715($r28)
    addi $r10, $r0, 230
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 716($r28)
    addi $r10, $r0, 231
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 717($r28)
    addi $r10, $r0, 232
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 718($r28)
    addi $r10, $r0, 233
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 719($r28)
    addi $r10, $r0, 234
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 720($r28)
    addi $r10, $r0, 235
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 721($r28)
    addi $r10, $r0, 236
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 722($r28)
    addi $r10, $r0, 237
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 723($r28)
    addi $r10, $r0, 238
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 724($r28)
    addi $r10, $r0, 239
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 725($r28)
    addi $r10, $r0, 240
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 726($r28)
    addi $r10, $r0, 241
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 727($r28)
    addi $r10, $r0, 242
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 728($r28)
    addi $r10, $r0, 243
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 729($r28)
    addi $r10, $r0, 244
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 730($r28)
    addi $r10, $r0, 245
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 731($r28)
    addi $r10, $r0, 246
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 732($r28)
    addi $r10, $r0, 247
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 733($r28)
    addi $r10, $r0, 248
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 734($r28)
    addi $r10, $r0, 249
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 735($r28)
    addi $r10, $r0, 250
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 736($r28)
    addi $r10, $r0, 251
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 737($r28)
    addi $r10, $r0, 252
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 738($r28)
    addi $r10, $r0, 253
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 739($r28)
    addi $r10, $r0, 254
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 740($r28)
    addi $r10, $r0, 255
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 741($r28)
    addi $r10, $r0, 256
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 742($r28)
    addi $r10, $r0, 257
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 743($r28)
    addi $r10, $r0, 258
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 744($r28)
    addi $r10, $r0, 259
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 745($r28)
    addi $r10, $r0, 260
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 746($r28)
    addi $r10, $r0, 261
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 747($r28)
    addi $r10, $r0, 262
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 748($r28)
    addi $r10, $r0, 263
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 749($r28)
    addi $r10, $r0, 264
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 750($r28)
    addi $r10, $r0, 265
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 751($r28)
    addi $r10, $r0, 266
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 752($r28)
    addi $r10, $r0, 267
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 753($r28)
    addi $r10, $r0, 268
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 754($r28)
    addi $r10, $r0, 269
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 755($r28)
    addi $r10, $r0, 270
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 756($r28)
    addi $r10, $r0, 271
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 757($r28)
    addi $r10, $r0, 272
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 758($r28)
    addi $r10, $r0, 273
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 759($r28)
    addi $r10, $r0, 274
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 760($r28)
    addi $r10, $r0, 275
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 761($r28)
    addi $r10, $r0, 276
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 762($r28)
    addi $r10, $r0, 277
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 763($r28)
    addi $r10, $r0, 278
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 764($r28)
    addi $r10, $r0, 279
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 765($r28)
    addi $r10, $r0, 280
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 766($r28)
    addi $r10, $r0, 281
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 767($r28)
    addi $r10, $r0, 282
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 768($r28)
    addi $r10, $r0, 283
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 769($r28)
    addi $r10, $r0, 284
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 770($r28)
    addi $r10, $r0, 285
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 771($r28)
    addi $r10, $r0, 286
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 772($r28)
    addi $r10, $r0, 287
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 773($r28)
    addi $r10, $r0, 288
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 774($r28)
    addi $r10, $r0, 289
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 775($r28)
    addi $r10, $r0, 290
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 776($r28)
    addi $r10, $r0, 291
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 777($r28)
    addi $r10, $r0, 292
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 778($r28)
    addi $r10, $r0, 293
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 779($r28)
    addi $r10, $r0, 294
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 780($r28)
    addi $r10, $r0, 295
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 781($r28)
    addi $r10, $r0, 296
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 782($r28)
    addi $r10, $r0, 297
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 783($r28)
    addi $r10, $r0, 298
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 784($r28)
    addi $r10, $r0, 299
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 785($r28)
    addi $r10, $r0, 300
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 786($r28)
    addi $r10, $r0, 301
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 787($r28)
    addi $r10, $r0, 302
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 788($r28)
    addi $r10, $r0, 303
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 789($r28)
    addi $r10, $r0, 304
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 790($r28)
    addi $r10, $r0, 305
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 791($r28)
    addi $r10, $r0, 306
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 792($r28)
    addi $r10, $r0, 307
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 793($r28)
    addi $r10, $r0, 308
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 794($r28)
    addi $r10, $r0, 309
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 795($r28)
    addi $r10, $r0, 310
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 796($r28)
    addi $r10, $r0, 311
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 797($r28)
    addi $r10, $r0, 312
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 798($r28)
    addi $r10, $r0, 313
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 799($r28)
    addi $r10, $r0, 314
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 800($r28)
    addi $r10, $r0, 315
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 801($r28)
    addi $r10, $r0, 316
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 802($r28)
    addi $r10, $r0, 317
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 803($r28)
    addi $r10, $r0, 318
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 804($r28)
    addi $r10, $r0, 319
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 805($r28)
    addi $r10, $r0, 320
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 806($r28)
    addi $r10, $r0, 321
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 807($r28)
    addi $r10, $r0, 322
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 808($r28)
    addi $r10, $r0, 323
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 809($r28)
    addi $r10, $r0, 324
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 810($r28)
    addi $r10, $r0, 325
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 811($r28)
    addi $r10, $r0, 326
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 812($r28)
    addi $r10, $r0, 327
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 813($r28)
    addi $r10, $r0, 328
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 814($r28)
    addi $r10, $r0, 329
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 815($r28)
    addi $r10, $r0, 330
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 816($r28)
    addi $r10, $r0, 331
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 817($r28)
    addi $r10, $r0, 332
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 818($r28)
    addi $r10, $r0, 333
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 819($r28)
    addi $r10, $r0, 334
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 820($r28)
    addi $r10, $r0, 335
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 821($r28)
    addi $r10, $r0, 336
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 822($r28)
    addi $r10, $r0, 337
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 823($r28)
    addi $r10, $r0, 338
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 824($r28)
    addi $r10, $r0, 339
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 825($r28)
    addi $r10, $r0, 340
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 826($r28)
    addi $r10, $r0, 341
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 827($r28)
    addi $r10, $r0, 342
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 828($r28)
    addi $r10, $r0, 343
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 829($r28)
    addi $r10, $r0, 344
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 830($r28)
    addi $r10, $r0, 345
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 831($r28)
    addi $r10, $r0, 346
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 832($r28)
    addi $r10, $r0, 347
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 833($r28)
    addi $r10, $r0, 348
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 834($r28)
    addi $r10, $r0, 349
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 835($r28)
    addi $r10, $r0, 350
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 836($r28)
    addi $r10, $r0, 351
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 837($r28)
    addi $r10, $r0, 352
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 838($r28)
    addi $r10, $r0, 353
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 839($r28)
    addi $r10, $r0, 354
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 840($r28)
    addi $r10, $r0, 355
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 841($r28)
    addi $r10, $r0, 356
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 842($r28)
    addi $r10, $r0, 357
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 843($r28)
    addi $r10, $r0, 358
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 844($r28)
    addi $r10, $r0, 359
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 845($r28)
    addi $r10, $r0, 360
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 846($r28)
    addi $r10, $r0, 361
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 847($r28)
    addi $r10, $r0, 362
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 848($r28)
    addi $r10, $r0, 363
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 849($r28)
    addi $r10, $r0, 364
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 850($r28)
    addi $r10, $r0, 365
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 851($r28)
    addi $r10, $r0, 366
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 852($r28)
    addi $r10, $r0, 367
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 853($r28)
    addi $r10, $r0, 368
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 854($r28)
    addi $r10, $r0, 369
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 855($r28)
    addi $r10, $r0, 370
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 856($r28)
    addi $r10, $r0, 371
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 857($r28)
    addi $r10, $r0, 372
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 858($r28)
    addi $r10, $r0, 373
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 859($r28)
    addi $r10, $r0, 374
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 860($r28)
    addi $r10, $r0, 375
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 861($r28)
    addi $r10, $r0, 376
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 862($r28)
    addi $r10, $r0, 377
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 863($r28)
    addi $r10, $r0, 378
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 864($r28)
    addi $r10, $r0, 379
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 865($r28)
    addi $r10, $r0, 380
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 866($r28)
    addi $r10, $r0, 381
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 867($r28)
    addi $r10, $r0, 382
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 868($r28)
    addi $r10, $r0, 383
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 869($r28)
    addi $r10, $r0, 384
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 870($r28)
    addi $r10, $r0, 385
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 871($r28)
    addi $r10, $r0, 386
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 872($r28)
    addi $r10, $r0, 387
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 873($r28)
    addi $r10, $r0, 388
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 874($r28)
    addi $r10, $r0, 389
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 875($r28)
    addi $r10, $r0, 390
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 876($r28)
    addi $r10, $r0, 391
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 877($r28)
    addi $r10, $r0, 392
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 878($r28)
    addi $r10, $r0, 393
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 879($r28)
    addi $r10, $r0, 394
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 880($r28)
    addi $r10, $r0, 395
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 881($r28)
    addi $r10, $r0, 396
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 882($r28)
    addi $r10, $r0, 397
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 883($r28)
    addi $r10, $r0, 398
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 884($r28)
    addi $r10, $r0, 399
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 885($r28)
    addi $r10, $r0, 400
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 886($r28)
    addi $r10, $r0, 401
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 887($r28)
    addi $r10, $r0, 402
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 888($r28)
    addi $r10, $r0, 403
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 889($r28)
    addi $r10, $r0, 404
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 890($r28)
    addi $r10, $r0, 405
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 891($r28)
    addi $r10, $r0, 406
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 892($r28)
    addi $r10, $r0, 407
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 893($r28)
    addi $r10, $r0, 408
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 894($r28)
    addi $r10, $r0, 409
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 895($r28)
    addi $r10, $r0, 410
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 896($r28)
    addi $r10, $r0, 411
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 897($r28)
    addi $r10, $r0, 412
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 898($r28)
    addi $r10, $r0, 413
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 899($r28)
    addi $r10, $r0, 414
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 900($r28)
    addi $r10, $r0, 415
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 901($r28)
    addi $r10, $r0, 416
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 902($r28)
    addi $r10, $r0, 417
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 903($r28)
    addi $r10, $r0, 418
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 904($r28)
    addi $r10, $r0, 419
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 905($r28)
    addi $r10, $r0, 420
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 906($r28)
    addi $r10, $r0, 421
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 907($r28)
    addi $r10, $r0, 422
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 908($r28)
    addi $r10, $r0, 423
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 909($r28)
    addi $r10, $r0, 424
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 910($r28)
    addi $r10, $r0, 425
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 911($r28)
    addi $r10, $r0, 426
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 912($r28)
    addi $r10, $r0, 427
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 913($r28)
    addi $r10, $r0, 428
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 914($r28)
    addi $r10, $r0, 429
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 915($r28)
    addi $r10, $r0, 430
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 916($r28)
    addi $r10, $r0, 431
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 917($r28)
    addi $r10, $r0, 432
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 918($r28)
    addi $r10, $r0, 433
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 919($r28)
    addi $r10, $r0, 434
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 920($r28)
    addi $r10, $r0, 435
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 921($r28)
    addi $r10, $r0, 436
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 922($r28)
    addi $r10, $r0, 437
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 923($r28)
    addi $r10, $r0, 438
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 924($r28)
    addi $r10, $r0, 439
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 925($r28)
    addi $r10, $r0, 440
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 926($r28)
    addi $r10, $r0, 441
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 927($r28)
    addi $r10, $r0, 442
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 928($r28)
    addi $r10, $r0, 443
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 929($r28)
    addi $r10, $r0, 444
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 930($r28)
    addi $r10, $r0, 445
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 931($r28)
    addi $r10, $r0, 446
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 932($r28)
    addi $r10, $r0, 447
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 933($r28)
    addi $r10, $r0, 448
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 934($r28)
    addi $r10, $r0, 449
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 935($r28)
    addi $r10, $r0, 450
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 936($r28)
    addi $r10, $r0, 451
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 937($r28)
    addi $r10, $r0, 452
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 938($r28)
    addi $r10, $r0, 453
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 939($r28)
    addi $r10, $r0, 454
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 940($r28)
    addi $r10, $r0, 455
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 941($r28)
    addi $r10, $r0, 456
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 942($r28)
    addi $r10, $r0, 457
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 943($r28)
    addi $r10, $r0, 458
    sll $r10, $r10, 9
    addi $r11, $r0, 452
    or $r10, $r10, $r11
    sw $r10, 944($r28)


    j loop