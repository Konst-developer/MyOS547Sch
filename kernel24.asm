use16
KERNEL_SEG		EQU	1000h
C_SEGMENT		EQU	8192

START:
	cli
	mov ax,KERNEL_SEG
	mov	es,ax
	mov ds,ax
	mov ss,ax
	mov sp,STACK
	sti
	
	mov si,84h
	push es
	xor ax,ax
	mov es,ax
	mov ax,INT21
	mov [es:si],ax
	mov word[es:si+2],KERNEL_SEG
	pop es
	
	mov ax,3
	mov bx,0500h
	int 21h
	
	mov ax,4
	mov bl,0Ch
	int 21h
	
	mov cx,500
L0002:
	push cx
	
	mov ax,1
	int 21h
	
	mov ax,5
	int 21h
	
	pop cx
	loop L0002
	
	mov ax, KERNEL_SEG
	mov ds,ax
	mov es,ax
	mov si,str1
	mov ax,5
	int 21h
	
	mov bl, 127  ;7F
	mov ax,6
	int 21h
	
	mov ax,5
	int 21h
	
	mov ax, KERNEL_SEG
	mov ds,ax
	mov es,ax
	mov si,str1
	mov ax,5
	int 21h
	
	mov bx, 32767  
	mov ax,7
	int 21h
	
	mov ax,5
	int 21h
	
	mov bx,0
L0003:
	push bx
	mov ax,7
	int 21h
	mov ax,5
	int 21h
	
	mov ax,KERNEL_SEG
	mov	es,ax
	mov ds,ax
	mov si,str2
	mov ax,5
	int 21h
	
	mov ecx,1000; задержка
	mov ax,8
	int 21h
	
	pop bx
	inc bx
	cmp bx,0
	jne L0003
	
	jmp KERNEL32
	
INT21:	
	push bx
	cli
	mov bx,cs
	mov	es,bx
	mov ds,bx
	mov ss,bx
	;mov sp,STACK
	sti
	
	mov bl,3
	mul bl
	mov bx,SWITCH
	add ax,bx
	pop bx
	jmp ax
	
SWITCH:
	jmp near FUNC00
	jmp near FUNC01
	jmp near FUNC02
	jmp near FUNC03
	jmp near FUNC04
	jmp near FUNC05
	jmp near FUNC06
	jmp near FUNC07
	jmp near FUNC08
	
FUNC00:
	mov bx,0001h
	xor ax,ax
	iret

OSName db 'MyOS 2024 v0.01',10,'Copyright (c) MyOS 2024',0
FUNC01:;возвращает в es:si адрес строки с названием ОС
	mov si,OSName
	mov ax,KERNEL_SEG
	mov es,ax
	xor ax,ax
	iret

FUNC02:	;Очищает экран
	mov ax,0B000h
	mov es,ax
	mov si,8000h
	mov cx,1000
F02_1:
	mov eax,07000700h
	mov [es:si],eax
	add si,4
	loop F02_1
	
	mov ax,KERNEL_SEG
	mov ds,ax
	mov byte[cursX],0
	mov byte[cursY],0
	mov ah,2
	mov bh,0
	xor dx,dx
	int 10h
	xor ax,ax
	
	iret

FUNC03:;задает координаты курсора, bh - Y, bl - X 
	mov ax,KERNEL_SEG
	mov ds,ax
	mov [cursX],bl
	mov [cursY],bh
	mov ah,2
	mov bh,0
	mov dl,[cursX]
	mov dh,[cursY]
	int 10h
	xor ax,ax
iret

FUNC04:;задает аттрибуты текста из bl 
	mov ax,KERNEL_SEG
	mov ds,ax
	mov [textAttr],bl
	xor ax,ax
iret

FUNC05:;выводит строку с глобальной позиции курсора
		;перемещает курсор. вход es:si - адрес строки
	mov ax,KERNEL_SEG
	mov ds,ax
	mov di,8000h
	
	mov al,160
	mul byte[cursY]
	movzx bx,byte[cursX]
	shl bx,1
	add ax,bx
	add di,ax
	
	mov ax,0B000h
	mov ds,ax
F05_2:
	cmp byte[es:si],0
	je	F05_1
	cmp byte[es:si],0Ah
	je	F05_4
	mov al,[es:si]
	mov [ds:di],al
	push ds
	mov ax,KERNEL_SEG
	mov ds,ax
	mov al,[textAttr]
	pop ds
	mov [ds:di+1],al
	push ds
	mov ax,KERNEL_SEG
	mov ds,ax
	inc byte[cursX]
	cmp byte[cursX],80
	jne F05_3
	inc byte[cursY]
	mov byte[cursX],0
	cmp byte[cursY],25
	jne F05_3
	
	mov byte[cursY],24
	call Shift

	mov di,8E5Eh;
