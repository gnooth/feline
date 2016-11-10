; Copyright (C) 2012-2016 Peter Graves <gnooth@gmail.com>

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

; ### under+
code underplus, 'under+'                ; n1 n2 n3 -- n1+n3 n2
        add     [rbp + BYTES_PER_CELL], rbx
        poprbx
        next
endcode

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

; ### 0=
inline zeq, '0='
; CORE
        _zeq
endinline

; ### 0<>
inline zne, '0<>'
; CORE EXT
        _zne
endinline

; ### 0>
inline zgt, '0>'
; CORE EXT
        _zgt
endinline

; ### 0>=
code zge, '0>='
        _zge
        next
endcode

; ### 0<
inline zlt, '0<'
; CORE
        _zlt
endinline

; ### s>d
inline stod, 's>d'                      ; n -- d
; CORE
        _stod
endinline

; ### min
code min, 'min'                         ; n1 n2 -- n3
        popd    rax
        cmp     rax, rbx
        jge     .1
        mov     rbx, rax
.1:
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

; ### lshift
inline lshift, 'lshift'                 ; x1 u -- x2
; CORE
        mov     ecx, ebx
        poprbx
        shl     rbx, cl
endinline
