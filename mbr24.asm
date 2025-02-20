org 0BC00h
begin:
	jmp near start
OSname db 'myOS2024'
LBA:
	pSize		db	10h
	reserved	db	0
	nSect		db	1
	res2		db	0
	offs		dw	0
	segm		dw	0
	nBlock1		dw	0
	nBlock2		dw	0
	nBlock3		dw	0
	nBlock4		dw	0
start:	
	cli
	xor ax,ax
	mov ds,ax
	mov es,ax
	mov ss,ax
	mov sp,0BC00h
	sti
	
	mov ax,0002h
	int 10h
	mov bp,msg1-4000h
	mov cx,20
	mov dx, 0100h
	mov bl,0Ah
	call Print
	
copyMBR:
	xor ax,ax
	mov bx,0BC00h
	mov [offs-4000h],bx
	mov dl,80h
	mov ds,ax
	mov ax,LBA-4000h
	mov si,ax
	mov ax,4200h
	int 13h
	
	jmp near Continue+4000h
	
Continue:	
	mov bp,msg2
	mov cx,32
	mov dx,0200h
	mov bl,0Ah
	call Print
	
	mov cx,4
	mov ax,0BDBEh
	mov si,ax
findPartition:
	mov al,[es:si]
	cmp al,80h
	je copyLoader
	add si,16
	dec cx
	cmp cx,0
	jne findPartition
	mov bp,err1
	mov cx,21
	mov bl,04h
	mov dx,0300h
	call Print
	jmp $
	
copyLoader:	
	mov ax,07C00h
	mov [offs],ax
	mov eax,[es:si+8]
	mov [nBlock1],eax
	mov dl,80h
	mov ax,LBA
	mov si,ax
	mov ax,4200h
	int 13h
	
	mov ax,7DFEh
	mov si,ax
	mov ax,[es:si]
	cmp ax,0AA55h
	jne error
	mov bp,msg3
	mov bl,0Ah
	mov cx,23
	mov dx,0300h
	call Print
	jmp word 0000h:7C00h
	
	
error:	
	mov bp,err2
	mov cx,11
	mov bl,04h
	mov dx,0300h
	call Print
	jmp $
	
Print:
	xor ax,ax
	mov es,ax
	;mov bl,04h
	mov ax,1301h
	mov bh, 0
	int 10h
	ret
	
msg1	db	'MBR start loading...'	
msg2	db	'MBR has been copied to 0000:BC00'
err1	db 	'No bootable partition'
err2	db	'Cannot boot'
msg3	db	'Going to boot sector...'

times 510-$+begin	db	0
db 55h,0AAh