F05_3:
	pop ds
	inc si
	add di,2
	jmp F05_2
F05_4:
	push ds
	mov ax,KERNEL_SEG
	mov ds,ax
	inc byte[cursY]
	mov byte[cursX],0
	cmp byte[cursY],25
	jne F05_5
	mov byte[cursY],24

	call Shift

F05_5:
	mov al,160
	mul byte[cursY]
	mov di, 8000h
	add di, ax
	inc si
	pop ds
	jmp F05_2

F05_1:
	mov ax,KERNEL_SEG
	mov ds,ax
	mov ah,2
	mov bh,0
	mov dl,[cursX]
	mov dh,[cursY]
	int 10h
	xor ax,ax
iret

hex		db	'00',0
hexStr	db	'0123456789ABCDEF'
FUNC06:;Преобразует байт из bl в hex-строку с адресом es:si
	mov ax,KERNEL_SEG
	mov ds,ax
	mov es,ax
	movzx ax,bl
	mov bl,16
	div bl
	mov di,hexStr
	mov si,hex
	movzx bx,ah
	add di,bx
	mov bl,[ds:di]
	mov [es:si+1],bl
	
	mov di,hexStr
	movzx bx,al
	add di,bx
	mov bl,[ds:di]
	mov [es:si],bl
	xor ax,ax
iret

decN	db '00000',0
FUNC07:;преобразует слово в bx в десятичную строку c адресом es:si
	mov ax,KERNEL_SEG
	mov ds,ax
	mov es,ax
	mov cx,5
	mov si,decN+4
	mov ax,bx
F07_2:
	xor dx,dx
	mov bx,10
	div bx
	mov di,hexStr
	add di,dx
	mov bl,[ds:di]
	mov [es:si],bl
	cmp ax,0
	je F07_1
	dec si
	loop F07_2
F07_1:	
	xor ax,ax
iret

FUNC08:;задержка. вход ecx
	dec ecx
	cmp ecx,0
	jne FUNC08
	xor ax,ax
iret

Shift:; скролит экран, если переполнен
	push es
	push ds
	push si
	push di
	mov ax,0B000h
	mov es,ax
	mov ds,ax
	mov si,8000h
	mov di,80A0h
	mov cx,1000
Shift_01:
	mov eax,[ds:di]
	mov [es:si],eax
	add si,4
	add di,4
	loop Shift_01
	pop di
	pop si
	pop ds
	pop es
ret

cursX		db	0
cursY		db	0
textAttr	db	0Fh 	
str1		db	10,0
str2		db	' ',0
times 1024 db 0
STACK:

GDT:
dsc0:
	dd 0,0
dsc1:; сегмент кода
	dw  0FFFFh;limit low
	dw  0000h; base low
	db	  01h; base middle
	db	1001_1010b;P DPL S | code/data c xr a
	db	1100_1111b;G 32bit 64bit AVL | limit high
	db 	  00h; base high
	
dsc2:; сегмент данных
	dw  0FFFFh;limit low
	dw  0000h; base low
	db	  01h; base middle
	db	1001_0010b;P DPL S | code/data c xr a
	db	1100_1111b;G 32bit 64bit AVL | limit high
	db 	  00h; base high	
	
dsc3:; видеобуфер
	dw  0FFFFh;limit low
	dw  8000h; base low
	db	  0Bh; base middle
	db	1001_0010b;P DPL S | code/data c xr a
	db	0100_0000b;G 32bit 64bit AVL | limit high
	db 	  00h; base high
	
dsc4:; код реального режима
	dw  0FFFFh;limit low
	dw  0000h; base low
	db	  01h; base middle
	db	1001_1010b;P DPL S | code/data c xr a
	db	0000_0000b;G 32bit 64bit AVL | limit high
	db 	  00h; base high
GDT_size	equ	$-GDT
GDTR		dw	GDT_size-1
			dd	GDT

