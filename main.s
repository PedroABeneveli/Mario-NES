.include "MACROSv21.s"

.data

.include "matrizMapa.data"
.include "tiles.data"

music.num: .word 72
# note0, duration_bote0, note1, ... 
music.note_and_duration: .half 76,400,75,200,76,600,75,200,76,400,69,200,72,1200,76,400,75,200,76,200,76,300,72,300,74,1800,76,400,75,200,76,600,75,200,76,400,69,200,72,1200,76,400,76,200,76,200,67,300,69,300,72,1600,69,200,69,200,72,200,72,400,77,200,69,400,67,200,67,200,72,200,72,400,76,200,67,400,65,200,65,200,69,200,69,400,74,200,65,400,64,200,64,200,67,200,67,400,72,200,64,400,69,200,69,200,72,200,72,400,77,200,69,400,69,200,69,200,72,200,72,400,78,200,69,400,71,200,71,200,72,200,72,200,73,200,73,200,74,200,74,400,79,600,79,800
music.initial_time: .word 0 		# guarda o tempo que a nota comeï¿½ou a tocar
music.counter: .half 0, 1		# para manter referï¿½ncia de qual nota deve tocar
music.note_counter: .word 0		# conta a quant. de notas
music.current_duration: .half 0		# duraï¿½ï¿½o da nota que estï¿½ tocando agora

.text

setup: 
	# teste do printMap
	la a0, map
	la t0, posSupEsq
	lhu t0, 0(t0)
	slli t0, t0, 1
	add a0, a0, t0
	li a1, 0
	la a2, mapLength
	lhu a2, 0(a2)
	la a3, cortePixel
	lb a3, 0(a3)
	call printMap

	li s0, 0xFF000000
	li s1, 0x38

	la a0, fundoAzul
	li a1, 0
	li a2, 0
	li a3, 0
	li a4, 0
	li a5, 0
	call printTile
	
	la a0, fundoAzul
	li a1, 17
	li a2, 0
	li a3, 6
	li a4, 0
	li a5, 0
	call printTile
	
	la a0, tile1
	li a1, 0
	li a2, 17
	li a3, 0
	li a4, 1
	li a5, 0
	call printTile
	
	la a0, tile1
	li a1, 17
	li a2, 17
	li a3, 6
	li a4, 1
	li a5, 0
	call printTile

	la a0, mario
	li a1, 34
	li a2, 190
	li a3, 0
	li a4, 1
	li a5, 0
	call printTile

	la a0, floorBlock
	li a1, 0
	li a2, 207
	li a3, 0
	li a4, 1
	li a5, 0
	call printTile

	la a0, floorBlock
	li a1, 17
	li a2, 207
	li a3, 0
	li a4, 1
	li a5, 0
	call printTile

	la a0, itemBlock
	li a1, 17
	li a2, 156
	li a3, 0
	li a4, 1
	li a5, 0
	call printTile
	
	sb s1, 0(s0)
	
	sb s1, 16(s0)
	li t0, 5120
	add t0, s0, t0
	sb s1, 0(t0)
	sb s1, 16(t0)
	
gameloop:
	
	# verifica se uma nova nota da mï¿½sica precisa tocar e, se precisa, toca
  	call music.NOTE
	
	j gameloop

# ---- Funcoes ----

# printa a tela toda com base nos tiles e no quanto precisa cortar dos lados
# a0 = endereco do comeco de onde vai printar (matriz + tile inicial)
# a1 = frame
# a2 = largura da matriz do mapa
# a3 = o quanto vai cortar da tile da esquerda
printMap:
	addi sp, sp, -36
	sw ra, 0(sp)
	sw s0, 4(sp)
	sw s1, 8(sp)
	sw s2, 12(sp)
	sw s3, 16(sp)
	sw s4, 20(sp)
	sw s5, 24(sp)
	sw s6, 28(sp)
	sw s7, 32(sp)
	
	# implementar a parte dos ponteiros dos limites visiveis depois, por enquanto so conseguir imprimir com base nos tiles
	
	li s4, 0	# contador coluna
	li s5, 0	# contador linha
	mv s0, a0	# t2 = endereco movel da matriz
	li s2, 0	# posX
	li s3, 0	# posY
	mv s1, a1	# salva o frame
	mv s6, a2	# tamanho da matriz do mapa
	slli s6, s6, 1	# multiplicando por 2 pois a matriz eh composta de halfwords
	mv s7, a3	# num de pixeis a cortar na esquerda
	
	# labels que vão definir o quanto cortar baseado em qual tile tem que imprimir
