.MODEL SMALL

.CODE

DRAW_BLOCKS proc
    push bx
    
    mov bx, 162
    mov cl, 5
    mov dl, ' '
    mov dh, 0
    
    CLEAR_ONE:
        push cx
        mov cl, 76
        CLEAR_TWO:
            mov es:[bx], dx
            add bx, 2
        loop CLEAR_TWO
        add bx, 8
        pop cx
    loop CLEAR_ONE
    
    lea bx, BLOCKS
    mov dl, ' '
    mov dh, 01010000b
    mov cl, 5
    
    DRAW_ALL_BLOCKS:
        push cx
        test cl, 1
        JZ EIGHT
        mov cl, 9
        
        DRAW_BLOCK_LINE:
            mov al, [bx + 3]
            cmp al, 1
            jne SKIP_ONE
            
            push bx
            push cx 
            
            mov al, [bx + 2]
            mov cl, 160
            mul cl
            add ax, [bx]
    
            mov bx, ax
            xor cx, cx
            mov cl, 7
            
            DRAW_ONE_BLOCK:
                mov es:[bx], dx
                add bx, 2
            loop DRAW_ONE_BLOCK
            
            pop cx
            pop bx
            
            SKIP_ONE:
            add bx, 4
        
        loop DRAW_BLOCK_LINE
        pop cx
    loop DRAW_ALL_BLOCKS
    pop bx
    ret

EIGHT:
    mov cl, 8
    jmp DRAW_BLOCK_LINE    

DRAW_BLOCKS endp

CREATE_BLOCKS proc
    push bx
    lea bx, BLOCKS
    xor ax, ax
    xor cx, cx
    xor dx, dx
    mov cl, 5
    mov ax, 168
    
    BUILD_LONG_CYCLE: 
        push cx    
        test cl, 1
        jz SET_EIGHT
        mov cl, 9
       
        BUILD_LINE_CYCLE:
            push ax    
            push cx
            
            mov cl, 160
            div cl
        
            mov byte ptr [bx], ah
            mov byte ptr [bx + 1], 0
            mov byte ptr [bx + 2], al
            mov byte ptr [bx + 3], 1
            
            pop cx
            pop ax
            
            add bx, 4
            add ax, 16
       loop BUILD_LINE_CYCLE
       pop cx
       add ax, 24
   loop BUILD_LONG_CYCLE
   
   pop bx
   ret
   
   SET_EIGHT:
   mov cl, 8
   jmp BUILD_LINE_CYCLE
   
CREATE_BLOCKS endp

PREPARE_RTC proc
    in al, 0A1h
    and al, 11111110b
    out 0A1h, al
    
    in al, 0Bh
    or al, 0100000b
    out 0Bh, al
    
    ret
PREPARE_RTC endp

BALL_PHYSICS proc
    mov dl, BALL_X
    cmp dl, EXTREME_LEFT_FOR_BALL
    je REVERSE_X
    cmp dl, EXTREME_RIGHT_FOR_BALL
    je REVERSE_X

WORK_WITH_X:
    add dl, STEP_X
    mov BALL_X, dl
    
    mov dl, BALL_Y
    cmp dl, EXTREME_TOP_FOR_BALL
    je REVERSE_Y
    cmp dl, EXTREME_BOTTOM_FOR_BALL
    je IS_GAME_OVER  
    
    cmp dl, LINE_OF_BLOCKS
    jle WORK_WITH_BLOCK
    
    cmp dl, PLAT_Y_MIN
    jne WORK_WITH_Y
    
    mov al, PLAT_X
    dec al
    cmp BALL_X, al
    jb WORK_WITH_Y
    
    add al, PLAT_WIDTH
    add al, PLAT_WIDTH
    add al, 2
    
    cmp BALL_X, al
    jbe REVERSE_Y
   
WORK_WITH_Y:
    add dl, STEP_Y
    mov BALL_Y, dl
    ret 
    
REVERSE_X:
    mov al, STEP_X
    mov ah, -1
    imul ah
    mov STEP_X, al
    jmp WORK_WITH_X

REVERSE_Y:
    mov al, STEP_Y
    mov ah, -1
    imul ah
    mov STEP_Y, al
    jmp WORK_WITH_Y    

WORK_WITH_BLOCK:
    call FIND_BLOCK
    cmp ah, -1
    jne REVERSE_Y
    cmp SCORE, 43
    je WIN
    jmp WORK_WITH_Y

IS_GAME_OVER:
    mov al, COLOR
    cmp al, GREEN_COLOR
    jne GAME_OVER
    mov al, RED_COLOR
    mov COLOR, al
    jmp REVERSE_Y
BALL_PHYSICS endp

WIN:
   call INSTAL_OLD_HANDLER
   mov LOSE_FLAG, -1
   jmp MAIN

