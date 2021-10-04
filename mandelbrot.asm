; Domokos Bernat Illes

; Mandelbrot Set

; Meg gyorsitas szukseges SSE -vel vagy AVX -el.

; Compile Windows:
; nasm -f win32 mandelbrot.asm
; nlink mandelbrot.obj -lio -lmio -lgfx -o mandelbrot.exe

; Compile Linux:
; wine nasm -f win32 mandelbrot.asm
; wine nlink mandelbrot.obj -lio -lmio -lgfx -o mandelbrot.exe

%include 'io.inc'
%include 'mio.inc'
%include 'gfx.inc'

%define WIDTH   1024
%define HEIGHT  768

section .data
    
    ; For double floating points
    ketto_d             dq  2.0, 2.0
    egyegeszot_d        dq  1.5, 1.5
    egy_d               dq  1.0, 1.0

    ratio_d             dq  1.0, 1.0

    mozgat_negativ_d    dq  -0.025, -0.025
    mozgat_pozitiv_d    dq  0.025, 0.025

    delta_move_in_d     dq  0.93, 0.93
    delta_move_out_d    dq  0.93, 0.93

    offsetx_d           dq  0.0, 0.0
    offsety_d           dq  0.0, 0.0
    changeX_d           dq  0.0, 0.0
    changeY_d           dq  0.0, 0.0

    zoom_d                  dq  1.0, 1.0
    change_delta_zoom_in_d  dq  1.1, 1.1
    change_delta_zoom_out_d dq  0.9, 0.9
    change_zoom_d           dq  1.0, 1.0
    mozgat_zoom_negativ_d   dq  -0.05, -0.05
    mozgat_zoom_pozitiv_d   dq  0.05, 0.05

    hatar_d   dq  4.0, 4.0
    width_d   dq  0.0, 0.0
    height_d  dq  0.0, 0.0


;................................................................
    ; For single floating points

    ketto               dd  2.0, 2.0, 2.0, 2.0
    egyegeszot          dd  1.5, 1.5, 1.5, 1.5
    egy                 dd  1.0, 1.0, 1.0, 1.0

    mozgat_negativ      dd  -0.025, -0.025,-0.025, -0.025
    mozgat_pozitiv      dd  0.025, 0.025,0.025, 0.025

    delta_move_in       dd  0.93, 0.93, 0.93, 0.93
    delta_move_out      dd  0.93, 0.93, 0.93, 0.93

    offsetx             dd  0.0, 0.0, 0.0, 0.0
    offsety             dd  0.0, 0.0, 0.0, 0.0
    changeX             dd  0.0, 0.0, 0.0, 0.0
    changeY             dd  0.0, 0.0, 0.0, 0.0

    zoom                  dd  1.0, 1.0, 1.0, 1.0
    change_delta_zoom_in  dd  1.1, 1.1, 1.1, 1.1
    change_delta_zoom_out dd  0.9, 0.9, 0.9, 0.9
    change_zoom           dd  1.0, 1.0, 1.0, 1.0
    mozgat_zoom_negativ   dd  -0.05, -0.05, -0.05, -0.05
    mozgat_zoom_pozitiv   dd  0.05, 0.05, 0.05, 0.05

    hatar                 dd  4.0, 4.0, 4.0, 4.0
    width                 dd  0.0, 0.0, 0.0, 0.0
    height                dd  0.0, 0.0, 0.0, 0.0

    zoom_pressed_in_S     dd  0
    zoom_pressed_out_S    dd  0

    hanyszor_pressed      dd  0

    
    p1_iter  dd 0
    p2_iter  dd 0
    p3_iter  dd 0
    p4_iter  dd 0

    maxiter     dd  255

    szin1       dd  1
    szin2       dd  1

    caption db "Mandelbrot Set", 0
    errormsg db "ERROR: could not initialize graphics!", 0

    welcome   db " Welcome in Mandelbrot Set! ", 0
    info_zoom db " Press  O (not 0) or P to zoom!", 0
    info_move db " Press W or A or S or D to move the picture! ", 0
    info_animation db " Press u - start animation !", 13, 10 , " Press i - stop animation ! ", 0

    info_switch_flt db " Press 1 - float precision ! ", 0
    info_switch_d   db " Press 2 - double precision ! ", 0
    line      db "--------------------------------------------------", 0
    autor     db "By Domokos Bernat Illes. Have fun :)", 0


    switch_animate  dd  0