tileEsq:
	mv a3, s7
	li a4, 1
	j loopPrMap

# vou colocar aqui no meio pra n ter que colocar mais jumps
incEsqPosX:
	li t0, 16
	sub t0, t0, s7
	add s2, s2, t0
	j voltaMap

tileDir:
	li t0, 16
	sub a3, t0, s7	# vai cortar o num de pixeis na direita o quanto apareceu na esq, pra completar
	li a4, 0
	j loopPrMap
	
tileMid:
	li a3, 0
	
loopPrMap:
	lh t3, 0(s0)
	
	# idx 0
	beqz t3, addr0
	
	# idx 1
	li t0, 1
	beq t0, t3, addr1
	
	# idx 2
	la a0, itemBlock
	j imprimirTile
	
addr0:
	la a0, fundoAzul
	j imprimirTile

addr1:
	la a0, floorBlock
	
imprimirTile:
	mv a1, s2	# posX
	mv a2, s3	# posY
	mv a5, s1	# frame a printar
	call printTile
	beqz s4, incEsqPosX	# se for o primeiro tile, vai ter um incremento diferente pro s2
	addi s2, s2, 16
voltaMap:
	addi s4, s4, 1
	addi s0, s0, 2
	li t0, 20
	blt s4, t0, tileMid
	# se imprimiu 20, agora eh so imprimir o da direita e depois fazer a troca de linha
	li t0, 21
	bne s4, t0, tileDir
	
	# troca de linha
	li s4, 0		# reinicia o contador
	li s2, 0		# reincia a posX
	addi s5, s5, 1		# incrementa o num de linhas
	addi s0, s0, -42	# volta o num de tiles que pinta horizontalmente *2 pq o endereco eh de halfwords
	add s0, s0, s6		# depende de quantos tiles vai ter por linha no mapa todo, ai a gente vai mudando
	addi s3, s3, 16		# incrementa o posY
	li t1, 15
	bne s5, t1, tileEsq	# se n terminou as linhas, vai printar a prox
	
	lw s7, 32(sp)
	lw s6, 28(sp)
	lw s5, 24(sp)
	lw s4, 20(sp)
	lw s3, 16(sp)
	lw s2, 12(sp)
	lw s1, 8(sp)
	lw s0, 4(sp)
	lw ra, 0(sp)
	addi sp, sp, 36
	ret

# printa uma tile de 16 por 16, a partir do pixel especificado
# -- Argumentos --
# a0: endereco base da tile
# a1: posX do bitmap
# a2: posY do bitmap
# a3: quantos pixeis cortar dos lados (0 a 15)
# a4: cortar da direita = 1, cortar da esquerda = 0
# a5: frame
printTile:
	addi sp, sp -8
	sw s0, 0(sp)
	sw s1, 4(sp)

	# se ta pedindo pra cortar mais que 15 pixeis, imprime nada
	li t0, 16
	bge a3, t0, fimPrTile

	li t6, 0xFF0	# t6 = endereï¿½o base da tela que queremos printar
	add t6, t6, a5
	slli t6, t6, 20
	add t6, a1, t6	# adiciona a posX no endereco do bitmap
	li t0, 320	# pos na vertical * o num de pixeis por linha
	mul t0, a2, t0	
	add t6, t6, t0	# posicao inicial pra impressao
	
	li s0, 16	# s0 = numero de pixeis por linha
	sub s0, s0, a3	# nao usei o addi pra garantir que o num em s0 eh positivo
	li s1, 16	# s1 = num de colunas
	
	li t0, 0	# num de pixeis na linha pintados
	li t1, 0	# num de linhas pintadas
	
	bnez a4, printTileDir
	
	# print pela esquerda	
	mv t2, a0	# endereco do tile
	
loopPrTile1:
	lb t3, 0(t2)		# carrega a cor do tile
	sb t3, 0(t6)		# pinta na tela
	addi t0, t0, 1		# incrementa o num de pixeis pintados na linha
	addi t2, t2, 1		# incrementa o endereco da img 
	addi t6, t6, 1		# incrementa o endereco da VGA
	bne t0, s0, loopPrTile1
	
	# troca de linha
	li t0, 0		# reinicia o contador
	addi t1, t1, 1		# incrementa o num de linhas
	sub t2, t2, s0		# volta o num de pixeis que pinta horizontalmente
	addi t2, t2, 16		# + 17 pq: +1 pra ajustar o indice, pq estamos indexados em 0, e +16 pra ir pra prox linha
	sub t6, t6, s0		# volta o num de pixeis que pinta horizontalmente
	addi t6, t6, 320	# vamos testar, mas acho que n segue a logica do t2
	bne t1, s1, loopPrTile1	# se n terminou as linhas, vai printar a prox
	
	j fimPrTile

