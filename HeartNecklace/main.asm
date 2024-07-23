.include "common_macros.asm"
.list

.equ	LED_PIN = pinb1
.equ	BTN_PIN = pinb2
/*(1_000_000 / 1024) = 976 - timer ticks per second
  (1 / 976) = 1ms - per tick
  (x / 1ms) = TIMER_THRESHOLD, x - delay in ms
  x = 1ms * TIMER_THRESHOLD
*/
.equ	TIMER_THRESHOLD = 150
.equ	PWM_MAX_VALUE = 150

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
; PWM timer initialization
		; Synchronous mode
		ldi temp, (0<<PCKE)
		out PLLCSR, temp
		; PWM mode A enable, Clear OC1A pin on compare, 8 prescaler
		ldi temp, (1<<PWM1A) | (1<<COM1A1) | (0<<CS13) | (1<<CS12) | (0<<CS11) | (0<<CS10)
		out TCCR1, temp
		; Compare register value
		ldi temp, PWM_MAX_VALUE
		out OCR1C, temp

		ldi temp, 0
		out OCR1A, temp

; External interrupts initialization
		ldi temp, (0<<ISC00) | (1<<ISC01) ; falling edge
		out MCUCR, temp
		ldi temp, (1<<INT0)
		out GIMSK, temp
		sei
		rjmp main

main:
		rjmp main

heartbeat:
		ldi temp, 0
heartbeatSmallUp:
		; wait before inc brightness
		rcall delay
		; inc brightness
		inc temp
		out OCR1A, temp
		; check if enough brightness
		cpi temp, PWM_MAX_VALUE * 0.5
		brne heartbeatSmallUp
heartbeatSmallDown:
		; wait before dec brightness
		rcall delay
		dec temp
		out OCR1A, temp
		; check if enough brightness
		cpi temp, 3
		brne heartbeatSmallDown
heartbeatBigUp:
		; wait before inc brightness
		rcall delay
		; inc brightness
		inc temp
		out OCR1A, temp
		; check if enough brightness
		cpi temp, PWM_MAX_VALUE * 0.8
		brne heartbeatBigUp
heartbeatBigDown:
		; wait before dec brightness
		rcall delay
		dec temp
		out OCR1A, temp
		; check if enough brightness
		cpi temp, 0
		brne heartbeatBigDown

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
		ldi outerDelay, 5
		dec innerDelay
		brne innerLoop
		ret
innerLoop:
		dec outerDelay
		brne innerLoop
		rjmp outerLoop


int0_ISR:
		cli
		rcall heartbeat
		sei
		reti

;EEPROM ==========================================

.eseg

