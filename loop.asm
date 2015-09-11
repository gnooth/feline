; Copyright (C) 2012-2015 Peter Graves <gnooth@gmail.com>

; This program is free software: you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation, either version 3 of the License, or
; (at your option) any later version.

; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.

; You should have received a copy of the GNU General Public License
; along with this program.  If not, see <http://www.gnu.org/licenses/>.

file __FILE__

; ### (do)
code parendo, '(do)'                    ; limit index --
        pop     rcx                     ; return address
        mov     rax, [rcx]              ; address for LEAVE
        push    rax                     ; r: -- leave-addr
        ; index is in rbx
        mov     rdx, [rbp]              ; limit in rdx
        mov     rax, $8000000000000000  ; offset loop limit by $8000000000000000
        add     rdx, rax
        push    rdx                     ; r: -- leave-addr limit
        sub     rbx, rdx                ; subtract modified limit from index
        push    rbx                     ; r: -- leave-addr limit index
        mov     rbx, [rbp + BYTES_PER_CELL]
        lea     rbp, [rbp + BYTES_PER_CELL * 2]
        add     rcx, BYTES_PER_CELL
        push    rcx
        next
endcode

; ### x(?do)
inline xparen?do, 'x(?do)'                  ; limit index --
;         pop     rcx                     ; return address
;         mov     rax, [rcx]              ; address for LEAVE
;         push    rax                     ; r: -- leave-addr

        cmp     rbx, [rbp]
        jne     .1
        mov     rbx, [rbp + BYTES_PER_CELL]
        lea     rbp, [rbp + BYTES_PER_CELL * 2]
        ret                             ; same as jumping to %1_exit
.1:
        ; index is in rbx
        mov     rdx, [rbp]              ; limit in rdx
        mov     rax, $8000000000000000  ; offset loop limit by $8000000000000000
        add     rdx, rax
        push    rdx                     ; r: -- leave-addr limit
        sub     rbx, rdx                ; subtract modified limit from index
        push    rbx                     ; r: -- leave-addr limit index
        mov     rbx, [rbp + BYTES_PER_CELL]
        lea     rbp, [rbp + BYTES_PER_CELL * 2]
;         add     rcx, BYTES_PER_CELL
;         push    rcx
endinline

; ### inline-(do)
inline inline_parendo, 'inline-(do)'      ; limit index --
;         pop     rcx                     ; return address
;         mov     rax, [rcx]              ; address for LEAVE
;         push    rax                     ; r: -- leave-addr
        ; index is in rbx
        mov     rdx, [rbp]              ; limit in rdx
        mov     rax, $8000000000000000  ; offset loop limit by $8000000000000000
        add     rdx, rax
        push    rdx                     ; r: -- leave-addr limit
        sub     rbx, rdx                ; subtract modified limit from index
        push    rbx                     ; r: -- leave-addr limit index
        mov     rbx, [rbp + BYTES_PER_CELL]
        lea     rbp, [rbp + BYTES_PER_CELL * 2]
;         add     rcx, BYTES_PER_CELL
;         push    rcx
;         next
endinline

; ### xdo
code xdo, 'xdo', IMMEDIATE                ; -- addr
        _ ?comp
        _ flush_compilation_queue

        _lit $48
        _ ccommac
        _lit $0b8
        _ ccommac
        _ here_c                        ; address to be patched
        _ zero
        _ commac
        _lit $50                        ; push rax
        _ ccommac

        _lit inline_parendo_xt
;         _lit xparendo_xt
        _ compilecomma

        _ here_c ; added Sep 9 2015 7:35 AM loop back address
;         _ dup
;         _ ?cr
;         _dotq "xdo   loop back addr = $"
;         _ hdot

        next
endcode

; ### x?do
code x?do, 'x?do', IMMEDIATE                ; -- addr
        _ ?comp
        _ flush_compilation_queue

        _lit $48
        _ ccommac
        _lit $0b8
        _ ccommac
        _ here_c                        ; address to be patched
        _ zero
        _ commac
        _lit $50                        ; push rax
        _ ccommac

        _lit xparen?do_xt
        _ compilecomma

        _ here_c ; added Sep 9 2015 7:35 AM loop back address
