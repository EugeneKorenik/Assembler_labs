.model small 

.code        
org 100h

start:      
    mov ax, @data
    mov ds, ax    
    
;    mov di, 82h
;    lea si, line
;    mov cx, 35    
;    repe movsb                      
      
    call get_param   
    call find_word_length         
    
    lea di, source_file_name
    call is_txt_files       
    lea di, destination_file_name
    call is_txt_files                         
       
    mov ah, 0
    call open_file  ; open source file        
    mov ah, 1
    call open_file  ; opem destination file            
         
    while:         
       mov ah, 9
       lea dx, read_next_string
       int 21h                         
       call read        
       call analyse_buffer                   
    jmp while            

;=========================================IS TXT FILES============================================;

proc is_txt_files    
    lea si, txt_string    
    
    mov cx, 255  
    mov al, '$'
    repne scasb
                      
    std
    mov cx, 255 
    mov al, '.'       
    repne scasb     
    cld
        
    cmp cx, 0       
    je is_not_txt                 
    add di, 2
    
    mov cx, 3
    repe cmpsb        
    je end_of_check  
    
    is_not_txt:    
        lea dx, this_is_not_txt_message
        mov ah, 9 
        int 21h
        jmp exit
    
    end_of_check:        
    
    ret
is_txt_files endp     
             
;=================================GET COMAND LINE PARAMETRE=======================================;

proc get_param
    mov di, 82h
    mov cx, 3
    mov al, ' '
    
    for:        
        push cx
        mov cx, 256
        repe scasb
        dec di  
        pop cx
        
        cmp cx, 3
        je source
        
        cmp cx, 2
        je destination
        
        cmp cx, 1
        je word 
              
    scan_parametr:     
        mov ax, [di]
        mov [si], al
        inc di
        inc si
        
        cmp [di], 0dh
        je check_on_valid   
        
        cmp [di], ' '
        jne scan_parametr
        
        cmp cx, 1
        je end_param       
        mov [si], 0
        inc di
                       
        loop for  
    
    check_on_valid: 
        cmp cx, 1
        je end_param 
        lea dx, error_with_parametr 
        mov ah, 9
        int 21h 
        jmp exit 
           
    source:
        lea si, source_file_name
        jmp scan_parametr
    
    destination:
        lea si, destination_file_name
        jmp scan_parametr
    
    word:
        lea si, word_must_search
        jmp scan_parametr
    
    end_param:   
                         
    ret
get_param endp
 
;================================FIND LENGHT==============================================;

proc find_word_length
    lea di, word_must_search
    xor cx,cx
    dec cx
    
    mov al, '$'
    repne scasb
    
    neg cx        
    mov word_must_search_length, cl
    sub word_must_search_length, 1  
    
    ret
find_word_length endp 
        
;================================WRITE_LINE================================================;

proc write_line   
    call set_file_pointer   
    jmp writing_cycle
    
    increase_bigger:
        inc file_pointer_bigger     
        jmp continue writing_cycle
               
    writing_cycle:  
         
        mov ah, 9
        lea dx, write_line_message
        int 21h 
   
        call read 
        call find_buffer_write_size 
                              
        mov ah, 40h
        mov bx, destination_file_id
        lea dx, buffer   
        int 21h    
        
        add cx, 2
        add file_pointer_lower, cx  
        jc increase_bigger
        
        continue_writing_cycle:                            
        cmp string_end_flag, 0
        je writing_cycle              
     
        mov ah, 40h
        mov bx, destination_file_id 
        mov cx, 2
        lea dx, new_line         
        int 21h                                    
        
        call set_file_pointer
                                             
    ret          
write_line endp

;===================================SET FILE POINTER======================================;

proc set_file_pointer       
    mov ah, 42h
    mov al, 0
    mov bx, source_file_id      
                                 
    mov cx, file_pointer_bigger                          
    mov dx, file_pointer_lower    
    
    int 21h       
    ret
set_file_pointer endp

;===============================FIND BUFFER WRITE SIZE=====================================;

proc find_buffer_write_size
    mov string_end_flag, 0 
    lea di, buffer   
    xor cx, cx
    dec cx   
                                                                 
    for3:                          
        cmp [di], 0Dh
            je exit_with_string_end   
        cmp [di], '$'
            je exit_from_find         
        inc di   
    loop for3
    
    exit_with_string_end:
        mov string_end_flag, 1                                    
                                                 
    exit_from_find: 
        inc cx
        neg cx                                 
        ret          
