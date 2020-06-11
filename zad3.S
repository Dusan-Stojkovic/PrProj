#autor: Dušan Stojković INDEX ra140-2019
.section .data
    prompt1: .ascii "Unesite logicki izraz: \0"
    len1 = .-prompt1
    prompt2: .ascii "Rezultat: \0"
    len2 = .-prompt2
    err1: .ascii "Greska kod operanda.\n\0"
    len_err1 = .-err1
    err2: .ascii "Greska kod operacije.\n\0"
    len_err2 = .-err2
    newline: .ascii "\n\0"
    leN = 100
    izraz:       .fill leN, 1, 0       #unos korisnika
    rezultat:    .fill leN, 1, 0         #ispis rezultata
.section .text
.globl main
#int unos(char* string, int strlen);        vraca duzinu stringa u %eax
.macro unos u_string, duz_max=$0
    movl $3, %eax
    movl $0, %ebx
    leal \u_string, %ecx
    movl \duz_max, %edx
    int $0x80
.endm

ispis:
    pushl %ebp
    movl %esp, %ebp
    movl $4, %eax
    movl $1, %ebx
    movl 12(%ebp), %ecx
    movl 8(%ebp), %edx
    int $0x80
    jmp kraj_func

main:
    pushl $prompt1
    pushl $len1
    call ispis                  
 
    unos izraz, $leN       

    pushl $izraz
    pushl %eax   
    movl $0, %edi
    call Obradi

    cmpl $1, %ebx
        je err

    jmp interni_oktalni

    kraj:
    pushl $prompt2
    pushl $len2
    call ispis  

    pushl $rezultat
    pushl $leN
    call ispis  

    movl $0, %ebx
    err:
    movl $1, %eax
    int $0x80

kraj_func:                      #kraj svake funkcije je uvek isti
    movl %ebp, %esp
    popl %ebp
    ret

Obradi:                             #int Obradi(char* izraz, int len);
    pushl %ebp
    movl %esp, %ebp
    decl 8(%ebp)
    movl 12(%ebp), %esi
    movl $0, %eax
    #proveri operand
    pushl $1
    call Parser
    popl %edx
    cmpl $1, %ebx
        je kraj_func
    incl %edi
    pushl %eax
    #proveri operaciju
    pushl $2
    call Parser
    popl %eax
    cmpl $1, %ebx
        je kraj_func
    incl %edi
    pushl %edx
    #operand 2
    pushl $1
    call Parser
    popl %edx
    cmpl $1, %ebx
        je kraj_func
    incl %edi
    jmp izracunaj
    obrada:
        cmpl %edi, 8(%ebp)
            je kraj_func
        cmpl $0, (%esi, %edi, 1)
            je kraj_func
        #proveri operaciju
        pushl %eax
        pushl $2
        call Parser
        cmpl $1, %ebx
            je kraj_func
        popl %eax
        pushl %edx
        incl %edi
        #operand
        pushl $1
        call Parser
        popl %edx
        cmpl $1, %ebx
            je kraj_func
        incl %edi
    izracunaj:
        popl %edx       #operacija
        popl %ecx       #prvi operand
        cmpb $60, %dl
            je rotacija_levo
        cmpb $62, %dl
            je rotacija_desno
        cmpb $94, %dl
            je xili
        rotacija_levo:
            rolb $1, %cl
            decb %al
            cmpb $0, %al
                je rez
            jmp rotacija_levo
        rotacija_desno:
            rorb $1, %cl
            decb %al
            cmpb $0, %al
                je rez
            jmp rotacija_desno
        xili:
            xorb %al, %cl
    rez:
    movb %cl, %al
    jmp obrada
