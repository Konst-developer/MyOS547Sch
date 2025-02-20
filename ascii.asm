;org 100h
	mov ax,0b000h
	mov es,ax
	mov si,8000h
	add si,160
	mov cx,0
LP0:
	mov byte [es:si],cl
	mov byte [es:si+1],cl
	add si,2
	inc cx
	cmp cx,100h
	jne LP0
	;mov ax, 4ch
	;int 21h
	jmp $