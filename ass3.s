section	.rodata	
    argumant_str_int: db "%d" , 0
    argumant_str_float: db "%f" , 0

section .bss
    current_arg_ptr resd 1

    drone_num resd 1
    scheduler_cycles resd 1
    printer_steps resd 1
    max_distance_destroy resq 1 
    seed resd 1

    cors_num resd 1
    CORS resd 1
    drone_array resd 1


    TARGET_OFFSET resd 1
    PRINTER_OFFSET resd 1
    SCHEDULER_OFFSET resd 1

    randomized_num resw 1
    SPT resd 1                          
    SPMAIN resd 1

;      CORS -> [CO1 , CO2 , ...] : 4N b | COi -> [Funci , SPi , CO-Index] : 12 b | STKi -> [... , SPi] : 1 kb

section .data
    STKSIZE: dd 1024
    

section .text 
    
  global main
  global get_random_number
  global CORS
  global drone_num
  global SPMAIN
  global SPT

  global drone_array
  global scheduler_cycles
  global printer_steps
  global max_distance_destroy

  global SCHEDULER_OFFSET  
  global TARGET_OFFSET
  global PRINTER_OFFSET

  extern initSchedulerCor
  extern initDroneCor
  extern initTargetCor
  extern initPrinterCor

  extern createDrone
  extern getNewCoords

  extern printf
  extern fprintf 
  extern sscanf
  extern malloc 
  extern calloc 
  extern free



%macro define_array_of_cors 1
    push 4                  ; the size of each CORi pointer 
    push %1                 ; the amount of cors
    call calloc
    add esp , 8             ; EAX = return value from calloc
    mov [CORS] , eax        ; CORS = EAX
%endmacro

%macro init_cors_struct 1
     mov ecx , 0
    %%next_cor:
        push ecx                            ; Save counter
        push 4                              ; the size of Func and SPP
        push 3                              ; Func , spp , index
        call calloc
        add esp , 8                         ; EAX = return value from calloc
        pop ecx
        mov ebx , %1 
        mov [ebx + (4*ecx)] , eax
        mov [eax + 8] , ecx
        inc ecx
        cmp ecx, dword [cors_num]
        jl %%next_cor
%endmacro    

%macro init_stacks_in_cors 1
    mov ecx , 0
    %%next_cor:
        push ecx
        push %1                    ; the size of each stack
        push 1                              ; Create a stack for each co routine      
        call calloc
        add esp , 8                         ; EAX = return value from calloc
        
        mov edi, [CORS]                     ; CORS[i] -> EBX
        pop ecx
        mov edx , [edi + (4*ecx)]
        mov ebx , eax
        add ebx , %1
        mov [edx + 4], ebx
        inc ecx

        cmp ecx, dword [cors_num]
        jl %%next_cor
%endmacro

%macro init_cor_and_offset 2
    inc ecx
    mov ebx , [esi + (4*ecx)]
    mov eax , 4
    mul ecx
    mov %1, eax
    call %2

%endmacro

%macro init_drone_array 1          ; flag4b + x8b + y8b + angle8b + speed8b + targetDestroyed4b + index4b = 44b
    mov edx , [drone_num]
    push  44                          ; Each block is 40 bytes
    push edx                            ; edx -> the amount pof drones
    call calloc
    add esp , 8                         ; EAX = return value from calloc
    mov %1 , eax                          ; drone_array = EAX

%endmacro


%macro get_argumant 2
    add dword [current_arg_ptr] , 4                 ; ECX = args[i]
    push %1
    push %2
    mov ecx , [current_arg_ptr]
    push dword [ecx]
    call sscanf
    add esp , 12
%endmacro 



get_random_number:
    pushad
    mov ax ,  [randomized_num]

    mov bx , 1                         ; 0000 0000 0000 0001
    and bx , ax
    mov cx , 4                         ; 0000 0000 0000 0100
    and cx , ax
    shr cx , 2
    xor bx , cx
    mov cx , 8                         ; 0000 0000 0000 1000
    and cx , ax
    shr cx , 3
    xor bx , cx
    mov cx , 32                        ; 0000 0000 0010 0000
    and cx , ax
    shr cx , 5
    xor bx , cx

    shl bx , 15
    shr ax , 1
    or ax , bx
    mov [randomized_num] , ax

    popad
    mov eax , 0
    mov ax , [randomized_num]
    ret        

  


main:
	push ebp
	mov ebp, esp	
	pushad

handle_args:
    mov ebx , 0
    mov edx , [ebp + 12]                 ; edx contains a pointer to the args
    mov ecx , edx 
    mov [current_arg_ptr] , ecx

    get_argumant drone_num , argumant_str_int
    get_argumant scheduler_cycles , argumant_str_int
    get_argumant printer_steps , argumant_str_int
    get_argumant max_distance_destroy , argumant_str_float
    get_argumant seed , argumant_str_int


    mov ecx , [seed]          ; tranfer seed to edx
    mov [randomized_num] , ecx          ; move the seed into the random number

    mov edx , [drone_num]
    add edx , 3
    mov [cors_num] , edx


;Initialise co-routines -> Number of drones + target + scheduler + printer


    define_array_of_cors dword [cors_num]     ; Create the coroutines array

    init_cors_struct dword [CORS]
    init_stacks_in_cors dword [STKSIZE] 
    init_drone_array dword [drone_array]

    call getNewCoords                            ; Initialize the target

    mov ecx , 0
    mov esi , [CORS]

drones_creator:                         
    mov ebx , [esi + (4*ecx)]
    call createDrone
    inc ecx
    cmp ecx, [drone_num]
    jl drones_creator

    mov ecx , 0
    mov esi , [CORS]
init_cors:
    mov ebx , [esi + (4*ecx)]
    call initDroneCor
    inc ecx
    cmp ecx , dword [drone_num] 
    jl init_cors

    dec ecx
    init_cor_and_offset dword [TARGET_OFFSET] , initTargetCor
    init_cor_and_offset dword [PRINTER_OFFSET] , initPrinterCor
    init_cor_and_offset dword [SCHEDULER_OFFSET] , initSchedulerCor


end:
	popad			
	mov esp, ebp	
	pop ebp
    mov eax, 1                      ; call exit
    int 0x80    
