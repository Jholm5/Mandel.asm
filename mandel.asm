;Jeremy Holm
;Mandel part 3
;CS2810 Spring 2014

global _start
global itoa

section .text
	_start:
		mov rax, 0
		mov rbx, 0	;initilize buffer counter
		mov r13, 0	;initilize y counter
		mov r15, 0	;initilize x counter
	
	open:
		mov rax, SYS_OPEN
		mov rdi, filename
		mov rsi, flag
		mov rdx, mode
		syscall
		
		mov [fd], rax	;Save file descriptor

		cmp rax, 0	;Check if syscall succeeded
		jge write_header
		
		mov rax, SYS_EXIT	;Exit if failed to open
		mov rdi, fail_open
		syscall

	write_header:
		mov rax, SYS_WRITE
		mov rdi, [fd]	
		mov rsi, header
		mov rdx, headerL
		syscall

		cmp rax, 0
		jge y_row_loop

		mov rax, SYS_EXIT
		mov rdi, fail_write_header	;Check for errors
		syscall
		
	
		
	y_row_loop:
		mov rdi, buffer ;send r8 to itoa; returns to rax
		mov rsi, r13
		call itoa
		
		mov [y_value], rax	;save rax into y_value
		
		mov rax, range_y	;Test to quit out of loop
		cmp r13, rax
		jge exit

		mov r15, 0		;set r15 to 0


	x_column_loop:
		
		mov rdi, r15
		mov rsi, r13
		call calcPixel			;


		mov rsi, rax		;RGB parameter
		mov rdi, buffer		;buffer parameter
		call writeRGB

		mov r14, rax		;Save number of iterations

		mov rax, SYS_WRITE
		mov rdi, [fd]
		mov rsi, buffer
		mov rdx, r14
		syscall
		
		inc r15

		mov rax, range_x
		cmp r15, rax	;test if r15 is less than 256
		jl x_column_loop
		
		mov rax, SYS_WRITE	
		mov rdi, [fd]
		mov rsi, NEWLINE
		mov rdx, 2
		syscall
	
		cmp rax, 0		;Check if program succeeded
		jge next

		mov rax, SYS_EXIT	;If failed then exit
		mov rdi, fail_loop
		syscall

	next:
		inc r13

		jmp y_row_loop	;Jump back up to row loop

		
		

	close:
		mov rax, SYS_CLOSE	;Close File
		syscall

		cmp rax, 0		;Check if program succeeded
		jge exit

		mov rax, SYS_EXIT
		mov rdi, fail_close ;If failed then exit
		syscall
	
		jmp exit



	calcPixel:
		push r14
		push r15
	y_loopy:
		cvtsi2sd xmm13, r14
		movsd xmm12, [point_5]
		addsd xmm12, xmm13

		cvtsi2sd xmm13, [Anti_Alias]
		subsd xmm13, [point_5]
		divsd xmm12, xmm13

		movsd [offset_y], xmm12
			
	x_loopy:
		cvtsi2sd xmm13, r15
		movsd xmm12, [point_5]
		addsd xmm12, xmm13

		cvtsi2sd xmm13, [Anti_Alias]
		subsd xmm13, [point_5]
		divsd xmm12, xmm13

		movsd [offset_x], xmm12
		

		cvtsi2sd xmm9, rdi		;convert col (x value) 
		cvtsi2sd xmm10, rsi		;convert row (y value) 

		;x = x_cordf + ((col-centerxf)/(magnf*(rangexf - 1)))
		subsd xmm9, [centerXf]
		movsd xmm14, [range_yf]
		subsd xmm14, [onef]
		mulsd xmm14, [magnification]
		divsd xmm9, xmm14
		addsd xmm9, [x_cord]
		
		;y = -(row - centerYf)/magnification*(rangeyf-1)))
		subsd xmm10, [centerYf]
		movsd xmm11, [range_yf]
		subsd xmm11, [onef]
		mulsd xmm11, [magnification]
		divsd xmm10, xmm11
		movsd xmm11, xmm10
		movsd xmm10, [y_cord]
		subsd xmm10, xmm11

		inc r15
		cmp r15, [Anti_Alias]
		jl x_loopy
		
		inc r14
		cmp r14, [Anti_Alias]
		jl y_loopy

		pop r15
		pop r14
		call mandel
		call getColor
		ret



	mandel:
		mov r14, 0	;initilize r14 to 0
		movsd xmm0, xmm9
		movsd xmm1, xmm10

	m_loop:

		movsd xmm2, xmm0
		mulsd xmm2, xmm2	; xmm2 = a^2

		movsd xmm3, xmm1
		mulsd xmm3, xmm3	; xmm3 = b^2

		movsd xmm4, xmm2
		addsd xmm4, xmm3	; xmm4 = a^2 + b^2

		movsd xmm5, xmm2
		subsd xmm5, xmm3
		addsd xmm5, xmm9	; xmm5 = a^2 - b^2 + x

		movsd xmm6, xmm0
		mulsd xmm6, xmm1
		addsd xmm6, xmm6
		addsd xmm6, xmm10	; xmm6 = 2*a*b + y

		movsd xmm0, xmm5
		movsd xmm1, xmm6

		inc r14
		cmp r14, Max_Iteration
		jg exit_M
		
		comisd xmm4, [Boundary_x]
		jb m_loop		;jump back to loop if xmm6

	exit_M:	
		mov rax, r14	;r14 = # of iterations
		ret



	getColor:
		mov r14, rax
		cmp r14, Max_Iteration
		jge return_black
		

	return_color:					
		;r14 divided by maxiterations gives percentage
		; palette_size * r14 = the color number
		;mov rax, color number
	
		mov rax, r14
		mov rdx, 0 
		mov rsi, [palette - palette_size]
		div rsi
		mov rax, [palette + rdx * 8]
		ret

	return_black:
		mov rax, [BLACK]
		ret





