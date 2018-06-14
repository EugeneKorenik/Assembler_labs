.model small

.code
org 100h

start:
    mov ax, @data
    mov ds, ax
    lea si, array
    mov cx, 30
    mov al,0 
    
    lea dx,hello                                                                                                                            /
    mov ah,9
    int 21h                       
    
    for: 
    call showMessage                
    call enterString
    call addZeroCharacter     
    call shift
    call isValid     
    
    cmp valid,0
    je invalid  
    
    cmp valid,2
    je getResult     
    
    call toDigit  
    loop for        
    
getResult:              
    call findSum 
    call divide

show:
    mov ah,9
    lea dx, result
    int 21h
    
    call showMinus  
    xor ax,ax
    mov al,integer        
    call showDigit
    
    mov ah,2
    mov dl,'.'
    int 21h
                     
    mov ax,float                 
    call showDigit 
    jmp exit

invalid:                     
    mov [si],0         
    mov dx, offset error
    mov ah,9
    int 21h    
    mov valid,1
    jmp for

proc showMessage 
    
    lea dx,message
    mov ah,9      
    
    push ax
    int 21h  
    pop ax
    
    xor ax,ax
    mov al,30
    sub al,cl
    call showDigit
    
    mov ah,2
    mov dx,']'
    int 21h
    mov ah,2
    mov dx,'='
    int 21h    
       
    ret  
endp showMessage

proc enterString
    mov ah, 0Ah
    lea dx, buffer
    int 21h
    mov ah, buffer+1
    cmp ah, 0
    je enterString
    ret
endp enterString  
    
proc addZeroCharacter
    lea di, buffer+2
    mov al, buffer+1
    xor ah,ah    
    add di, ax
    mov [di], '$'              
    ret
addZeroCharacter endp 

proc shift
    call replaceTabsOnSpaces
    
    lea bx, buffer+2
    
    whileNotEnd:
        cmp [bx],' ' 
        jne prepareToShift    
        inc bx
        jmp whileNotEnd
    
    prepareToShift:
        lea di, buffer+2
        sub bx, di
        sub buffer+1,bl 
     
    shiftStr:   
        push [di+bx]
        pop [di]
        cmp [di],'$'  
        je endShift
        inc di
        jne shiftStr  
     
    endShift:          
    ret
endp shift    

proc replaceTabsOnSpaces
    lea di, buffer+2
                 
    while:
         cmp [di],9
         je replaceOnSpace
         continueFind: 
         inc di
         cmp [di],'$'
         jne while
         je endReplace
    
    replaceOnSpace:
        mov [di],' '
        jmp continueFind
    
    endReplace:
    ret
endp raplaceTabsOnSpaces

proc isValid
    lea di, buffer+2  
    cmp [di],'$'
    je notValid
    
    cmp [di],'e'
    je isExit 
    
    cmp [di],'-'
    jne for0
    
    inc di
    cmp [di],'0'
    jl invalid
    cmp [di],'9'
    jg invalid
                          
    for0:
        cmp [di],'$'  
        je checkOnOverflow
        
        cmp [di],' '
        je justSpacesInEnd
        
        cmp [di],'0'   
        jl  notValid
      
        cmp [di],'9'
        jg  notValid  
    
        inc di    
        jmp for0
        
    justSpacesInEnd:
        mov bx,di
        justSpacesCycle:
            inc di
            cmp [di],'$'
            je setZeroCharacter      
            cmp [di],' '
            jne invalid
            je justSpacesCycle    
    
    setZeroCharacter:
         mov [bx],'$'
         xchg di,bx
         sub bx,di
         sub buffer+1,bl       
    
    checkOnOverflow:     
    lea di, buffer+2
    mov al, buffer+1
    xor ah,ah
    cmp [di], '-' 
    je threeDigitWithSign      
    jne threeDigit  
                           
    threeDigit:
        cmp ax,4
        je firstIsZero     
    
    continueCheck:
        cmp ax,3
        jl allRight  
        cmp [di],'1'
        jg notValid    
        cmp [di+1],'2'
        jg notValid
        cmp [di+2],'7'
        jg notValid
        jmp exitV
    
    firstIsZero:
        cmp [di],'0'
        jne notValid
        inc di
        je continueCheck
    
    threeDigitWithSign:
        inc di           
        dec ax
        jmp continueCheck    
    
    allRight:
        mov valid,1
        jmp exitV
    
    notValid:
        mov valid,0
        jmp exitV
    
    isExit:
        mov valid,2
    
    exitV:
    
    ret
