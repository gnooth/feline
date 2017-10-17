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

; ### cmove
code cmove, 'cmove'                     ; c-addr1 c-addr2 u --
        mov     rcx, rbx                        ; count
        mov     rdi, [rbp]                      ; destination
        mov     rsi, [rbp + BYTES_PER_CELL]     ; source
        mov     rbx, [rbp + BYTES_PER_CELL * 2]
        lea     rbp, [rbp + BYTES_PER_CELL * 3]
        jrcxz   .1
        rep     movsb
.1:
        next
endcode

; ### cmove>
code cmoveup, 'cmove>'                  ; c-addr1 c-addr2 u --
        mov     rcx, rbx                        ; count
        mov     rdi, [rbp]                      ; destination
        mov     rsi, [rbp + BYTES_PER_CELL]     ; source
        mov     rbx, [rbp + BYTES_PER_CELL * 2]
        lea     rbp, [rbp + BYTES_PER_CELL * 3]
        jrcxz   .1
        dec     rcx
        add     rdi, rcx
        add     rsi, rcx
        inc     rcx
        std
        rep     movsb
        cld
.1:
        next
endcode

; ### move_cells_down
code move_cells_down, 'move_cells_down', SYMBOL_INTERNAL
; source destination count --
%ifdef WIN64
        push    rdi
        push    rsi
%endif
        mov     rcx, rbx                        ; count
        mov     rdi, [rbp]                      ; destination
        mov     rsi, [rbp + BYTES_PER_CELL]     ; source
        mov     rbx, [rbp + BYTES_PER_CELL * 2]
        lea     rbp, [rbp + BYTES_PER_CELL * 3]
        jrcxz   .1

        rep     movsq

.1:
%ifdef WIN64
        pop     rsi
        pop     rdi
%endif
        next
endcode

; ### move_cells_up
code move_cells_up, 'move_cells_up', SYMBOL_INTERNAL
; source destination count --
%ifdef WIN64
        push    rdi
        push    rsi
%endif
        mov     rcx, rbx                        ; count
        mov     rdi, [rbp]                      ; destination
        mov     rsi, [rbp + BYTES_PER_CELL]     ; source
        mov     rbx, [rbp + BYTES_PER_CELL * 2]
        lea     rbp, [rbp + BYTES_PER_CELL * 3]
        jrcxz   .1

        mov     rdx, rcx
        dec     rdx
        shl     rdx, 3
        add     rdi, rdx
        add     rsi, rdx

        std
        rep     movsq
        cld

.1:
%ifdef WIN64
        pop     rsi
        pop     rdi
%endif
        next
endcode
