org 7C00h
begin:
	jmp near START
BootSector:
	mName		db	'myOS2024'
	nBytesS		dw	0
	nSectInCl	db	0
	nRes		dw	0
	nFAT		db	0
	nDSC		dw	0
	nSectD		dw	0
	dType		db	0
	sectPerFAT	dw	0
	sectPerTr	dw	0
	nHead		dw	0
	nHiddenS	dd	0
	nSect32		dd  0
	nDisk		db	0
	resNT		db  0
	extBoot		db	0
	nLog		dd	0
	dLabel		db	'myOS2024DRV'
	FSname		db	'FAT16',0,0,0

LBA:
	pSize		db	10h
	reserved	db	0
	nSect		db	32
	res2		db	0
	offs		dw	8000h
	segm		dw	0
	nBlock1		dw	0
	nBlock2		dw	0
	nBlock3		dw	0
	nBlock4		dw	0
	
	FileName	db	'MYOS2024SYS'
	compare		db	0
	cnt			dw	0
	secondCl	dd	0;первый сектор, где начинается DataArea
	Err			db	'Kernel not found'
	
START:
	cli
	xor ax,ax
	mov ds,ax
	mov es,ax
	mov ss,ax
	mov sp,7C00h
	sti
	
	xor eax,eax
	mov ax,[sectPerFAT]
	xor ebx,ebx
	mov bl,[nFAT]
	mul ebx
	mov	[nBlock1],eax
	mov eax,[nHiddenS]
	add [nBlock1],eax
	xor	eax,eax
	mov ax,[nRes]
	add [nBlock1],eax
	mov eax,[nBlock1]
	mov [secondCl],eax
	mov ax,[nDSC]
	shr ax,4
	add [secondCl],ax
	adc word[secondCl+2],0
	
	
	call readSector
	
	;mov ax,8000h
	mov di,8000h
	mov ax,FileName
	mov si,ax
	
findFile:
	call strcmp
	cmp byte[compare],1
	je LB2
	add di,32
	inc word[cnt]
	cmp word[cnt],512
	jne findFile
	mov bp,Err
	mov cx,16
	mov bl,04h
	mov dx,0500h
	call Print
	jmp $
	
LB2:
	mov ax,[ds:di+1Ah]
	mov bx,0C000h
	mov si,bx
	mov [es:si],ax
	


findNext:
	add si,2
	call findClusterFAT
	mov word[offs],8000h
	mov byte[nSect],1
	call readSector
	mov di,8000h
	add di,ax
	mov ax,[ds:di]
	mov [es:si],ax
	cmp ax,0FFFFh
	jne findNext


	
	mov si,0C000h
	mov word[segm],1000h
	mov word[offs],0		;1000:0000
	
loadNext:
	mov ax,[es:si]
	call loadCluster
	
	xor bx,bx
	xor cx,cx
	mov bl,byte[nSectInCl]
	shl bx,9
	xor cx,cx
	add word[offs],bx
	adc cx,0
	shl cx,12
	add word[segm],cx
	add si,2
	cmp word[es:si],0FFFFh
	jne loadNext
	

	
	jmp word 1000h:0000h

loadCluster:
	pusha
	sub ax,2
	mov ebx,[secondCl]
	mov [nBlock1],ebx
	xor ebx,ebx
	mov bl,[nSectInCl]
	mul bx
	add [nBlock1],ax
	adc [nBlock2],dx
	mov [nSect],bl
	call readSector
	popa
	ret
	
findClusterFAT:	;Вход:ax-номер кластера; Выход: ax-номер записи в найденом секторе
	xor ebx,ebx
	mov bx,ax
	shr bx,8
	mov [nBlock1],ebx
	xor ecx,ecx
	mov ecx,[nHiddenS]
	add [nBlock1],ecx
	xor ecx,ecx
	mov cx,[nRes]
	add [nBlock1],ecx
	shl	bx,8
	sub ax,bx
	shl ax,1
	ret
	
	
	
	
readSector:
	pusha
	mov dl,80h
	mov ax,LBA
	mov si,ax
	mov ax,4200h
	int 13h
	popa
	ret

strcmp: ;es:si  ds:di
	push si
	push di
	mov byte[compare],1
	mov cx,11
LP1:
	mov al,[es:si]
	cmp al,[ds:di]
	je L1
	mov byte[compare],0
L1:	
	inc si
	inc di
	loop LP1
	pop di
	pop si
	ret

Print:
	xor ax,ax
	mov es,ax
	;mov bl,04h
	mov ax,1301h
	mov bh, 0
	int 10h
	ret	

debug:
;	mov ax,1000h
;	mov ds,ax
;	mov cx,512
;	mov ax,0b000h
;	mov es,ax
;	mov di,0000h	
;	mov si,8640h
LP5:	
;	mov al,[ds:di]
;	mov byte[es:si],al
;	mov byte[es:si+1],0Ch
;	inc di
;	add si,2
;	loop LP5
;	ret
	
times 510 -$+begin db 0
db 55h,0AAh