; writeRGB(buffer, RGB)  return # of bytes written
	writeRGB:
		push r12
		push r13
		push r14
		mov r12, rdi				; r12 = buffer
		mov r13, rsi				; r13 = RGB
		mov r14, 0				; r14 = # bytes written

		; write red
		shr rsi, 16
		and rsi, 255
		call itoa
		add r14, rax
		mov [r12 + r14], byte ' '
		inc r14

		; write green
		lea rdi, [r12 + r14]
		mov rsi, r13
		shr rsi, 8
		and rsi, 255
		call itoa
		add r14, rax
		mov [r12 + r14], byte ' '
		inc r14

		; write blue
		lea rdi, [r12 + r14]
		mov rsi, r13
		and rsi, 255
		call itoa
		add r14, rax

		mov [r12 + r14], byte ' '		;add space
		inc r14
		
		; return # bytes written
		mov rax, r14
		pop r14
		pop r13
		pop r12
		ret


; itoa(buffer, n) -> # bytes written
; rdi: buffer
; rsi: n
	itoa:
		mov rax, rsi                ; copy n into rax
		mov rsi, 0                  ; rsi = length of output
		mov r10, 10

	itoa_loop:
		; do a division
		mov rdx, 0
		div r10                     
		add rdx, '0'
		mov [rdi + rsi], dl
		inc rsi
		cmp rax, 0
		jg itoa_loop

		; reverse the string
		mov rdx, rdi
		lea rcx, [rdi + rsi - 1]
		jmp itoa_reverse_test

	itoa_reverse_loop:
		mov al, [rdx]
		mov ah, [rcx]
		mov [rcx], al
		mov [rdx], ah
		inc rdx
		dec rcx
	
	itoa_reverse_test:
		cmp rdx, rcx
		jl itoa_reverse_loop

		mov rax, rsi
		ret
	
	mov r14, 0
	exit:
		mov rax, SYS_EXIT
		mov rdi, r14
		syscall