SET_WIN:
   lea di, WIN_MESSAGE
   jmp TO_RAND
   
GAME_OVER:
    call INSTAL_OLD_HANDLER
    mov LOSE_FLAG, 1
   
MAIN:
    call PREPARE_RTC
    mov ax, @DATA
    mov ds, ax
    
    mov ax, 0b800h
    mov es, ax
    
    mov ax, 0003
    int 10h
    
    call HIDE_CURS
    call CLEAR_SCREEN
    call DRAW_FIELD 
    
    lea di, HELLO_MESSAGE
    cmp LOSE_FLAG, -1
    je SET_WIN
    
    cmp LOSE_FLAG, 0
    je TO_RAND
    lea di, LOSE_MESSAGE
    
    TO_RAND:
    call SHOW_MESSAGE
    call GET_RANDOM
    
    mov STEP_X, 2
    mov STEP_Y, 1
    mov BALL_X, al
    mov PLAT_X, al
    mov BALL_Y, 17
    mov SCORE, 0
    
    call CLEAR_SCREEN
    call DRAW_FIELD 
    call INSTAL_NEW_HANDLER
    call DRAW_PLATFORM 
    call CREATE_BLOCKS
    call DRAW_BLOCKS
    
    GAME_CYCLE:
        cmp REDRAW_COUNTER, 1
        jge REDRAW
        RETURN:
        cmp GAME_EXIT_FLAG, 0
    je GAME_CYCLE

EXIT:
    call INSTAL_OLD_HANDLER  
    call CLEAR_SCREEN
    call SHOW_CURS
    mov ax, 4c00h
    int 21h

REDRAW:
    call BALL_PHYSICS
    call DRAW_BALL
    mov REDRAW_COUNTER, 0
jmp RETURN

SHOW_MESSAGE proc
    mov bx, 1460
    mov dh, 0000100b
   
    SHOW_MESSAGE_CYCLE:
        mov dl, [di]
        mov es:[bx], dx
        
        inc di
        add bx, 2
        
        cmp byte ptr [di], '$'
    jne SHOW_MESSAGE_CYCLE
    ret
SHOW_MESSAGE endp

GET_RANDOM proc
    push cx
    push bx
    push dx
    
    xor ax, ax
    mov al, 0b6h
    out 43h, al
    
    mov al, 120
    out 42h, al
    mov al, 0
    out 42h, al
    
    in al, 61h
    or al, 1
    out 61h, al

    mov ah, 1
    int 21h

    in al, 61h
    and al, 11111110b
    out 61h, al
    
    mov al, 86h
    out 43h, al
    
    xor dx, dx
    in al, 42h
    mov ch, al
    mov cl, 4
    div cl
    sub ch, ah
    mov al, ch
    add al, 2
    
EXIT_RANDOM:
    pop dx
    pop bx
    pop cx
    ret
 
GET_RANDOM endp

FIND_BLOCK proc
    push cx
    push dx
    push bx
    
    xor cx, cx
    mov al, 1
    mov ah, -1
    lea bx, BLOCKS
    mov cl, BLOCKS_QUANTITY
    mov dh, BALL_Y
    
    FIND_BLOCK_FROM_SIDE:
        mov dl, [bx + 2]
        cmp dl, dh
        jne SKIP_ITER_FROM_SIDE
        
        cmp STEP_X, 2
        je IF_RIGHT
        
        IF_LEFT:
        mov dl, [bx]
        add dl, 14
        add dl, 2
        cmp dl, BALL_X
        jne SKIP_ITER_FROM_SIDE
        
        mov al, -1
        jmp FOUND
        
        IF_RIGHT:
        mov dl, [bx]
        sub dl, 2
        cmp dl, BALL_X
        jne SKIP_ITER_FROM_SIDE
        mov al, -1
        jmp FOUND
        
        SKIP_ITER_FROM_SIDE:
        add bx, 4
    loop FIND_BLOCK_FROM_SIDE
    
    lea bx, BLOCKS
    mov cl, BLOCKS_QUANTITY 
    dec dh

    FIND_BLOCK_FIRST:
       mov dl, [bx + 2]
       cmp dl, dh
       jne SKIP_ITER
       
       mov dl, [bx]
       add dl, 2
       cmp dl, BALL_X
       ja SKIP_ITER
       
       NEXT_STEP:
       add dl, 16
       cmp dl, BALL_X
       ja FOUND
        
    SKIP_ITER:
       add bx, 4
    loop FIND_BLOCK_FIRST
    
    EXIT_FROM_FINDING:
    
    pop bx
    pop dx
    pop cx
    ret
    
    FOUND:
    cmp byte ptr [bx + 3], 1
    jne EXIT_FROM_FINDING
    
    cmp al, -1
    je REVERSE_ON_X
    
    DEL:
    mov byte ptr [bx + 3], 0
    mov ah, 1
    call DELETE_BLOCK
    jmp EXIT_FROM_FINDING
    
    REVERSE_ON_X:
    mov al, STEP_X
    mov ah, -1
    imul ah
    mov STEP_X, al
    jmp DEL
    
