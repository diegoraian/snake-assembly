;Snake!
[BITS 16]

org 100h           ;Offset de memória requerido pelo DOS

TOTAL_SEGMENTS equ 0xFF ; total de segmentos da cobra;
;Alocação de espaço para dados não inicializados
section .bss
  x_coord   RESW TOTAL_SEGMENTS ; [x_coord] is the head, [x_coord+2] is the next cell, etc.
  y_coord   RESW TOTAL_SEGMENTS ; Same here
  t1        RESB 2 ;Registrador na memória primária para alocação da posição X do cursor da cobra durante a execução
  t2        RESB 2 ;Registrador na memória primária para alocação da posição Y do cursor da cobra durante a execução
  enabled   RESB 2
  x_apple   RESB 2 ;Registrador na memória primária contendo a posição x maçã
  y_apple   RESB 2 ;Registrador na memória primária contendo a posição y da maçã
  
section  .text
  global _start 
; Procedure _start
; Faz a chamada de das procedures que serão responsáveis pelo fluxo inicial do programa
; SetVideoMode - Define os parametros 
; SetInitialCoords - Define as coordenadas iniciais da maçã e da cobra
; Debug - Limpa os registradores e redefine o cursor da VSync e HSync para 

_start:
  CALL SetVideoMode
  CALL SetInitialCoords
  CALL ClearScreen
  CALL Debug
  CALL ListenForInput
; Chama interrupção de video SetVideoMode 0x10 com AH = 0x00 
; AL -  registrador responsável pelo modo de vídeo
; O parametro  0x13 corresponde as configurações seguintes;
; text/      text    pixel   pixel     colors     display   screen     system
; 13h    G  40x25    8x8    320x200    256/256K     .       A000   VGA,MCGA,ATI VIP
;
SetVideoMode:
  MOV AH, 0x00
  MOV AL, 0x13
  INT 0x10
  RET
 ;#Procedure - Clear Screen
 ; Limpa os registradores CX e DX, e do inicio ao ultimo pixel da resolução configurada com a cor preta;
 ; Resolução 320 x 255 
 ; AL - 0h Define como cor preta;
 ; CX - coordenada do pixel na vertical
 ; DX - coordenada do pixel na  horizontal
 ; BH - Número da página
ClearScreen:
  MOV CX, 0x00
  MOV DX, 0x00
  MOV AL, 0xFF
  MOV BH, 0x00
  MOV AH, 0x0C
  .x_loop_begin: ;Inicia o loop em 0 até 255 em "X - linha"
  MOV CX, 0x00 
  .y_loop_begin: ;Inicia o loop em 0 até 255 em "Y - Coluna"
  INT 0x10 ;Interrupção de configuração de video - pinta o pixel  (Dx,Cx) na cor preta no frame;
  INC CX ; incrementa em CX (Y) uma unidade
  CMP CX, 0x140 ; Verifica se chegou na posição cx 320
  JNAE .y_loop_begin  ;Caso não tenha chegado na posição 320 ele retornará para o inicio do loop;
  .y_loop_end:
  INC DX ; incrementa em DX (X) uma unidade
  CMP DX, 0xFF ;Verifica se chegou na posição 255
  JNAE .x_loop_begin
  .x_loop_end:
  RET ;Finaliza a limpeza da tela retornando para o ultima procedure da pilha

; Define as coordenadas iniciais do loop
SetInitialCoords:
  MOV AX, 0x0F ; Initial x/y coord
  MOV BX, 0x00
  MOV DX, TOTAL_SEGMENTS
  ADD DX, DX
  .initialize_loop_begin:
  MOV [x_coord+BX], AX
  MOV [y_coord+BX], AX
  ADD BX, 0x02
  CMP BX, DX
  JNE .initialize_loop_begin
  
  MOV AX, 0x00
  MOV [t1]       , AX
  MOV [t2]       , AX
  MOV AX, 2
  MOV [enabled]  , AX

  CALL RandomNumber ; Chama função que retorna um número aleatório e salva em eax
  MOV [x_apple], AX ; Atribui o número aletório gerado na posição x da maçã
  CALL RandomNumber ; Chama função que retorna um número aleatório e salva em eax
  MOV [y_apple], AX ; Atribui o número aletório gerado na posição x da maçã
  RET


