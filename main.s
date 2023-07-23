.include "MACROSv21.s"

.data

.include "matrizMapa.data"
.include "tiles.data"

music.num: .word 72
# note0, duration_bote0, note1, ... 
music.note_and_duration: .half 76,400,75,200,76,600,75,200,76,400,69,200,72,1200,76,400,75,200,76,200,76,300,72,300,74,1800,76,400,75,200,76,600,75,200,76,400,69,200,72,1200,76,400,76,200,76,200,67,300,69,300,72,1600,69,200,69,200,72,200,72,400,77,200,69,400,67,200,67,200,72,200,72,400,76,200,67,400,65,200,65,200,69,200,69,400,74,200,65,400,64,200,64,200,67,200,67,400,72,200,64,400,69,200,69,200,72,200,72,400,77,200,69,400,69,200,69,200,72,200,72,400,78,200,69,400,71,200,71,200,72,200,72,200,73,200,73,200,74,200,74,400,79,600,79,800
music.initial_time: .word 0 		# guarda o tempo que a nota come�ou a tocar
music.counter: .half 0, 1		# para manter refer�ncia de qual nota deve tocar
music.note_counter: .word 0		# conta a quant. de notas
music.current_duration: .half 0		# dura��o da nota que est� tocando agora

# tempo que exibiu a ultima frame, pra controlar o fps
frameTime: .word 0

# variaveis pra controlar a anima��o
marioGrande: .byte 0	# 0 = mario pequeno, 1 = mario grande

# moveX foi utilizado para ver se está virado para a direita: 1, ou para a esquerda: -1
moveX: .byte 1			# 1 = andando direita, 0 = parado, -1 = andando esquerda
moveY: .byte 0 			# 1 = no ar, 0 = no chao
velocidadeY: .word 0 	# 0 se n estiver subindo, se estiver eh o num de pixeis que ainda tem que subir
marioPosY: .half 176	# posicao vertical do mario no bitmap (canto superior), comeca na tile 11 de cima pra baixo (11*16)
marioPosYAlin: .half 176	# posicao vertical do mario no bitmap que salva a ultima tile vertical que ele se alinhou
marioPosTileY: .byte 0	# qual dos pixeis de 0 a 15 no tile ele esta, vai ajudar na hora da colisao

# posicao do mario na matriz
marioPosMatriz: .half 9, 11		# x, y

# testando
MARIO_MOV: .byte 0		# 0 = parado, 1 = andando1, 2 = andando2, 3 = andando3

goomba_POS: .half 16, 11 #x, y #582
goombaFrames: .byte 0	# quantos frames desde que o goomba moveu pela ultima vez

.text

# imprime a tela principal e espera apertar espaco
	la a0, menu_principal
	li a1, 0
	call printTela

	la a0, tela_enredo
	li a1, 1
	call printTela

	li t0, 0xFF200000
esperaInput1:
	lw t1, 0(t0)			# controle teclado
	andi t1, t1, 1			# mascara bit
	beqz t1, esperaInput1	# le a tecla pressionada
	lw t2, 4(t0)			# tecla pressionada

	li t1, ' '
	bne t2, t1, esperaInput1	# se n for igual a espaco, continua esperando

	li t1, 0xFF200604
	li t2, 1
	sw t2, 0(t1)	# troca a frame

esperaInput2:
	lw t1, 0(t0)			# controle teclado
	andi t1, t1, 1			# mascara bit
	beqz t1, esperaInput2	# le a tecla pressionada
	lw t2, 4(t0)			# tecla pressionada

	li t1, ' '
	bne t2, t1, esperaInput2	# se n for igual a espaco, continua esperando

setup: 
	# teste do printMap
	la a0, map
	la t0, posEsq
	lhu t0, 0(t0)
	slli t0, t0, 1
	add a0, a0, t0
	li a1, 0
	la a2, mapLength
	lhu a2, 0(a2)
	la a3, cortePixel
	lb a3, 0(a3)
	call printMap
	
	# s0 = frame que sera exibido
	# s1 = endereco do mario na matriz do mapa
	li s0, 0
