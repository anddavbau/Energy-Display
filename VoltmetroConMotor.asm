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

; -- Variable para guardar el estado anterior --
estado_anterior  equ h'30'

; -- CONSTANTES PARA LOS ESTADOS (LEIDOS DESDE PORTE) --
ESTADO_INICIO     EQU B'00000000' ; RE2,RE1,RE0 = 000 -> Modo Inicio
ESTADO_BINARIO    EQU B'00000001' ; RE0=1 -> Modo Binario
ESTADO_DECIMAL    EQU B'00000010' ; RE1=1 -> Modo Decimal
ESTADO_HEX        EQU B'00000011' ; RE0=1, RE1=1 -> Modo Hexadecimal
ESTADO_VOLTAJE    EQU B'00000100' ; RE2=1 -> Modo Voltaje
ESTADO_BATERIA    EQU B'00000101' ; RE2=1, RE0=1 -> Modo Batería

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
    movwf   TRISB       ; PORTB como salida (LCD)
    movlw   0x00
    movwf   TRISD       ; PORTD como salida (LCD RS/E + Motor)
    movlw   0x01
    movwf   TRISA       ; RA0 como entrada (ADC)
    movlw   b'00000111'
    movwf   TRISE       ; RE0-RE2 como entrada (modos)
    movlw   0x0E
    movwf   ADCON1
    
    bcf     STATUS,5
    
    movlw   b'11000001'
    movwf   ADCON0
    
    ; Inicializar pines del motor como apagados
    bcf     PORTD, 2    ; RD2 = IN3 (apagado)
    bcf     PORTD, 3    ; RD3 = ENB (apagado)
    
    call    inicia_lcd
    call    crear_caracteres_bateria
    
    movlw   0xFF
    movwf   estado_anterior
    goto    control_estados
;================================================================
;                  BUCLE DE CONTROL DE ESTADOS
;================================================================
control_estados:
    ; Leer estado actual
    movf    PORTE,W
    andlw   b'00000111'
    
    ; Comparar con estado anterior
    xorwf   estado_anterior,W
    btfsc   STATUS,Z
    goto    sin_cambio_estado
    
    ; Hubo cambio de estado - limpiar pantalla
    call    limpiar_lcd
    
    ; Actualizar estado anterior
    movf    PORTE,W
    andlw   b'00000111'
    movwf   estado_anterior

sin_cambio_estado:
    ; Determinar qué modo ejecutar
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

    movf    PORTE,W
    andlw   b'00000111'
    xorlw   ESTADO_BATERIA
    btfsc   STATUS,Z
    goto    MODO_BATERIA

    ; Si no coincide ninguno, va al estado de inicio por defecto
    goto    MODO_INICIO

;================================================================
;                 BUCLES PARA CADA MODO
;================================================================

MODO_INICIO:
    ; Mostrar el mensaje de bienvenida solo una vez
    movlw   0x80
    call    comando
    call    ret100ms
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

inicio_loop:
    ; Revisar si el estado ha cambiado
    movf    PORTE,W
    andlw   b'00000111'
    xorlw   ESTADO_INICIO
    btfss   STATUS,Z
    goto    control_estados
    goto    inicio_loop

MODO_BINARIO:
    ; Mostrar título solo una vez
    call    mostrar_titulo_binario
binario_loop:
    movf    PORTE,W
    andlw   b'00000111'
    xorlw   ESTADO_BINARIO
    btfss   STATUS,Z
    goto    control_estados
    call    leer_adc
    call    controlar_motor    ; Controlar motor basado en voltaje
    call    mostrar_binario
    call    ret200
    goto    binario_loop

MODO_DECIMAL:
    ; Mostrar título solo una vez
    call    mostrar_titulo_decimal
decimal_loop:
    movf    PORTE,W
    andlw   b'00000111'
    xorlw   ESTADO_DECIMAL
    btfss   STATUS,Z
    goto    control_estados
    call    leer_adc
    call    controlar_motor    ; Controlar motor basado en voltaje
    call    mostrar_decimal
    call    ret200
    goto    decimal_loop

MODO_HEXADECIMAL:
    ; Mostrar título solo una vez
    call    mostrar_titulo_hex
hex_loop:
    movf    PORTE,W
    andlw   b'00000111'
    xorlw   ESTADO_HEX
    btfss   STATUS,Z
    goto    control_estados
    call    leer_adc
    call    controlar_motor    ; Controlar motor basado en voltaje
    call    mostrar_hexadecimal
    call    ret200
    goto    hex_loop

MODO_VOLTAJE:
    ; Mostrar título solo una vez
    call    mostrar_titulo_voltaje
voltaje_loop:
    movf    PORTE,W
    andlw   b'00000111'
    xorlw   ESTADO_VOLTAJE
    btfss   STATUS,Z
    goto    control_estados
    call    leer_adc
    call    controlar_motor    ; Controlar motor basado en voltaje
    call    mostrar_voltaje
    call    ret200
    goto    voltaje_loop