;/*
; Essa função tem o objetivo de "escutar"" os digitos dos teclados através da
; interrupção 0x16, definindo ah a interrupção só atrubui em eax após alguma 
; tecla ser acionada
;*/
ListenForInput:  ; Em loop checa se houve algum digito
  MOV AH, 0x00 ; Set AH to 0 to lock when listening for key
  
  INT 0x16   ; Escuta um acionamento de tecla e salva em AL
  
  CALL InterpretKeypress ; Chama Procedure que cuidará da intepretação da tecla

  CALL ListenForInput
  RET

;/*
; Essa função tem o objetivo de interpretar os digitos do teclado
; os digitos aceitados são: w,a,s,d com codigos ascii 0x77,0x61,0x73,0x64
; Se
;*/
InterpretKeypress:

  CMP AL, 0x77 ; Compara com o registrador al se o valor é igual a "w"
  JE .w_pressed ; direciona para função que trata quando w é pressionado;

  CMP AL, 0x61 ; Compara com registrador al se o valor é igual  "a"
  JE .a_pressed; direciona para função que trata quando a é pressionado

  CMP AL, 0x73 ; Compara com registrador al se o valor é igual  "s"
  JE .s_pressed ; direciona para função que trata quando s é pressionado

  CMP AL, 0x64 ; Compara com registrador al se o valor é igual  "d"
  JE .d_pressed ; direciona para função que trata quando d é pressionado
  JMP Debug ; Caso não tenha digitado uma tecla válida desenha um pixel em 0,0 do frame

  RET ; 

  ;Trata a tecla w
  .w_pressed:
  MOV AX, [x_coord] ; move para o registrador ax a posição corrente da cobra na horizontal
  MOV BX, [y_coord] ; move para o registrador bx a posição corrente da cobra na vertical
  DEC BX ;  decrementa em uma unidade a linha fazendo que a cobra seja movida para cima
  JMP .after_control_handle ;
  ;Trata a tecla a
  .a_pressed:
  MOV AX, [x_coord] ; move para o registrador ax a posição corrente da cobra na horizontal
  MOV BX, [y_coord] ; move para o registrador bx a posição corrente da cobra na vertical
  DEC AX ;  decrementa em uma unidade a coluna fazendo que a cobra seja movida para esquerda
  JMP .after_control_handle
  ;Trata a tecla s
  .s_pressed:
  MOV AX, [x_coord] ; move para o registrador ax a posição corrente da cobra na horizontal
  MOV BX, [y_coord] ; move para o registrador bx a posição corrente da cobra na vertical
  INC BX ;  incrementa em uma unidade a linha fazendo que a cobra seja movida para baixo
  JMP .after_control_handle 
  ;Trata a tecla d
  .d_pressed:
  MOV AX, [x_coord] ; move para o registrador ax a posição corrente da cobra na horizontal
  MOV BX, [y_coord] ; move para o registrador bx a posição corrente da cobra na vertical
  INC AX ;  incrementa em uma unidade a linha fazendo que a cobra seja movida para direita
 
 ;#after_control_handle - Ações que serão tomadas após apertar o botão
 ; Guarda na memória o cursor da cobra, verifica se houve colisão da maçã,
 ; desenha  a maçã e cobra
 ;
  .after_control_handle:
  MOV [t1], AX ; Guarda na memória a posição x da cobra;
  MOV [t2], BX ; Guarda ma memória a posição Y da cobra;
  CALL CheckAppleCollision ; Verifica se houve colisão com a maçã
  CALL ShiftArray ;
  CALL DrawSnake ; Desenha a cobra
  CALL DrawApple ;  Desenha a maçã
  RET

;#CheckAppleCollision - Verificador de colisão com a maçã
;Verifica se houve colisão entre a posição corrente da cobra (AX,BX) e  da maçã(x_apple,y_apple)

