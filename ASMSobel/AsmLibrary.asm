
.data
grayArrayStart QWORD 0		; pointer for input array
readyArray QWORD 0			; pointer for output array
helperArray QWORD 0			; pointer for array used in GY convolution
imageHeight DWORD 0			
imageWidth DWORD 0

; Passed arguments:
; 1 argument: RCX
; 2 argument: RDX
; 3 argument: R8
; 4 argument: R9
; rest on stack starting from [rbp+48]

.code
Sobel proc
; save nonvolatile registers
push r12
push r13
push r14
push r15
push rdi
push rsi

;Load arguments
mov grayArrayStart, RCX
mov readyArray, RDX
mov helperArray, R8
mov imageHeight, R9D

mov edx, DWORD PTR[rbp + 48]
mov imageWidth, edx

mov edx, DWORD PTR[rbp + 56]
mov r15d, edx

mov r14d, 0

; R14 is the starting point
; R15 is the ending point


xor eax, eax ; clearing register
xor ebx, ebx ; clearing register
xor ecx, ecx ; clearing register

call Vertical
call Horizontal


mov rdi, readyArray			;GX Matrix
mov rsi, helperArray		;GY Matrix


mov ecx, 0					; counter for loop
mov eax, r15d				; calculate number of loops
mov r11, 4					; divide by 4 because we take 16 pixels a time, so 4 dwords
div r11						; eax = number of loops

mov r10d, r14d
imul r10d, 4


squareloop:
	;Read result we got for GX and GY and put them into XMM0 and XMM1
	vmovdqu xmm0, OWORD PTR[rdi+r10]	;taking 16 pixels from GX
	vmovdqu xmm1, OWORD PTR[rsi+r10]	;taking 16 pixels from GY

	paddd xmm0, xmm1		; GX+GY

	cvtdq2ps xmm0, xmm0		;convert dword to single precision float so we can square it

	sqrtps xmm0, xmm0		; square root of xmm0

	cvtps2dq xmm0, xmm0		; convert back to dwords


	movdqu OWORD PTR[rdi+r10], xmm0 ;move the result to the output array

	inc ecx ; increment loop counter
	add r10d, 16 ; add 16 to move to the next 4 dwords
	cmp ecx, eax ; check if we are finished
	jnz squareloop

TheEnd:
; get back nonvolatile registers
pop rsi
pop rdi
pop r15
pop r14
pop r13
pop r12

ret

Sobel endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Vertical proc ;GX result stored in readyArray

; r14 - starting point
; r15 - ending point
; rsi - grayArrayStart
; rdi - readyArray
; rax - current row
; rcx - loop couner
; r8 - temporary value
; r9d - where to end in grayArray
; r10d - ecx%imagewidth
; r11 - register used in cmp
; r12d - ecx +/- 1
; r13b - byte holder for pixels

; GXMATRIX:
;  1  0 -1
;  2  0 -2
;  1  0 -1

;assigning GX matrix to XMM1

mov r8, 0FFFEFFFF00000001h			;hex for first 4 numbers 
pinsrq xmm1, r8, 0
mov r8, 000200010000FFFFh			;hex for last 4 numbers
pinsrq xmm1, r8, 1


mov rsi, grayArrayStart
mov rdi, readyArray


mov ecx, r14d						; Counter for loop

mov r9d, ecx						; use r9 for end of loop
add r9d, r15d						; ^

forloop:
	
		xorpd xmm0, xmm0 ; Clean xmm0 register

		;Calculate the current row
		mov eax, ecx	; save counter to eax
		xor edx,edx
		div imageWidth	; modulo in edx
		mov eax, ecx	; save the counter again
		sub eax, edx
		mov r10d, edx	; saving modulo in r10
		xor edx,edx
		div imageWidth	; finally row is saved in eax

	
		cmp r10d, 0
		jnz ifelse
		; IF we are on the left wall of the image:

		jmp ifend

	ifelse:
		mov r11d, imageWidth
		dec r11d
		cmp r10d, r11d					;i%imagewidth =?= imageWidth-1
		jnz ifelse2

		; IF we are on the right wall of the image:
		jmp ifend

	ifelse2:
		; if we are in the center of the image:
		;if(row!=0)
		cmp eax, 0
		jz ifend
		;if(row != imageHeight-1)
		mov r11d, imageHeight;
		dec r11d;
		cmp eax, r11d
		jz ifend

		mov r12d, ecx					; r12d = i
		inc r12d						; i+1

		mov r13b, BYTE PTR[rsi+r12]
		pinsrw xmm0, r13d, 3
		
		sub r12d, 2						; r12d = i-1

		mov r13b, BYTE PTR[rsi+r12]
		pinsrw xmm0, r13d, 7

		mov r8d, r12d					;r8d = i-1
		sub r8d, imageWidth				;r8d = (i-1)-imageWidth
		mov r13b, BYTE PTR[rsi+r8]
		pinsrw xmm0, r13d ,0

		add r8d, 2						;r8d = i+1-imageWidth
		mov r13b, BYTE PTR[rsi+r8]
		pinsrw xmm0, r13d ,2

		mov r8d, imageWidth				;r8d = imageWidth
		add r8d, ecx					;r8d = imageWidth +i
		inc r8d							;r8d = i+1+imageWidth
		mov r13b, BYTE PTR[rsi+r8]
		pinsrw xmm0, r13d ,4

		sub r8d,2						;r8d = i-1+imageWidth
		mov r13b, BYTE PTR[rsi+r8]
		pinsrw xmm0, r13d ,6
		jmp ifend


