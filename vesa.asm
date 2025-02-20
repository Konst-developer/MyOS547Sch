;org 100h
	
	mov ax,4f02h
	mov bx,324
	int 10h
	mov byte[BB],50
	
	mov word[YY],0
forY:	
	mov word[XX],0
	xor eax,eax
	mov ax,[YY]
	mov ebx,eax
	shr ax,2
	shr	bx,4
	add	ax,bx
	mov byte[GG],al
	
forX:
	xor eax,eax
	mov ax,[XX]
	shr ax,2
	mov [RR],al
	call putPixel
	inc word[XX]
	cmp word[XX],1024
	jne forX
	
	inc word[YY]
	cmp word[YY],768
	jne forY
	
	
	jmp $
	
	xor ax,ax
	int 16h
	mov ax,0002h
	int 10h
	;mov ax,4ch
	;int 21h
	
mem		dd	0
XX		dw	0
YY		dw	0
BB		db	0
GG		db	0
RR		db	0
NN		db	0
bank	dw	0

putPixel:
	xor ebx,ebx
	mov bx,[YY]
	shl ebx,12
	
	xor eax,eax
	mov ax,[XX]
	shl eax,2
	add eax,ebx
	mov [mem],eax
	
	mov ax,[mem+2]
	cmp ax,[bank]
	je lp1
	mov [bank],ax
	mov ax,4f05h
	xor bx,bx
	mov dx,[mem+2]
	int 10h
lp1:
	mov ax,0a000h
	mov es,ax
	mov di,[mem]
	mov eax,[BB]
	mov [es:di],eax
	ret