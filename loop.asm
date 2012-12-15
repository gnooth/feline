; Copyright (C) 2012 Peter Graves <gnooth@gmail.com>

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

code parendo, '(do)'                    ; limit index --
        pop     rcx                     ; return address
        mov     rax, [rcx]              ; address for LEAVE
        push    rax                     ; r: -- leave-addr
        popd    rax                     ; index in rax
        popd    rdx                     ; limit in rdx
        mov     r11, $8000000000000000  ; offset loop limit by $8000000000000000
        add     rdx, r11
        push    rdx                     ; r: -- leave-addr limit
        sub     rax, rdx                ; subtract modified limit from index
        push    rax                     ; r: -- leave-addr limit index
        add     rcx, BYTES_PER_CELL
        jmp     rcx
        next                            ; for disassembler
endcode

code do, 'do', IMMEDIATE                ; -- addr
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

code loop, 'loop', IMMEDIATE            ; c: do-sys --
        _lit parenloop
        _ commacall
        _ dup
        _ cellplus
        _ commac
        _ here_c
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
        _lit parenleave
        _ commacall
        next
endcode

code i, 'i'
        pushrbx
        mov     rbx, [rsp + BYTES_PER_CELL];
        add     rbx, [rsp + BYTES_PER_CELL * 2];
        next
endcode

code j, 'j'
        pushrbx
        mov     rbx, [rsp + BYTES_PER_CELL * 4];
        add     rbx, [rsp + BYTES_PER_CELL * 5];
        next
endcode

code unloop, 'unloop'
        pop     rcx                     ; return address
        add     rsp, BYTES_PER_CELL * 3
        jmp     rcx
        next                            ; for disassembler
endcode

code bounds, 'bounds'                   ; addr len -- addr+len addr
        _ over
        _ plus
        _ swap
        next
endcode
