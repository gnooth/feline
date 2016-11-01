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

; ### $.
code counttype, '$.'                    ; $addr --
        _ count
        _ type
        next
endcode

; ### place
code place, 'place'                     ; c-addr1 u c-addr2 --
%ifdef WIN64
        ; rsi and rdi are callee saved on Windows but not on Linux
        push    rsi
        push    rdi
%endif
        mov     rdi, rbx                ; destination in rdi
        mov     rcx, [rbp]              ; length in rcx
        mov     rsi, [rbp + BYTES_PER_CELL]     ; source in rsi
        mov     al, cl
        stosb                           ; store count byte
        jrcxz   .1
        rep     movsb
.1:
        xor     al, al                  ; terminal null byte
        stosb
        mov     rbx, [rbp + BYTES_PER_CELL * 2]
        lea     rbp, [rbp + BYTES_PER_CELL * 3]
%ifdef WIN64
        pop     rdi
        pop     rsi
%endif
        next
endcode

; ### zplace
code zplace, 'zplace'                   ; c-addr1 u c-addr2 --
        _ threedup
        _ swap
        _ move
        _ plus
        _zero
        _ swap
        _ cstore
        _ drop
        next
endcode

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

; ### (abort")
code parenabortquote, '(abort")'        ; flag c-addr --
        _drop
        _if .1
        _lit -2
        _ forth_throw
        _then .1
        next
endcode

; ### fill
code fill, 'fill'                       ; c-addr u char --
; CORE
%ifdef WIN64
        push    rdi                     ; rdi is callee-saved on Windows
%endif
        mov     rax, rbx                ; char in al
        mov     rcx, [rbp]              ; count in rcx
        mov     rdi, [rbp + BYTES_PER_CELL]
        mov     rbx, [rbp + BYTES_PER_CELL * 2]
        lea     rbp, [rbp + BYTES_PER_CELL * 3]
        jrcxz   .1                      ; do nothing if count = 0
        rep     stosb
.1:
%ifdef WIN64
        pop     rdi
%endif
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

; ### blank
code blank, 'blank'                     ; addr u --
; STRING
        _ blchar
        _ fill
        next
endcode

; ; ### compare
; code compare, 'compare'                 ; c-addr1 u1 c-addr2 u2 -- n
; ; STRING
; ; adapted from Win32Forth
;         mov     rdi, [rbp]                              ; c-addr2 in RDI
;         mov     rcx, [rbp + BYTES_PER_CELL]             ; u1 in RCX
;         mov     rsi, [rbp + BYTES_PER_CELL * 2]         ; c-addr1 in RSI
;         mov     rdx, 1
;         cmp     rcx, rbx                ; compare lengths
;         cmova   rcx, rbx                ; compare shorter of the strings
;         cmova   rbx, rdx                ; set string1 longer flag
;         mov     rdx, 0
;         cmove   rbx, rdx                ; strings equal lengths
;         mov     rdx, -1
;         cmovb   rbx, rdx                ; set string2 longer flag
;         repz    cmpsb                   ; compare the strings
;         mov     rsi, 1
;         cmovb   rbx, rdx                ; string1 > string2
;         cmova   rbx, rsi                ; string1 < string2
;         lea     rbp, [rbp + BYTES_PER_CELL * 3]
;         next
; endcode

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

; ### upc
code upc, 'upc'
        cmp     rbx, 'a'
        jl      .1
        cmp     rbx, 'z'
        jg      .1
        sub     rbx, 'a' - 'A'
.1:
        next
endcode

; ### upper
code upper, 'upper'                     ; c-addr1 u --
        _?dup_if .1
        _ bounds
        _do .2
        _i
        _ cfetch
        _ upc
        _i
        _ cstore
        _loop .2
        _else .1
        _ drop
        _then .1
        next
endcode

; ### is=
code isequal, 'is='                     ; addr1 addr2 len -- flag
        _?dup_if .1
        _zero
        _do .2
        _twodup
        _i
        _plus
        _cfetch
        _swap
        _i
        _plus
        _cfetch
        _notequal
        _if .3
        _twodup
        _i
        _plus
        _cfetch
        _ upc
        _swap
        _i
        _plus
        _cfetch
        _ upc
        _notequal
        _if .4
        _2drop
        _false
        _unloop
        _return
        _then .4
        _then .3
        _loop .2
        _then .1
        _2drop
        _true
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

; ### istr=
code istrequal, 'istr='                 ; addr1 len1 addr2 len2 -- flag
        ; compare lengths
        cmp     rbx, [rbp + BYTES_PER_CELL]
        jz .1
        lea     rbp, [rbp + BYTES_PER_CELL * 3]
        xor     ebx, ebx
        next
.1:
        ; lengths match                 ; -- addr1 len1 addr2 len2
        _dropswap                       ; -- addr1 addr2 len1
        _ isequal
        next
endcode

; ### /string
inline slashstring, '/string'           ; c-addr1 u1 n -- c-addr2 u2
; STRING 17.6.1.0245
        _slashstring
endinline

; ### count
inline count, 'count'                   ; c-addr -- c-addr+1 u
; CORE 6.1.0980
        _count
endinline
