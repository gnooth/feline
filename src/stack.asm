; Copyright (C) 2012-2017 Peter Graves <gnooth@gmail.com>

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

; ### sp@
code spfetch, 'sp@'
        lea     rbp, [rbp - BYTES_PER_CELL]
        mov     [rbp], rbx
        mov     rbx, rbp
        next
endcode

; ### sp!
code spstore, 'sp!'
        mov     rbp, rbx
        mov     rbx, [rbp]
        lea     rbp, [rbp + BYTES_PER_CELL]
        next
endcode

; ### ?dup
inline ?dup, '?dup'
        _?dup
endinline

%macro  _depth 0
        mov     rax, [sp0_data]
        sub     rax, rbp
        shr     rax, 3
        pushd   rax
%endmacro

%macro  _rdepth 0
        mov     rax, [rp0_data]
        sub     rax, rsp
        shr     rax, 3
        pushd   rax
%endmacro

; ### 2swap
code twoswap, '2swap'                   ; x1 x2 x3 x4 -- x3 x4 x1 x2
        mov     rax, [rbp]                              ; x3
        mov     rdx, [rbp + BYTES_PER_CELL]             ; x2
        mov     rcx, [rbp + BYTES_PER_CELL * 2]         ; x1
        mov     [rbp + BYTES_PER_CELL * 2], rax         ; x3
        mov     [rbp + BYTES_PER_CELL], rbx             ; x4
        mov     [rbp], rcx                              ; x1
        mov     rbx, rdx
        next
endcode

; ### >r
code tor, '>r'
        pop     rax                     ; return address
        push    rbx
        poprbx
        jmp     rax
        next                            ; for disassembler
endcode

; ### dup>r
code duptor, 'dup>r'
        pop     rax
        push    rbx
        jmp     rax
        next
endcode

; ### r@
code rfetch, 'r@'
        pop     rax                     ; return address
        pushrbx
        mov     rbx, [rsp]
        jmp     rax
        next                            ; for disassembler
endcode

; ### r>
code rfrom, 'r>'
        pop     rax                     ; return address
        pushrbx
        pop     rbx
        jmp     rax
        next                            ; for disassembler
endcode

; ### rdrop
code rdrop, 'rdrop'
        pop     rax                     ; return address
        pop     rdx                     ; discard
        jmp     rax
        next
endcode

%macro  _rpfetch 0
        pushrbx
        mov     rbx, rsp
%endmacro

%macro _rpstore 0
        mov     rsp, rbx
        poprbx
%endmacro
