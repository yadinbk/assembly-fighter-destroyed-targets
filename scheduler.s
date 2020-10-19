section .rodata
    winner: db "The winner is drone number : %d , with a score of %d !" , 10 , 0

section .data
    MAX_INT: dd 214748364
   

section .bss
  DRONES_LEFT resd 1
  CURRENT_COR resd 1
  schedule_counter resd 1
  LOWEST_SCORE resd 1

section .text
    global initSchedulerCor
    global resume
    global do_resume
    extern printer_steps
    extern drone_array
    extern SPT
    extern SPMAIN
    extern printf
    extern CORS
    extern drone_num
    extern PRINTER_OFFSET
    extern scheduler_cycles

initSchedulerCor:
    mov eax, SchedulerFunc
    mov [SPT], esp 
    mov esp, [ebx + 4] 
    push eax 
    pushfd 
    pushad 
    mov [ebx + 4], esp 
    mov esp, [SPT]
    call do_resume



SchedulerFunc:
    mov dword [CURRENT_COR] , ebx
    mov dword [schedule_counter] , 0
    mov esi , [CORS]
    mov edx , [drone_num]
    mov [DRONES_LEFT] , edx


    main_loop:
        mov eax , [schedule_counter]
        mov edx , 0
        div dword [drone_num]                   ; (i / N)
        mov eax , edx                           ; eax = (i % N)
        mov ebx , 44                            ; get offset for        
        push edx        
        mul ebx                                 ; 44 * (i % N)
        pop edx
        mov edi , [drone_array]
        add edi , eax
        cmp dword [edi] , 1
        jne check_print
        mov ebx , [esi + (4*edx)]
        call resume

        check_print:
            mov eax , [schedule_counter]
            mov edx , 0
            mov ebx , [printer_steps]
            div ebx 
            cmp edx , 0
            jne check_rounds
            mov edx , [PRINTER_OFFSET]
            mov ebx , [esi + edx]
            call resume

        check_rounds:
            mov eax , [schedule_counter]
            cmp eax , 0                         ; dont eliminate on first loop
            je end_of_loop
            mov edx , 0
            mov ebx , [drone_num]
            div ebx                         ; eax = (i / N) | edx = (i % N)
            cmp edx , 0
            jne end_of_loop
            mov edx , 0
            mov ebx , [scheduler_cycles]
            div ebx 
            cmp edx , 0
            jne end_of_loop
            call eliminateDrone

    end_of_loop:
        inc dword [schedule_counter]
        cmp dword [DRONES_LEFT] , 1
        jne main_loop

        call winnerDrone

        mov esp , [SPT]
        ret



eliminateDrone:
    pushad
    mov edx , [MAX_INT]
    mov [LOWEST_SCORE] , edx
    mov esi , [drone_array]
    mov ecx , 0

    check_if_active:
    mov edi , esi
    mov eax , ecx
    mov ebx , 44
    push edx
    mul ebx
    pop edx
    add edi , eax

    cmp dword [edi] , 1
    jne next_drone
    mov ebx , [edi + 36]                    ; ebx = score of drone i
    cmp ebx , dword [LOWEST_SCORE] 
    jge next_drone
    mov [LOWEST_SCORE] , ebx
    mov edx , ecx                           ; edx -> drone with the lowest score 

    next_drone: 
    mov ebx , [drone_num]
    dec ebx
    cmp ecx , ebx
    jge end_of_elimination
    inc ecx
    jmp check_if_active

    end_of_elimination:
    dec dword [DRONES_LEFT]
    mov eax , edx
    mov ebx , 44
    mul ebx
    add esi , eax
    mov dword [esi] , 0
    popad
    ret
    


winnerDrone:
    pushad
    mov esi , [drone_array]
    mov ecx , 0

    check_if_active_winner:
    mov edi , esi
    mov eax , ecx
    mov ebx , 44
    mul ebx
    add edi , eax
    cmp dword [edi] , 1
    je found_winner
    inc ecx
    jmp check_if_active_winner

    found_winner:
    inc ecx
    pushad
    push dword [edi + 36]
    push ecx
    push winner
    call printf
    add esp , 12
    popad

    popad
    ret



resume:; save state of current co-routine
     pushfd
     pushad
     mov edx, [CURRENT_COR]             ; CURR -> the struct of the current co-routine
     mov [edx+4], esp               ; save current ESP

   do_resume:                      ; load ESP for resumed co-routine
     mov esp, [ebx + 4]              ; Get to the wanted routine (in ebx)
     mov [CURRENT_COR], ebx              ; declare it as current routine
     popad                       ; restore resumed co-routine state
     popfd
     mov ebx , [CURRENT_COR]
     ret