FIND_BLOCK endp

SHOW_SCORE proc
    push bx
    push ax
    push dx
    
    xor dx, dx
    mov dh, 01000010b
    
    mov bx, 140
    lea di, SCORE_STR
    SHOW_STR:
       mov dl, [di]
       mov es:[bx], dx
       add bx, 2
       inc di
       
       cmp [di], '$'
       jne SHOW_STR
    
    xor ax, ax
    mov al, SCORE
    mov ch, 10
    div ch
    
    mov dl, al
    add dl, 30h
    mov es:[bx], dx
    add bx, 2
    
    mov dl, ah
    add dl, 30h
    mov es:[bx], dx
    
    pop dx
    pop ax
    pop bx
    ret
SHOW_SCORE endp

DELETE_BLOCK proc
    push ax
    push bx
    push cx
    push dx

    mov ah, 160
    mov al, [bx + 2]
    mul ah
    add ax, [bx]
    mov bx, ax
    mov cl, 8
    mov dl, ' '
    mov dh, 00000111b
    
    push dx
    xor dx, dx
    xor ax, ax
    mov cl, 18
    lea di, BLOCKS
    sub di, bx
    mov ax, di
    mov ah, 0
    div cl
    cmp ah, 17
    je SET_COLOR
    pop dx
    mov cx, 8
    
    DELETE_CYCLE:
        mov es:[bx], dx
        add bx, 2
    loop DELETE_CYCLE
    
    inc SCORE
    call SHOW_SCORE
    
    pop dx
    pop cx
    pop bx
    pop ax
    ret
    
    SET_COLOR:
       mov al, GREEN_COLOR
       mov COLOR, al
       mov cx, 8
       pop dx
    jmp DELETE_CYCLE
    
    call DRAW_BLOCKS
    
DELETE_BLOCK endp

CLEAR_SCREEN proc
    mov dl, ' '
    mov dh, 00000111b
    xor bx, bx
    
    xor cx, cx
    mov cl, 25
    
    CLEAR_CYCLE:
        push cx
        mov cl, 80
       
        LINE_CYCLE:
            mov es:[bx], dx
            add bx, 2
        loop LINE_CYCLE
        
        pop cx
    loop CLEAR_CYCLE

    ret
CLEAR_SCREEN endp    

SHOW_CURS proc
    mov ah, 1
    mov cx, 0607h
    int 10h
    ret
SHOW_CURS endp

HIDE_CURS proc 
    mov ah, 1
    mov cx, 2020h
    int 10h
    ret
HIDE_CURS endp

INSTAL_NEW_HANDLER proc
    push ds
    push es
    
    mov ax, 3509h
    int 21h
    mov word ptr OLD_HANDLER_KEY, bx
    mov word ptr OLD_HANDLER_KEY + 2, es    
    
    pop es
    pop ds
    push ds
    push es
    
    mov ax, 3508h
    int 21h
    mov word ptr OLD_HANDLER_RTC, bx
    mov word ptr OLD_HANDLER_RTC + 2, es
    
    CLI
    mov ax, cs
    mov ds, ax
    lea dx, GAME_KEYBOARD_HANDLER
    mov ax, 2509h
    int 21h
    
    mov ax, cs
    mov ds, ax
    lea dx, RTC_HANDLER
    mov ax, 2508h
    int 21h
    STI
    
    pop es
    pop ds
    ret
INSTAL_NEW_HANDLER endp

INSTAL_OLD_HANDLER proc
    CLI
    push ds
    push es
    mov ax, 2509h
    mov dx, word ptr OLD_HANDLER_KEY
    mov ds, word ptr OLD_HANDLER_KEY + 2
    int 21h
    pop es
    pop ds
    
    push ds
    push es
    mov ax, 2508h 
    mov dx, word ptr OLD_HANDLER_RTC
    mov ds, word ptr OLD_HANDLER_RTC + 2
    int 21h
    pop es
    pop ds
    STI
    
    ret
INSTAL_OLD_HANDLER endp

DRAW_BALL proc
    mov dh, 00000111b
    mov dl, ' '  
    mov es:[bx], dx
    
    xor ax, ax
    mov al, BALL_Y
    mov ah, 160
    mul ah
    mov bx, ax
    
    xor ax, ax
    mov al, BALL_X
    add bx, ax
    
    mov dh, 00000111b
    add dh, COLOR
    mov dl, ' '
    mov es:[bx], dx
    
    ret 
DRAW_BALL endp

