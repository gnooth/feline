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

code do, 'do', IMMEDIATE                ; -- addr
        _ flush_compilation_queue
        _lit parendo
        _ commacall
        _ here_c
        _ zero
        _ commac
        next
endcode

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

code ?do, '?do', IMMEDIATE
        _ flush_compilation_queue
        _lit paren?do
        _ commacall
        _ here_c
        _ zero
        _ commac
        next
endcode

code parenloop, '(loop)'                ; --
; "Add one to the loop index. If the loop index is then equal to the loop limit,
; discard the loop parameters and continue execution immediately following the
; loop. Otherwise continue execution at the beginning of the loop." 6.1.1800
                                        ; r: -- leave-addr limit index
        pop     rcx                     ; return address
        inc     qword [rsp]
        jo      .1
        jmp     [rcx]
.1:                                     ; r: -- leave-addr limit index
        add     rsp, BYTES_PER_CELL * 2 ; r: -- leave-addr
        next
endcode

section .text
doloop:
        inc     qword [rsp]
        jno     0                       ; <-- patch
doloop_patch    equ     $ - 4
        add     rsp, BYTES_PER_CELL * 3
doloop_end:

code loop, 'loop', IMMEDIATE            ; c: do-sys --
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
        _ swap
        _ lstore                        ; -- do-sys
        _ here_c                        ; -- do-sys leave-addr
        _ swap
        _ store
        next
endcode

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

code plusloop, '+loop', IMMEDIATE       ; addr --
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

code parenleave, '(leave)'
        add     rsp, BYTES_PER_CELL * 3
        ret
endcode

code leave, 'leave', IMMEDIATE
        _ flush_compilation_queue
        _lit parenleave
        _ commacall
        next
endcode

inline i, 'i'
; CORE
; "Interpretation semantics for this word are undefined."
        _i
endinline

inline iplus, 'i+'                      ; ( n -- i+n )
        add     rbx, [rsp]
        add     rbx, [rsp + BYTES_PER_CELL]
endinline

code j, 'j'
; CORE
; "Interpretation semantics for this word are undefined."
        pushrbx
        mov     rbx, [rsp + BYTES_PER_CELL * 4]
        add     rbx, [rsp + BYTES_PER_CELL * 5]
        next
endcode

inline unloop, 'unloop'
        _unloop
endinline

code bounds, 'bounds'                   ; addr len -- addr+len addr
        _ over
        _ plus
        _ swap
        next
endcode
