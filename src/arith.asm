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

; ### >
inline gt, '>'                          ; n1 n2 -- flag
        cmp     [rbp], rbx
        setg    bl
        neg     bl
        movsx   rbx, bl
        lea     rbp, [rbp + BYTES_PER_CELL]
endinline

; ### >=
inline ge, '>='                         ; n1 n2 -- flag
        cmp     [rbp], rbx
        setge   bl
        neg     bl
        movsx   rbx, bl
        lea     rbp, [rbp + BYTES_PER_CELL]
endinline

; ### <=
inline le, '<='                         ; n1 n2 -- flag
        cmp     [rbp], rbx
        setle   bl
        neg     bl
        movsx   rbx, bl
        lea     rbp, [rbp + BYTES_PER_CELL]
endinline

; ### u<
inline ult, 'u<'
; CORE
        _ult
endinline

; ### u>
inline ugt, 'u>'
; CORE EXT
        _ugt
endinline

; ### within
code within, 'within'                   ; n min max -- flag
; CORE EXT
; return true if min <= n < max
; implementation adapted from Win32Forth
        mov     rax, [rbp]
        mov     rdx, [rbp + BYTES_PER_CELL]
        sub     rbx, rax
        sub     rdx, rax
        lea     rbp, [rbp + BYTES_PER_CELL * 2]
        sub     rdx, rbx
        sbb     rbx, rbx
        next
endcode

; ### between
code between, 'between'                 ; n min max -- flag
; return true if min <= n <= max
; implementation adapted from Win32Forth
        _oneplus
        mov     rax, [rbp]
        mov     rdx, [rbp + BYTES_PER_CELL]
        sub     rbx, rax
        sub     rdx, rax
        lea     rbp, [rbp + BYTES_PER_CELL * 2]
        sub     rdx, rbx
        sbb     rbx, rbx
        next
endcode

; ### max
code max, 'max'                         ; n1 n2 -- n3
        popd    rax
        cmp     rax, rbx
        jle     .1
        mov     rbx, rax
.1:
        next
endcode
