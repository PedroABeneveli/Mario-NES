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
marioPosY: .half 176	# posicao vertical do mario no bitmap (canto superior esquerdo), comeca na tile 11 de cima pra baixo (11*16)
marioPosTileY: .byte 0	# qual dos pixeis de 0 a 15 no tile ele esta, vai ajudar na hora da colisao

# testando
MARIO_MOV: .byte 0		# 0 = parado, 1 = andando1, 2 = andando2, 3 = andando3


.text

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

	# verifica se uma nova nota da m�sica precisa tocar e, se precisa, toca
  	call music.NOTE
  	
  	# verifica se o jogador apertou alguma coisa
  	call input
  	
  	# printa o mapa atualizado
  	la a0, map
	la t0, posEsq
	lhu t0, 0(t0)
	slli t0, t0, 1
	add a0, a0, t0		# a0 = endereco deslocado
	mv a1, s0
	la a2, mapLength
	lhu a2, 0(a2)
	la a3, cortePixel
	lb a3, 0(a3)
	call printMap
	
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
	
	j fimInput
	
pula:
	la t0, moveY
	lb t1, 0(t0)
	bne t1, zero, fimInput	# se ja esta no ar, faz nada, nao tem pulo duplo

	li t1, 1
	sb t1, 0(t0)			# atualiza falando que ele esta no ar
	la t0, velocidadeY
	li t1, 48				# pular a altura de 3 tiles (16 * 3)
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
	addi t1, t1, -2			# vai 2 pixeis pra esquerda
	blt t1, zero, mudarTileEsq	# se passou do limite da tile atual, vai trocar a tile
	sb t1, 0(t0)			# guarda a nova posicao
	
	j fimInput

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
	sh zero, 0(t2)			# forca as duas variaveis pra zero, ou seja, para no canto esquerdo do mapa
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
	addi t1, t1, 2			# vai 2 pixeis pra esquerda
	li t2, 16
	bge t1, t2, mudarTileDir	# se passou do limite da tile atual, vai trocar a tile
	
	sb t1, 0(t0)			# guarda a nova posicao
	
	j fimInput

mudarTileDir:
	la t2 posEsq
	sh t3, 0(t2)			# guarda o novo tile
	
	addi t1, t1, -16		# coloca a quant de pixeis cortados como menor que 16 de novo
	sb t1, 0(t0)			# guarda a nova quant de pixeis cortados
	
	j fimInput
	
limiteDir:
	addi t4, t4, -20
	sh t4, 0(t2)			# forca as duas variaveis pra zero, ou seja, para no canto esquerdo do mapa
	sb zero, 0(t0)
	
	j fimInput

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
fisicaY:
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
	lh t3, 0(t1)
	addi t3, t3, 2
	sh t3, 0(t1)
	# voltando 2 a posicao relativa no tile
	lb t3, 0(t2)
	addi t3, t3, -2
	blt t3, zero, desceTileY
	sb t3, 0(t2)

	j fimFisicaY

desceTileY:
	addi t3, t3, 16
	sb t3, 0(t2)

	j fimFisicaY

fisSubindo:
	# TODO verificacao de colisao

	addi t2, t2, -2				# vamos subir 2 pixeis por vez
	sw t2, 0(t1)
	la t1, marioPosY
	la t2, marioPosTileY
	# adicionando 2 a posicao y do mario no bitmap
	lh t3, 0(t1)
	addi t3, t3, -2
	sh t3, 0(t1)
	# adicionando 2 a posicao relativa no tile (sobe)
	lb t3, 0(t2)
	addi t3, t3, 2
	li t0, 16
	bge t3, t0, sobeTileY		# se a pos relativa passou de 16, significa que ele foi pra prox tile
	sb t3, 0(t2)

	j fimFisicaY

sobeTileY:
	addi t3, t3, -16			# deixa o valor como menor que 16, ou seja, entre 0 e 15
	sb t3, 0(t2)

	# aqui tambem vamos ter que atualizar a posicao da matriz do mario

	j fimFisicaY

verificaChao:
	# TODO junto com a colisao

fimFisicaY:
	ret

# vamo que vamo :)

.include "SYSTEMv21.s"