;         _ dup
;         _ ?cr
;         _dotq "xdo   loop back addr = $"
;         _ hdot

        next
endcode

; ### do
code do, 'do', IMMEDIATE                ; -- addr
        _ ?comp
        _ flush_compilation_queue
%if 0
        _lit $48
        _ ccommac
        _lit $0b8
        _ ccommac
        _ here_c                        ; address to be patched
        _ zero
        _ commac
        _lit $50                        ; push rax
        _ ccommac
%endif
        _lit parendo
        _ commacall
        _ here_c
        _ zero
        _ commac
        next
endcode

; ### (?do)
code paren?do, '(?do)'                  ; limit index --
        pop     rcx                     ; return address
        mov     rax, [rcx]              ; address for LEAVE
        cmp     rbx, [rbp]
        jne     .1
        mov     rbx, [rbp + BYTES_PER_CELL]
        add     rbp, BYTES_PER_CELL * 2
        jmp     rax
.1:
        push    rax                     ; address for LEAVE
        popd    rax                     ; index
        popd    rdx                     ; limit
        mov     r11, $8000000000000000  ; offset loop limit by $8000000000000000
        add     rdx, r11
        push    rdx
        sub     rax, rdx                ; subtract modified limit from index
        push    rax
        add     rcx, BYTES_PER_CELL
        jmp     rcx
        next                            ; for disassembler
endcode

%if 0
; ## x(?do)
code xparen?do, 'x(?do)'                  ; limit index --
;         pop     rcx                     ; return address
;         mov     rax, [rcx]              ; address for LEAVE
        cmp     rbx, [rbp]
        jne     .1
        mov     rbx, [rbp + BYTES_PER_CELL]
        add     rbp, BYTES_PER_CELL * 2
;         jmp     rax
        ret
.1:
;         push    rax                     ; address for LEAVE
;         popd    rax                     ; index
;         popd    rdx                     ; limit
;         mov     r11, $8000000000000000  ; offset loop limit by $8000000000000000
;         add     rdx, r11
;         push    rdx
;         sub     rax, rdx                ; subtract modified limit from index
;         push    rax
;         add     rcx, BYTES_PER_CELL
;         jmp     rcx
        pop     rcx                     ; return address
;         mov     rax, [rcx]              ; address for LEAVE
;         push    rax                     ; r: -- leave-addr
        ; index is in rbx
        mov     rdx, [rbp]              ; limit in rdx
        mov     rax, $8000000000000000  ; offset loop limit by $8000000000000000
        add     rdx, rax
        push    rdx                     ; r: -- leave-addr limit
        sub     rbx, rdx                ; subtract modified limit from index
        push    rbx                     ; r: -- leave-addr limit index
        mov     rbx, [rbp + BYTES_PER_CELL]
        lea     rbp, [rbp + BYTES_PER_CELL * 2]
;         add     rcx, BYTES_PER_CELL
        push    rcx
        next
endcode
%endif

; ### ?do
code ?do, '?do', IMMEDIATE
        _ ?comp
        _ flush_compilation_queue
        _lit paren?do
        _ commacall
        _ here_c
        _ zero
        _ commac
        next
endcode

; ; ### (loop)
; code parenloop, '(loop)'                ; --
; ; "Add one to the loop index. If the loop index is then equal to the loop limit,
; ; discard the loop parameters and continue execution immediately following the
; ; loop. Otherwise continue execution at the beginning of the loop." 6.1.1800
;                                         ; r: -- leave-addr limit index
;         pop     rcx                     ; return address
;         inc     qword [rsp]
;         jo      .1
;         jmp     [rcx]
; .1:                                     ; r: -- leave-addr limit index
;         add     rsp, BYTES_PER_CELL * 2 ; r: -- leave-addr
;         next
; endcode