global main

section .text

main:

    ; Create the graphics window
    mov     eax, WIDTH      ; window width (X)
    mov     ebx, HEIGHT     ; window hieght (Y)
    mov     ecx, 0          ; window mode (NOT fullscreen!)
    mov     edx, caption    ; window caption
    call    gfx_init
    
    test    eax, eax        ; if the return value is 0, something went wrong
    jnz     .init
    ; Print error message and exit
    mov     eax, errormsg
    call    io_writestr
    call    io_writeln
    ret
    
.init:

    mov     eax, welcome
    call    mio_writestr
    call    mio_writeln
    call    mio_writeln

    mov     eax, info_move
    call    mio_writestr
    call    mio_writeln
    

    mov     eax, info_zoom
    call    mio_writestr
    call    mio_writeln

    mov     eax, info_animation
    call    mio_writestr
    call    mio_writeln

    mov     eax, info_switch_flt
    call    mio_writestr
    call    mio_writeln

    mov     eax, info_switch_d
    call    mio_writestr
    call    mio_writeln

    mov     eax, line
    call    mio_writestr
    call    mio_writeln

    mov     eax, autor
    call    mio_writestr
    call    mio_writeln


;........................
            .Single_point:
;........................


    xor     esi, esi        
    xor     edi, edi 

    ; Convert double to single float

    mov     eax, WIDTH
    cvtsi2ss xmm0, eax
    vpermilps xmm0, xmm0, 0x00
    movups  [width], xmm0

    mov     eax, HEIGHT
    cvtsi2ss xmm0, eax
    vpermilps xmm0, xmm0, 0x00
    movups  [height], xmm0

    ; Pozicio megadasa double -> float -ba
    xorps    xmm0, xmm0

    cvtsd2ss xmm0, [offsetx_d]
    vpermilps xmm0, xmm0, 0x00
    movups   [offsetx], xmm0

    cvtsd2ss xmm0, [offsety_d]
    vpermilps xmm0, xmm0, 0x00
    movups   [offsety], xmm0

    cvtsd2ss xmm0, [changeX_d]
    vpermilps xmm0, xmm0, 0x00
    movups    [changeX], xmm0

    cvtsd2ss xmm0, [changeY_d]
    vpermilps xmm0, xmm0, 0x00
    movups  [changeY], xmm0

    ; Mozgas szabalyozasa double -> float -ba

    cvtsd2ss xmm0, [mozgat_pozitiv_d]
    vpermilps xmm0, xmm0, 0x00
    movups   [mozgat_pozitiv], xmm0

    cvtsd2ss xmm0, [mozgat_negativ_d]
    vpermilps xmm0, xmm0, 0x00
    movups   [mozgat_negativ], xmm0

    cvtsd2ss xmm0, [mozgat_zoom_negativ_d]
    vpermilps xmm0, xmm0, 0x00
    movups   [mozgat_zoom_negativ], xmm0

    cvtsd2ss xmm0, [mozgat_zoom_pozitiv_d]
    vpermilps xmm0, xmm0, 0x00
    movups   [mozgat_zoom_pozitiv], xmm0

    ;Zoom szabalyzasa
    cvtsd2ss xmm0, [zoom_d]
    vpermilps xmm0, xmm0, 0x00
    movups   [zoom], xmm0

    cvtsd2ss xmm0, [change_zoom_d]
    vpermilps xmm0, xmm0, 0x00
    movups   [change_zoom], xmm0


.mainloop_S:

    call    gfx_map         

    xor     ecx, ecx

.yloop_S:
    cmp     ecx, HEIGHT
    je     .yend_S   

    xor     edx, edx