find_buffer_write_size endp

;=================================READ=====================================================;
                                                          
proc read
    mov ah, 3fh
    mov bx, source_file_id     
    xor cx, cx
    mov cl, buffer_size
    lea dx, buffer     
    int 21h           
    
    cmp ax, 0
        je exit       
    
    lea di, buffer  
    add di, ax      
    mov [di], '$'
    
    ret
read endp     

;===============================ANALYSE BUFFER=============================================;

proc analyse_buffer
    mov al, ' '
    lea di, buffer 
    jmp while1
    
    set_adress:  
        dec si   
        inc di
        xor cx, cx
        mov cl, letters_left_compare    
    
        mov continue_compare, 0
        jmp start_compare        
        
    while1:    
        
        cmp continue_compare, 1
        je set_adress   
                     
        lea si, word_must_search   
        xor cx, cx
        mov cl, word_must_search_length   
        
        start_compare:                          
        repe cmpsb  
        
        dec di
        cmp cl, 0                
        je check_next_character  
        
        continue:
            cmp [di], 0Dh
                je not_found_at_string
            cmp [di], '$'
                je finded_part_of_word
            cmp [di], ' '
                je without_space
            cmp [di], 09h
                je without_space   
            inc di
            jmp continue        
    
    without_space:      
            inc di
            cmp [di], ' '
                je  without_space
            cmp [di], 09h
                je without_space
            cmp [di], 0Dh
                je not_found_at_string
            cmp [di], '$'       
                je exit_from_function
        jmp while1
                        
    check_next_character:     
        cmp [di], ' '    
        je write
        cmp [di], 0Dh   
        je write
        cmp [di], 09h
        je write      
        cmp [di], '$'
        je write
        jmp continue
        
    write:
        call write_line     
        jmp exit_from_function  
    
    finded_part_of_word:     
        cmp cl, word_must_search_length - 1
        je exit_from_function              
        mov continue_compare, 1    
        mov letters_left_compare, cl        
        jmp exit_from_function
    
    inc_bigger_part:
        inc file_pointer_bigger
        jmp continue_analyse 
    
    not_found_at_string:       
        add di, 2
        lea si, buffer
        sub di, si                   
        
        add file_pointer_lower, di
        jc inc_bigger_part
        
        continue_analyse:
        call set_file_pointer            ; set pointer at last found string to read
        jmp exit_from_function
                       
    exit_from_function: 
        
    ret
analyse_buffer endp          
                              
                      
;===============================OPEN FILE =================================================;
          
proc open_file
    cmp ah, 0
    je open_source_file
    
    open_destination_file:  
    mov ah, 3ch                    ; creation
    mov cx, 0
    lea dx, destination_file_name
    int 21h        
    
    mov ah, 3dh                   ; open to write
    mov al, 1
    lea dx, destination_file_name
    int 21h
    mov destination_file_id, ax        
    jmp end_of_open
    
    open_source_file:         
    mov ah, 3dh
    mov al, 0
    lea dx, source_file_name
    int 21h            
    jc error 
    
    mov source_file_id, ax  
    jmp end_of_open   
    
    error:
    lea dx, not_found_file_string
    mov ah, 9
    int 21h
    jmp exit
    
    end_of_open:
    ret  
open_file endp

;=====================EXIT============================================================;
    
exit:      
    mov ah, 3eh 
    mov bx, destination_file_id
    int 21h
             
    mov ah, 3eh         
    mov bx, source_file_id
    int 21h
    
    mov ah, 4ch
    int 21h

.data                                      
source_file_name db 256 dup('$')    
destination_file_name db 256 dup('$')     
new_line db 13,10  

word_must_search db 51 dup('$')
word_must_search_length db 0   
                                     
not_found_file_string db "Source file not found$"
error_with_parametr db "Error with coman line parametrs$"        
this_is_not_txt_message db "Files must have .txt extension$"   
read_next_string db "Read next string", 10, 13, "$"
write_line_message db "Write line", 10, 13, "$"                
txt_string db "txt"

source_file_id dw dup(0)        
destination_file_id dw dup(0)

file_pointer_bigger dw 0
file_pointer_lower dw 0
      
continue_compare db 0
letters_left_compare db 0

string_end_flag db 0     
not_found_at_buffer_flag db 0

buffer db 51 dup('$')  
buffer_size db 50           

line db "Source.txt Destination.txt second", 0dh

end start




