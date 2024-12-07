# tank_shooter.s
# This program initializes two sprites in sprite memory and updates their positions based on controller input.

_start:
    ##########################
    # Step 1: Initialization #
    ##########################
    # Initialize Sprite Memory Base Address in $r1 (0x50000000)
    addi $r1, $r0, 20480       # Load 20480 (0x5000) into $r1
    sll $r1, $r1, 16           # Shift left to set high bits (0x50000000)

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
    # Initialize MMIO Base Address in $r3 (0xFFFF0000)
    addi $r3, $r0, 65535       # Load 65535 (0xFFFF) into $r3
    sll $r3, $r3, 16           # Shift left to set high bits (0xFFFF0000)

loop:
    # Check Player 1 Controller Inputs (P1_CONTROLLER1)

check_p1_controller1_up:
    # P1_CONTROLLER1_UP
    lw $r4, 12($r3)            # Load P1_CONTROLLER1_UP into $r4
    bne $r4, $r0, p1_move_up   # If P1_CONTROLLER1_UP is active, move sprite1 up

check_p1_controller1_down:
    # P1_CONTROLLER1_DOWN
    lw $r4, 0($r3)             # Load P1_CONTROLLER1_DOWN into $r4
    bne $r4, $r0, p1_move_down # If P1_CONTROLLER1_DOWN is active, move sprite1 down

check_p1_controller1_left:
    # P1_CONTROLLER1_LEFT
    lw $r4, 8($r3)             # Load P1_CONTROLLER1_LEFT into $r4
    bne $r4, $r0, p1_move_left # If P1_CONTROLLER1_LEFT is active, move sprite1 left

check_p1_controller1_right:
    # P1_CONTROLLER1_RIGHT
    lw $r4, 4($r3)             # Load P1_CONTROLLER1_RIGHT into $r4
    bne $r4, $r0, p1_move_right # If P1_CONTROLLER1_RIGHT is active, move sprite1 right

    # Check Player 2 Controller Inputs (P2_CONTROLLER1)

check_p2_controller1_up:
    # P2_CONTROLLER1_UP
    lw $r4, 44($r3)            # Load P2_CONTROLLER1_UP into $r4
    bne $r4, $r0, p2_move_up   # If P2_CONTROLLER1_UP is active, move sprite2 up

check_p2_controller1_down:
    # P2_CONTROLLER1_DOWN
    lw $r4, 32($r3)            # Load P2_CONTROLLER1_DOWN into $r4
    bne $r4, $r0, p2_move_down # If P2_CONTROLLER1_DOWN is active, move sprite2 down

check_p2_controller1_left:
    # P2_CONTROLLER1_LEFT
    lw $r4, 40($r3)            # Load P2_CONTROLLER1_LEFT into $r4
    bne $r4, $r0, p2_move_left # If P2_CONTROLLER1_LEFT is active, move sprite2 left

check_p2_controller1_right:
    # P2_CONTROLLER1_RIGHT
    lw $r4, 36($r3)            # Load P2_CONTROLLER1_RIGHT into $r4
    bne $r4, $r0, p2_move_right # If P2_CONTROLLER1_RIGHT is active, move sprite2 right

temp_label:

    # Sleep to slow down execution
    j sleep                    # Jump to sleep before looping back

    #############################
    # Player 1 Movement Handlers
    #############################
p1_move_up:
    lw $r5, 4($r1)             # Load sprite1_y into $r5
    addi $r5, $r5, -2          # Decrement y-coordinate by 2
    sw $r5, 4($r1)             # Store updated y back to SpriteMem[1]
    j check_p1_controller1_down

p1_move_down:
    lw $r5, 4($r1)             # Load sprite1_y into $r5
    addi $r5, $r5, 2           # Increment y-coordinate by 2
    sw $r5, 4($r1)             # Store updated y back to SpriteMem[1]
    j check_p1_controller1_left

p1_move_left:
    lw $r5, 0($r1)             # Load sprite1_x into $r5
    addi $r5, $r5, -2          # Decrement x-coordinate by 2
    sw $r5, 0($r1)             # Store updated x back to SpriteMem[0]
    j check_p1_controller1_right

p1_move_right:
    lw $r5, 0($r1)             # Load sprite1_x into $r5
    addi $r5, $r5, 2           # Increment x-coordinate by 2
    sw $r5, 0($r1)             # Store updated x back to SpriteMem[0]
    j check_p2_controller1_up

    #############################
    # Player 2 Movement Handlers
    #############################
p2_move_up:
    lw $r5, 12($r1)            # Load sprite2_y into $r5
    addi $r5, $r5, -1          # Decrement y-coordinate
    sw $r5, 12($r1)            # Store updated y back to SpriteMem[3]
    j check_p2_controller1_down

p2_move_down:
    lw $r5, 12($r1)            # Load sprite2_y into $r5
    addi $r5, $r5, 1           # Increment y-coordinate
    sw $r5, 12($r1)            # Store updated y back to SpriteMem[3]
    j check_p2_controller1_left

p2_move_left:
    lw $r5, 8($r1)             # Load sprite2_x into $r5
    addi $r5, $r5, -1          # Decrement x-coordinate
    sw $r5, 8($r1)             # Store updated x back to SpriteMem[2]
    j check_p2_controller1_right

p2_move_right:
    lw $r5, 8($r1)             # Load sprite2_x into $r5
    addi $r5, $r5, 1           # Increment x-coordinate
    sw $r5, 8($r1)             # Store updated x back to SpriteMem[2]
    j temp_label

    #############################
    # Sleep Section
    #############################
sleep:
    addi $r6, $r0, 0           # Initialize counter in $r6
    addi $r7, $r0, 16384       # Load dely value into $r7

sleep_loop:
    addi $r6, $r6, 1           # Increment counter
    bne $r6, $r7, sleep_loop   # Loop until counter reaches delay
    j loop                     # Return to main loop
