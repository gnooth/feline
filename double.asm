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

code dplus, 'd+'                        ; d1|ud1 d2|ud2 -- d3|ud3
; DOUBLE 8.6.1.1040
        mov     rax, [rbp + BYTES_PER_CELL * 2]
        add     rax, [rbp]
        adc     rbx, [rbp + BYTES_PER_CELL]
        mov     [rbp + BYTES_PER_CELL * 2], rax
        lea     rbp, [rbp + BYTES_PER_CELL * 2]
        next
endcode

code dzeroequal, 'd0='                  ; xd -- flag
; DOUBLE
        mov     rax, [rbp]
        lea     rbp, [rbp + BYTES_PER_CELL]
        or      rbx, rax
        jz      dze1
        xor     rbx, rbx
        next
dze1:
        mov     rbx, -1
        next
endcode

code dequal, 'd='                       ; xd1 xd2 -- flag
; DOUBLE
; adapted from Win32Forth
        mov     rax, [rbp + BYTES_PER_CELL * 2]
        sub     rax, [rbp]
        sbb     rbx, [rbp + BYTES_PER_CELL]
        or      rbx, rax
        sub     rbx, 1
        sbb     rbx, rbx
        lea     rbp, [rbp + BYTES_PER_CELL * 3]
        next
endcode

code dabs, 'dabs'                       ; d -- ud
; DOUBLE
; gforth
        _ dup
        _zlt
        _if dabs1
        _ dnegate
        _then dabs1
        next
endcode

code dnegate, 'dnegate'                 ; d1 -- d2
; DOUBLE
        xor     rax, rax
        mov     rdx, rax
        sub     rdx, [rbp]
        sbb     rax, rbx
        mov     [rbp], rdx
        mov     rbx, rax
        next
endcode

