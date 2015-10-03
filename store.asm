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

; ### !
code store, '!'                         ; n addr --
        mov     rax, [rbp]              ; n
        mov     [rbx], rax
        mov     rbx, [rbp + BYTES_PER_CELL]
        add     rbp, BYTES_PER_CELL * 2
        next
endcode

; ### c!
inline cstore, 'c!'                     ; c addr --
        mov     al, [rbp]               ; c
        mov     [rbx], al
        mov     rbx, [rbp + BYTES_PER_CELL]
        lea     rbp, [rbp + BYTES_PER_CELL * 2]
endinline

; ### l!
code lstore, 'l!'                       ; l addr --
        mov     eax, [rbp]              ; l
        mov     [rbx], eax
        mov     rbx, [rbp + BYTES_PER_CELL]
        lea     rbp, [rbp + BYTES_PER_CELL * 2]
        next
endcode

; ### +!
code plusstore, '+!'                    ; n addr --
        mov     rax, [rbp]
        add     [rbx], rax
        mov     rbx, [rbp + BYTES_PER_CELL]
        lea     rbp, [rbp + BYTES_PER_CELL * 2]
        next
endcode

; ### c+!
code cplusstore, 'c+!'                  ; byte addr --
        mov     al, byte [rbp]
        add     byte [rbx], al
        mov     rbx, [rbp + BYTES_PER_CELL]
        lea     rbp, [rbp + BYTES_PER_CELL * 2]
        next
endcode

; ### off
code off, 'off'                         ; addr --
        xor     eax, eax
        mov     [rbx], rax
        poprbx
        next
endcode

; ### on
code on, 'on'                           ; addr --
        mov     qword [rbx], -1
        poprbx
        next
endcode

; ### 2!
code twostore, '2!'                     ; x1 x2 a-addr --
; CORE
; "Store the cell pair x1 x2 at a-addr, with x2 at a-addr and x1 at the next
; consecutive cell."
        mov     rax, [rbp]                      ; x2
        mov     [rbx], rax                      ; store at a-addr
        mov     rax, [rbp + BYTES_PER_CELL]     ; x1
        mov     [rbx + BYTES_PER_CELL], rax     ; store at next consecutive cell
        mov     rbx, [rbp + BYTES_PER_CELL * 2]
        add     rbp, BYTES_PER_CELL * 3
        next
endcode