.xloop_S:

    cmp     edx, WIDTH
    je      .xend_S  
    
    ; X koordinatai 4 pixelnek
    ; 1. pixel x1
    xorps      xmm1,xmm1  
    cvtsi2ss   xmm1, edx ;

    ; xmm0 = [x1], [0.0], [0.0], [0.0]
    vpermilps   xmm1, xmm1, 0x15

    ; 2.pixel x2
    ; xmm0 = [x1], [x2], [0.0], [0.0]
    inc         edx
    cvtsi2ss    xmm1, edx
    vpermilps   xmm1, xmm1, 0xC0


    ; 3.pixel x3
    ; xmm0 = [x1], [x2], [x3], [0.0]
    inc         edx
    cvtsi2ss    xmm1, edx   
    vpermilps   xmm1, xmm1, 0xE0

    ; 4.pixel x4
    ; xmm0 = [x1], [x2], [x3], [x4]
    inc         edx
    cvtsi2ss    xmm1, edx

    ; Tehat akkor xmm1 = [x1], [x2], [x3], [x4]

    ; eax, edx, ecx, ebx

    ; pr = 1.5 * (x - w / 2) / (0.5 * zoom * w) + moveX;

    xorps   xmm0, xmm0
    movups  xmm0, [width]
    divps   xmm0, [ketto]

    subps   xmm1, xmm0

    mulps   xmm1, [egyegeszot]

    movups  xmm2, xmm0
    mulps   xmm2, [zoom]   
    divps   xmm1, xmm2  
    addps   xmm1, [offsetx] ; xmm1 = [pr1], [pr2], [pr3], [pr4]

    ; Vege 4X koordinata

    ; Y koordinatak meghatarozasa 

    ; pi = (y - h / 2) / (0.5 * zoom * h) + moveY;
    ; xmm2 = [y], [y], [y], [y]
    xorps     xmm2, xmm2
    cvtsi2ss  xmm2, ecx
    vpermilps xmm2, xmm2, 0x00

    movups   xmm3, [height]
    divps    xmm3, [ketto]

    subps    xmm2, xmm3

    movups   xmm4, xmm3
    mulps    xmm4, [zoom]


    divps   xmm2, xmm4  
    addps   xmm2, [offsety] ; xmm2 = [pi1], [pi2], [pi3], [pi4]

    ;newRe = newIm = oldRe = oldIm = 0;
    xorps   xmm3, xmm3 ; oldRe
    xorps   xmm4, xmm4 ; oldIm
    xorps   xmm5, xmm5 ; newRe
    xorps   xmm6, xmm6 ; newIm
    xorps   xmm7, xmm7

    xor     ebx, ebx
    mov     [p1_iter], ebx
    mov     [p2_iter], ebx
    mov     [p3_iter], ebx
    mov     [p4_iter], ebx

    .iteration_S:

        cmp     ebx, [maxiter]
        jae      .kilep_S    

        movups  xmm3, xmm5 ; oldRe = newRe
        movups  xmm4, xmm6 ; oldIm = newIm

        movups  xmm5, xmm3
        mulps   xmm5, xmm5 ;oldRe * oldRe
        movups  xmm7, xmm4 
        mulps   xmm7, xmm7 ;oldIm * oldIm

        subps   xmm5, xmm7 ;oldRe * oldRe - oldIm * oldIm
        addps   xmm5, xmm1 ; xmm5(newRe) = oldRe * oldRe - oldIm * oldIm + pr

        movups  xmm6, xmm3 
        mulps   xmm6, [ketto] ; 2 * oldRe
        mulps   xmm6, xmm4 ; 2 * oldRe * oldIm
        addps   xmm6, xmm2 ; xmm6(newIm) = 2 * oldRe * oldIm + pi

        movups  xmm0, xmm5
        mulps   xmm0, xmm0 ; xmm0 = newRe * newRe

        movups  xmm7, xmm6
        mulps   xmm7, xmm7 ; xmm7 = newIm * newIm

        addps   xmm0, xmm7 ; xmm0 = newRe * newRe + newIm * newIm

        cmpps   xmm0, [hatar], 1  ; cmpltps xmm0, 4 (xmm0 minden eleme kisebb -e mint 4)

        xor         edi, edi
        movmskps    edi, xmm0 ; edi = [28 bit = 0]...[3. bit = 0 - ha nagyobb vagy egyenlo mint 4, 1 - ha kisebb, mint 4], [2.], [1.], [0.]

        test    edi, edi
        jz      .kilep_S

        ; 1. pixel vizsgalata

        xor     esi, esi
        mov     esi, 8
        and     esi, edi
        cmp     esi, 8
        jne     .nem_no_p1_S

        mov     esi, [p1_iter]
        inc     esi 
        mov     [p1_iter], esi

        .nem_no_p1_S:

        mov     esi, 4
        and     esi, edi
        cmp     esi, 4
        jne     .nem_no_p2_S

        mov     esi, [p2_iter]
        inc     esi
        mov     [p2_iter], esi

        .nem_no_p2_S:

        mov     esi, 2
        and     esi, edi
        cmp     esi, 2
        jne     .nem_no_p3_S

        mov     esi, [p3_iter]
        inc     esi
        mov     [p3_iter], esi

        .nem_no_p3_S:

        mov     esi, 1
        and     esi, edi
        cmp     esi, 1
        jne     .nem_no_p4_S

        mov     esi, [p4_iter]
        inc     esi
        mov     [p4_iter], esi

        .nem_no_p4_S:

        inc     ebx     ; globalis iteraciot novel

    jmp     .iteration_S

    jmp     .xloop_S

    .kilep_S:

