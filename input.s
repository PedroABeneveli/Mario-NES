INPUT:		li		t1, KDMMIO_KEYDOWN_ADDRESS
		lw		t0, 0(t1)
		andi		t0, t0, 1
  	 	beqz		t0, INPUT.ZERO	# se nao tiver input, zera as entradas
 
		lw		t0, 4(t1)	# se houver input, pega o valor que ta no buffer pra comparacao

  		# Movimentos normais (lowercase)
  		li		t1, 'w'
  		beq		t0, t1, INPUT.W
  		li		t1, 'a'
  		beq		t0, t1, INPUT.A
  		li		t1, 's'
  		beq		t0, t1, INPUT.S
  		li		t1, 'd'
  		beq		t0, t1, INPUT.D
  		
  		
INPUT.ZERO:	la		t0, MOVEX
		sw		zero, 0(t0)		# zera moveX, moveY, jump e dash (cada um eh um byte, por isso usamos word, pra zerar os quatro)
		sh		zero, 4(t0)		# zera dashX e dashY (cada um eh um byte, por isso usamos half)
		ret

INPUT.W:	la		t0, MOVEY
		li		t1, -1
		sb		t1, 0(t0)		# moveY = -1 (cima)
		
		la		t0, JUMP
		li		t1, 1
		sb		t1, 0(t0)		# input jump = 1	

		ret

INPUT.A:	la		t0, MOVEX
		li		t1, -1
		sb		t1, 0(t0)		# moveX = -1 (esquerda)
		
		la		t0, MARIO_DIR
		li		t1, 1
		sb		t1, 0(t0)		# charDir = 1 (esquerda)
		
		ret

INPUT.S:	la		t0, MOVEY
		li		t1, 1
		sb		t1, 0(t0)		# moveY = 1 (baixo)
		ret

INPUT.D:	la		t0, MOVEX
		li		t1, 1
		sb		t1, 0(t0)		# moveX = 1 (direita)
		
		la		t0, MARIO_DIR
		sb		zero, 0(t0)		# charDir = 0 (direita)

	#addi sp, sp, -20
	#sw a0, 0(sp)
	#sw t0, 4(sp)
	#sw a1, 8(sp)
	#sw a2, 12(sp)
	#sw a3, 16(sp)
	#la a0, map
	#la t0, posSupEsq
	#lhu t0, 0(t0)
	#slli t0, t0, 1
	#add a0, a0, t0
	#li a1, 0
	#la a2, mapLength
	#lhu a2, 0(a2)
	#la a3, cortePixel
	#li a3, a3, 1
	#lb a3, 0(a3)
	#call printMap
	#lw a3, 16(sp)
	#lw a2, 12(sp)
	#lw a1, 8(sp)
	#lw t0, 4(sp)
	#lw a0, 0(sp)
	#addi sp, sp, 20	
	
		ret