gameloop:
	# 30 fps, se n passou o tempo suficiente a gente n muda a tela
	li a7, 30
	ecall
	
	la t0, frameTime
	lw t0, 0(t0)
	sub t0, a0, t0	# quanto tempo passou
	li t1, 33	# 1000 ms / 30 fps
	bltu t0, t1, gameloop

	# calcula a posicao do mario na matriz e salva em s1
	la t2, map
	la t3, mapLength
	lh t3, 0(t3)

	la t0, marioPosMatriz
	lh t1, 0(t0)
	slli t1, t1, 1			# pra ajustar, pq o endereco eh de halfs
	add t2, t2, t1			# matriz + x
	lh t1, 2(t0)
	slli t1, t1, 1			# ajustando pra endereco de halfword
	mul t1, t1, t3
	add s1, t2, t1			# matriz + len * y, ou seja, s1 = *matriz[y][x]

	# verifica se uma nova nota da m�sica precisa tocar e, se precisa, toca
  	call music.NOTE

  	# verifica se o jogador apertou alguma coisa
	mv a0, s1
	la a1, mapLength
	lh a1, 0(a1)
  	call input

	# necessita de temporização
	la a1, mapLength
	lh a1, 0(a1)
	la a0, map

	la t0, goomba_POS
	lh t1, 0(t0)
	slli t1, t1, 1
	add a0, a0, t1
	lh t0, 2(t0)
	slli t1, t0, 1
	mul t0, t1, a1
	add a0, a0, t0
	call goombaMove
  	
  	# printa o mapa atualizado
  	la a0, map
	la t0, posEsq
	lhu t0, 0(t0)
	slli t0, t0, 1
	add a0, a0, t0		# a0 = endereco deslocado
	mv a1, s0
	la a2, mapLength
	lh a2, 0(a2)
	la a3, cortePixel
	lb a3, 0(a3)
	call printMap
	
	# verifica se o mario ta caindo ou se ta subindo, modificando sua posicao
	mv a0, s1
	la a1, mapLength
	lh a1, 0(a1)
	call fisicaY

	# imprime o mario no tile em cima do chao, no 10 do canto da tela
	la a0, MARIO_MOV
	lb a2, 0(a0)

	la t0, moveY
	lb t1, 0(t0)
	bnez t1, pulando		# se moveY for 1, ele esta pulando, que tem preferencia sobre as outras sprites de movimento

	li a1, 1
	beq a2, a1, andando2
	li a1, 2
	beq a2, a1, andando3
	li a1, 3
	beq a2, a1, andando1
	j default

andando1:
	li a1, 1
	sb a1, 0(a0)
	la a0, mario_andar1
	j printMarioGL

andando2:
	li a1, 2
	sb a1, 0(a0)
	la a0, mario_andar2
	j printMarioGL

andando3:
	li a1, 3
	sb a1, 0(a0)
	la a0, mario_andar3
	j printMarioGL

pulando:
	la a0, mario_pulo
	j printMarioGL

default:
	la a0, mario_default
printMarioGL:
	li a1, 9	# vai aparecer no decimo tile a partir da esquerda (indexado em 0)
	li t0, 16
	mul a1, a1, t0
	la a2, marioPosY
	lh a2, 0(a2)
	li a3, 0
	li a4, 0
	mv a5, s0
	la a6, moveX
	lb a6, 0(a6)
	call printTile
	
	# troca qual vai ser a proxima frame a exibir, pra n ter problema dos personagens na frente ficarem piscando
	li t0, 0xFF200604
	sw s0, 0(t0)
	
	xori s0, s0, 1
	
	# guarda o tempo que terminou de fazer essa frame
	li a7, 30
	ecall
	
	la t0, frameTime
	sw a0, 0(t0)
	
	j gameloop

# aqui vamos printar o mario com a sprite de morte
gameOver:
	la a0, map
	la t0, posEsq
	lhu t0, 0(t0)
	slli t0, t0, 1
	add a0, a0, t0		# a0 = endereco deslocado
	mv a1, s0
	la a2, mapLength
	lh a2, 0(a2)
	la a3, cortePixel
	lb a3, 0(a3)
	call printMap

	la a0, mario_morte
	li a1, 9	# vai aparecer no decimo tile a partir da esquerda (indexado em 0)
	li t0, 16
	mul a1, a1, t0
	la a2, marioPosY
	lh a2, 0(a2)
	li a3, 0
	li a4, 0
	mv a5, s0
	la a6, moveX
	lb a6, 0(a6)
	call printTile

	# troca qual vai ser a proxima frame a exibir, pra n ter problema dos personagens na frente ficarem piscando
	li t0, 0xFF200604
	sw s0, 0(t0)

	li a0,40		# define a nota
	li a1,1500		# define a duracao da nota em ms
	li a2,1		# define o instrumento
	li a3,127		# define o volume
	li a7,33		# define o syscall
	ecall			# toca a nota
	li a0, 1500
	li a7, 32
	ecall			# realiza uma pausa de 1500 ms

	li a7, 10
	ecall

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
	
	# labels que v�o definir o quanto cortar baseado em qual tile tem que imprimir
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

	# idx 3
	li t0, 3
	beq t0, t3, addr3

	# idx 5
	li t0, 5
	beq t0, t3, addr5

	# idx 6
	li t0, 6
	beq t0, t3, addr6

	# mario, como nos imprimimos o mario por cima depois, a gente pinta como ceu
	li t0, 4
	beq t0, t3, addr0
	
	# idx 2
	la a0, itemBlock
	j imprimirTile
	
