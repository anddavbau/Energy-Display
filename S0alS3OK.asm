
processor 16f877
include<p16f877.inc>

; -- Variables para retardos --
valor  equ h'20'
valor1 equ h'21'
valor2 equ h'22'

; -- Variables para conversión ADC --
adc_resultado equ h'23'
temp          equ h'24'
centenas      equ h'25'
decenas       equ h'26'
unidades      equ h'27'
hex_high      equ h'28'
hex_low       equ h'29'

; -- Variables para conversión a voltaje --
volt_entero      equ h'2A'
volt_dec1        equ h'2B'
volt_dec2        equ h'2C'
mult_resultado_h equ h'2D'
mult_resultado_l equ h'2E'
temp_quotient    equ h'2F'

; -- CONSTANTES PARA LOS ESTADOS (LEIDOS DESDE PORTE) --
ESTADO_INICIO     EQU B'00000000' ; RE2,RE1,RE0 = 000 -> Modo Inicio
ESTADO_BINARIO    EQU B'00000001' ; RE0=1 -> Modo Binario
ESTADO_DECIMAL    EQU B'00000010' ; RE1=1 -> Modo Decimal
ESTADO_HEX        EQU B'00000011' ; RE0=1, RE1=1 -> Modo Hexadecimal
ESTADO_VOLTAJE    EQU B'00000100' ; RE2=1 -> Modo Voltaje

;================================================================
;                         VECTORES DE RESET
;================================================================
    org 0
    goto inicio
    org 5

;================================================================
;                          PROGRAMA PRINCIPAL
;================================================================
inicio:
    clrf    PORTD
    clrf    PORTB
    clrf    PORTA
    clrf    PORTE
    
    bsf     STATUS,5
    
    movlw   0x00
    movwf   TRISB
    movlw   0x00
    movwf   TRISD
    movlw   0x01
    movwf   TRISA
    movlw   b'00000111'
    movwf   TRISE
    movlw   0x0E
    movwf   ADCON1
    
    bcf     STATUS,5
    
    movlw   b'11000001'
    movwf   ADCON0
    
    call    inicia_lcd
    

    goto    control_estados

;================================================================
;                  BUCLE DE CONTROL DE ESTADOS
;================================================================
control_estados:
    movf    PORTE,W
    andlw   b'00000111'

    xorlw   ESTADO_BINARIO
    btfsc   STATUS,Z
    goto    MODO_BINARIO

    movf    PORTE,W
    andlw   b'00000111'
    xorlw   ESTADO_DECIMAL
    btfsc   STATUS,Z
    goto    MODO_DECIMAL

    movf    PORTE,W
    andlw   b'00000111'
    xorlw   ESTADO_HEX
    btfsc   STATUS,Z
    goto    MODO_HEXADECIMAL

    movf    PORTE,W
    andlw   b'00000111'
    xorlw   ESTADO_VOLTAJE
    btfsc   STATUS,Z
    goto    MODO_VOLTAJE

    ; Si no coincide ninguno, va al estado de inicio por defecto
    goto    MODO_INICIO

;================================================================
;                 BUCLES PARA CADA MODO
;================================================================

MODO_INICIO:
    ; Primero, muestra el mensaje de bienvenida
    movlw   0x80
    call    comando
	call 	ret100ms
    movlw   'P'
    call    datos
    movlw   'r'
    call    datos
    movlw   'o'
    call    datos
    movlw   'y'
    call    datos
    movlw   'e'
    call    datos
    movlw   'c'
    call    datos
    movlw   't'
    call    datos
    movlw   'o'
    call    datos
    movlw   ' '
    call    datos
    movlw   'N'
    call    datos
    movlw   'o'
    call    datos
    movlw   '.'
    call    datos
    movlw   '2'
    call    datos
    
    movlw   0xC0
    call    comando
    
    movlw   'V'
    call    datos
    movlw   'O'
    call    datos
    movlw   'L'
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

inicio_loop:
    ; Ahora se queda en un bucle revisando si el estado ha cambiado
    movf    PORTE,W
    andlw   b'00000111'
    xorlw   ESTADO_INICIO
    btfss   STATUS,Z
    goto    salir_de_inicio
    goto    inicio_loop

salir_de_inicio:
    call    restaurar_titulo
    goto    control_estados

MODO_BINARIO:
    movf    PORTE,W
    andlw   b'00000111'
    xorlw   ESTADO_BINARIO
    btfss   STATUS,Z
    goto    control_estados
    call    leer_adc
    call    mostrar_binario
    call    ret200
    goto    MODO_BINARIO

