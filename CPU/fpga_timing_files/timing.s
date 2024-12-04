main:
	addi $s0, $0, 10
	jal read_mem
	add $s1, $v0, $0
	mul $a0, $s1, $s0
	jal write_mem
	j main

write_mem:
	sw $a0, 4097($0)
	jr $ra

read_mem:
	lw $v0, 4096($0)
	jr $ra

