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

; ### $bufstart
value stringbuf_start, '$bufstart', 0   ; initialized in main()

; ### $bufend
code stringbuf_end, '$bufend'
        _ stringbuf_start
        _lit 1024
        _ plus
        next
endcode

; ### $buf
value stringbuf, '$buf', 0              ; initialized in main()

; ### +$buf
code plus_stringbuf, '+$buf'
        _ stringbuf
        _ count
        _ plus
        _oneplus
        mov     [stringbuf_data], rbx
        poprbx
        _ stringbuf
        _ stringbuf_end
        _lit 258
        _ minus
        _ ugt
        _if .1
        mov     rax, [stringbuf_start_data]
        mov     [stringbuf_data], rax
        _then .1
        next
endcode

; ### place
code place, 'place'                     ; c-addr1 u c-addr2 --
        _ twodup
        _ cstore
        _oneplus
        _ swap
        _ move
        next
endcode

; ### zplace
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

; ### zappend
code zappend, 'zappend'                 ; c-addr len zdest --
        _ zcount
        _ plus
        _ zplace
        next
endcode

; ### string,
code stringcomma, 'string,'             ; addr u --
        _ here
        _ over
        _ oneplus
        _ allot
        _ place
        ; REVIEW terminal null byte
        _ zero
        _ ccomma
        next
endcode

do_sliteral:
        pushrbx
        db      $48                     ; mov rbx, 0
        db      $0bb
        dq      0                       ; 64-bit immediate value (to be patched)
do_sliteral_end:

; ### cliteral
code cliteral, 'cliteral', IMMEDIATE    ; c: addr1 u --         runtime: -- c-addr2
; not in standard
        _ here                          ; addr for counted string
        _ rrot                          ; -- here addr1 u
        _ stringcomma                   ; -- here
        _lit do_sliteral
        _lit do_sliteral_end - do_sliteral
        _ paren_copy_code
        _ here_c
        _ cellminus
        _ store
        next
endcode

; ### sliteral
code sliteral, 'sliteral', IMMEDIATE    ; c: addr1 u --         runtime: -- c-addr2 u
; STRING
; "Interpretation semantics for this word are undefined."
        _ here                          ; addr for counted string
        _ rrot
        _ stringcomma
        _lit do_sliteral
        _lit do_sliteral_end - do_sliteral
        _ paren_copy_code
        _ here_c
        _ cellminus
        _ store
        _lit count
        _ commacall
        next
endcode

; ### c"
code cquote, 'c"', IMMEDIATE
; CORE EXT
; "Interpretation semantics for this word are undefined."
        _lit '"'
        _ parse                         ; -- addr len
        _ statefetch
        _if .1
        _ cliteral
        _else .1
        _ stringbuf
        _ place
        _ stringbuf
        _ plus_stringbuf
        _then .1
        next
endcode

; ### s"
code squote, 's"', IMMEDIATE
; CORE  FILE
        _lit '"'
        _ parse                         ; -- addr len
        _ statefetch
        _if .1
        _ sliteral
        _else .1
        _ stringbuf
        _ place
        _ stringbuf
        _ plus_stringbuf
        _ count
        _then .1
        next
endcode

; ### ."
code dotquote, '."', IMMEDIATE
        _ squote
        _lit type
        _ commacall
        next
endcode

; ### (abort")
code parenabortquote, '(abort")'        ; flag c-addr --
        _ swap
        _if parenabortquote1
        _ msg
        _ store
        _lit -2
        _ throw
        _else parenabortquote1
        _ drop
        _then parenabortquote1
        next
endcode

; ### abort"
code abortquote, 'abort"', IMMEDIATE
; CORE
        _ cquote
        _lit parenabortquote
        _ commacall
        next
endcode

; ### cmove
code cmove, 'cmove'                     ; c-addr1 c-addr2 u --
        popd    rcx                     ; count
        popd    rdi                     ; destination
        popd    rsi                     ; source
        jrcxz   cmove2
        rep     movsb
cmove2:
        next
endcode

; ### cmove>
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

; ### move
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

; ### fill
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

; ### erase
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

; ### buffer:
code buffer_colon, 'buffer:'
        _ create
        _ allot
        next
endcode

; ### compare
code compare, 'compare'                 ; c-addr1 u1 c-addr2 u2 -- n
; STRING
; adapted from Win32Forth
        mov     rdi, [rbp]                              ; c-addr2 in RDI
        mov     rcx, [rbp + BYTES_PER_CELL]             ; u1 in RCX
        mov     rsi, [rbp + BYTES_PER_CELL * 2]         ; c-addr1 in RSI
        mov     rdx, 1
        cmp     rcx, rbx                ; compare lengths
        cmova   rcx, rbx                ; compare shorter of the strings
        cmova   rbx, rdx                ; set string1 longer flag
        mov     rdx, 0
        cmove   rbx, rdx                ; strings equal lengths
        mov     rdx, -1
        cmovb   rbx, rdx                ; set string2 longer flag
        repz    cmpsb                   ; compare the strings
        mov     rsi, 1
        cmovb   rbx, rdx                ; string1 > string2
        cmova   rbx, rsi                ; string1 < string2
        lea     rbp, [rbp + BYTES_PER_CELL * 3]
        next
endcode

; ### s=
code sequal, 's='                       ; addr1 addr2 len -- flag
        _ ?dup
        _if sequal1
        _ zero
        _do sequal2
        _ twodup
        _i
        _ plus
        _ cfetch
        _ swap
        _i
        _ plus
        _ cfetch
        _ notequal
        _if sequal3
        _ twodrop
        _ false
        _unloop
        _return
        _then sequal3
        _loop sequal2
        _then sequal1
        _ twodrop
        _ true
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

; ### is=
code isequal, 'is='                     ; addr1 addr2 len -- flag
        _ ?dup
        _if isequal1
        _ zero
        _do isequal2
        _ twodup
        _i
        _ plus
        _ cfetch
        _ swap
        _i
        _ plus
        _ cfetch
        _ notequal
        _if isequal3
        _ twodup
        _i
        _ plus
        _ cfetch
        _ upc
        _ swap
        _i
        _ plus
        _ cfetch
        _ upc
        _ notequal
        _if isequal4
        _ twodrop
        _ false
        _unloop
        _return
        _then isequal4
        _then isequal3
        _loop isequal2
        _then isequal1
        _ twodrop
        _ true
        next
endcode

; ### str=
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

; ### istr=
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

; ### /string
code slashstring, '/string'             ; c-addr1 u1 n -- c-addr2 u2
        sub     [rbp], rbx
        add     [rbp + BYTES_PER_CELL], rbx
        poprbx
        next
endcode

; ### count
code count, 'count'                     ; c-addr -- c-addr+1 u
; CORE 6.1.0980
        mov     al, [rbx]
        inc     rbx
        pushrbx
        movzx   rbx, al
        next
endcode

; ### -trailing
code dashtrailing, '-trailing'          ; c-addr u1 -- c-addr u2
; STRING
        test    rbx, rbx
        jz      .2
        mov     rax, [rbp]
.1:
        cmp     byte [rax + rbx - 1], ' '
        jne     .2
        dec     rbx
        jnz     .1
.2:
        next
endcode

%if 0
code search, 'search'                   ; c-addr1 u1 c-addr2 u2 -- c-addr3 u3 flag
; STRING
; "Search the string specified by c-addr1 u1 for the string specified by c-addr2 u2.
; If flag is true, a match was found at c-addr3 with u3 characters remaining.
; If flag is false there was no match and c-addr3 is c-addr1 and u3 is u1."
        next
endcode
%endif