Parser:                            #Sve veze sa vezom
    pushl %ebp
    movl %esp, %ebp
    movl 8(%ebp), %eax
    #pronadji rezim
    cmpl $1, %eax
        je operand
    cmpl $2, %eax
        je operacija
    operand:
        #transformisati u primarni koji prima dve varijante kao funkcija
        movl %esp, %ebp
        popl %ebp
        cmpb $48, (%esi, %edi, 1)
            je preskoci
        cmpb $48, (%esi, %edi, 1)
            jl greska_operand
        cmpb $58, (%esi, %edi, 1)
            jl dec_interni
        preskoci:
        incl %edi
        cmpb $47, (%esi, %edi, 1)
            jl greska_operand
        cmpb $58, (%esi, %edi, 1)
            jl dec_interni
        cmpb $88, (%esi, %edi, 1)
            je hex_interni       
        cmpb $120, (%esi, %edi, 1)
            je hex_interni
        cmpb $47, (%esi, %edi, 1)
            jl greska_operand
        cmpb $58, (%esi, %edi, 1)
            jl cifra_09
        greska_operand:
            pushl $err1
            pushl $len_err1
            call ispis
            movl $1, %ebx
            jmp kraj_func
        hex_interni:
            movl $0, %edx
            movl $0, %eax           #privremena promenjiva cifri
            switch:                 #rasclanjuje cifre i noise
                incl %edi
                cmpl 8(%ebp), %edi
                    je hex_gotov
                cmpb $0, (%esi, %edi, 1)
                    je hex_gotov
                cmpb $32, (%esi, %edi, 1)
                    je hex_gotov
                shll $4, %eax
                cmpb $47, (%esi, %edi, 1)
                    jl greska_operand
                cmpb $58, (%esi, %edi, 1)
                    jl cifra_09            
                cmpb $64, (%esi, %edi, 1)
                    jl greska_operand
                cmpb $71, (%esi, %edi, 1)
                    jl cifra_AF
                cmpb $96, (%esi, %edi, 1)
                    jl greska_operand
                cmpb $103, (%esi, %edi, 1)
                    jl cifra_af
            cifra_09:
                addb (%esi, %edi, 1), %al
                subb $48, %al
                jmp konstruktor
            cifra_AF:
                addb (%esi, %edi, 1), %al
                subb $55, %al
                jmp konstruktor
            cifra_af:
                addb (%esi, %edi, 1), %al
                subb $87, %al
            konstruktor:            #konstruktor pravi mesta za jos cifra u %eax
                addb $1, %dl
                cmpb $8, %dl
                    je greska_operand
                jmp switch
            hex_gotov:
                ret
        dec_interni:
            decl %edi
            movl $0, %eax
            movl $10, %ecx
            movl $0, %ebx
            dec_cifra:                  #svaki karakter se pojedinacno salje na stack
                incl %edi
                cmpl 8(%ebp), %edi
                    je kraj_dec
                cmpb $32, (%esi, %edi, 1)
                    je kraj_dec
                cmpb $127, %al
                    jge greska_operand
                cmpb $47, (%esi, %edi, 1)
                    jl greska_operand
                cmpb $58, (%esi, %edi, 1)
                    jl cifra 
                jmp greska_operand
                cifra:  
                    movb (%esi, %edi, 1), %bl
                    andb %bl, %bl
                        jz kraj_dec
                    subb $48, %bl
                    mull %ecx
                    addl %ebx, %eax
                jmp dec_cifra
        kraj_dec:
            cmpl $255, %eax
                ja greska_operand
            movl $0, %ebx
            ret
        interni_oktalni:
            leal rezultat, %esi
            movl $0, %edi
            movl $8, %ecx
            oktalna_cifra:                  #svaki karakter se pojedinacno salje na stack
                xorl %edx, %edx
                div %ecx
                addb $48, %dl
                pushl %edx
                incl %edi
                andl %eax, %eax
            jnz oktalna_cifra
            movl $0, %ecx
        popuni:                     #ovde se stack prazni u obrnutom redosledu
            cmpl %ecx, %edi
                je kraj
            popl %edx
            movb %dl, (%esi, %ecx, 1)
            incl %ecx
                jmp popuni
    operacija:
        movl %esp, %ebp
        popl %ebp
        movl $0, %edx
        cmpb $60, (%esi, %edi, 1)
            je pronadjena
        cmpb $62, (%esi, %edi, 1)   
            je pronadjena
        cmpb $94, (%esi, %edi, 1)
            je pronadjena
        greska_operacija:
            pushl $err2
            pushl $len_err2
            call ispis
            movl $1, %ebx
            jmp kraj_func
        pronadjena:
            movb (%esi, %edi, 1), %dl
            incl %edi
            ret