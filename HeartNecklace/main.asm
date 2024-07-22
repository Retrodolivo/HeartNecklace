.include "common_macros.asm"
.list

.equ	LED_PIN = pinb0
.equ	BTN_PIN = pinb2
/*(1_600_000 / 1024) = 1953 - timer ticks per second
  (1 / 1953) = 1ms - per tick
  (x / 1ms) = TIMER_THRESHOLD, x - delay in ms
  x = 1ms * TIMER_THRESHOLD
*/
.equ	TIMER_THRESHOLD = 150
.def	temp = r16
.def	innerDelay = r17
.def	outerDelay = r18


;RAM =============================================

.dseg

;FLASH ===========================================

.cseg
.org	0x0000
		rjmp reset
.org	INT0addr
		rjmp int0_ISR
.org INT_VECTORS_SIZE

reset:
; Stack pointer initializing
		setStackto RAMEND
; Turn off analog comparator and its interrupt
		cbi ACSR, ACIE
		sbi ACSR, ACD
; Ports configuration
		sbi DDRB, LED_PIN
		cbi PORTB, LED_PIN		
		cbi DDRB, BTN_PIN
		sbi PORTB, BTN_PIN
; Delay timer initialization
		ldi temp, (1<<CS00) | (0<<CS01) | (1<<CS02)
		out TCCR0B, temp
; External interrupts initialization
		ldi temp, (0<<ISC00) | (1<<ISC01) ; falling edge
		out MCUCR, temp
		ldi temp, (1<<INT0)
		out GIMSK, temp
		sei

main:
/* Light LED via button
buttonCheck:	
		sbic PINB, BTN_PIN
		rjmp buttonCheck
led:	
		sbi PORTB, LED_PIN
		rcall delay
		sbis PINB, BTN_PIN
		rjmp led
		cbi PORTB, LED_PIN
		rjmp buttonCheck
*/

/* Blinking LED */
loop:
		rjmp loop

timerDelay:
		push temp
		ldi	temp, 0
		out TCNT0, temp
m1:
		in	temp, TCNT0
		cpi temp, TIMER_THRESHOLD
		brne m1
 		pop temp
		ret

delay:
		ldi innerDelay, 255
outerLoop:
		ldi outerDelay, 255
		dec innerDelay
		brne innerLoop
		ret
innerLoop:
		dec outerDelay
		brne innerLoop
		rjmp outerLoop


int0_ISR:
		sbi PORTB, LED_PIN
		rcall delay
		cbi PORTB, LED_PIN
		rcall delay
		reti

;EEPROM ==========================================

.eseg