.elso_S: 
    
    mov     ebx, dword[p1_iter]
    mov     byte[eax], bl ; b
    add     ebx, [szin1]
    mov     byte[eax+1], bl ; g
    add     ebx, [szin2]
    mov     byte[eax+2], bl  ; r
    mov     byte[eax+3], 0

    add     eax, 4  ; 2. pixel

.masodik_S:

    mov     ebx, dword[p2_iter]
    mov     byte[eax], bl
    add     ebx, [szin1]
    mov     byte[eax+1], bl
    add     ebx, [szin2]
    mov     byte[eax+2], bl 
    mov     byte[eax+3], 0

    add     eax, 4 ; 3. pixel

.harmadik_S:

    mov     ebx, dword[p3_iter]
    mov     byte[eax], bl
    add     ebx, [szin1]
    mov     byte[eax+1], bl
    add     ebx, [szin2]
    mov     byte[eax+2], bl 
    mov     byte[eax+3], 0

    add     eax, 4 ; 4. pixel

.negyedik_S:
    
    mov     ebx, dword[p4_iter]
    mov     byte[eax], bl
    add     ebx, [szin1]
    mov     byte[eax+1], bl
    add     ebx, [szin2]
    mov     byte[eax+2], bl 
    mov     byte[eax+3], 0

    add     eax, 4 ; 1. pixel az uj iteracioban

    .next_set_S:
    inc     edx

    jmp     .xloop_S
    
.xend_S:
    inc     ecx

    jmp     .yloop_S
    
.yend_S:

    call    gfx_unmap       ; unmap the framebuffer
    call    gfx_draw        ; draw the contents of the framebuffer (*must* be called once in each iteration!)
    

    ; Query and handle the events (loop!)
    xor     ebx, ebx

.eventloop_S:
    
    call    gfx_getevent

    cmp     eax,'o'     
    je      .zoom_in_S             
    cmp     eax, -'o'
    je      .zoom_release_S
    cmp     eax,'p'             
    je      .zoom_out_S            
    cmp     eax, -'p'
    je      .zoom_release_S
    cmp     eax, 'w'    ; w key pressed
    je      .up_press_S   ; deltay = -1 (if equal)
    cmp     eax, -'w'   ; w key released
    je      .release_up_down_S ; deltay = 0 (if equal)
    cmp     eax, 's'    ; s key pressed
    je      .down_press_S    ; deltay = 1 (if equal)
    cmp     eax, -'s'   ; s key released
    je      .release_up_down_S    ; deltay = 0
    cmp     eax, 'a'
    je      .left_press_S
    cmp     eax, -'a'
    je      .release_right_left_S
    cmp     eax, 'd'
    je      .right_press_S
    cmp     eax, -'d'
    je      .release_right_left_S

    cmp     eax, '2'
    je      .Double_point

    cmp     eax, 'u'
    je      .animation

    cmp     eax, 'i'
    je      .stop_animation

    cmp     [switch_animate], dword 0
    je      .updateoffset_S

    .animation:

    mov     [switch_animate], dword 1

    add     [szin1], dword 3
    sub     [szin2], dword 6

    jmp .updateoffset_S

    .stop_animation:
    mov     [switch_animate], dword 0
    jmp     .updateoffset_S

