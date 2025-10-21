;================================================================
;        CONFIGURACI?N INICIAL Y DEFINICI?N DE VARIABLES
;================================================================
    processor 16f877
    include<p16f877.inc>

; -- Variables para retardos --
valor  equ h'20'
valor1 equ h'21'
valor2 equ h'22'

; -- Variables para conversi?n ADC --
adc_resultado equ h'23' ; Resultado ADC de 8 bits
temp          equ h'24' ; Variable temporal

centenas      equ h'25' ; Dígito de centenas (decimal)
decenas       equ h'26' ; Dígito de decenas (decimal)
unidades      equ h'27' ; Dígito de unidades (decimal)
hex_high      equ h'28' ; Nibble alto (hexadecimal)
hex_low       equ h'29' ; Nibble bajo (hexadecimal)

;================================================================
;                       VECTORES DE RESET
;================================================================
    org 0
    goto inicio

    org 5
;================================================================
;                         PROGRAMA PRINCIPAL
;================================================================
inicio:
    ; -- Configuraci?n de puertos --
    clrf    PORTD       ; Limpia el puerto D
    clrf    PORTB       ; Limpia el puerto B
    clrf    PORTA       ; Limpia el puerto A
    
    bsf     STATUS,5    ; Cambia al Banco 1 de memoria
    bcf     STATUS,6
    
    movlw   0x00        ; Configura el puerto B como salida
    movwf   TRISB
    movlw   0x00        ; Configura el puerto D como salida
    movwf   TRISD
    movlw   0x01        ; Configura RA0 como entrada (para ADC)
    movwf   TRISA

    MOVLW   00H
    MOVWF   ADCON1      ; Configurar el puerto A como entrada anal?gica
    
    bcf     STATUS,5    ; Regresa al Banco 0 de memoria
    
    ; -- Configuraci?n del m?dulo ADC --
    movlw   b'11000001' ; ADCON0: ADC habilitado, canal 0 (RA0), Fosc/64, justificado izquierda
    movwf   ADCON0
    
    ; -- L?gica principal --
    call    inicia_lcd  ; Llama a la subrutina de inicializaci?n del LCD
    
    ; Mensaje inicial
    movlw   0x80        ; Posici?n inicial (l?nea 1)
    call    comando
    
	call ret100ms
    movlw   'V'
    call    datos
    movlw   'O'
    call    datos
    movlw   'L'
    call    datos
    movlw   'T'
    call    datos
    movlw   'I'
    call    datos
    movlw   'M'
    call    datos
    movlw   'E'
    call    datos
    movlw   'T'
    call    datos
    movlw   'R'
    call    datos
    movlw   'O'
    call    datos
    
    call    ret100ms


	call bucle_principal

;================================================================
;                      BUCLE PRINCIPAL
;================================================================
bucle_principal:
    call    leer_adc        ; Lee el valor del ADC
    call    mostrar_decimal ; Muestra en binario
    call    ret200         ; Retardo entre lecturas
    goto    bucle_principal

;================================================================
;                 SUBRUTINA DE LECTURA DEL ADC
;================================================================
leer_adc:
    bsf     ADCON0,2        ; Inicia la conversi?n (GO/DONE=1)
	call ret200
    
    ; Guarda el resultado (8 bits m?s significativos en ADRESH)
    movf    ADRESH,W        ; Lee resultado de 8 bits
    movwf   adc_resultado
    return

;================================================================
;           SUBRUTINA PARA MOSTRAR EN BINARIO
;================================================================
mostrar_binario:
    ; Limpiar segunda l?nea
    movlw   0xC0            ; Segunda l?nea, posici?n 0
    call    comando
    
    ; Cargar el resultado ADC en temp para procesarlo
    movf    adc_resultado,W
    movwf   temp
    
    ; Mostrar los 8 bits (bit 7 a bit 0)
    
    ; Bit 7 (m?s significativo)
    btfsc   temp,7
    goto    bit7_es_1
    movlw   '0'
    goto    mostrar_bit7
bit7_es_1:
    movlw   '1'
mostrar_bit7:
    call    datos
    
    ; Bit 6
    btfsc   temp,6
    goto    bit6_es_1
    movlw   '0'
    goto    mostrar_bit6
bit6_es_1:
    movlw   '1'
mostrar_bit6:
    call    datos
    
    ; Bit 5
    btfsc   temp,5
    goto    bit5_es_1
    movlw   '0'
    goto    mostrar_bit5
bit5_es_1:
    movlw   '1'
mostrar_bit5:
    call    datos
    
    ; Bit 4
    btfsc   temp,4
    goto    bit4_es_1
    movlw   '0'
    goto    mostrar_bit4
bit4_es_1:
    movlw   '1'
mostrar_bit4:
    call    datos
    
    ; Bit 3
    btfsc   temp,3
    goto    bit3_es_1
    movlw   '0'
    goto    mostrar_bit3
bit3_es_1:
    movlw   '1'
mostrar_bit3:
    call    datos
	call ret100ms
    
    ; Bit 2
    btfsc   temp,2
    goto    bit2_es_1
    movlw   '0'
    goto    mostrar_bit2
bit2_es_1:
    movlw   '1'
mostrar_bit2:
    call    datos
    
    ; Bit 1
    btfsc   temp,1
    goto    bit1_es_1
    movlw   '0'
    goto    mostrar_bit1
bit1_es_1:
    movlw   '1'
mostrar_bit1:
    call    datos
    
    ; Bit 0 (menos significativo)
    btfsc   temp,0
    goto    bit0_es_1
    movlw   '0'
    goto    mostrar_bit0
bit0_es_1:
    movlw   '1'
mostrar_bit0:
    call    datos
    return


