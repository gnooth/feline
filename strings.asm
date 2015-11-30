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

; ### $bufstart
value stringbuf_start, '$bufstart', 0   ; initialized in main()

; ### $bufend
value stringbuf_end, '$bufend', 0       ; initialized in main()

; ### $buf
value stringbuf, '$buf', 0              ; initialized in main()

; ### temp$
code tempstring, 'temp$'                ; -- $addr
; Returns the address of a temporary buffer big enough for the biggest
; counted string.
        _ stringbuf
        _duptor
        _lit 260                        ; count byte, 255 chars, terminal null byte (and round up)
        _ plus
        mov     [stringbuf_data], rbx
        poprbx
        _ stringbuf
        _ stringbuf_end
        _lit 260
        _ minus
        _ ugt
        _if .1
        mov     rax, [stringbuf_start_data]
        mov     [stringbuf_data], rax
        _then .1
        _zero
        _ stringbuf
        _ store
        _rfrom
        next
endcode

; ### +$buf
code plus_stringbuf, '+$buf'
; advance $buf past the string at $buf
        _ stringbuf
        _ count
        _ plus
        _oneplus                        ; terminal null byte
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
        _zero
        _ stringbuf
        _ store
        next
endcode

; ### $buf+
code stringbuf_plus, '$buf+'            ; -- $addr
        _ stringbuf                     ; leave the current value of $buf on the stack
        _ plus_stringbuf                ; advance the pointer past the current string
        next
endcode

; ### >temp$
code copy_to_temp_string, '>temp$'      ; c-addr u -- $addr
; copy the string at c-addr u to the temporary string area
; advance the temporary string pointer past the copied string
; return the address of the copied string
        _ stringbuf
        _ place_string
        _ stringbuf_plus
        next
endcode

; ### $>z
inline string_to_zstring, '$>z'         ; $addr -- zaddr
; skip over the count byte
        _string_to_zstring              ; 1+
endinline

; ### $!
code copystring, '$!'                   ; $addr1 $addr2 --
; Upper Deck Forth
; "Copies the packed, null-terminated string at $addr1 to $addr2. The buffer
; at $addr2 must be big enough to accept the string, including its length
; byte and terminal null byte."
        _ over
        _cfetch
        _twoplus
        _ move
        next
endcode

; ### $+
code appendstring, '$+'                 ; $addr1 $addr2 -- $addr3
; Upper Deck Forth
; "Appends the packed, null-terminated string at $addr2 (without its length
; byte) to the end of the packed, null-terminated string at $addr1 and places
; the resulting string at the next free location in the temporary string
; storage location. $addr3 is the address of that location."
        _ swap
        _ stringbuf
        _ copystring
        _ count
        _duptor
        _ stringbuf
        _ count
        _ plus
        _ swap
        _oneplus
        _ move
        _ stringbuf
        _cfetch
        _rfrom
        _ plus
        _ stringbuf
        _ cstore
        _ stringbuf
        _ plus_stringbuf
        next
endcode

; ### $place
code place_string, '$place'             ; c-addr u $addr --
        _ twodup
        _ cstore
        _duptor
        _oneplus
        _ swap
        _ move
        _zero
        _rfrom
        _ count
        _ plus
        _ cstore
        next
endcode

; ### >$
code save_string, '>$'                  ; c-addr u -- $addr
; copy the string specified by c-addr u to allocated storage
        _dup
        _if .1
        _dup
        _twoplus                        ; count byte, terminal null byte
        _ iallocate                     ; -- c-addr u $addr
        _duptor
        _ place_string
        _rfrom
        _else .1
        ; zero length
        _nip
        _then .1
        next
endcode

; ### $.
code counttype, '$.'                    ; $addr --
        _ count
        _ type
        next
endcode

; ### place
code place, 'place'                     ; c-addr1 u c-addr2 --
        _ place_string
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

; ### zappend
code zappend, 'zappend'                 ; c-addr len zdest --
        _ zcount
        _ plus
        _ zplace
        next
endcode

; ### string,
code stringcomma, 'string,'             ; addr u --
; not in standard
        _ here
        _ over
        _oneplus
        _ allot
        _ place
        ; terminal null byte
        _zero
        _ ccomma
        next
endcode

do_cliteral:
        pushrbx
        db      $48                     ; mov rbx, 0
        db      $0bb
        dq      0                       ; 64-bit immediate value (to be patched)
do_cliteral_end:

; ### cliteral
code cliteral, 'cliteral', IMMEDIATE    ; c: addr1 u --         runtime: -- c-addr2
; not in standard
        _ ?comp
        _ flush_compilation_queue
        _ here                          ; addr for counted string
        _ rrot                          ; -- here addr1 u
        _ stringcomma                   ; -- here
        _lit do_cliteral
        _lit do_cliteral_end - do_cliteral
        _ paren_copy_code
        _ here_c
        _cellminus
        _ store
        next
endcode

; ### sliteral-string,
code sliteral_stringcomma, 'sliteral-string,'   ; addr u --
; not in standard
        _ here
        _ over
        _ allot
        _ swap
        _ move
        ; terminal null byte
        _zero
        _ ccomma
        next
endcode

do_sliteral:
        lea     rbp, [rbp - BYTES_PER_CELL * 2]
        mov     [rbp + BYTES_PER_CELL], rbx
        db      $48
        db      $0bb
do_sliteral_end:

; ### sliteral
code sliteral, 'sliteral', IMMEDIATE    ; c: c-addr1 u --       runtime: -- c-addr2 u
; STRING
; "Interpretation semantics for this word are undefined."
        _ ?comp
        _ flush_compilation_queue
        _ here                          ; addr for counted string
        _ rrot                          ; -- here c-addr1 u
        _ twodup                        ; -- here c-addr1 u c-addr1 u
        _ sliteral_stringcomma          ; -- here c-addr1 u
        _ nip                           ; -- here u
        _ swap                          ; -- u here

        _lit do_sliteral
        _lit do_sliteral_end - do_sliteral
        _ paren_copy_code               ; -- u here

        _ commac                        ; -- u

        ; mov [rbp], rbx
        _ccommac $48
        _ccommac $89
        _ccommac $5d
        _ccommac 0

        _ccommac $48
        _ccommac $0bb
        _ commac

        next
endcode

; ### c"
code cquote, 'c"', IMMEDIATE
; CORE EXT
; "Interpretation semantics for this word are undefined."
        _lit '"'
        _ parse                         ; -- c-addr u
        _ statefetch
        _if .1
        _ cliteral
        _else .1
        _ copy_to_temp_string
        _then .1
        next
endcode

; ### $"
code dollarquote, '$"', IMMEDIATE       ; -- $addr
; Upper Deck Forth
; "Parses a string delimited by " from the input stream.
; Returns address of packed, null-terminated string."
        _lit '"'
        _ parse                         ; -- addr len
        _ statefetch
        _if .1
        _ cliteral
        _else .1
        _ copy_to_temp_string
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
        _ copy_to_temp_string
        _ count
        _then .1
        next
endcode

; ### ."
code dotquote, '."', IMMEDIATE
; CORE
; "Interpretation semantics for this word are undefined."
        _ ?comp
        _ flush_compilation_queue
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
; "Interpretation semantics for this word are undefined."
        _ ?comp
        _ flush_compilation_queue
        _ cquote
        _lit parenabortquote
        _ commacall
        next
endcode

; ### cmove
code cmove, 'cmove'                     ; c-addr1 c-addr2 u --
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
code cmoveup, 'cmove>'                  ; c-addr1 c-addr2 u --
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

; ### move
code move, 'move'                       ; addr1 addr2 u --
        _ tor
        _ twodup
        _ ult
        _if .1
        _ rfrom
        _ cmoveup
        _else .1
        _ rfrom
        _ cmove
        _then .1
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
code buffer_colon, 'buffer:'            ; u "<spaces>name" --
                                        ; Execution: -- a-addr
; CORE EXT
; "Reserve u address units at an aligned address. Contiguity of
; this region with any other region is undefined."
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

; ### mem=
code memequal, 'mem='                   ; addr1 addr2 len -- flag
        _ ?dup
        _if .1
        _zero
        _do .2
        _ twodup
        _i
        _ plus
        _ cfetch
        _ swap
        _i
        _ plus
        _ cfetch
        _ notequal
        _if .3
        _2drop
        _ false
        _unloop
        _return
        _then .3
        _loop .2
        _then .1
        _2drop
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

; ### upper
code upper, 'upper'                     ; c-addr1 u --
        _ ?dup
        _if .1
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
        _ ?dup
        _if isequal1
        _zero
        _do isequal2
        _ twodup
        _i
        _plus
        _cfetch
        _ swap
        _i
        _plus
        _cfetch
        _ notequal
        _if isequal3
        _ twodup
        _i
        _plus
        _cfetch
        _ upc
        _ swap
        _i
        _plus
        _cfetch
        _ upc
        _ notequal
        _if isequal4
        _2drop
        _ false
        _unloop
        _return
        _then isequal4
        _then isequal3
        _loop isequal2
        _then isequal1
        _2drop
        _ true
        next
endcode

; ### str=
code strequal, 'str='                   ; addr1 len1 addr2 len2 -- flag
        _ rot
        _ tuck
        _ notequal
        _if .1
        _3drop
        _ false
        _return
        _then .1
        _ memequal
        next
endcode

; ### istr=
code istrequal, 'istr='                 ; addr1 len1 addr2 len2 -- flag
        _ rot                           ; -- addr1 addr2 len2 len1
        _ tuck                          ; -- addr1 addr2 len1 len2 len1
        _ notequal                      ; -- addr1 addr2 len1 flag
        _if .1
        _3drop
        _ false
        _else .1
        _ isequal
        _then .1
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

; ### string-nth
code string_nth, 'string-nth'           ; index $addr -- char
; name from Factor, but slightly different behavior
; returns character at index, or 0 if index is out of range
        movzx   rax, byte [rbx]         ; length in rax
        mov     rdx, [rbp]              ; index in rdx
        lea     rbp, [rbp + BYTES_PER_CELL]     ; adjust stack
        cmp     rax, rdx
        jle     .1
        add     rbx, rdx
        mov     al, [rbx + 1]
        mov     rbx, rax
        ret
.1:
        ; index out of range
        xor     rbx, rbx
        next
endcode

; ### string-first-char
inline string_first_char, 'string-first-char'   ; $addr -- char
; returns char at index 0 (which is 0 if it's an empty string)
        movzx   rbx, byte [rbx + 1]
endinline

; ### string-last-char
code string_last_char, 'string-last-char'       ; $addr -- char
; returns last char of string (0 if the string is empty)
        movzx   rax, byte [rbx]         ; length in rax
        add     rbx, rax
        movzx   rbx, byte [rbx]
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