addr0:
	la a0, fundoAzul
	j imprimirTile

addr1:
	la a0, floorBlock
	j imprimirTile

addr3:
	la a0, goomba
	j imprimirTile

addr5:
	la a0, powerUp
	j imprimirTile

addr6:
	la a0, itemBlockUsed
	
imprimirTile:
	mv a1, s2	# posX
	mv a2, s3	# posY
	mv a5, s1	# frame a printar
	li a6, 1
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
# a6: imagem espelhada? a6 = -1 sim, a6 = 1 normal
printTile:
	addi sp, sp -8
	sw s0, 0(sp)
	sw s1, 4(sp)

	# se ta pedindo pra cortar mais que 15 pixeis, imprime nada
	li t0, 16
	bge a3, t0, fimPrTile

	li t6, 0xFF0	# t6 = endere�o base da tela que queremos printar
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
	bgt a6, zero, prTile1Normal
	
	# print espelhado
	addi t2, a0, 15		# nao tenho ctz se pra printar com corte esse espelhado funciona
	j loopPrTile1
	
prTile1Normal:
	mv t2, a0	# endereco do tile
	
loopPrTile1:
	lb t3, 0(t2)		# carrega a cor do tile
	sb t3, 0(t6)		# pinta na tela
	addi t0, t0, 1		# incrementa o num de pixeis pintados na linha
	add t2, t2, a6		# incrementa o endereco da img 
	addi t6, t6, 1		# incrementa o endereco da VGA
	bne t0, s0, loopPrTile1
	
	# troca de linha
	li t0, 0		# reinicia o contador
	addi t1, t1, 1		# incrementa o num de linhas
	bgt a6, zero, loopNormal1
	add t2, t2, s0		# pra fazer o print espelhado, tem que ir pra frente, de onde comecou
	j voltaPr1
loopNormal1:
	sub t2, t2, s0		# volta o num de pixeis que pinta horizontalmente
voltaPr1:
	addi t2, t2, 16		# + 17 pq: +1 pra ajustar o indice, pq estamos indexados em 0, e +16 pra ir pra prox linha
	sub t6, t6, s0		# volta o num de pixeis que pinta horizontalmente
	addi t6, t6, 320	# vamos testar, mas acho que n segue a logica do t2
	bne t1, s1, loopPrTile1	# se n terminou as linhas, vai printar a prox
	
	j fimPrTile

printTileDir:
	bgt a6, zero, prTile2Normal
	# print espelhado
	addi t2, a0, 15		# nao tenho ctz se pra printar com corte esse espelhado funciona
	j loopPrTile2
	
prTile2Normal:
	add t2, a0, a3		# o idx do 1o pixel que vamos printar eh o msm que o num de pixeis que vao ser cortados
	
loopPrTile2:
	lb t3, 0(t2)		# carrega a cor do tile
	sb t3, 0(t6)		# pinta na tela
	addi t0, t0, 1		# incrementa o num de pixeis pintados na linha
	add t2, t2, a6		# incrementa o endereco da img 
	addi t6, t6, 1		# incrementa o endereco da VGA
	bne t0, s0, loopPrTile2
	
	# troca de linha
	li t0, 0		# reinicia o contador
	addi t1, t1, 1		# incrementa o num de linhas
	bgt a6, zero, loopNormal2
	add t2, t2, s0		# o voltar do espelhado eh ir pra frente
	j voltaPr2
loopNormal2:
	sub t2, t2, s0		# volta o num de pixeis que pinta horizontalmente
