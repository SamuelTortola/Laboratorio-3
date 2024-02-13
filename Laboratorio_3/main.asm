;******************************************************************************
; Universidad Del Valle De Guatemala
; IE2023: Programación de Microcontroladores
; Autor: Samuel Tortola - 22094
; Proyecto: Laboratorio 3
; Hardware: Atmega238p
; Creado: 8/02/2024
; Última modificación: 12/02/2024 
;******************************************************************************



;******************************************************************************
;ENCABEZADO
;******************************************************************************
.include "M328PDEF.inc"
.CSEG
.ORG 0x00
	JMP MAIN  //Vector RESET
.ORG 0X0006
	JMP ISR_PCINT0 //Vector de ISR: PCINT0

.ORG 0X0020
	JMP ISR_TIMER0_OVF //Vector ISR del timer0



MAIN:
	;******************************************************************************
	;STACK POINTER
	;******************************************************************************
	LDI R16, LOW(RAMEND)  
	OUT SPL, R16
	 LDI R17, HIGH(RAMEND)
	OUT SPH, R17


;******************************************************************************
;CONFIGURACIÓN
;******************************************************************************

SETUP:
	LDI R16, 0b1000_0000
	LDI R16, (1 << CLKPCE) //Corrimiento a CLKPCE
	STS CLKPR, R16        // Habilitando el prescaler 

	LDI R16, 0b0000_0001
	STS CLKPR, R16   //Frecuencia del sistema de 8MHz

	LDI R16, 0b01111111
    OUT DDRD, R16   //Configurar pin PD0 a PD6 Como salida

	LDI R16, 0b00000111
	OUT DDRB, R16   //Configurar PB1 y PB2 como entrada y PB3 y PB4 como salida  **PB3 para display 1, PB4 para display 2**
	LDI R16, 0b00000111
	OUT PORTB, R16    //Configurar PULLUP de pin PB1 y PB2

	LDI R16, 0b0011111
	OUT DDRC, R16   //Configurar pin PC0 a PC4 como salidas
	LDI R18, 0

	LDI R16, (1 << PCIE0)
	STS PCICR, R16  //Habilitando PCINT 0-7 

	LDI R16, (1 << PCINT1)|(1 << PCINT2)
	STS PCMSK0, R16      //Registro de la mascara
	SBI PINB, PB4     //Encender display 2
	SEI  //Habilitar interrupciones Globales
	LDI R19, 0 //Displays
	LDI R17, 0
	LDI R28, 0
	LDI R25, 0
	TABLA: .DB 0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7C, 0x07, 0x7F, 0X6F
	LDI R22, 0  //Contador de las UNIDADES
	LDI R21, 0 //Contador de las DECENAS
	CALL INITTIMER0
	


;conexiones de display a atmega: a=PD0, b=PD1, c=PD2, d=PD3, e=PD4, f= PD5, g=PD6

LOOP:
     CPI R22, 10
	 BREQ RESETT
     CPI R23, 50   //Verificar cuantas pasadas a dado el TIMER0
	 BREQ UNIDADES

	   CALL RETARDO
       SBI PINB, PB3   //Encender PB3
	   SBI PINB, PB4   //Apagar PB4

	   LDI ZH, HIGH(TABLA <<1)  //da el byte mas significativo
	   LDI ZL, LOW(TABLA <<1) //va la dirección de TABLA
	   ADD ZL, R21
	   LPM R25,Z
	   OUT PORTD, R25

	   CALL RETARDO
	   SBI PINB, PB3   //Apagar PB3
	   SBI PINB, PB4   //Encender  PB4

	 
	   LDI ZH, HIGH(TABLA <<1)  //da el byte mas significativo
	   LDI ZL, LOW(TABLA <<1) //va la dirección de TABLA
	   ADD ZL, R22
	   LPM R25,Z
	   OUT PORTD, R25
	   CALL RETARDO

	   CPI R21, 6
	   BREQ RESDE
	JMP LOOP//Regresa al LOOP

	RETARDO:
	LDI R19, 255   //Cargar con un valor a R16
	delay:
		DEC R19 //Decrementa R16
		BRNE delay   //Si R16 no es igual a 0, tira al delay
	LDI R19, 255   //Cargar con un valor a R16
	delay1:
		DEC R19 //Decrementa R16
		BRNE delay1   //Si R16 no es igual a 0, tira al delay
	LDI R19, 255   //Cargar con un valor a R16
	delay2:
		DEC R19 //Decrementa R16
		BRNE delay2   //Si R16 no es igual a 0, tira al delay
	LDI R19, 255   //Cargar con un valor a R16
	delay3:
		DEC R19 //Decrementa R16
		BRNE delay3  //Si R16 no es igual a 0, tira al delay

	RET

	RESETT:    //reset para el contador de unidades
		LDI R22, 0
		INC R21   //Suma contador de decenas
	    JMP LOOP

	UNIDADES:      //Contador de Unidades
		INC R22
		LDI R23, 0
		JMP LOOP

	RESDE:    //Resetea el contador de decemas
	CALL RETARDO
	LDI R21, 0
	LDI R22, 0
	JMP LOOP

;**************************Inicio TIMER0***************************************		
INITTIMER0:     //Arrancar el TIMER0
	LDI R26, 0
	OUT TCCR0A, R26 //trabajar de forma normal con el temporizador

	LDI R26, (1<<CS02)|(1<<CS00)
	OUT TCCR0B, R26  //Configurar el temporizador con prescaler de 1024

	LDI R26, 100
	OUT TCNT0, R26 //Iniciar timer en 158 para conteo

	LDI R26, (1 << TOIE0)
	STS TIMSK0, R26 //Activar interrupción del TIMER0 de mascara por overflow

	RET

;********************************SUBRUTINA DE PULSADORES***********************
ISR_PCINT0:
	PUSH R16         //Se guarda en pila el registro R16
	IN R16, SREG
	PUSH R16

	IN R20, PINB  //Leer  el puerto B
	SBRC R20, PB1 // Salta si el bit del registro es 1
	
	JMP CPB2 //Verifica si esta apachado el pin PB2

	DEC R18 //Decrementa R18
	JMP EXIT


CPB2:
	SBRC R20, PB2  //Verifica SI PB2 esta a 1
	JMP EXIT

	INC R18 //Incrementa R18
	JMP EXIT

EXIT:
	CPI R18, -1
	BREQ res1
	CPI R18, 16
	BREQ res2

	OUT PORTC, R18
	SBI PCIFR, PCIF0  //Apagar la bandera de ISR PCINT0

	POP R16         //Obtener el valor de SREG
	OUT SREG, R16   //Restaurar los valores de SREG
	POP R16
	RETI      //Retorna de la ISR


res1:   //Reseteo de valor bajo 
	LDI R18, 0
	OUT PORTC, R18
	JMP EXIT

res2:     //Reseteo de valor alto
	LDI R18, 15
	OUT PORTC, R18
	JMP EXIT




;********************************SUBRUTINA DE TIMER0***************************

ISR_TIMER0_OVF:

	PUSH R16   //Se guarda R16 En la pila 
	IN R16, SREG  
	PUSH R16      //Se guarda SREG actual en R16

	LDI R16, 100  //Cagar el valor de desbordamiento
	OUT TCNT0, R16  //Cargar el valor inicial del contador
	SBI TIFR0, TOV0   //Borrar la bandera de TOV0
	INC R23    //Incrementar el contador de 20ms

	POP R16    //Obtener el valor del SREG
	OUT SREG, R16   //Restaurar antiguos valores del SREG
	POP R16    //Obtener el valor de R16    

	RETI //Retornar al LOOP



