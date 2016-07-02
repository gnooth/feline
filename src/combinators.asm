; Copyright (C) 2016 Peter Graves <gnooth@gmail.com>

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

; ### dip
code dip, 'dip'                         ; x quot -- x
; Removes x, calls quot, restores x to top of stack after quot returns.
        _ callable_code_address         ; code address in rbx
        mov     rax, [rbp]              ; x in rax
        push    rax
        mov     rax, rbx
        mov     rbx, [rbp + BYTES_PER_CELL]
        lea     rbp, [rbp + BYTES_PER_CELL * 2]
        call    rax
        pushrbx
        pop     rbx
        next
endcode

; ### keep
code keep, 'keep'                       ; .. x quot -- .. x
; Factor
; "Call a quotation with a value on the stack, restoring the value when
; the quotation returns."
        _ callable_code_address         ; code address in rbx
        mov     rax, rbx                ; code address in rax
        poprbx
        push    rbx
        call    rax
        pushrbx
        pop     rbx
        next
endcode

; ### bi@
code bi_at, 'bi@'                       ; x y quot --
; Applies quotation to x, then to y.
; Quotation must have stack effect ( obj -- ... ).
        push    r12                     ; save non-volatile register
        _ callable_code_address
        mov     r12, rbx                ; address to call in r12
        mov     rax, [rbp]              ; y in rax
        mov     rbx, [rbp + BYTES_PER_CELL]
        lea     rbp, [rbp + BYTES_PER_CELL * 2] ; -- x
        push    rax                     ; save y
        call    r12
        pushrbx
        pop     rbx                     ; -- y
        call    r12
        pop     r12
        next
endcode