RTC_HANDLER proc far
    inc REDRAW_COUNTER
    push ax
    mov al, 20h
    out 20h, al
    pop ax
    iret
RTC_HANDLER endp

GAME_KEYBOARD_HANDLER proc far
    push cx
    push ax
    
    in al, 60h
    
    cmp al, 1
    je SET_EXIT_FLAG
    
    cmp al, 1Eh
    je TO_LEFT
    
    cmp al,20h
    je TO_RIGHT
    
INTERRUPTION_END:
    call DRAW_PLATFORM
    mov al, 20h
    out 20h, al 
    pop ax
    pop cx
    iret  

SET_EXIT_FLAG:
    mov GAME_EXIT_FLAG, 1
    jmp INTERRUPTION_END
    
TO_LEFT:
    mov al, PLAT_X
    cmp al, EXTREME_LEFT
    je INTERRUPTION_END
    sub PLAT_X, 4
    jmp INTERRUPTION_END

TO_RIGHT:
    mov al, PLAT_X
    cmp al, EXTREME_RIGHT
    je INTERRUPTION_END
    add PLAT_X, 4
    jmp INTERRUPTION_END
  
GAME_KEYBOARD_HANDLER endp
  
DRAW_FIELD proc
    mov ax, 0b800h
    mov es, ax
    mov dl, ' '
    mov dh, 00101000b
    
    xor bx, bx
    xor cx, cx
    mov cl, 2
    
    DRAW_TOP_AND_BOTTOM:
        push cx
        mov cl, 80
        
        DRAW_LINE_CYCLE:
            mov es:[bx], dx
            add bx, 2
            loop DRAW_LINE_CYCLE
        
        pop cx
        mov bx, 3840
    loop DRAW_TOP_AND_BOTTOM
    
    mov cl, 24
    mov bx, 160
    DRAW_LEFT_AND_RIGHT:
        mov es:[bx], dx
        add bx, 158
        mov es:[bx], dx
        add bx, 2
    loop DRAW_LEFT_AND_RIGHT
    
    mov dh, 01000010b
    lea di, CONTROL
    mov bx, 6
    mov cl, 38
    SHOW_CONTROL:
        mov dl, [di]
        mov es:[bx], dx
        inc di
        add bx, 2
    loop SHOW_CONTROL
  
    ret
DRAW_FIELD endp

DRAW_PLATFORM proc
    push ax
    push cx
    push bx
    push dx
    
    mov ax, 0b800h
    mov es, ax
    mov dl, ' '
    
    xor ax, ax
    mov al, PLAT_Y
    mov bl, 160
    mul bl
    
    mov bx, ax
    add bx, 2
    mov cl, 78
    
    mov dh, 00000111b
    CLEAR_PLATFORM_LINE:
        mov es:[bx], dx
        add bx, 2
    loop CLEAR_PLATFORM_LINE
    
    mov dh, 01110111b
    mov bx, ax
    add bl, PLAT_X
    
    mov cl, PLAT_WIDTH
    
    DRAW_PLATFORM_CYCLE:
        mov es:[bx], dx
        add bx, 2
        loop DRAW_PLATFORM_CYCLE
    
    pop dx  
    pop bx
    pop cx
    pop ax
    ret
DRAW_PLATFORM endp
    
.DATA

BLOCK STRUC
   POS_X dw ?
   POS_Y db ?
   ON_SCREEN db ?
BLOCK ends

BLOCKS_QUANTITY db 43
BLOCKS dd 43 dup(?)
BLOCK_WIDTH db 14
  
OLD_HANDLER_KEY DD ?
OLD_HANDLER_RTC DD ?

PLAT_X db ?
PLAT_Y db 21
PLAT_WIDTH db 14

BALL_X db ?
BALL_Y db 19

STEP_Y db 1
STEP_X db 2

MOVE_LEFT db 0
MOVE_RIGHT db 0

LINE_OF_BLOCKS db 6
EXTREME_RIGHT db 130
EXTREME_LEFT db 2

EXTREME_LEFT_FOR_BALL db 2
EXTREME_RIGHT_FOR_BALL db 156
EXTREME_TOP_FOR_BALL db 1
EXTREME_BOTTOM_FOR_BALL db 23
PLAT_Y_MIN db 20
LOSE_FLAG db 0

GAME_EXIT_FLAG db 0
REDRAW_COUNTER db 0 
SCORE db 0
CAN_JUMP db 0


COLOR db 1000000b
RED_COLOR db 1000000b
GREEN_COLOR db 0100000b

CONTROL db "A AND D ARRAYS TO CONTROL ESC to exit $"
LOSE_MESSAGE db "You lose, any key to try again$"
HELLO_MESSAGE db "Any key to start$"
WIN_MESSAGE db "You wind, any key, to try again$"
SCORE_STR db "SCORE $"

END MAIN