printTileDir:
	add t2, a0, a3		# o idx do 1o pixel que vamos printar eh o msm que o num de pixeis que vao ser cortados
	
loopPrTile2:
	lb t3, 0(t2)		# carrega a cor do tile
	sb t3, 0(t6)		# pinta na tela
	addi t0, t0, 1		# incrementa o num de pixeis pintados na linha
	addi t2, t2, 1		# incrementa o endereco da img 
	addi t6, t6, 1		# incrementa o endereco da VGA
	bne t0, s0, loopPrTile2
	
	# troca de linha
	li t0, 0		# reinicia o contador
	addi t1, t1, 1		# incrementa o num de linhas
	sub t2, t2, s0		# volta o num de pixeis que pinta horizontalmente
	addi t2, t2, 16		# nï¿½o precisa do +1 pelos testes em papel que eu fiz, funciona sï¿½ indo pra prox linha (caracteristica de comecar pela direita)
	sub t6, t6, s0		# volta o num de pixeis que pinta horizontalmente
	addi t6, t6, 320	# segue a mesma logica do  t2
	bne t1, s1, loopPrTile2	# se n terminou as linhas, vai printar a prox
	
fimPrTile:
	lw s0, 0(sp)
	lw s1, 4(sp)
	addi sp, sp, 8
	ret

music.NOTE:
  # pega a duraï¿½ï¿½o da nota atual
  	la t1, music.current_duration
  	lhu t1, 0(t1)
  # faz a syscall de tempo para comparar com o tempo inicial salvo
  	li a7, 30
  	ecall					# a0 = low order 32 bits of the current time in milliseconds since 1 January 1970

  	la t0, music.initial_time		# low order 32 bits of the time when the current note started playing
  	lw t0, 0(t0)

  # gets the difference between the stored time and the current time and check it that's greater than the duration
  	sub t0, a0, t0

  # in case there was a rare exception in which that difference is zero, play the note anyway to keep the music playing
 	blt t0, zero, music.PLAY

  # now check if that difference is equal or greater than the note duration
  	bge t0, t1, music.PLAY

	ret		# if not, just go back

music.PLAY:
  # gets the current time and stores it in memory
	li a7, 30
	ecall
	la t0, music.initial_time
	sw a0, 0(t0)
  # gets the next note and duration in memory
  	la t0, music.counter
  	lhu t1, 0(t0)
  	lhu t2, 2(t0)
  	slli t1, t1, 1		# multiplies by 2 because we are dealing with halfword addresses
  	slli t2, t2, 1
  	la t3, music.note_and_duration
  	add t4, t3, t2		# duration address
  	add t3, t3, t1		# note address
  	lhu a0, 0(t3)		# note
  	lhu a1, 0(t4)		# duration
  	
  # setting up the rest of the parameters of the syscall
  	li a2, 1		# instrument
  	li a3, 127		# volume 
  	li a7, 31		# MIDI Out Syscall
  	ecall
  	
  # stores new duration and counters in memory
  	srli t1, t1, 1		# restores the original form of the note counters
  	srli t2, t2, 1
  	addi t1, t1, 1		# goes to next note and duration
  	addi t2, t2, 1 
  	sh t1, 0(t0)
  	sh t2, 2(t0)
  	
  	la t0, music.current_duration
  	sh a1, 0(t0)		# stores the duration of the current note
  	
  	la t0, music.note_counter
  	lw t0, 0(t0)
  	la t1, music.num
  	lw t1, 0(t1)		# total number of notes
  	
  	bgt t0, t1, music.RESET	# if the number of notes played is bigger than what is avilable, reset
  	
  	la t1, music.note_counter
  	addi t0, t0, 1		# number of notes that have been played
  	sw t0, 0(t1)
  	
  	ret
  	
music.RESET:
	la t0, music.note_counter
	sw zero, 0(t0)
	
	la t0, music.counter
	li t1, 1
	sh zero, 0(t0)
	sh t1, 2(t0)
	
	ret

# vamo que vamo :)

.include "SYSTEMv21.s"
