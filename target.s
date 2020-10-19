section	.rodata	
    print_num: db "0x%X", 10, 0	        ; format string sor fprinf
    print_cor: db " ------------------ >>>>>>     The target now is in loaction: (%f , %f)     <<<<-------------------", 10,10, 0	        ; format string sor fprinf
    MAX_INT: dd 65535
    BOARD_SIZE: dd 100


section .bss
    x_target_loc resq 1                    
    y_target_loc resq 1  
    random_number resw 1                  


section .text  
  global getNewCoords
  global x_target_loc
  global y_target_loc
  global initTargetCor


  extern SPT
  extern SCHEDULER_OFFSET
  extern drone_index

  extern resume
  extern CORS
  extern PARAMS
  extern get_random_number
  extern printf
  extern fprintf 
  extern sscanf
  extern malloc 
  extern calloc 
  extern free

initTargetCor:
    mov eax, createTarget
    mov [SPT], esp 
    mov esp, [ebx + 4] 
    push eax 
    pushfd 
    pushad 
    mov [ebx + 4], esp 
    mov esp, [SPT]
    ret

createTarget:                  ; Initialise the target
    call getNewCoords

    mov esi , [CORS]
    mov eax , [drone_index]     
    mov ebx , [esi + (4*eax)]            
    call resume
    jmp createTarget

getNewCoords:
    push ebp
    mov ebp , esp
    pushad

    call get_random_number      ; EAX = random(2 BYTE) 0x1234
    mov cx, ax
    mov word [random_number], cx
    fild dword [random_number]
    fidiv dword [MAX_INT]                      ; EAX = EAX \ MAXINT
    fimul dword [BOARD_SIZE]                       ; EAX = EAX * 100
    fstp qword [x_target_loc]                  ; X = (EAX / MAXINT) * 100 -> [0,100]

    call get_random_number      
    mov cx, ax
    mov word [random_number], cx
    fild dword [random_number]
    fidiv dword [MAX_INT]               ; EAX = EAX \ MAXINT
    fimul dword [BOARD_SIZE]                    ; EAX = EAX * 100
    fstp qword [y_target_loc]         ; Y = (EAX / MAXINT) * 100 -> [0,100]

    popad
    pop ebp
    ret    