.up_press_S: ; w
    movups   xmm1, [mozgat_negativ]
    movups   [changeY], xmm1

jmp     .updateoffset_S

.down_press_S: ; s
    movups   xmm1, [mozgat_pozitiv]
    movups   [changeY], xmm1
jmp     .updateoffset_S

.left_press_S: ; a
    movups   xmm1, [mozgat_negativ]
    movups   [changeX], xmm1
jmp     .updateoffset_S

.right_press_S: ; d
    movups   xmm1, [mozgat_pozitiv]
    movups   [changeX], xmm1 
jmp     .updateoffset_S

.release_up_down_S: ; -W -S
    xorps    xmm1, xmm1
    movups   [changeY], xmm1
jmp     .updateoffset_S

.release_right_left_S: ; -A -D
    xorps    xmm1, xmm1
    movups   [changeX], xmm1

jmp     .updateoffset_S

.zoom_in_S: ; o
    
    ; volt zoom tehat zoom
    mov     [zoom_pressed_in_S], dword 1 

    movups xmm0, [change_delta_zoom_in]
    movups [change_zoom], xmm0 

jmp     .updateoffset_S

.zoom_out_S: ; p
    
    mov     [zoom_pressed_out_S], dword 1

    movups xmm0, [change_delta_zoom_out]
    movups [change_zoom], xmm0

jmp     .updateoffset_S

.zoom_release_S: ; -o
    
    mov    [zoom_pressed_in_S], dword 0
    mov    [zoom_pressed_out_S], dword 0
    movups xmm0, [egy]
    movups [change_zoom], xmm0
        
jmp     .updateoffset_S

    
.updateoffset_S:

    ; Handle exit
    cmp     eax, 23         ; the window close button was pressed: exit
    je      .end_S
    cmp     eax, 27         ; ESC: exit
    je      .end_S
    test    eax, eax        ; 0: no more events
    jnz     .eventloop_S


    movups   xmm1, [offsetx]
    movups   xmm2, [offsety]

    addps    xmm1, [changeX]
    addps    xmm2, [changeY]

    movups   [offsetx], xmm1
    movups   [offsety], xmm2 

    movups   xmm0, [zoom]
    mulps    xmm0, [change_zoom]
    movups   [zoom], xmm0

    cmp     [zoom_pressed_in_S], dword 0
    je      .nem_volt_zoom_be_S
    .volt_zoom_be_S:


    movups xmm0, [mozgat_negativ]
    mulps  xmm0, [delta_move_in]
    movups [mozgat_negativ], xmm0

    movups xmm0, [mozgat_pozitiv]
    mulps  xmm0, [delta_move_in]
    movups [mozgat_pozitiv], xmm0

    .nem_volt_zoom_be_S:
    cmp     [zoom_pressed_out_S], dword 0
    je      .nem_volt_zoom_ki_S
    .volt_zoom_ki_S:

    movups xmm0, [mozgat_negativ]
    divps  xmm0, [delta_move_out]
    ;divps  xmm0, [delta_move_out]
    movups [mozgat_negativ], xmm0

    movups xmm0, [mozgat_pozitiv]
    divps  xmm0, [delta_move_out]
    ;divps  xmm0, [delta_move_out]
    movups [mozgat_pozitiv], xmm0

    .nem_volt_zoom_ki_S:
  
    jmp     .mainloop_S

.end_S:
    call    gfx_destroy

ret

;...............................
                  .Double_point:            