section .text
doloop:
        inc     qword [rsp]                             ; 48 FF 04 24
        jno     0                       ; <-- patch     ; 0F 81 00 00 00 00
doloop_patch    equ     $ - 4
        add     rsp, BYTES_PER_CELL * 3                 ; 48 83 C4 18
doloop_end:

        ; ### loop
        code loop, 'loop', IMMEDIATE            ; c: do-sys --
        ;         _ ?cr
        ;         _dotq "loop tos = "
        ;         _ dup
        ;         _ hdot

        _ ?comp
        _ flush_compilation_queue
        _ here_c
        _ tor                           ; -- do-sys             r: here-c
        _lit doloop
        _lit doloop_end - doloop
        _ paren_copy_code               ; -- do-sys             r: here-c
        _lit doloop_patch - doloop
        _ rfrom
        _ plus                          ; -- do-sys addr-to-be-patched
        _ twodup
        _ swap                          ; -- do-sys addr-to-be-patched addr-to-be-patched do-sys
        _cellplus
        _ swap
        _ four
        _ plus
        _ minus                         ; -- do-sys addr-to-be-patched signed-displacement

        ;         _ ?cr
        ;         _dotq "loop displacement = "
        ;         _ dup
        ;         _ hdot

        _ swap
        _ lstore                        ; -- do-sys

        _ here_c                        ; -- do-sys leave-addr
        _ swap
        _ store

        next
        endcode

; section .text
; doloop:
;         inc     qword [rsp]                             ; 48 FF 04 24
;         jno     0                       ; <-- patch     ; 0F 81 00 00 00 00
; doloop_patch    equ     $ - 4
;         add     rsp, BYTES_PER_CELL * 3                 ; 48 83 C4 18
; doloop_end:

; ### xloop NEW VERSION
code xloop, 'xloop', IMMEDIATE            ; addr1 addr2 --
                                        ; addr1 is where we need to put the LEAVE address
                                        ; addr2 is top of loop (after setup code)

        _ ?comp
        _ flush_compilation_queue

        ; move top of loop address to return stack
        _ tor                           ; -- address-to-be-patched-with-LEAVE-address
                                        ; r: -- top-of-loop-addr

        ; copy the (LOOP) code
;         _lit doloop
;         _lit doloop_end - doloop
;         _ paren_copy_code
        ; copy the first part of the (LOOP) code
        _lit doloop
        _lit doloop_patch - doloop
        _ paren_copy_code

        ; compute the offset back to the top of the loop
        _ here_c
        _lit 4
        _ plus
        _ rfrom
        _ swap
        _ minus                         ; -- offset
        _ lcommac

        _lit $18c48348                  ; add rsp, 24
        _ lcommac

        ; patch the setup code with the LEAVE address
        _ here_c                        ; this is the LEAVE address
        _ swap                          ; -- LEAVE-addr addr-to-be-patched
        _ store                         ; --

        next
endcode

section .text
doplusloop:
;         inc     qword [rsp]                             ; 48 FF 04 24
        add     qword [rsp], rbx
        poprbx
        jno     0                       ; <-- patch     ; 0F 81 00 00 00 00
doplusloop_patch    equ     $ - 4
        add     rsp, BYTES_PER_CELL * 3                 ; 48 83 C4 18
doplusloop_end:

; ### x+loop NEW VERSION
code xplusloop, 'x+loop', IMMEDIATE       ; addr1 addr2 --
                                        ; addr1 is where we need to put the LEAVE address
                                        ; addr2 is top of loop (after setup code)

        _ ?comp
        _ flush_compilation_queue

        ; move top of loop address to return stack
        _ tor                           ; -- address-to-be-patched-with-LEAVE-address
                                        ; r: -- top-of-loop-addr

        ; copy the first part of the (LOOP) code
        _lit doplusloop
        _lit doplusloop_patch - doplusloop
        _ paren_copy_code

        ; compute the offset back to the top of the loop
        _ here_c
        add     rbx, 4                  ; address of first byte of next instruction
        _ rfrom
        _ swap
        _ minus                         ; -- offset
        _ lcommac

        _lit $18c48348                  ; add rsp, 24
        _ lcommac

        ; patch the setup code with the LEAVE address
        _ here_c                        ; this is the LEAVE address
        _ swap                          ; -- LEAVE-addr addr-to-be-patched
        _ store                         ; --

        next