IDT:
	dd		0,0;0
	dw		syscall_handler, 0008h,1000_1110_0000_0000b,0;1
	dd		0,0
	dd		0,0
	dd		0,0
	dd		0,0
	dd		0,0
	dd		0,0 ;7
	dw		int8_handler,0008h,1000_1110_0000_0000b,0; Системный таймер 8
	dw		int9_handler,0008h,1000_1110_0000_0000b,0; Клавиатура
	dw		int_EOI,0008h,1000_1110_0000_0000b,0; ведомый контроллер прерываний
	dw		int_EOI,0008h,1000_1110_0000_0000b,0;COM2
	dw		int_EOI,0008h,1000_1110_0000_0000b,0;COM1
	dw		exGP_handler,0008h,1000_1110_0000_0000b,0;General Protection Fault 
	dw		int_EOI,0008h,1000_1110_0000_0000b,0; FDD
	dw		int_EOI,0008h,1000_1110_0000_0000b,0; LPT
	dw		int_EOI,0008h,1000_1110_0000_0000b,0
	dw		int_EOI,0008h,1000_1110_0000_0000b,0
	dw		int_EOI,0008h,1000_1110_0000_0000b,0
	dw		int_EOI,0008h,1000_1110_0000_0000b,0
	dw		int_EOI,0008h,1000_1110_0000_0000b,0
	dw		int_EOI,0008h,1000_1110_0000_0000b,0
	dw		int_EOI,0008h,1000_1110_0000_0000b,0
	dw		int_EOI,0008h,1000_1110_0000_0000b,0
IDT_size	equ $-IDT
IDTR		dw	IDT_size-1
			dd	IDT
REAL_IDTR	dw	3FFh
			dd	0
KERNEL32:
	cli
	mov ax,cs
	mov ds,ax
	mov ss,ax
	mov es,ax
	mov sp,STACK
	mov bp,sp
	
	;открываем линию А20
	in	al,92h
	or	al,2
	out	92h,al
	
	;запрещаем NMI
	in 	al,70h
	or 	al,80h
	out 70h,al
	
	xor eax,eax
	mov ax,cs
	shl eax,4
	add eax,GDT
	mov [GDTR+2],eax
	
	xor eax,eax
	mov ax,cs
	shl eax,4
	add	eax,IDT
	mov dword[IDTR+2],eax
	
	lgdt	[GDTR]
	lidt	[IDTR]	
	
	;переходим в защищенный режим
	mov eax,cr0
	or al,1
	mov cr0,eax
	
	db 66h;префикс изменения разрядности операнда
	db 0EAh; опкод команды jmp
	ENTRY_OFF dd PROTECTED_ENTRY; 32-битное смещение
	dw 8;селектор сегмента кода (1-й дескриптор)
	;jmp far 08h:PROTECTED_ENTRY
	
use32
PROTECTED_ENTRY:
	mov ax,16
	mov ds,ax
	mov ss,ax
	mov ax,24
	mov es,ax
	mov byte[es:2000],'A'
	mov byte[es:2001],0Ch
	
	in	al,70h;включаем прерывания
	and	al,7fh
	out	70h,al
	sti
	
	mov esi, strHello
	int 1
	
	mov eax,0
	call getFnAddress
	call eax
	
	jmp $
	
getFnAddress:;Возвращает адрес функции из блока C по ее номеру.
			; вход eax
	inc eax
	shl eax,5
	add eax,C_SEGMENT
	mov eax,[eax]
	add eax,C_SEGMENT
	add eax,[C_SEGMENT]
ret
	
;Обработчики прерываний защищенного режима
;=========================================
;IRQ 0 обработчик прерываний системного таймера
int8_handler:
	inc byte[es:158]
	push eax
	mov eax,8
	call getFnAddress
	call eax
	pop eax
	jmp int_EOI
	
;IRQ 1 клавиатура 
cursor	dd 0
int9_handler:
	push eax
	push edi
	xor eax,eax
	
	in	al,60h; считываем позиционный код клавиши
	
	mov ah,al
	and ah,80h
	jnz clear_request
	
;преобразуем позиционный код в ASCII
	and	al,7Fh
	push edi
	mov edi,ascii
	add edi,eax
	mov al,[edi]
	pop edi
	
	mov edi,dword[cursor]
	shl edi,1
	mov byte[es:edi],al
	inc dword[cursor]
;посылаем подтверждение обработки в порт клавиатуры
;установка и сброс 7-го бита порта 61h
Ack:	
	in	al,61h
	or	al,80h
	out 61h,al
	xor al,80h
	out 61h,al
clear_request:
	pop	edi
	pop eax
	jmp int_EOI

int_EOI:
	push eax
	mov al,20h
	out 20h,al
	out 0A0h,al
	pop eax
	iretd
	
exGP_handler:
	iretd
syscall_handler:
	pushad
_puts:
	lodsb
	mov edi,[cursor]
	mov [es:edi*2],al
	mov bl,0Fh;
	mov	[es:edi*2+1],bl
	inc dword[cursor]
	test al,al
	jnz _puts
	popad
	iretd

strHello db 'Hello World!!!',0
ascii	db 0,'1234567890-=',0,0,'QWERTYUIOP[]',0,0,'ASDFGHJKL;',"'`",0,0,'ZXCVBNM,./',0,'*',0,' ',0,0,0,0,0,0,0,0,0,0,0,0,0,'789-456+1230.',0,0
times C_SEGMENT -$+START db 0