voltaPr2:
	addi t2, t2, 16		# n�o precisa do +1 pelos testes em papel que eu fiz, funciona s� indo pra prox linha (caracteristica de comecar pela direita)
	sub t6, t6, s0		# volta o num de pixeis que pinta horizontalmente
	addi t6, t6, 320	# segue a mesma logica do  t2
	bne t1, s1, loopPrTile2	# se n terminou as linhas, vai printar a prox
	
fimPrTile:
	lw s0, 0(sp)
	lw s1, 4(sp)
	addi sp, sp, 8
	ret

# imprime uma imagem na tela inteira
# a0 = endereco da imagem
# a1 = frame
printTela:
	li t0, 0xFF0
	add t0, t0, a1
	slli t0, t0, 20		# endereco da tela com o frame desejado

	li t1, 76800
	add t1, t0, t1		# t1 = ultimo endereco da tela

loopPrTela:
	lw t2, 0(a0)
	sw t2, 0(t0)
	addi a0, a0, 4
	addi t0, t0, 4
	bne t0, t1, loopPrTela

	ret

# toca a musica, vendo se passou tempo suficiente pra tocar a proxima
# (bug que so toca ate a metade, ja tava no meu codigo de musica de ISC)
music.NOTE:
  # pega a dura��o da nota atual
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
  	bgeu t0, t1, music.PLAY

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
	
# verifica se o jogador apertou alguma tecla e faz o necessario com base nela
# a0 = pos do mario na matriz
# a1 = largura da matriz
input:	
	li t0, 0xFF200000	# endereco KDMMIO
	lw t1, 0(t0)		# bit de controle do teclado
	andi t1, t1, 1		# isola so o bit menos significativo
	
	beqz t1, fimInputParado
	#beqz t1, fimInput	# se nao apertou, entao volta pro loop
	lw t2, 4(t0)		# carrega a tecla pressionada
	
	li t3, 'a'
	beq t3, t2, left
	
	li t3, 'd'
	beq t3, t2, right

	li t3 'w'
	beq t3, t2, pula

	#li t3, 'g'
	#beq t3, t2, goombaMove
	
	j fimInput
	
pula:
	la t0, moveY
	lb t1, 0(t0)
	bne t1, zero, fimInput	# se ja esta no ar, faz nada, nao tem pulo duplo

	li t1, 1
	sb t1, 0(t0)			# atualiza falando que ele esta no ar
	la t0, velocidadeY
	li t1, 56				# pular a altura de 3.5 tiles (16 * 3.5)
	sw t1, 0(t0)

	j fimInput

left:
	li t0, -1
	la t1, moveX
	sb t0, 0(t1)			# mario olhando pra esquerda

	la t0, MARIO_MOV
	lb t1, 0(t0)
	bnez t1, notzerol
	li t1, 1
	sb t1, 0(t0)
notzerol:
	la t0, cortePixel		# quantidade de pixeis que vao ser cortados
	lb t1, 0(t0)

	li t6, 8
	bge t1, t6, colisaoEsq
	beqz t1, colisaoEsq		# se for 0 vai tentar acessar o tile do lado, entao tem que verificar
voltaLeft1:
	li t2, 8
	beq t1, t2, trocaMatrizEsq

voltaLeft2:
	addi t1, t1, -2			# vai 2 pixeis pra esquerda
	blt t1, zero, mudarTileEsq	# se passou do limite da tile atual, vai trocar a tile
	sb t1, 0(t0)			# guarda a nova posicao
	
	j fimInput

trocaMatrizEsq:
	lh t3, -2(a0)			# ve a tile na esquerda do mario

	bnez t3, voltaLeft2		# se a tile na esquerda n eh zero, nao eh pra ocupar aquele espaco
	sh zero, 0(a0)
	li t3, 4
	sh t3, -2(a0)

	la t3, marioPosMatriz
	lh t2, 0(t3)
	addi t2, t2, -1
	sh t2, 0(t3)

	j voltaLeft2

colisaoEsq:
	# verifica a colisao da tile da esquerda
	lh t5, -2(a0)
	
	li t4, 1				# chao
	beq t5, t4, limiteEsq

	li t4, 2				# |?|
	beq t5, t4, limiteEsq

	j voltaLeft1