MODO_DECIMAL:
    movf    PORTE,W
    andlw   b'00000111'
    xorlw   ESTADO_DECIMAL
    btfss   STATUS,Z
    goto    control_estados
    call    leer_adc
    call    mostrar_decimal
    call    ret200
    goto    MODO_DECIMAL

MODO_HEXADECIMAL:
    movf    PORTE,W
    andlw   b'00000111'
    xorlw   ESTADO_HEX
    btfss   STATUS,Z
    goto    control_estados
    call    leer_adc
    call    mostrar_hexadecimal
    call    ret200
    goto    MODO_HEXADECIMAL

MODO_VOLTAJE:
    movf    PORTE,W
    andlw   b'00000111'
    xorlw   ESTADO_VOLTAJE
    btfss   STATUS,Z
    goto    control_estados
    call    leer_adc
    call    mostrar_voltaje
    call    ret200
    goto    MODO_VOLTAJE

;================================================================
;           *** NUEVA RUTINA PARA RESTAURAR EL TÍTULO ***
;================================================================
restaurar_titulo:
    movlw   0x80
    call    comando
    movlw   'V'
    call    datos
    movlw   'O'
    call    datos
    movlw   'L'
    call    datos
    movlw   'T'
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
    movlw   ' '
    call    datos
    movlw   ' '
    call    datos

    ; Limpiar los caracteres sobrantes de "Proyecto No.2"
    movlw   ' '
    call    datos
    movlw   ' '
    call    datos
    movlw   ' '
    call    datos
    return

;====================================================================
;       SUBRUTINA PARA MOSTRAR VOLTAJE (corregir)
;====================================================================
mostrar_voltaje:
    clrf    mult_resultado_h
    clrf    mult_resultado_l
    movlw   d'100'
    movwf   temp
mult_100_loop:
    movf    adc_resultado, W
    addwf   mult_resultado_l, F
    btfsc   STATUS, C
    incf    mult_resultado_h, F
    decfsz  temp, F
    goto    mult_100_loop

    clrf    temp_quotient
div_51_loop:
    movf    mult_resultado_h, W
    sublw   0
    btfsc   STATUS, Z
    goto    div_check_low
    goto    div_subtract
div_check_low:
    movf    mult_resultado_l, W
    sublw   d'51'
    btfss   STATUS, C
    goto    div_51_fin
div_subtract:
    movlw   d'51'
    subwf   mult_resultado_l, F
    btfss   STATUS, C
    decf    mult_resultado_h, F
    incf    temp_quotient, F
    goto    div_51_loop
div_51_fin:
    
    movf    temp_quotient, W
    movwf   temp
    clrf    volt_entero
    clrf    volt_dec1
sep_unidades:
    movlw   d'100'
    subwf   temp, W
    btfss   STATUS, C
    goto    sep_decimas
    incf    volt_entero, F
    movwf   temp
    goto    sep_unidades
sep_decimas:
    movlw   d'10'
    subwf   temp, W
    btfss   STATUS, C
    goto    sep_centesimas
    incf    volt_dec1, F
    movwf   temp
    goto    sep_decimas
sep_centesimas:
    movf    temp, W
    movwf   volt_dec2

    movlw   0xC0
    call    comando
    movf    volt_entero, W
    addlw   '0'
    call    datos
    movlw   '.'
    call    datos
    movf    volt_dec1, W
    addlw   '0'
    call    datos
    movf    volt_dec2, W
    addlw   '0'
    call    datos
    movlw   ' '
    call    datos
    movlw   'V'
    call    datos
    movlw   ' '
    call    datos
    movlw   ' '
    call    datos
    return

;================================================================
;           *** SUBRUTINAS ***
;================================================================
leer_adc:
    bsf     ADCON0,2
    call ret200
    movf    ADRESH,W
    movwf   adc_resultado
    return
;----------------------------------------------------------------
mostrar_binario:
    movlw   0xC0
    call    comando
    movf    adc_resultado,W
    movwf   temp
bit7_es_1:
    btfsc   temp,7
    goto    es_1_b7
    movlw   '0'
    goto    mostrar_bit7
es_1_b7:
    movlw   '1'
mostrar_bit7:
    call    datos
bit6_es_1:
    btfsc   temp,6
    goto    es_1_b6
    movlw   '0'
    goto    mostrar_bit6
es_1_b6:
    movlw   '1'
mostrar_bit6:
    call    datos