;...............................

    xor     esi, esi        
    xor     edi, edi
    mov     [zoom_pressed_in_S], dword 0
    mov     [zoom_pressed_out_S], dword 0  


    mov     eax, WIDTH
    cvtsi2sd  xmm0, eax
    vpermilpd xmm0, xmm0, 0x00
    movupd   [width_d], xmm0

    mov     eax, HEIGHT
    cvtsi2sd  xmm0, eax
    vpermilpd xmm0, xmm0, 0x00
    movupd  [height_d], xmm0

    xorps    xmm0, xmm0

    cvtss2sd xmm0, [offsetx]
    vpermilpd xmm0, xmm0, 0x00
    movupd   [offsetx_d], xmm0

    cvtss2sd xmm0, [offsety]
    vpermilpd xmm0, xmm0, 0x00
    movupd   [offsety_d], xmm0

    cvtss2sd xmm0, [changeX]
    vpermilpd xmm0, xmm0, 0x00
    movupd    [changeX_d], xmm0

    cvtss2sd xmm0, [changeY]
    vpermilpd xmm0, xmm0, 0x00
    movupd  [changeY_d], xmm0


    ; Mozgas szabalyozasa float -> double -ba

    cvtss2sd xmm0, [mozgat_pozitiv]
    vpermilpd xmm0, xmm0, 0x00
    movupd   [mozgat_pozitiv_d], xmm0

    cvtss2sd xmm0, [mozgat_negativ]
    vpermilpd xmm0, xmm0, 0x00
    movupd   [mozgat_negativ_d], xmm0

    cvtss2sd xmm0, [mozgat_zoom_negativ]
    vpermilpd xmm0, xmm0, 0x00
    movupd   [mozgat_zoom_negativ_d], xmm0

    cvtss2sd xmm0, [mozgat_zoom_pozitiv]
    vpermilpd xmm0, xmm0, 0x00
    movupd   [mozgat_zoom_pozitiv_d], xmm0

    ;Zoom szabalyzasa
    cvtss2sd xmm0, [zoom]
    vpermilpd xmm0, xmm0, 0x00
    movupd   [zoom_d], xmm0

    cvtss2sd xmm0, [change_zoom]
    vpermilpd xmm0, xmm0, 0x00
    movupd   [change_zoom_d], xmm0

.mainloop:

    call    gfx_map         

    xor     ecx, ecx

.yloop:
    cmp     ecx, HEIGHT
    je     .yend   

    xor     edx, edx

