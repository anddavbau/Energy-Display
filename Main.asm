processor 16f877
include <p16f877.inc>

valor  equ h'20'
valor1 equ h'21'
valor2 equ h'22'

ORG 0
GOTO INICIO

ORG 5
INICIO:	BCF STATUS,RP0
		BCF STATUS,RP1;Cambiamos al banco 0
		CLRF PORTA
		CLRF PORTB
		CLRF PORTD;Limpiamos los puertos A,B y D
		BSF STATUS,RP0;Cambiamos al banco 1
		MOVLW H'07'
		MOVWF ADCON1;Utilizamos las entradas A y E como entradas del convertidor.
		CLRF TRISA;Definimos el puerto A como salida(Control y señal de entrada
		CLRF TRISB;Definimos el puerto B como salida (Control del BUS LCD)
		CLRF TRISD;Definimos el puerto D como salida (Control del motor)
		MOVLW H'FF'
		MOVWF TRISE;Definimos el puerto E como entrada
		BCF STATUS,RP0;Cambiamos al banco 0
		MOVLW B'00010000';Definimos a AN2/Puerto A2 como entrada de señal.
		MOVWF ADCON0
		BSF ADCON0,ADCS1
		BCF ADCON0,ADCS0;Configuramos reloj a 20 MHz
		BSF ADCON0,ADON;Encendemos el A/D
		CALL START_LCD
MAIN_L:	MOVF PORTE,W
		XORLW H'00'
		BTFSC STATUS,Z
		GOTO S0

		MOVF PORTE,W
		XORLW H'01'
		BTFSC STATUS,Z
		GOTO S1

		MOVF PORTE,W
		XORLW H'02'
		BTFSC STATUS,Z
		GOTO S2

		MOVF PORTE,W
		XORLW H'03'
		BTFSC STATUS,Z
		GOTO S3

		MOVF PORTE,W
		XORLW H'04'
		BTFSC STATUS,Z
		GOTO S4

		MOVF PORTE,W
		XORLW H'05'
		BTFSC STATUS,Z
		GOTO S5

		MOVF PORTE,W
		XORLW H'06'
		BTFSC STATUS,Z
		GOTO S6

		GOTO MAIN_L

S0:		; --- MENSAJE LÍNEA 1: "Proyecto No.2" ---
    	movlw   0x80        ; Comando para posicionar cursor en línea 1, columna 1
    	call    COMANDO
    
	    movlw   'H'
		call    DATOS
		movlw   'P'
	    call    DATOS
	    movlw   'r'
	    call    DATOS
	    movlw   'o'
	    call    DATOS
	    movlw   'y'
	    call    DATOS
	    movlw   'e'
	    call    DATOS
	    movlw   'c'
	    call    DATOS
	    movlw   't'
	    call    DATOS
	    movlw   'o'
	    call    DATOS
	    movlw   ' '
	    call    DATOS
	    movlw   'N'
	    call    DATOS
	    movlw   'o'
	    call    DATOS
	    movlw   '.'
	    call    DATOS
	    movlw   '2'
	    call    DATOS
	
	    ; --- MENSAJE LÍNEA 2: "VOLMETRO" ---
	    movlw   0xC0        ; Comando para posicionar cursor en línea 2, columna 1
	    call    COMANDO
	
	    movlw   'V'
	    call    DATOS
	    movlw   'O'
	    call    DATOS
	    movlw   'L'
	    call    DATOS
	    movlw   'M'
	    call    DATOS
	    movlw   'E'
	    call    DATOS
	    movlw   'T'
	    call    DATOS
	    movlw   'R'
	    call    DATOS
	    movlw   'O'
	    call    DATOS
S0_WAIT:MOVF PORTE,W
		XORLW H'00'
		BTFSS STATUS,Z
		GOTO MAIN_L
		GOTO S0_WAIT

S1:		GOTO MAIN_L

S2:		GOTO MAIN_L

S3:		GOTO MAIN_L

S4:		GOTO MAIN_L

S5:		GOTO MAIN_L

S6:		GOTO MAIN_L

START_LCD:
		MOVLW H'30';Comando de inicializacion
		CALL COMANDO
		CALL ret100ms;Genera retraso de 100ms
		
		MOVLW H'30'
		CALL COMANDO
		CALL ret100ms
		
		MOVLW H'38';Configura LCD: 2 lineas, matriz de 5x8
		CALL COMANDO

		MOVLW H'0C';Enciende el display, cursor apagado
		CALL COMANDO

		MOVLW H'01';Limpia la pantalla
		CALL COMANDO

		MOVLW H'06';Configura modo de entrada: Incrementa cursor
		CALL COMANDO

		MOVLW H'02';Retorna el cursor al inicio 
		CALL COMANDO
		RETURN

COMANDO:MOVWF PORTB;Mueve el valor de W al puerto B (Bus de Datos)
		CALL ret200
		BCF PORTA,0;Pone RS en 0 para indicar que es un COMANDO
		BSF PORTA,1;Pone Enable en 1 para iniciar la escritura
		CALL ret200
		BCF PORTA,1;Pone Enable en 0 para finalizar la escritura
		MOVF PORTB,W;Recuperamos el valor de W
		RETURN

DATOS:	MOVWF PORTB;Mueve el valor de W al puerto B (Bus de DATOS)
		CALL ret200
		BSF PORTA,0;Pone RS en 1 para indicar que es un dato
		BSF PORTA,1;Pone Enable en 1 para iniciar la escritura
		CALL ret200
		BCF PORTA,1;Pone Enable en 0 para finalizar la escritura
		MOVF PORTB,W;Recuperamos el valor de W
		RETURN

; -- Retardo de ~200 microsegundos --
ret200:
    movlw   0x02
    movwf   valor1
loop:
    movlw   d'164'
    movwf   valor
loop1:
    decfsz  valor,1
    goto    loop1
    decfsz  valor1,1
    goto    loop
    return

; -- Retardo de ~100 milisegundos --
ret100ms:
    movlw   0x03
    movwf   valor
tres:
    movlw   0xff
    movwf   valor1
dos:
    movlw   0xff
    movwf   valor2
uno:
    decfsz  valor2
    goto    uno
    decfsz  valor1
    goto    dos
    decfsz  valor
    goto    tres
    return
		END