MODO_BATERIA:
    ; Mostrar título solo una vez
    call    mostrar_titulo_bateria
bateria_loop:
    movf    PORTE,W
    andlw   b'00000111'
    xorlw   ESTADO_BATERIA
    btfss   STATUS,Z
    goto    control_estados
    call    leer_adc
    call    controlar_motor    ; Controlar motor basado en voltaje
    call    mostrar_bateria
    call    ret200
    goto    bateria_loop
;====================================================================
;       SUBRUTINA PARA CONTROLAR MOTOR (CORREGIDA)
;====================================================================
controlar_motor:
    ; Verificar si el voltaje es >= 2.5V
    ; 2.5V corresponde a ADC = (2.5 * 255) / 5 = 127.5 ˜ 128
    
    movf    adc_resultado, W
    sublw   d'127'      ; W = 127 - adc_resultado
    
    ; Si adc_resultado <= 127, entonces C=1 (voltaje < 2.5V)
    ; Si adc_resultado > 127, entonces C=0 (voltaje >= 2.5V)
    
    btfss   STATUS, C   ; Saltar si C=1 (voltaje < 2.5V)
    goto    encender_motor
    goto    apagar_motor

encender_motor:
    bsf     PORTD, 2    ; IN3 = 1 (sentido de giro)
    bsf     PORTD, 3    ; ENB = 1 (habilitar motor)
    return

apagar_motor:
    bcf     PORTD, 3    ; ENB = 0 (deshabilitar motor - FRENO)
    bcf     PORTD, 2    ; IN3 = 0 (por seguridad)
    return
;================================================================
;           *** RUTINAS PARA LIMPIAR Y MOSTRAR TÍTULOS ***
;================================================================
limpiar_lcd:
    movlw   0x01        ; Comando para limpiar LCD
    call    comando
    call    ret100ms    ; Esperar a que se complete
    return

mostrar_titulo_binario:
    movlw   0x80
    call    comando
    movlw   'M'
    call    datos
    movlw   'O'
    call    datos
    movlw   'D'
    call    datos
    movlw   'O'
    call    datos
    movlw   ':'
    call    datos
    movlw   ' '
    call    datos
    movlw   'B'
    call    datos
    movlw   'I'
    call    datos
    movlw   'N'
    call    datos
    movlw   'A'
    call    datos
    movlw   'R'
    call    datos
    movlw   'I'
    call    datos
    movlw   'O'
    call    datos
    return

mostrar_titulo_decimal:
    movlw   0x80
    call    comando
    movlw   'M'
    call    datos
    movlw   'O'
    call    datos
    movlw   'D'
    call    datos
    movlw   'O'
    call    datos
    movlw   ':'
    call    datos
    movlw   ' '
    call    datos
    movlw   'D'
    call    datos
    movlw   'E'
    call    datos
    movlw   'C'
    call    datos
    movlw   'I'
    call    datos
    movlw   'M'
    call    datos
    movlw   'A'
    call    datos
    movlw   'L'
    call    datos
    return

mostrar_titulo_hex:
    movlw   0x80
    call    comando
    movlw   'M'
    call    datos
    movlw   'O'
    call    datos
    movlw   'D'
    call    datos
    movlw   'O'
    call    datos
    movlw   ':'
    call    datos
    movlw   ' '
    call    datos
    movlw   'H'
    call    datos
    movlw   'E'
    call    datos
    movlw   'X'
    call    datos
    movlw   'A'
    call    datos
    movlw   'D'
    call    datos
    movlw   'E'
    call    datos
    movlw   'C'
    call    datos
    return

mostrar_titulo_voltaje:
    movlw   0x80
    call    comando
    movlw   'M'
    call    datos
    movlw   'O'
    call    datos
    movlw   'D'
    call    datos
    movlw   'O'
    call    datos
    movlw   ':'
    call    datos
    movlw   ' '
    call    datos
    movlw   'V'
    call    datos
    movlw   'O'
    call    datos
    movlw   'L'
    call    datos
    movlw   'T'
    call    datos
    movlw   'A'
    call    datos
    movlw   'J'
    call    datos
    movlw   'E'
    call    datos
    return

mostrar_titulo_bateria:
    movlw   0x80
    call    comando
    movlw   'M'
    call    datos
    movlw   'O'
    call    datos
    movlw   'D'
    call    datos
    movlw   'O'
    call    datos
    movlw   ':'
    call    datos
    movlw   ' '
    call    datos
    movlw   'B'
    call    datos
    movlw   'A'
    call    datos
    movlw   'T'
    call    datos
    movlw   'E'
    call    datos
    movlw   'R'
    call    datos
    movlw   'I'
    call    datos
    movlw   'A'
    call    datos
    return