isValid endp
  
proc findSum  
    cmp size,0
    je endFindSum
    
    xor ch, ch
    mov cl, size
    lea di, array
    lea si, sum
    
    sumCycle:    
        cmp [di], 0
        jl minus
        jge plus    
        continueCycle:
        inc di
    loop sumCycle 
    
    jmp endFindSum
   
    minus:
        neg [di]     
        mov ax,[di]
        xor ah,ah
        sub [si],ax 
    jmp continueCycle 
    
    plus:   
        mov ax,[di]  
        xor ah,ah 
        add [si],ax  
    jmp continueCycle       
    
    endFindSum:
                         
    ret     
findSum endp                    

makePositive:
    neg sum      
    mov positive, 0
    jmp continueDivide

proc returnNegative
    cmp positive,1
    je endOperation:   
    neg integer      
    
    endOperation: 
    ret
returnNegative endp    

proc divide   
    cmp [sum],0
    jl makePositive    
    continueDivide:    
     
    mov ax, sum       
    mov bh, 10
    mov bl, size

    div bl
    mov integer, al         
      
    mov al,ah
    mov ah,0     
    mul bh
    
    mov dx,1          ; Enter 100,10 and 1 in stack 
    push dx
    mov dx,10
    push dx
    mov dx,100
    push dx      
        
    mov cx,3         
    floatCycle: 
        div bl           ; Divide on size of array
        mov temp, ah      ; Enter left part int temp
        mov ah,0
        pop dx            ; Get 100, 10 or 1
        mul dx            ; Mul al on 100, 10 or 1
    
        add float, ax     ; Add to our float part
    
        mov al,temp       ; Get left part to al
        mov ah,0
        mul bh            ; Mul al on 10
    
    loop floatCycle   ; Repeat 
    
    cmp positive, 0   
    call returnNegative
   
    ret
divide endp           
   
proc toDigit 
    
    lea di, buffer+2
    xor dx, dx
    xor ah, ah
    mov al, 1
    mov dl, 10
    
    push cx
    mov cl, buffer+1
    xor ch, ch
    
    inStack:         
        push [di]
        inc di
        cmp [di], '$'
        jne inStack  
    
    buildDigit:
        pop bx
        cmp bl,'-'
        je makeNegative
        
        sub bl, 30h
        
        push ax
        mul bl  
        add [si], ax     
     
        pop ax
        mul dl
             
    loop buildDigit   
    
    jmp endToDigit
    
    makeNegative: 
        neg [si]            
    
    endToDigit:    
        pop cx
        inc si
        mov [si],0
        inc size
    ret
toDigit endp

proc showMinus     
    cmp positive,0
    jne endOp
    neg [integer]
    push ax
    mov ah,2
    mov dl,'-'
    int 21h
    pop ax
    
    endOp:
    ret
showMinus endp   

proc showDigit
    push cx
    push 1
    push 10
    push 100   
    
    xor cx,cx
    mov cl,3
    
    showDigitCycle:
        pop bx
        div bl
    
        mov dl,al
        add dl,30h
        mov al,ah
        mov ah,2        
      
        push ax
        int 21h
        pop ax 
        xor ah,ah  
    loop showDigitCycle
    pop cx           
    ret   
showDigit endp
      
exit:              
    mov ax,4c00h
    int 21h

.data                      
hello db "This program find arithmetical mean and work with digits [-127,127]",10,13,"Press e to get answer",10,13,"You can enter 30 digits$"
error db 10,13,"Error, enter digit in [-127, 127]$"     
message db 10,13,"arr[$"    
result db 10,13,"Result: $"

buffer db 5, 6 dup('$')
array db 30 dup(0)   

sum dw dup(0)
size db dup(0)
integer db dup(0)
float dw dup(0)
temp db dup(0)
positive db dup(1) 
valid db dup(1)

end start