mudarTileEsq:
	la t2, posEsq			# carrega o tile superior esquerdo que ta exibindo
	lh t3, 0(t2)			
	addi t3, t3, -1			# vai um tile pra esquerda
	blt t3, zero, limiteEsq		# a nao ser que seja negativo, senao nao move
	sh t3, 0(t2)			# guarda o novo tile
	
	addi t1, t1, 16			# coloca a quant de pixeis cortados como positivo de novo
	sb t1, 0(t0)			# guarda a nova quant de pixeis cortados
	
	j fimInput
	
limiteEsq:
	la t2, posEsq			# carrega o tile superior esquerdo que ta exibindo
	lh t3, 0(t2)
	li t6, 8
	blt t1, t6, continuaLimEsq
	addi t3, t3, 1			# se o num de corte eh >= 8, enta ele esta no tile do lado, entao tem que ir pro tile mais pra direita
continuaLimEsq:
	sh t3, 0(t2)			# forca as duas variaveis pra zero, ou seja, para no canto esquerdo do mapa
	sb zero, 0(t0)
	
	j fimInput
	
right:
	li t0, 1
	la t1, moveX
	sb t0, 0(t1)			# mario olhando pra direita

	la t0, MARIO_MOV
	lb t1, 0(t0)
	bnez t1, notzeror
	li t1, 1
	sb t1, 0(t0)
notzeror:
	# a diferenca pode ser no maximo 20 pra so mostrar o que tem na matriz
	la t2, posEsq			# carrega o tile superior esquerdo que ta exibindo
	lh t3, 0(t2)
	la t4, mapLength		# pega o tamanho do mapa
	lh t4, 0(t4)		
	addi t3, t3, 1			# vai um tile pra direita
	sub t5, t4, t3
	li t6, 20
	blt t5, t6, limiteDir		# se dif for menor que 20, "prende" a matriz

	la t0, cortePixel		# quantidade de pixeis que vao ser cortados
	lb t1, 0(t0)

	li t6, 8
	blt t1, t6, colisaoDir		# se o mario ta alinhado na esquerda precisamos verificar se ele ta encostando em alguma coisa

voltaRight:
	addi t1, t1, 2			# vai 2 pixeis pra esquerda
	li t2, 16
	bge t1, t2, mudarTileDir	# se passou do limite da tile atual, vai trocar a tile
	
	sb t1, 0(t0)			# guarda a nova posicao

	li t2, 8
	beq t1, t2, trocaMatrizDir		# se chegou em 8, eh pra trocar a pos na matriz
	
	j fimInput

trocaMatrizDir:
	lh t0, 2(a0)			# ve a tile na direita do mario

	bnez t0, fimInput		# se a tile na direita n eh zero, nao eh pra ocupar aquele espaco
	sh zero, 0(a0)
	li t0, 4
	sh t0, 2(a0)

	la t0, marioPosMatriz
	lh t1, 0(t0)
	addi t1, t1, 1
	sh t1, 0(t0)

	j fimInput

mudarTileDir:
	la t2 posEsq
	sh t3, 0(t2)			# guarda o novo tile
	
	addi t1, t1, -16		# coloca a quant de pixeis cortados como menor que 16 de novo
	sb t1, 0(t0)			# guarda a nova quant de pixeis cortados
	
	j fimInput
	
limiteDir:
	addi t3, t3, -1
	sh t3, 0(t2)			# forca as duas variaveis pra zero, ou seja, para no canto esquerdo do mapa
	sb zero, 0(t0)
	
	j fimInput

colisaoDir:
	lh t6, 2(a0)			# elemento na matriz adireita da pos do mario

	li t5, 1
	beq t6, t5, limiteDir	# se eh uma parede, n move a tela (pos do mario)

	li t5, 2
	beq t6, t5, limiteDir	# se eh uma caixa de item, n move a tela (pos do mario)

	# caso seja nenhum, move normal
	j voltaRight

fimInput:
	ret

fimInputParado:
	addi sp, sp, -8
	sw t0, 0(sp)
	sw t1, 4(sp)
	la t0, MARIO_MOV
	li t1, 0
	sb t1, 0(t0)
	lw t1, 4(sp)
	lw t0, 0(sp)
	addi sp, sp, 8
	ret

