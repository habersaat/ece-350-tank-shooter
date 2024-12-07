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
    ########################
    #  Update Game Time    #
    ########################
    addi $r18, $r0, 1000      # Load game time address
    lw $r20, 0($r18)          # Load game time into $r20
    addi $r20, $r20, 1        # Increment game time by 1
    addi $r19, $r0, 11      # Load the reset threshold (11)
    blt $r20, $r19, skip_gametime_reset # If game time < 11, skip reset
    addi $r20, $r0, 0         # Reset game time to 0

skip_gametime_reset:
    sw $r20, 0($r18)          # Save updated game time back to memory

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

    # Set TTL = 64
    addi $r11, $r0, 64         # $r11 = TTL

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

    ##########################
    # Update TTL Every 10 Game Ticks
    ##########################
    
    # Load the game time
    addi $r18, $r0, 10      # Game time memory address
    lw $r20, 0($r18)          # Load game time into $r20
    
    # Check if game time is 10
    addi $r19, $r0, 10      # Compare against 10
    bne $r20, $r19, skip_ttl_update # If game time != 10, skip TTL update
    
    ##########################
    # Update TTL and Check if Bullet Should Be Deactivated
    ##########################
    addi $r12, $r12, -1                 # Decrement TTL
    blt $r12, $r0, deactivate_bullet    # If TTL < 0, deactivate bullet

skip_ttl_update:

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
    j pack_bullet              # Skip to packing

bullet_move_down:
    addi $r11, $r11, 1         # Increment y-coordinate
    j pack_bullet

bullet_move_up:
    addi $r11, $r11, -1        # Decrement y-coordinate

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

deactivate_bullet:
    # Write all 0s to deactivate the bullet
    sw $r0, 0($r7)             # Store 0 to clear the bullet entry
    j next_bullet              # Move to the next bullet

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
