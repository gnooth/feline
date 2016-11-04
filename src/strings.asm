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

; ### zstrlen
code zstrlen, 'zstrlen'                 ; zaddr -- len
        mov     rcx, rbx
.1:
        mov     al, [rbx]
        test    al, al
        jz      .2
        inc     rbx
        jmp     .1
.2:
        sub     rbx, rcx
        next
endcode

; ### zcount
code zcount, 'zcount'                   ; zaddr -- zaddr len
        _dup
        _ zstrlen
        next
endcode

; ### erase
code erase, 'erase'                     ; addr u --
; CORE EXT
%ifdef WIN64
        push    rdi                     ; rdi is callee-saved on Windows
%endif
        xor     al, al                  ; 0 in al
        mov     rcx, rbx                ; count in rcx
        mov     rdi, [rbp]
        mov     rbx, [rbp + BYTES_PER_CELL]
        lea     rbp, [rbp + BYTES_PER_CELL * 2]
        jrcxz   .1                      ; do nothing if count = 0
        rep     stosb
.1:
%ifdef WIN64
        pop     rdi
%endif
        next
endcode

; ### mem=
code memequal, 'mem='                   ; addr1 addr2 len -- flag
        mov     rcx, rbx
        mov     rdi, [rbp]
        mov     rsi, [rbp + BYTES_PER_CELL]
        lea     rbp, [rbp + BYTES_PER_CELL * 2]
        jrcxz   .1
        repe    cmpsb
        jne     .2
.1:
        mov     rbx, -1
        next
.2:
        xor     ebx, ebx
        next
endcode

; ### str=
code strequal, 'str='                   ; addr1 len1 addr2 len2 -- flag
        cmp     rbx, [rbp + BYTES_PER_CELL]
        jz      .1
        lea     rbp, [rbp + BYTES_PER_CELL * 3]
        xor     ebx, ebx
        next
.1:
        ; lengths match                 ; -- addr1 len1 addr2 len2
        _dropswap                       ; -- addr1 addr2 len1
        _ memequal
        next
endcode

; ### count
inline count, 'count'                   ; c-addr -- c-addr+1 u
; CORE 6.1.0980
        _count
endinline