# faz toda a verificacao de se o mario ta caindo, pulando, se tem que atualizar a pos vertical dele
# a0 = endereco do mario da matriz do mapa
# a1 = largura da matriz do mapa
fisicaY:
	# manipulacao pra pegar a posicao do mario na matriz

	la t0, moveY
	lb t1, 0(t0)
	beqz t1, verificaChao	# se o mario esta no chao, verifica se agora tem algum buraco debaixo dele

	la t1, velocidadeY
	lw t2, 0(t1)
	bgt t2, zero, fisSubindo	# se a velocidade eh maior que 0, eh pra subir

# mario caindo
	# TODO verificacao de colisao pra ver se o mario chegou no chao
	la t1, marioPosY
	la t2, marioPosTileY
	# adicionando 2 a posicao y do mario no bitmap (desce)
	lh t4, 0(t1)
	addi t4, t4, 2
	# voltando 2 a posicao relativa no tile
	lb t3, 0(t2)
	addi t3, t3, -2
	blt t3, zero, desceTileY
	sh t4, 0(t1)
	sb t3, 0(t2)

	j fimFisicaY

desceTileY:
	# quando ele tenta descer, vemos se tem algum chao ou alguma coisa pra parar a queda (ou inimigo pra derrotar)\
	slli t0, a1, 1
	add t0, a0, t0
	lh t5, 0(t0)

	li t0, 1	# chao
	beq t0, t5, aterrissagem

	li t0, 2	# |?|
	beq t0, t5, aterrissagem

	# se for inimigo acho que pode tratar depois de alterar a posicao

	addi t3, t3, 16
	sh t4, 0(t1)
	sb t3, 0(t2)

	la t1, marioPosYAlin
	sh t4, 0(t1)				# salva essa posicao, que esta alinhada com o tile

	# atualizamos a posicao dele na matriz aqui pois faz mais sentido, ele so pode passar de altura quando ele estiver toda nela
	la t0, marioPosMatriz
	lh t2, 2(t0)
	addi t2, t2, 1
	sh t2, 2(t0)			# atualiza a pos Y na memoria

	li t0, 15
	bge t2, t0, gameOver	# se passou do limite inferior entao ele caiu em um burado e morreu

	sh zero, 0(a0)			# guarda ceu onde o mario tava
	slli t1, a1, 1
	add a0, a0, t1			# volta pra linha de baixo
	li t1, 4
	sh t1, 0(a0)			# guarda mario na pos de cima

	j fimFisicaY

aterrissagem:
	la t0, moveY
	sb zero, 0(t0)

	j fimFisicaY

fisSubindo:
	slli t6, a1, 1		# t6 = incremento de linha
	sub t0, a0, t6		# t0 = bloco em cima do mario na matriz
	lh t4, 0(t0)

	li t3, 1
	beq t3, t4, colisaoCima

	li t3, 2
	beq t3, t4, colisaoCima

	li t3, 6
	beq t3, t4, colisaoCima

	addi t2, t2, -2				# vamos subir 2 pixeis por vez
	sw t2, 0(t1)
	la t1, marioPosY
	la t2, marioPosTileY
	# adicionando 2 a posicao y do mario no bitmap
	lh t4, 0(t1)
	addi t4, t4, -2
	# adicionando 2 a posicao relativa no tile (sobe)
	lb t3, 0(t2)
	addi t3, t3, 2
	li t0, 16
	bge t3, t0, sobeTileY		# se a pos relativa superior passou de 16, significa que ele foi pra prox tile
	# se n trocou de tile, so tem que verificar se tem um bloco em cima pra onde quer ir
	sh t4, 0(t1)
	sb t3, 0(t2)


	j fimFisicaY

colisaoCima:
	la t3, velocidadeY
	sh zero, 0(t3)			# para a ida pra cima

	la t1, marioPosY
	la t2, marioPosYAlin
	lh t2, 0(t2)
	sh t2, 0(t1)
	la t1, marioPosTileY
	sb zero, 0(t1)

	li t5, 2
	bne t5, t4, fimFisicaY	# se n eh interrogacao pode parar

	li t1, 6
	sh t1, 0(t0)		# bloco |?| se torna usado
	sub t0, t0, t6		# posicao em cima do bloco |?|
	li t1, 5
	sh t1, 0(t0)

	j fimFisicaY

