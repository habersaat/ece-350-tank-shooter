nop            # Specifically tests lw into jr
nop            # Author: Philip Xue
nop
nop            # EDGE CASE: bypassing from lw -> jr
nop            # checks if the value of lw is being bypassed, not the address
addi $1, $0, 10        # r1 = 10
nop
nop
sw $1, 11($0)         # mem[11] = r1 = 10
lw $4, 11($0)         # r4 = mem[11] = 10
jr $4          # This is line 10: the program should get stuck here
nop
nop
addi $2, $0, 1 # This line should never be reached