.xloop:

    cmp     edx, WIDTH
    je      .xend 
    
    ; X koordinatai 4 pixelnek
    ; 1. pixel x1
    xorpd      xmm1,xmm1  
    cvtsi2sd   xmm1, edx ;

    ; xmm0 = [x1], [x1], [0.0], [0.0]
    vpermilpd   xmm1, xmm1, 0x15

    ; 2.pixel x2
    ; xmm0 = [x1], [x1], [x2], [x2]
    inc         edx
    cvtsi2sd    xmm1, edx

    ; Tehat akkor xmm1 = [x1], [x2], [x3], [x4]
    ; 
    ; pr = 1.5 * (x - w / 2) / (0.5 * zoom * w) + moveX;

    xorpd       xmm0, xmm0
    movupd      xmm0, [width_d]
    divpd       xmm0, [ketto_d]

    subpd   xmm1, xmm0

    mulpd   xmm1, [egyegeszot_d]

    movupd  xmm2, xmm0
    mulpd   xmm2, [zoom_d]   
    divpd   xmm1, xmm2  
    addpd   xmm1, [offsetx_d] ; xmm1[pr] = [pr1], [pr2], [pr3], [pr4]


    ; Vege 4X koordinata

    ; Y koordinatak meghatar_dozasa 

    ; pi = (y - h / 2) / (0.5 * zoom * h) + moveY;
    ; xmm2 = [y], [y], [y], [y]
    xorpd     xmm2, xmm2
    cvtsi2sd  xmm2, ecx
    vpermilpd xmm2, xmm2, 0x00

    movupd   xmm3, [height_d]
    divpd    xmm3, [ketto_d]

    subpd    xmm2, xmm3

    movupd   xmm4, xmm3
    mulpd    xmm4, [zoom_d]


    divpd   xmm2, xmm4  
    addpd   xmm2, [offsety_d] ; xmm2 = [pi1], [pi2], [pi3], [pi4]


    ;newRe = newIm = oldRe = oldIm = 0;
    xorpd   xmm3, xmm3 ; oldRe
    xorpd   xmm4, xmm4 ; oldIm
    xorpd   xmm5, xmm5 ; newRe
    xorpd   xmm6, xmm6 ; newIm
    xorpd   xmm7, xmm7

    xor     ebx, ebx
    mov     [p1_iter], ebx
    mov     [p2_iter], ebx
    mov     [p3_iter], ebx
    mov     [p4_iter], ebx

    .iteration:

        cmp     ebx, [maxiter]
        jae     .kilep_    

        movupd  xmm3, xmm5 ; oldRe = newRe
        movupd  xmm4, xmm6 ; oldIm = newIm

        movupd  xmm5, xmm3
        mulpd   xmm5, xmm5 ;oldRe * oldRe
        movupd  xmm7, xmm4 
        mulpd   xmm7, xmm7 ;oldIm * oldIm

        subpd   xmm5, xmm7 ;oldRe * oldRe - oldIm * oldIm
        addpd   xmm5, xmm1 ; xmm5(newRe) = oldRe * oldRe - oldIm * oldIm + pr

        movupd  xmm6, xmm3 
        mulpd   xmm6, [ketto_d] ; 2 * oldRe
        mulpd   xmm6, xmm4 ; 2 * oldRe * oldIm
        addpd   xmm6, xmm2 ; xmm6(newIm) = 2 * oldRe * oldIm + pi

        movupd  xmm0, xmm5
        mulpd   xmm0, xmm0 ; xmm0 = newRe * newRe

        movupd  xmm7, xmm6
        mulpd   xmm7, xmm7 ; xmm7 = newIm * newIm

        addpd   xmm0, xmm7 ; xmm0 = newRe * newRe + newIm * newIm

        cmppd   xmm0, [hatar_d], 1  ; cmpltps xmm0, 4 (xmm0 minden eleme kisebb -e mint 4)

        xor         edi, edi
        movmskpd    edi, xmm0 ; edi = [28 bit = 0]...[3. bit = 0 - ha nagyobb vagy egyenlo mint 4, 1 - ha kisebb, mint 4], [2.], [1.], [0.]

        test    edi, edi
        jz      .kilep_

        ; 1. pixel vizsgalata

        xor     esi, esi
        mov     esi, 2
        and     esi, edi
        cmp     esi, 2
        jne     .nem_no_p1

        mov     esi, [p1_iter]
        inc     esi 
        mov     [p1_iter], esi

        .nem_no_p1:

        mov     esi, 1
        and     esi, edi
        cmp     esi, 1
        jne     .nem_no_p2

        mov     esi, [p2_iter]
        inc     esi
        mov     [p2_iter], esi

        .nem_no_p2:

        inc     ebx     ; globalis iteraciot novel

    jmp     .iteration

    jmp     .xloop

    .kilep_:

    .elso: 

    mov     ebx, dword[p1_iter]
    mov     byte[eax], bl
    add     ebx, [szin1]
    mov     byte[eax+1], bl
    add     ebx, [szin2]
    mov     byte[eax+2], bl 
    mov     byte[eax+3], 0

    add     eax, 4  ; 2. pixel

.masodik:
    
    mov     ebx, dword[p2_iter]
    mov     byte[eax], bl
    add     ebx, [szin1]
    mov     byte[eax+1], bl
    add     ebx, [szin2]
    mov     byte[eax+2], bl 
    mov     byte[eax+3], 0

    add     eax, 4 ; 3. pixel

    .next_set:
    inc     edx

    jmp     .xloop
    
.xend:
    inc     ecx

    jmp     .yloop
    
.yend:

    call    gfx_unmap       ; unmap the framebuffer
    call    gfx_draw        ; draw the contents of the framebuffer (*must* be called once in each iteration!)
    

    ; Query and handle the events (loop!)
    xor     ebx, ebx

.eventloop:
    
    call    gfx_getevent

    cmp     eax,'o'     
    je      .zoom_in             
    cmp     eax, -'o'
    je      .zoom_release
    cmp     eax,'p'             
    je      .zoom_out            
    cmp     eax, -'p'
    je      .zoom_release

    cmp     eax, 'w'    ; w key pressed
    je      .up_press   ; deltay = -1 (if equal)
    cmp     eax, -'w'   ; w key released
    je      .release_up_down ; deltay = 0 (if equal)
    cmp     eax, 's'    ; s key pressed
    je      .down_press    ; deltay = 1 (if equal)
    cmp     eax, -'s'   ; s key released
    je      .release_up_down    ; deltay = 0
    cmp     eax, 'a'
    je      .left_press
    cmp     eax, -'a'
    je      .release_right_left
    cmp     eax, 'd'
    je      .right_press
    cmp     eax, -'d'
    je      .release_right_left

    cmp     eax, '1'
    je      .Single_point

    cmp     eax, 'u'
    je      .animation_D

    cmp     eax, 'i'
    je      .stop_animation_D

    cmp     [switch_animate], dword 0
    je      .updateoffset

    .animation_D:

    mov     [switch_animate], dword 1

    add     [szin1], dword 3
    sub     [szin2], dword 5

    jmp .updateoffset

    .stop_animation_D:
    mov     [switch_animate], dword 0
    jmp     .updateoffset


    jmp .updateoffset