sobeTileY:
	addi t3, t3, -16			# deixa o valor como menor que 16, ou seja, entre 0 e 15
	sh t4, 0(t1)
	sb t3, 0(t2)

	la t1, marioPosYAlin
	sh t4, 0(t1)				# salva essa posicao, que esta alinhada com o tile

	# atualizamos a posicao dele na matriz aqui pois faz mais sentido, ele so pode passar de altura quando ele estiver toda nela
	# vai ter que verificar ainda
	sh zero, 0(a0)			# guarda ceu onde o mario tava
	slli t1, a1, 1
	sub a0, a0, t1			# volta pra linha de cima
	li t1, 4
	sh t1, 0(a0)			# guarda mario na pos de cima

	la t0, marioPosMatriz
	lh t2, 2(t0)
	addi t2, t2, -1
	sh t2, 2(t0)			# atualiza a pos Y na memoria

	j fimFisicaY

verificaChao:
	# pra ser justo, vamos ver se debaixo do mario na matriz na colisao eh vazio e se a posicao em pixeis no tile no eixo X eh maior que 0, ou se na posicao que ele esta no meio eh buraco tbm
	slli t0, a1, 1
	add t0, a0, t0
	lh t1, 0(t0)		# tile logo debaixo do mario

	bnez t1, fimFisicaY	# se n eh ar debaixo dele, entao n eh pra cair

	la t2, cortePixel
	lb t2, 0(t2)

	bnez t2, fimFisicaY	# teste
	la t3, moveY
	li t4, 1
	sb t4, 0(t3)

fimFisicaY:
	ret

# move o goomba
# a0 = endereco do goomba na matriz
# a1 = tamanho do mapa
goombaMove:
	addi sp, sp, -20
	sw a0, 0(sp)
	sw a1, 4(sp)
	sw a2, 8(sp)
	sw a3, 12(sp)
	sw a4, 16(sp)

	la t0, goombaFrames
	lb t1, 0(t0)
	addi t1, t1, 1
	li t2, 30
	bne t1, t2, goomba_fim		# se ja passaram 30 frames, faz a movimentacao
	li t1, 0					# se vai andar, reseta o contador

	#la a0, goomba_POS
	#lh a1, 0(a0)			# a1 = valor do goomba_POS
	#la a2, map
	#add a2, a2, a1			# a2 = endereço atual do goomba na matriz
	mv a2, a0
	la a0, goomba_POS
	lh a1, 0(a0)			# x do goomba

	# se chegar ao fim do mapa na esquerda, limbo pro goomba
	li t0, 0
	beq t0, a1, goomba_limbo

	# faz a verificação de onde está o mario
	li a4, 4
	lh a3, 2(a2)
	beq a3, a4, goomba_dir

	lh a3, 4(a2)
	beq a3, a4, goomba_dir

	lh a3, 6(a2)
	beq a3, a4, goomba_dir

	lh a3, 8(a2)
	beq a3, a4, goomba_dir

	lh a3, 10(a2)
	beq a3, a4, goomba_dir

	lh a3, 12(a2)
	beq a3, a4, goomba_dir

	# se o mario estiver à esquerda, vai à esquerda
goomba_esq:
	lh a3, -2(a2)		# um endereço à esquerda do goomba
	li a4, 1
	# se tiver uma parede na frente, fica parado
	beq a3, a4, goomba_fim

	li a3, 0
	sh a3, 0(a2)			# lugar atual do goomba -> fundoAzul
	li a3, 3
	sh a3, -2(a2)
	addi a3, a1, -1		# decrementa o goomba_POS em 2
	sh a3, 0(a0)
	j goomba_fim

	# se o mario estiver a 6 posições (tiles) à direita, vai à direita
goomba_dir:
	lh a3, 2(a2)		# um endereço à direita do goomba
	li a4, 1
	# se tiver uma parede na frente, fica parado
	beq a3, a4, goomba_fim

	li a3, 0
	sh a3, 0(a2)			# lugar atual do goomba -> fundoAzul
	li a3, 3
	sh a3, 2(a2)
	la a0, goomba_POS
	lh a1, 0(a0)
	addi a3, a1, 1		# decrementa o goomba_POS em 2
	sh a3, 0(a0)
	j goomba_fim

goomba_limbo:
	li a3, 0
	sh a3, 0(a2)			# lugar atual do goomba -> fundoAzul

goomba_fim:
	la t0, goombaFrames
	sb t1, 0(t0)

	lw a4, 16(sp)
	lw a3, 12(sp)
	lw a2, 8(sp)
	lw a1, 4(sp)
	lw a0, 0(sp)
	addi sp, sp, 20
	ret

# vamo que vamo :)

.include "SYSTEMv21.s"
