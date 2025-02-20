org 100h
	mov bx,2F00h
start:
	xor ax,ax;    al - x-координата, ah - y-координата


fory:
forx:
	call print
	mov cx,65535
	call delay
	inc bl
	inc bh
	inc al
	cmp al,80
	jne forx
	
	mov al,0
	inc ah
	cmp ah,25
	jne fory

;	jmp start

	xor ax,ax
	int 16h
	mov ax, 4ch
	int 21h

print:
	push ax
	xor cx,cx
	mov cl,ah
	shl cx,6
	mov [V_off],cx
	xor cx,cx
	mov cl,ah
	shl cx,4
	add [V_off],cx
	mov ah,0
	add [V_off],ax
	mov ax,[V_off]
	shl ax,1
	add ax,8000h
	mov si,ax
	mov ax,0B000h
	mov es,ax
	mov [es:si],bx
	pop ax
ret
V_off dw 0

delay:
	loop delay
ret