;====================================================================
;       SUBRUTINA PARA MOSTRAR VOLTAJE (VERSIÓN CORREGIDA Y SIMPLE)
;====================================================================
mostrar_voltaje:
    ; Fórmula simple: Voltaje = (ADC * 500) / 255
    ; Pero para evitar división por 255, usamos: ˜ (ADC * 196) / 100
    
    movf    adc_resultado, W
    movwf   temp
    
    ; Calcular parte entera directamente
    clrf    volt_entero
calc_entero:
    movlw   d'51'       ; 255/5 = 51
    subwf   temp, W
    btfss   STATUS, C
    goto    calc_decimales
    movwf   temp
    incf    volt_entero, F
    goto    calc_entero

calc_decimales:
    ; Los decimales son: (resto * 100) / 51
    ; Pero simplificamos: mostrar (resto * 2) como aproximación
    movf    temp, W
    movwf   mult_resultado_l
    
    ; Multiplicar por 2
    bcf     STATUS, C
    rlf     mult_resultado_l, F
    
    ; Separar en décimas y centésimas
    movf    mult_resultado_l, W
    movwf   temp
    
    ; Calcular décimas (temp / 10)
    clrf    volt_dec1
calc_decimas:
    movlw   d'10'
    subwf   temp, W
    btfss   STATUS, C
    goto    calc_centesimas
    movwf   temp
    incf    volt_dec1, F
    goto    calc_decimas

calc_centesimas:
    ; Lo que queda son las centésimas
    movf    temp, W
    movwf   volt_dec2
    
    ; Mostrar en LCD
    movlw   0xC0
    call    comando
    
    ; Parte entera (0-5)
    movf    volt_entero, W
    addlw   '0'
    call    datos
    
    ; Punto decimal
    movlw   '.'
    call    datos
    
    ; Décimas
    movf    volt_dec1, W
    addlw   '0'
    call    datos
    
    ; Centésimas
    movf    volt_dec2, W
    addlw   '0'
    call    datos
    
    ; Texto "Volts"
    movlw   ' '
    call    datos
    movlw   'V'
    call    datos
    movlw   'o'
    call    datos
    movlw   'l'
    call    datos
    movlw   't'
    call    datos
    movlw   's'
    call    datos
    
    return

;====================================================================
;       SUBRUTINA PARA CREAR CARACTERES PERSONALIZADOS
;====================================================================
; El LCD puede almacenar hasta 8 caracteres personalizados (0-7)
; Cada carácter es de 5x8 píxeles
; Vamos a crear 5 niveles de batería (vacía, 25%, 50%, 75%, llena)

crear_caracteres_bateria:
    ; Carácter 0: Batería vacía
    movlw   0x40        ; Dirección CGRAM para carácter 0
    call    comando
    movlw   B'00001110' ; Línea 1: ___***_
    call    datos
    movlw   B'00011011' ; Línea 2: _**_**_
    call    datos
    movlw   B'00010001' ; Línea 3: _*___*_
    call    datos
    movlw   B'00010001' ; Línea 4: _*___*_
    call    datos
    movlw   B'00010001' ; Línea 5: _*___*_
    call    datos
    movlw   B'00010001' ; Línea 6: _*___*_
    call    datos
    movlw   B'00011111' ; Línea 7: _*****_
    call    datos
    movlw   B'00000000' ; Línea 8: _______
    call    datos

    ; Carácter 1: Batería 25%
    movlw   0x48        ; Dirección CGRAM para carácter 1
    call    comando
    movlw   B'00001110'
    call    datos
    movlw   B'00011011'
    call    datos
    movlw   B'00010001'
    call    datos
    movlw   B'00010001'
    call    datos
    movlw   B'00010001'
    call    datos
    movlw   B'00010001'
    call    datos
    movlw   B'00011111' ; Línea 7 llena
    call    datos
    movlw   B'00000000'
    call    datos

    ; Carácter 2: Batería 50%
    movlw   0x50        ; Dirección CGRAM para carácter 2
    call    comando
    movlw   B'00001110'
    call    datos
    movlw   B'00011011'
    call    datos
    movlw   B'00010001'
    call    datos
    movlw   B'00010001'
    call    datos
    movlw   B'00010001'
    call    datos
    movlw   B'00011111' ; Línea 6 llena
    call    datos
    movlw   B'00011111' ; Línea 7 llena
    call    datos
    movlw   B'00000000'
    call    datos

    ; Carácter 3: Batería 75%
    movlw   0x58        ; Dirección CGRAM para carácter 3
    call    comando
    movlw   B'00001110'
    call    datos
    movlw   B'00011011'
    call    datos
    movlw   B'00010001'
    call    datos
    movlw   B'00010001'
    call    datos
    movlw   B'00011111' ; Línea 5 llena
    call    datos
    movlw   B'00011111' ; Línea 6 llena
    call    datos
    movlw   B'00011111' ; Línea 7 llena
    call    datos
    movlw   B'00000000'
    call    datos

    ; Carácter 4: Batería 100%
    movlw   0x60        ; Dirección CGRAM para carácter 4
    call    comando
    movlw   B'00001110'
    call    datos
    movlw   B'00011011'
    call    datos
    movlw   B'00011111' ; Línea 3 llena
    call    datos
    movlw   B'00011111' ; Línea 4 llena
    call    datos
    movlw   B'00011111' ; Línea 5 llena
    call    datos
    movlw   B'00011111' ; Línea 6 llena
    call    datos
    movlw   B'00011111' ; Línea 7 llena
    call    datos
    movlw   B'00000000'
    call    datos

    ; Regresar al modo DDRAM
    movlw   0x80
    call    comando
    return