.up_press: ; w
    movupd   xmm1, [mozgat_negativ_d]
    movupd   [changeY_d], xmm1
jmp     .updateoffset

.down_press: ; s
    movupd   xmm1, [mozgat_pozitiv_d]
    movupd   [changeY_d], xmm1
jmp     .updateoffset

.left_press: ; a
    movupd   xmm1, [mozgat_negativ_d]
    movupd   [changeX_d], xmm1
jmp     .updateoffset

.right_press: ; d
    movupd   xmm1, [mozgat_pozitiv_d]
    movupd   [changeX_d], xmm1 
jmp     .updateoffset

.release_up_down: ; -W -S
    xorpd    xmm1, xmm1
    movupd   [changeY_d], xmm1
jmp     .updateoffset

.release_right_left: ; -A -D
    xorpd    xmm1, xmm1
    movupd   [changeX_d], xmm1

jmp     .updateoffset

.zoom_in: ; o
    
    mov     [zoom_pressed_in_S], dword 1
    movupd xmm0, [change_delta_zoom_in_d]
    movupd [change_zoom_d], xmm0

jmp     .updateoffset

.zoom_out: ; p
    mov     [zoom_pressed_out_S], dword 1
    movupd xmm0, [change_delta_zoom_out_d]
    movupd [change_zoom_d], xmm0

jmp     .updateoffset

.zoom_release: ; -o
    mov     [zoom_pressed_in_S], dword 0
    mov     [zoom_pressed_out_S], dword 0
    movupd xmm0, [egy_d]
    movupd [change_zoom_d], xmm0
        
jmp     .updateoffset

    
.updateoffset:

    ; Handle exit
    cmp     eax, 23         ; the window close button was pressed: exit
    je      .end
    cmp     eax, 27         ; ESC: exit
    je      .end
    test    eax, eax        ; 0: no more events
    jnz     .eventloop


    movupd   xmm1, [offsetx_d]
    movupd   xmm2, [offsety_d]

    addpd    xmm1, [changeX_d]
    addpd    xmm2, [changeY_d]

    movupd   [offsetx_d], xmm1
    movupd   [offsety_d], xmm2 

    movupd   xmm0, [zoom_d]
    mulpd    xmm0, [change_zoom_d]
    movupd   [zoom_d], xmm0

    cmp     [zoom_pressed_in_S], dword 0
    je      .nem_volt_zoom_be_D
    .volt_zoom_be_D:

    movupd xmm0, [mozgat_negativ_d]
    mulpd  xmm0, [delta_move_in_d]
    movupd [mozgat_negativ_d], xmm0

    movupd xmm0, [mozgat_pozitiv_d]
    mulpd  xmm0, [delta_move_in_d]
    movupd [mozgat_pozitiv_d], xmm0

    .nem_volt_zoom_be_D:
    cmp    [zoom_pressed_out_S], dword 0
    je     .nem_volt_zoom_ki_D
    .volt_zoom_ki_D:

    movupd xmm0, [mozgat_negativ_d]
    divpd  xmm0, [delta_move_out_d]
    ;divpd  xmm0, [delta_move_out_d]
    movupd [mozgat_negativ_d], xmm0

    movupd xmm0, [mozgat_pozitiv_d]
    divpd  xmm0, [delta_move_out_d]
    ;divpd  xmm0, [delta_move_out_d]
    movupd [mozgat_pozitiv_d], xmm0
    .nem_volt_zoom_ki_D:
  
    jmp     .mainloop
    
.end:
    call    gfx_destroy

ret