endcode

; ### (+loop)
code parenplusloop, '(+loop)'           ; n --
; "Add n to the loop index. If the loop index did not cross the boundary
; between the loop limit minus one and the loop limit, continue execution
; at the beginning of the loop. Otherwise, discard the current loop control
; parameters and continue execution immediately following the loop."
        pop     rcx                     ; return address
        pop     rax                     ; index
        pop     rdx                     ; limit
        add     rax, rbx
        mov     rbx, [rbp]
        lea     rbp, [rbp + BYTES_PER_CELL]
        jo      .1
        push    rdx
        push    rax
        mov     rcx, [rcx]
        jmp     rcx
.1:
        pop     rax                     ; drop LEAVE address from return stack
        add     rcx, BYTES_PER_CELL     ; skip past loopback address
        jmp     rcx
        next                            ; for disassembler
endcode

; ### +loop
code plusloop, '+loop', IMMEDIATE       ; addr --
        _ ?comp
        _ flush_compilation_queue
        _lit parenplusloop
        _ commacall
        _ dup
        _ cellplus
        _ commac
        _ here_c
        _ swap
        _ store
        next
endcode

; ### inline-leave
inline inline_leave, 'inline-leave'
        add     rsp, BYTES_PER_CELL * 2
        ret
endinline

; ### (leave)
code paren_leave, '(leave)'
        add     rsp, BYTES_PER_CELL * 3
        ret
endcode

; ### leave
code leave, 'leave', IMMEDIATE
        _ ?comp
        _ flush_compilation_queue
;         _lit paren_leave
;         _ commacall
        _lit inline_leave_xt
        _ copy_code
        next
endcode

; ### inline-i
inline inline_i, 'inline-i'
        pushrbx
        mov     rbx, [rsp]
        add     rbx, [rsp + BYTES_PER_CELL]
endinline

; ### i
code i, 'i', IMMEDIATE
        _ ?comp
        _ flush_compilation_queue
        _lit inline_i_xt
        _ copy_code
        next
endcode

; ### j
; FIXME should be immediate compile-only
; runtime should be inline
code j, 'j'
; CORE
; "Interpretation semantics for this word are undefined."
        pushrbx
        mov     rbx, [rsp + BYTES_PER_CELL * 4]
        add     rbx, [rsp + BYTES_PER_CELL * 5]
        next
endcode

; ### inline-unloop
inline inline_unloop, 'inline-unloop'
        _unloop
endinline

; ### unloop
code unloop, 'unloop', IMMEDIATE
        _ ?comp
        _lit inline_unloop_xt
        _ copy_code
        next
endcode

; ### bounds
code bounds, 'bounds'                   ; addr len -- addr+len addr
        _ over
        _ plus
        _ swap
        next
endcode

; Tests
code loop_empty, 'loop-empty'
        _lit 10
        _ zero
        _do .1
        _i
        _ dot
        _loop .1
        next
endcode

code loop_?do, 'loop-?do'
        _?do .1
        _i
        _ dot
        _loop .1
        next
endcode

code loop_test, 'loop-test'
        _lit 10
        _ zero
        _do .1
        _i
        _ dot
        _i
        _lit 7
        _ equal
        _if .2
        _ ?cr
        _dotq "leaving "
        _ paren_leave
        _then .2
        _loop .1
        _ ?cr
        _dotq "after loop, leaving... "
        next
endcode

code ?do_test, '?do-test'
        _?do .1
        _i
        _ dot
        _loop .1
        _dotq "done!"
        next
endcode
