org 100h

	mov ax,0b000h
	mov es,ax
	mov si,8000h
	add si,320
	mov di,var4
L1:
	cmp byte[di],0
	je L2
	mov al,[di]
	mov [es:si],al
	mov byte[es:si+1],2Fh
	inc di
	add si,2
	jmp L1
	
L2:	
	mov ax, 4ch
	int 21h

var1 db 25
var2 db 3ah
var3 db 21h,7Fh,16,32
var4 db 'Hello World!!!'
var7 db 25,0Fh, 'Another string'
var5 dw 60124,0FFFFh,16,32,7Fh
var6 dd 4000000000,11223344h,0aaffh,99h 