ifend:
	
	pmaddwd	xmm0, xmm1	; multiply and add words into dwords
	phaddd xmm0, xmm0	; add 2 neighbouring dwords into one dword
	phaddd xmm0, xmm0	; ^ and now the sum of all words(bytes) is in the first dword of xmm0

	pextrd eax, xmm0, 0	; the sum is now in eax

	imul eax, eax		; calculate the power of 2 of the number for later

	mov [rdi+rcx*4], eax


	inc ecx				;increment counter
	cmp ecx, r9d
jnz forloop

ret
Vertical endp	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Horizontal proc	;GY result stored in helperArray

; r14 - whereToStart
; r15 - bytesToCalculate
; rsi - grayArrayStart
; rdi - readyArray
; rax - current row
; rcx - loop couner
; r8 - temporary value
; r9d - where to end in grayArray
; r10d - ecx%imagewidth
; r11 - register used in cmp
; r12d - ecx +/- 1
; r13b - byte holder for pixels

;GYMATRIX:	
; 1  2  1
; 0  0  0
;-1 -2 -1

;assigning GY matrix to XMM1

mov r8, 0000000100020001h			; hex for first 4 numbers 
pinsrq xmm1, r8, 0
mov r8, 0000FFFFFFFEFFFFh			; hex for last 4 numbers
pinsrq xmm1, r8, 1


mov rsi, grayArrayStart
mov rdi, helperArray


mov ecx, r14d						; Counter for loop

mov r9d, ecx						; use r9 for end of loop
add r9d, r15d						; ^

forloop:
	xorpd xmm0, xmm0 ; Clean xmm0 register

	;Calculate the current row
	mov eax, ecx	; save the conter into eax
	xor edx,edx		; clean edx for division
	div imageWidth	; div to get modulo in edx. <-SLOW?
	mov eax, ecx	; save the counter again
	sub eax, edx
	mov r10d, edx	; save the  i%imageWidth for later
	xor edx,edx		; clean edx for division
	div imageWidth	; finally row is saved in eax


	cmp eax, 0
	jnz ifelse
	; IF statement - top wall:
		jmp ifend

	ifelse:
		mov r11d, imageHeight
		dec r11d
		cmp eax, r11d					;row =?= imageHeight-1
		jnz ifelse2

		; ELSEIF statement - bottom wall:
		jmp ifend

	ifelse2:
		; ELSE statement - center:

		;if(i%imageWidth!=0)
		cmp r10d, 0
		jz ifend

		;if(i%imageWidth != imageWidth-1)
		mov r11d, imageWidth;
		dec r11d;
		cmp r10d, r11d
		jz ifend

		mov r8d, ecx
		add r8d, imageWidth				; r8d = i+imageWidth
		mov r13b, BYTE PTR[rsi+r8]
		pinsrw xmm0, r13d, 5

		mov r12d, ecx
		sub r12d, imageWidth			; r12d = i-imageWidth
		mov r13b, BYTE PTR[rsi+r12]
		pinsrw xmm0, r13d, 1

		dec r12d						; r12d = i-1-imageWidth
		mov r13b, BYTE PTR[rsi+r12]
		pinsrw xmm0, r13d, 0

		dec r8d							; r8d = i-1+imageWidth
		mov r13b, BYTE PTR[rsi+r8]
		pinsrw xmm0, r13d, 6

		mov r8d, ecx
		inc r8d
		add r8d, imageWidth				; r8d = i+1+imageWidth
		mov r13b, BYTE PTR[rsi+r8]
		pinsrw xmm0, r13d, 4

		mov r8d, ecx
		inc r8d
		sub r8d, imageWidth				; r8d = i+1-imageWidth
		mov r13b, BYTE PTR[rsi+r8]
		pinsrw xmm0, r13d, 2

		jmp ifend


ifend:
	
	pmaddwd	xmm0, xmm1	; multiply and add words into dwords
	phaddd xmm0, xmm0	; add 2 neighbouring dwords into one dword
	phaddd xmm0, xmm0	; sum of all is now in the first dword

	pextrd eax, xmm0, 0	; the sum is now in eax

	imul eax, eax		; GY^2
	mov [rdi+rcx*4], eax

	inc ecx
	cmp ecx, r9d
	jnz forloop

ret
Horizontal endp

end