;====================================================================
;       SUBRUTINA PARA MOSTRAR BATERÍA
;====================================================================
mostrar_bateria:
    movlw   0xC0
    call    comando
    
    ; Calcular porcentaje (adc_resultado * 100 / 255)
    ; Para simplificar: 
    ; 0-51    = 0%    -> carácter 0
    ; 52-102  = 25%   -> carácter 1
    ; 103-153 = 50%   -> carácter 2
    ; 154-204 = 75%   -> carácter 3
    ; 205-255 = 100%  -> carácter 4
    
    movf    adc_resultado, W
    sublw   d'51'
    btfsc   STATUS, C
    goto    bat_0
    
    movf    adc_resultado, W
    sublw   d'102'
    btfsc   STATUS, C
    goto    bat_25
    
    movf    adc_resultado, W
    sublw   d'153'
    btfsc   STATUS, C
    goto    bat_50
    
    movf    adc_resultado, W
    sublw   d'204'
    btfsc   STATUS, C
    goto    bat_75
    
    goto    bat_100

bat_0:
    movlw   0x00        ; Carácter personalizado 0
    call    datos
    movlw   ' '
    call    datos
    movlw   '0'
    call    datos
    movlw   '%'
    call    datos
    movlw   ' '
    call    datos
    movlw   'V'
    call    datos
    movlw   'a'
    call    datos
    movlw   'c'
    call    datos
    movlw   'i'
    call    datos
    movlw   'a'
    call    datos
    return

bat_25:
    movlw   0x01        ; Carácter personalizado 1
    call    datos
    movlw   ' '
    call    datos
    movlw   '2'
    call    datos
    movlw   '5'
    call    datos
    movlw   '%'
    call    datos
    movlw   ' '
    call    datos
    movlw   ' '
    call    datos
    movlw   ' '
    call    datos
    movlw   ' '
    call    datos
    movlw   ' '
    call    datos
    return

bat_50:
    movlw   0x02        ; Carácter personalizado 2
    call    datos
    movlw   ' '
    call    datos
    movlw   '5'
    call    datos
    movlw   '0'
    call    datos
    movlw   '%'
    call    datos
    movlw   ' '
    call    datos
    movlw   ' '
    call    datos
    movlw   ' '
    call    datos
    movlw   ' '
    call    datos
    movlw   ' '
    call    datos
    return

bat_75:
    movlw   0x03        ; Carácter personalizado 3
    call    datos
    movlw   ' '
    call    datos
    movlw   '7'
    call    datos
    movlw   '5'
    call    datos
    movlw   '%'
    call    datos
    movlw   ' '
    call    datos
    movlw   ' '
    call    datos
    movlw   ' '
    call    datos
    movlw   ' '
    call    datos
    movlw   ' '
    call    datos
    return

bat_100:
    movlw   0x04        ; Carácter personalizado 4
    call    datos
    movlw   ' '
    call    datos
    movlw   '1'
    call    datos
    movlw   '0'
    call    datos
    movlw   '0'
    call    datos
    movlw   '%'
    call    datos
    movlw   ' '
    call    datos
    movlw   'L'
    call    datos
    movlw   'l'
    call    datos
    movlw   'e'
    call    datos
    movlw   'n'
    call    datos
    movlw   'a'
    call    datos
    return

;================================================================
;           *** SUBRUTINAS ***
;================================================================
leer_adc:
    bsf     ADCON0,2
    call    ret200
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
    movlw   '('
    call    datos
    movlw   '0'
    call    datos
    movlw   '-'
    call    datos
    movlw   '2'
    call    datos
    movlw   '5'
    call    datos
    movlw   '5'
    call    datos
    movlw   ')'
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
    movlw   '('
    call    datos
    movlw   '0'
    call    datos
    movlw   '-'
    call    datos
    movlw   'F'
    call    datos
    movlw   'F'
    call    datos
    movlw   ')'
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