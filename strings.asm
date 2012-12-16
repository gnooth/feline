; Copyright (C) 2012 Peter Graves <gnooth@gmail.com>

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

code place, 'place'                     ; c-addr1 u c-addr2 --
        _ threedup
        _ oneplus
        _ swap
        _ move
        _ cstore
        _ drop
        next
endcode

code zplace, 'zplace'                   ; c-addr1 u c-addr2 --
        _ threedup
        _ swap
        _ move
        _ plus
        _ zero
        _ swap
        _ cstore
        _ drop
        next
endcode

code stringcomma, 'string,'             ; addr u --
        _ here
        _ over
        _ oneplus
        _ allot
        _ place
        next
endcode

dosliteral:
        pushrbx
        db      $48                     ; mov rbx, 0
        db      $0bb
        dq      0                       ; 64-bit immediate value (to be patched)
dosliteral_end:

code cliteral, 'cliteral', IMMEDIATE    ; c: addr1 u --         runtime: -- c-addr2
; not in standard
        _ here                          ; addr for counted string
        _ rrot                          ; -- here addr1 u
        _ stringcomma                   ; -- here
        _lit dosliteral
        _lit dosliteral_end - dosliteral
        _ paren_copy_code
        _ here_c
        _ cellminus
        _ store
        next
endcode

code sliteral, 'sliteral', IMMEDIATE    ; c: addr1 u --         runtime: -- c-addr2 u
; STRING
; "Interpretation semantics for this word are undefined."
        _ here                          ; addr for counted string
        _ rrot
        _ stringcomma
        _lit dosliteral
        _lit dosliteral_end - dosliteral
        _ paren_copy_code
        _ here_c
        _ cellminus
        _ store
        _lit count
        _ commacall
        next
endcode

code cquote, 'c"', IMMEDIATE
; CORE EXT
; "Interpretation semantics for this word are undefined."
        _lit '"'
        _ parse                         ; -- addr len
        _ state
        _fetch
        _if cquote1
        _ cliteral
        _else cquote1
        _ syspad
        _ place
        _ syspad
        _then cquote1
        next
endcode

code squote, 's"', IMMEDIATE
; CORE  FILE
        _lit '"'
        _ parse                         ; -- addr len
        _ state
        _fetch
        _if squote1
        _ sliteral
        _else squote1
        _ syspad
        _ place
        _ syspad
        _ count
        _then squote1
        next
endcode


code dotquote, '."', IMMEDIATE
        _ squote
        _lit type
        _ commacall
        next
endcode

code parenabortquote, '(abort")'        ; flag c-addr u --
        _ rot
        _if parenabortquote1
        _ ?cr
        _ type
        _ abort
        _else parenabortquote1
        _ twodrop
        _then parenabortquote1
        next
endcode

code abortquote, 'abort"', IMMEDIATE
; CORE
        _ squote
        _lit parenabortquote
        _ commacall
        next
endcode

code cmove, 'cmove'                     ; c-addr1 c-addr2 u --
        popd    rcx                     ; count
        popd    rdi                     ; destination
        popd    rsi                     ; source
        jrcxz   cmove2
        rep     movsb
cmove2:
        next
endcode

code cmoveup, 'cmove>'                  ; c-addr1 c-addr2 u --
        popd    rcx
        popd    rdi
        popd    rsi
        jrcxz   cmoveup2
cmoveup1:
        dec     rcx
        add     rdi, rcx
        add     rsi, rcx
        inc     rcx
        std
        rep     movsb
        cld
cmoveup2:
        next
endcode

code move, 'move'                       ; addr1 addr2 u --
        _ tor
        _ twodup
        _ ult
        _if move1
        _ rfrom
        _ cmoveup
        _else move1
        _ rfrom
        _ cmove
        _then move1
        next
endcode

code fill, 'fill'                       ; c-addr u char --
        mov     rax, rbx                ; char in AL
        mov     rcx, [rbp]              ; count in RCX
        mov     rdi, [rbp + BYTES_PER_CELL]
        mov     rbx, [rbp + BYTES_PER_CELL * 2]
        add     rbp, BYTES_PER_CELL * 3
        jrcxz   .1                      ; do nothing if count = 0
        rep     stosb
.1:
        next
endcode

code erase, 'erase'                     ; addr u --
        xor     al, al                  ; 0 in AL
        mov     rcx, rbx                ; count in RCX
        mov     rdi, [rbp]
        mov     rbx, [rbp + BYTES_PER_CELL]
        add     rbp, BYTES_PER_CELL * 2
        jrcxz   .1                      ; do nothing if count = 0
        rep     stosb
.1:
        next
endcode

code buffer_colon, 'buffer:'
        _ create
        _ allot
        next
endcode

code sequal, 's='                       ; addr1 addr2 len -- flag
        _ ?dup
        _if sequal1
        _ zero
        _do sequal2
        _ twodup
        _ i
        _ plus
        _ cfetch
        _ swap
        _ i
        _ plus
        _ cfetch
        _ notequal
        _if sequal3
        _ twodrop
        _ false
        _ unloop
        _return
        _then sequal3
        _loop sequal2
        _then sequal1
        _ twodrop
        _ true
        next
endcode

code upc, 'upc'
        cmp     rbx, 'a'
        jl      .1
        cmp     rbx, 'z'
        jg      .1
        sub     rbx, 'a' - 'A'
.1:
        next
endcode

code isequal, 'is='                     ; addr1 addr2 len -- flag
        _ ?dup
        _if isequal1
        _ zero
        _do isequal2
        _ twodup
        _ i
        _ plus
        _ cfetch
        _ swap
        _ i
        _ plus
        _ cfetch
        _ notequal
        _if isequal3
        _ twodup
        _ i
        _ plus
        _ cfetch
        _ upc
        _ swap
        _ i
        _ plus
        _ cfetch
        _ upc
        _ notequal
        _if isequal4
        _ twodrop
        _ false
        _ unloop
        _return
        _then isequal4
        _then isequal3
        _loop isequal2
        _then isequal1
        _ twodrop
        _ true
        next
endcode

code strequal, 'str='                   ; addr1 len1 addr2 len2 -- flag
        _ rot
        _ tuck
        _ notequal
        _if strequal1
        _ threedrop
        _ false
        _return
        _then strequal1
        _ sequal
        next
endcode

code istrequal, 'istr='                 ; addr1 len1 addr2 len2 -- flag
        _ rot                           ; -- addr1 addr2 len2 len1
        _ tuck                          ; -- addr1 addr2 len1 len2 len1
        _ notequal                      ; -- addr1 addr2 len1 flag
        _if istrequal1
        _ threedrop
        _ false
        _else istrequal1
        _ isequal
        _then istrequal1
        next
endcode

code slashstring, '/string'             ; c-addr1 u1 n -- c-addr2 u2
        sub     [rbp], rbx
        add     [rbp + BYTES_PER_CELL], rbx
        poprbx
        next
endcode

code count, 'count'                     ; c-addr -- c-addr+1 u
; CORE 6.1.0980
        mov     al, [rbx]
        inc     rbx
        pushrbx
        movzx   rbx, al
        next
endcode