bit5_es_1:
    btfsc   temp,5
    goto    es_1_b5
    movlw   '0'
    goto    mostrar_bit5
es_1_b5:
    movlw   '1'
mostrar_bit5:
    call    datos
bit4_es_1:
    btfsc   temp,4
    goto    es_1_b4
    movlw   '0'
    goto    mostrar_bit4
es_1_b4:
    movlw   '1'
mostrar_bit4:
    call    datos
bit3_es_1:
    btfsc   temp,3
    goto    es_1_b3
    movlw   '0'
    goto    mostrar_bit3
es_1_b3:
    movlw   '1'
mostrar_bit3:
    call    datos
    call ret100ms
bit2_es_1:
    btfsc   temp,2
    goto    es_1_b2
    movlw   '0'
    goto    mostrar_bit2
es_1_b2:
    movlw   '1'
mostrar_bit2:
    call    datos
bit1_es_1:
    btfsc   temp,1
    goto    es_1_b1
    movlw   '0'
    goto    mostrar_bit1
es_1_b1:
    movlw   '1'
mostrar_bit1:
    call    datos
bit0_es_1:
    btfsc   temp,0
    goto    es_1_b0
    movlw   '0'
    goto    mostrar_bit0
es_1_b0:
    movlw   '1'
mostrar_bit0:
    call    datos
    return
;----------------------------------------------------------------
mostrar_decimal:
    movlw   0xC0
    call    comando
    movf    adc_resultado,W
    movwf   temp
    clrf    centenas
    clrf    decenas
    clrf    unidades
calcular_centenas:
    movlw   d'100'
    subwf   temp,W
    btfss   STATUS,C
    goto    calcular_decenas
    movwf   temp
    incf    centenas,F
    goto    calcular_centenas
calcular_decenas:
    movlw   d'10'
    subwf   temp,W
    btfss   STATUS,C
    goto    calcular_unidades
    movwf   temp
    incf    decenas,F
    goto    calcular_decenas
calcular_unidades:
    movf    temp,W
    movwf   unidades
    movf    centenas,W
    addlw   0x30
    call    datos
    movf    decenas,W
    addlw   0x30
    call    datos
    movf    unidades,W
    addlw   0x30
    call    datos
    movlw   ' '
    call    datos
    movlw   'D'
    call    datos
    movlw   'E'
    call    datos
    movlw   'C'
    call    datos
    movlw   ' ' ; Tu solución
    call    datos
    movlw   ' ' ; Tu solución
    call    datos
    return
;----------------------------------------------------------------
mostrar_hexadecimal:
    movlw   0xC0
    call    comando
    movf    adc_resultado,W
    movwf   temp
    swapf   temp,W
    andlw   0x0F
    movwf   hex_high
    movf    temp,W
    andlw   0x0F
    movwf   hex_low
    movlw   '0'
    call    datos
    movlw   'x'
    call    datos
    movf    hex_high,W
    call    hex_a_ascii
    call    datos
    movf    hex_low,W
    call    hex_a_ascii
    call    datos
    movlw   ' '
    call    datos
    movlw   'H'
    call    datos
    movlw   'E'
    call    datos
    movlw   'X'
    call    datos
    movlw   ' ' ; Tu solución
    call    datos
    movlw   ' ' ; Tu solución
    call    datos
    return
;----------------------------------------------------------------
hex_a_ascii:
    movwf   temp
    sublw   d'9'
    btfss   STATUS,C
    goto    es_letra
    movf    temp,W
    addlw   0x30
    return
es_letra:
    movf    temp,W
    addlw   0x37
    return
;----------------------------------------------------------------
inicia_lcd:
    call    ret100ms
    movlw   0x30
    call    comando
    call    ret100ms
    movlw   0x30
    call    comando
    call    ret100ms
    movlw   0x38
    call    comando
    movlw   0x0c
    call    comando
    movlw   0x01
    call    comando
    call    ret100ms
    movlw   0x06
    call    comando
    movlw   0x02
    call    comando
    return
;----------------------------------------------------------------
comando:
    movwf   PORTB
    call    ret200
    bcf     PORTD,0
    bsf     PORTD,1
    call    ret200
    bcf     PORTD,1
    call    ret200
    return
;----------------------------------------------------------------
datos:
    movwf   PORTB
    call    ret200
    bsf     PORTD,0
    bsf     PORTD,1
    call    ret200
    bcf     PORTD,1
    call    ret200
    return
;----------------------------------------------------------------
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
;----------------------------------------------------------------
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
    end
;================================================================