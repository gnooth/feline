; Copyright (C) 2012-2018 Peter Graves <gnooth@gmail.com>

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
code cmove, 'cmove', SYMBOL_INTERNAL    ; c-addr1 c-addr2 u --
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
code cmoveup, 'cmove>', SYMBOL_INTERNAL ; c-addr1 c-addr2 u --
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

; ### move_cells
subroutine move_cells
; arg0_register: untagged source address
; arg1_register: untagged destination address
; arg2_register: untagged count (cells, not bytes)
; handles overlapping moves correctly

        ; do nothing if count <= 0
        test    arg2_register, arg2_register
        jle     .exit

        cmp     arg0_register, arg1_register

        ; do nothing if source = destination
        jz      .exit

        ja      .2

        ; source < destination
        ; copy last cell first
.1:
        mov     rax, [arg0_register + BYTES_PER_CELL * arg2_register - BYTES_PER_CELL]
        mov     [arg1_register + BYTES_PER_CELL * arg2_register - BYTES_PER_CELL], rax
        sub     arg2_register, 1
        jnz     .1
        ret

.2:
        ; source > destination
        ; copy first cell first
        xor     eax, eax
.3:
        mov     r10, [arg0_register + rax * BYTES_PER_CELL]
        mov     [arg1_register + rax * BYTES_PER_CELL], r10
        add     rax, 1
        cmp     arg2_register, rax
        jne     .3

.exit:
        ret
endsub