section .data
	
	filename:	    db "./fractal.ppm", 0

	header:		    db "P3", 10, "1024 768", 10, "255", 10
	headerL:	    equ $-header

	NEWLINE:	    db " ", 10
	SPACE:		    db " "
	LARGE_SPACE:	db "  "
	blue:		    db "0"
	zero:		    dq "0.0"

	WHITE:		    dq 0xffffff 
	BLACK:		    dq 0x000000 

	size_x:         dq 1024
	size_y:         dq 768
	
	
	SYS_WRITE:	equ 1
	SYS_OPEN:	equ 2
	SYS_CLOSE:	equ 3
	SYS_EXIT:	equ 60

	STDOUT:		equ 1
	
	flag:		equ 577
	mode:		equ 0o644

	; x coordinate helpers
	centerXf:	dq 512.0 
	range_x:	equ 1024 
	range_xf:	dq 1024.0 
	offset_x:	dq 1.0
	; y coordinate assistance
	centerYf:	dq 384.0 
	range_y:	equ 768 
	range_yf:	dq 768.0 
	offset_y:	dq 1.0


	onef:		    dq 1.0
	twof:		    dq 2.0
	x_cord:		    dq 0.32
	y_cord:		    dq 0.45
	magnification:	dq 1000.50
	point_5:	    dq 0.5


	Boundary_x:	    dq 5.12
	Boundary_y:	    dq 4.0
	Max_Iteration:	equ 1000
	Anti_Alias:	    dq 100

	palette:
		;Red
		dq	0x100000		;dark red
		dq	0x200000
		dq	0x300000	
		dq	0x400000
		dq 	0x500000
		dq	0x600000	
		dq	0x700000
		dq	0x800000
		dq	0x900000
		dq	0xa00000
		dq	0xb00000
		dq	0xc00000
		dq	0xd00000
		dq	0xe00000
		dq	0xf00000
		dq	0xff0000
		dq  0xf00000
		dq	0xe00000
		dq	0xd00000
		dq	0xc00000
		dq	0xb00000
		dq	0xa00000
		dq	0x900000
		dq 	0x800000
		dq	0x700000
		dq	0x600000
		dq	0x500000
		dq 	0x400000
		dq	0x300000
		dq	0x200000


		;Green
		dq	0x001000		;dark green
		dq	0x002000
		dq	0x003000
		dq	0x004000
		dq 	0x005000
		dq	0x006000
		dq	0x007000
		dq	0x008000
		dq	0x009000
		dq	0x00a000
		dq	0x00b000
		dq	0x00c000
		dq	0x00d000
		dq	0x00e000
		dq	0x00f000
		dq	0x00ff00
		dq	0x00f000	
		dq	0x00e000
		dq	0x00d000
		dq	0x00c000
		dq 	0x00b000
		dq	0x00a000
		dq	0x009000
		dq	0x008000
		dq	0x007000
		dq	0x006000
		dq	0x005000
		dq	0x004000
		dq	0x003000
		dq	0x002000
		dq	0x001000


		;Blue
		dq	0x000010		;dark Blue
		dq	0x000020
		dq	0x000030	
		dq	0x000040
		dq 	0x000050
		dq	0x000060	
		dq	0x000070
		dq	0x000080
		dq	0x000090
		dq	0x0000a0
		dq	0x0000b0	
		dq	0x0000c0
		dq	0x0000d0
		dq	0x0000e0
		dq	0x0000f0
		dq	0x0000ff
		


	palette_size:	equ ($-palette) / 8

		
section .bss
	buffer:		    resb 32*1024
	sizex2:         resq 1
	sizey2:         resq 1
	smallersize1:   resq 1

	fd:		    resb 64
	y_value:	resb 64
	x_value:	resb 64

	; math equation variables
	var1:		resb 64
	var2:		resb 64

	fail_open:		    equ 1
	fail_write_header:	equ 2
	fail_loop:		    equ 3
	fail_close:		    equ 4