CheckAppleCollision:
  CMP AX, [x_apple] ; Compara se colide com a maçã em x
  JNE .no_collision ;não havendo colisão não faz nada

  CMP BX, [y_apple]; Compara se colide com a maçã em y 
  JNE .no_collision;não havendo colisão não faz nada
  ; TODO - Não sei o que faz
  MOV AX, [enabled];
  INC AX
  MOV [enabled], AX
  ;Havendo a colisão gera uma nova posição para a maçã em x e y
  CALL RandomNumber
  MOV [x_apple], AX
  CALL RandomNumber
  MOV [y_apple], AX

  .no_collision:
  RET

;#DrawApple - Desenha a maçã 
;Desenha o pixel vermelho que represetará a maçã na tela
DrawApple:
  MOV CX, [x_apple] ; Atribbui ao registrador CX a posição x da maçã
  MOV DX, [y_apple] ; Atribui ao registrador DX a posição y da maçã
  MOV AL, 0x0C ; cor da maçã - Vermelho
  CALL DrawPixel ; Chama procedure que desenhará o pixel na tela;
  RET

;#DrawSnake - Desenha a cobra
;Para desenhar a cobra primeiramente são apagados o todos os pixels, desenhando com cor preta;
;
DrawSnake:
  CALL ClearScreen ; Limpa a tela
  MOV BX, 0x00
  MOV AL, 0x0A ;define a cor do pixel -  Verde;
  MOV [t1], BX
  .draw_snake_loop_begin: ; inicia o loop para desenhar a cobra
   CMP [enabled], BX
   JBE .skip ;TODO - Sendo bx menor ou igual a  enabled sai do loop;
   MOV [t1], BX
   ADD BX, BX 
   MOV CX, [x_coord+BX] ; coordenada em que o pixel da cobra será desenhado em x
   MOV DX, [y_coord+BX] ; coordenada em que o pixel da cobra será desenhado em y
   CALL DrawPixel ; Desenha um pixel
   MOV BX, [t1]
   INC BX
   JMP .draw_snake_loop_begin
  
  .skip:
  RET

;TODO - não entendi
ShiftArray:
  MOV BX, TOTAL_SEGMENTS
  DEC BX
  ADD BX, BX
  .loop_begin:
   ADD BX, -2
   MOV DX, [x_coord+BX]
   MOV CX, [y_coord+BX]
   ADD BX, 2
   MOV [x_coord+BX], DX
   MOV [y_coord+BX], CX
   ADD BX, -2
   CMP BX, 0x00
   JNE .loop_begin
  MOV DX, [t1]
  MOV [x_coord], DX
  MOV DX, [t2]
  MOV [y_coord], DX
  RET

 ;/**
 ; A ao acionar a interrupção 0x10 o sistema operacional se encarregará de criar desenhar em uma determinada posição
 ; no monitor um pixel. Para definir como será escrito o pixel definimos  os seguintes registradores;
 ; CX - Coluna
 ; DX - Linha
 ; BH - Número da página
 ;  AL - Cor do Pixel
 ;*/
DrawPixel:
  MOV AH, 0x0C     ; Draw mode
  MOV BH, 0x00     ; Pg 0
  INT 0x10           ; Draw
  RET
 ;/**
 ;  A procedure RandomNumber gera um número aletório de 32 16 bits fazendo acesso ao TSC(Time Stamp counter) que conta o número de ciclos 
 ;  desde o reset do processador 
 ;  exemplo: supondo que o contador esteja com o valor : 11111111111111111111111101101111 e fazendo um and com 1111111111111111
 ;  retorará os 16 bits partindo do LSB; 1111111101101111
 ;  
 ;*/
RandomNumber:
  RDTSC ; Retorna o contador de timeStamp em EAX
  AND EAX, 0xF ; retorna os 16 bits menos significativos do contador retornando sempre um valor diferente a cada chamada e armazena em eax;
  RET

 ;/* Para caso nenhuma das opções sejam selecionadas  desenha um pixel preto na posição 0,0 
 ;  CX - Coluna
 ;  DX - Linha
 ;  AL - Cor do Pixel
 ;*/
Debug:
  MOV AL, 0x0A
  MOV CX, 0x00
  MOV DX, 0x00
  CALL DrawPixel
  RET

TIMES 510 - ($ - $$) db 0  ;Fill the rest of sector with 0
DW 0xAA55      ;Add boot signature at the end of bootloader
