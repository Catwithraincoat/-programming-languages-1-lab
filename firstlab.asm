section .text
 
 
; Принимает код возврата и завершает текущий процесс
exit: 
    mov rax, 60 
    xor rdi, rdi 						
	syscall 							 
	ret


; Принимает указатель на нуль-терминированную строку, возвращает её длину
string_length:
    xor rax, rax						
    .loop:
        cmp byte [rdi + rax], 0				
        je .end								
        inc rax								
        jmp .loop							 
    .end:
        ret


; Принимает указатель на нуль-терминированную строку, выводит её в stdout
print_string:;print_string(rdi)
    call string_length
    mov rdx, rax
    mov rsi, rdi
    mov rax, 1
    mov rdi, 1
    syscall
    ret

; Принимает код символа и выводит его в stdout
print_char:;print_char(rdi)
    push rdi
    mov rsi , rsp
    mov rdx, 1
    mov rax, 1
    mov rdi, 1
    syscall
    pop rdi
    ret

; Переводит строку (выводит символ с кодом 0xA)
print_newline:
    mov rdi, 0xA

; Выводит беззнаковое 8-байтовое число в десятичном формате 
; Совет: выделите место в стеке и храните там результаты деления
; Не забудьте перевести цифры в их ASCII коды.
print_uint:
    xor rax, rax
    mov r10, 10
    mov r9, 0
	push r9 ; кладем нуль-терминатор в стек 
    mov rax, rdi
    .loop:
        xor rdx, rdx
        div r10
        mov rsi, rdx
        add rsi, 48
        inc r9
        dec rsp
        mov [rsp], sil
        cmp rax, 0
        jne .loop

    mov rdi, rsp ; выводим число
	call print_string

    add rsp, r9
	add rsp, 8 ; возвращаем стек в исходное состояние
        ret


; Выводит знаковое 8-байтовое число в десятичном формате 
print_int:
    cmp rdi, 0
    jge print_uint
    neg rdi
    push rdi
    mov rdi, "-"
    call print_char
    pop rdi
    call print_uint
    ret

; Принимает два указателя на нуль-терминированные строки, возвращает 1 если они равны, 0 иначе
string_equals:
    xor cl, rcx
	xor al, rax
    .iterates:
        mov cl, [rsi]
        mov al, [rdi]
        cmp cl, al
        jne .not_equal
        cmp cl, 0
        je .equal
        inc rsi
        inc rdi
        jmp .iterates
    .not_equal:
        mov rax, 0
        ret
    .equal:
        mov rax, 1
        ret

; Читает один символ из stdin и возвращает его. Возвращает 0 если достигнут конец потока
read_char:
    mov rax, 0
    mov rdi, 0
    push rax 
    mov rsi, rsp 						
	mov rdx, 1
    syscall
    pop rax 
    ret 

; Принимает: адрес начала буфера, размер буфера
; Читает в буфер слово из stdin, пропуская пробельные символы в начале, .
; Пробельные символы это пробел 0x20, табуляция 0x9 и перевод строки 0xA.
; Останавливается и возвращает 0 если слово слишком большое для буфера
; При успехе возвращает адрес буфера в rax, длину слова в rdx.
; При неудаче возвращает 0 в rax
; Эта функция должна дописывать к слову нуль-терминатор

read_word:
    xor r8, r8
    xor r9, r9
    call read_char
    .iterates:
        call read_char
    .check_space:
        cmp rax, 0x20 						
        je .iterates 							
        cmp rax, 0x9 						
        je .iterates							
        cmp rax, 0xA 						
        je .iterates							
        jmp .sym 	
    .plus_zero:
    .error:
	    xor rax, rax 						
	    ret
    .end:
        mov rax, 
        mov rdx, 
        ret
 

; Принимает указатель на строку, пытается
; прочитать из её начала беззнаковое число.
; Возвращает в rax: число, rdx : его длину в символах
; rdx = 0 если число прочитать не удалось
parse_uint:
    mov r8, 10  						
	xor rax, rax 						
	xor rcx, rcx 						
.loop:
	movzx r9, byte [rdi + rcx] 			
	cmp r9b, '0' 						
	jb .end 							
	cmp r9b, '9' 						
	ja .end 							
	xor rdx, rdx 						
	mul r8							 
	sub r9b, '0' 						
	add rax, r9 						
	inc rcx								
	jmp .loop 							
.end:
	mov rdx, rcx 						
	ret
; Принимает указатель на строку, пытается
; прочитать из её начала знаковое число.
; Если есть знак, пробелы между ним и числом не разрешены.
; Возвращает в rax: число, rdx : его длину в символах (включая знак, если он был) 
; rdx = 0 если число прочитать не удалось
parse_int:
    mov r8, 10 							
	xor rax, rax 						
	xor rcx, rcx 						
	push 1 								
.loop:
	movzx r9, byte [rdi + rcx] 			
	cmp r9b, '-' 						
	je .minus 							
	cmp r9b, '0' 						
	jb .check 							
	cmp r9b, '9' 						
	ja .check 							
	xor rdx, rdx 						
	mul r8 								
	sub r9b, '0' 						
	add rax, r9 						
.continue:
	inc rcx 							
	jmp .loop 							

.minus:
	mov r10, 0 							
	mov [rsp], r10 						 
	jmp .continue 						 

.check:
	pop r10 							
	cmp r10, 0 							 
	je .neg 							
	jmp .end 							

.neg:
	neg rax 							
	jmp .end 							

.end:
	mov rdx, rcx 						
	ret 


; Принимает указатель на строку, указатель на буфер и длину буфера
; Копирует строку в буфер
; Возвращает длину строки если она умещается в буфер, иначе 0
string_copy:
    call string_length ;rax => str_len
    cmp rax, rdx
    jae .error    

    xor r8, r8
    .loop:
        
        mov r8, [rdi]
        mov [rsi], r8
        sub rdx, 1
        inc rsi
        inc rdi
        cmp rdx, 0
        jnz .loop

    ret
    
    .error:
        mov rax, 0
        ret
