.macro setStackto
	.if @0 > RAMEND
	.error "Value greater than RAMEND used for setting stack"
	.else
	ldi	r16, LOW(@0)
	out SPL, r16
	ldi	r16, HIGH(@0)
	out SPH, r16
	.endif
.endmacro