;================================================================
;           SUBRUTINA PARA MOSTRAR EN DECIMAL
;================================================================
mostrar_decimal:
    ; Limpiar segunda línea
    movlw   0xC0            ; Segunda línea, posición 0
    call    comando
    
    ; Separar el valor en centenas, decenas y unidades
    movf    adc_resultado,W
    movwf   temp
    clrf    centenas
    clrf    decenas
    clrf    unidades
    
    ; Calcular centenas (restar 100 repetidamente)
calcular_centenas:
    movlw   d'100'
    subwf   temp,W
    btfss   STATUS,C        ; ¿Resultado negativo?
    goto    calcular_decenas
    movwf   temp
    incf    centenas,F
    goto    calcular_centenas
    
    ; Calcular decenas (restar 10 repetidamente)
calcular_decenas:
    movlw   d'10'
    subwf   temp,W
    btfss   STATUS,C        ; ¿Resultado negativo?
    goto    calcular_unidades
    movwf   temp
    incf    decenas,F
    goto    calcular_decenas
    
calcular_unidades:
    movf    temp,W
    movwf   unidades
    
    ; Mostrar en LCD
    movf    centenas,W
    addlw   0x30            ; Convertir a ASCII
    call    datos
    
    movf    decenas,W
    addlw   0x30            ; Convertir a ASCII
    call    datos
    
    movf    unidades,W
    addlw   0x30            ; Convertir a ASCII
    call    datos
    
    ; Mostrar " DEC"
    movlw   ' '
    call    datos
    movlw   'D'
    call    datos
    movlw   'E'
    call    datos
    movlw   'C'
    call    datos
    
    return

;================================================================
;           SUBRUTINA PARA MOSTRAR EN HEXADECIMAL
;================================================================
mostrar_hexadecimal:
    ; Limpiar segunda línea
    movlw   0xC0            ; Segunda línea, posición 0
    call    comando
    
    ; Separar en nibbles (4 bits cada uno)
    movf    adc_resultado,W
    movwf   temp
    
    ; Nibble alto (bits 7-4)
    swapf   temp,W          ; Intercambia nibbles
    andlw   0x0F            ; Enmascara nibble bajo
    movwf   hex_high
    
    ; Nibble bajo (bits 3-0)
    movf    temp,W
    andlw   0x0F            ; Enmascara nibble bajo
    movwf   hex_low
    
    ; Mostrar "0x"
    movlw   '0'
    call    datos
    movlw   'x'
    call    datos
    
    ; Mostrar nibble alto
    movf    hex_high,W
    call    hex_a_ascii
    call    datos
    
    ; Mostrar nibble bajo
    movf    hex_low,W
    call    hex_a_ascii
    call    datos
    
    ; Mostrar " HEX"
    movlw   ' '
    call    datos
    movlw   'H'
    call    datos
    movlw   'E'
    call    datos
    movlw   'X'
    call    datos
    
    return

;================================================================
;           SUBRUTINA PARA CONVERTIR NIBBLE A ASCII
;================================================================
hex_a_ascii:
    ; Convierte un nibble (0-F) a su carácter ASCII
    movwf   temp
    sublw   d'9'            ; W = 9 - temp
    btfss   STATUS,C        ; ¿Es <= 9?
    goto    es_letra
    ; Es número (0-9)
    movf    temp,W
    addlw   0x30            ; Convertir a ASCII '0'-'9'
    return
es_letra:
    ; Es letra (A-F)
    movf    temp,W
    addlw   0x37            ; Convertir a ASCII 'A'-'F' (0x41-0x46)
    return





;================================================================
;                 SUBRUTINA DE INICIALIZACI?N DEL LCD
;================================================================
inicia_lcd:
    call    ret100ms        ; Espera inicial
    
    movlw   0x30            ; Comando de inicializaci?n
    call    comando
    call    ret100ms        ; Retardo de 100ms
    
    movlw   0x30
    call    comando
    call    ret100ms        ; Retardo de 100ms
    
    movlw   0x38            ; Configura LCD: 2 l?neas, matriz de 5x8
    call    comando
    
    movlw   0x0c            ; Enciende el display, cursor apagado
    call    comando
    
    movlw   0x01            ; Limpia la pantalla (Clear Display)
    call    comando
    call    ret100ms
    
    movlw   0x06            ; Configura modo de entrada: incrementa cursor
    call    comando
    
    movlw   0x02            ; Retorna el cursor al inicio (Return Home)
    call    comando
    return

;================================================================
;                 SUBRUTINAS DE CONTROL Y DATOS
;================================================================
; -- Subrutina para enviar un COMANDO a la LCD --
comando:
    movwf   PORTB           ; Mueve el valor de W al puerto B (Bus de Datos)
    call    ret200          ; Peque?o retardo
    bcf     PORTD,0         ; Pone RS en 0 para indicar que es un comando
    bsf     PORTD,1         ; Pone E (Enable) en 1 para iniciar la escritura
    call    ret200          ; Peque?o retardo
    bcf     PORTD,1         ; Pone E (Enable) en 0 para finalizar la escritura
    call    ret200
    return

; -- Subrutina para enviar un DATO (car?cter) a la LCD --
datos:
    movwf   PORTB           ; Mueve el valor de W al puerto B (Bus de Datos)
    call    ret200          ; Peque?o retardo
    bsf     PORTD,0         ; Pone RS en 1 para indicar que es un dato
    bsf     PORTD,1         ; Pone E (Enable) en 1 para iniciar la escritura
    call    ret200          ; Peque?o retardo
    bcf     PORTD,1         ; Pone E (Enable) en 0 para finalizar la escritura
    call    ret200
    return

;================================================================
;                      SUBRUTINAS DE RETARDO
;================================================================
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

;================================================================
    end                     ; Fin del programa
;================================================================