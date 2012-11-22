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

variable dp, 'dp', 0                    ; initialized in main()

; code (8 bytes) link (8 bytes) flag (1 byte) name (1-256 bytes)

code ntolink, 'n>link'
        sub     rbx, BYTES_PER_CELL + 1
        next
endcode

code ltoname, 'l>name'
        add     rbx, BYTES_PER_CELL + 1
        next
endcode

code linkfrom, 'link>'
        sub     rbx, BYTES_PER_CELL
        next
endcode

code toname, '>name'
        add     rbx, BYTES_PER_CELL * 2 + 1
        next
endcode

code namefrom, 'name>'
        sub     rbx, BYTES_PER_CELL * 2 + 1
        next
endcode

code tocode, '>code'
        mov     rbx, [rbx]
        next
endcode

code tobody, '>body'
        _ toname
        _ dup
        _ cfetch
        _ oneplus
        _ plus
        _lit 5                          ; length of CALL instruction
        _ plus
        next
endcode

code immediate, 'immediate'
        _ latest
        _ oneminus
        _lit 0x80
        _ swap
        _ cstore
        next
endcode

code immediate?, 'immediate?'           ; xt -- flag
        _ toname
        _ oneminus
        _ cfetch
        _ zne
        next
endcode

code recurse, 'recurse', IMMEDIATE
        _ latest
        _ namefrom
        _ tocode
        _ commacall
        next
endcode

code hide, 'hide'
        _ latest
        _ dup
        _ cfetch
        _lit $80
        _ or
        _ swap
        _ cstore
        next
endcode

code reveal, 'reveal'
        _ latest
        _ dup
        _ cfetch
        _lit $7f
        _ and
        _ swap
        _ cstore
        next
endcode

; REVIEW
code align_, 'align'                    ; --
; CORE
        next
endcode

; REVIEW
code aligned, 'aligned'                 ; addr -- a-addr
; CORE
        next
endcode

code comma, ','
        _ here
        _ store
        pushd   BYTES_PER_CELL
        _ dp
        _ plusstore
        next
endcode

code ccomma, 'c,'
        _ here
        _ cstore
        _ one
        _ dp
        _ plusstore
        next
endcode

code allot, 'allot'
        _ dp
        _ plusstore
        next
endcode

code header, 'header'                   ; --
        _ parse_name                    ; -- c-addr u
        _ here
        _ tor
        _ zero                          ; code field (will be patched)
        _ comma
        _ latest
        _ comma                         ; link
        _ zero                          ; flag
        _ ccomma                        ; -- c-addr u
        _ here
        _ last
        _ store                         ; -- c-addr u
        _ here                          ; -- c-addr u here
        _ over
        _ oneplus
        _ allot
        _ place
        ; patch code field
        _ here
        _ rfrom
        _ store
        next
endcode

code commacall, ',call'                 ; code-addr --
        pushd 0xe8
        _ ccomma
        _ here                          ; -- code-addr here
        add     rbx, 4
        _ minus                         ; 32-bit displacement in EBX
        popd    rax                     ; displacement in RAX ( -- )
        mov     rdx, [dp_data]          ; HERE
        mov     [rdx], eax              ; store 32-bit displacement
        add     rdx, 4                  ; 4 ALLOT
        mov     [dp_data], rdx
        next
endcode

code docreate, 'docreate'
        pushrbx
        pop     rbx
        ret
endcode

code create, 'create'                   ; "<spaces>name" --
        _ header
        pushd   docreate
        _ commacall
        next
endcode

code var, 'variable'
        _ create
        _ zero
        _ comma
        next
endcode

code doconstant, 'doconstant'
        pop     rax                     ; return address
        pushrbx
        mov     rbx, [rax]
        next
endcode

code constant, 'constant'
        _ header
        pushd   doconstant
        _ commacall
        _ comma
        next
endcode

code compilecomma, 'compile,'
        _ tocode
        _ commacall
        _ next
endcode

code colon, ':'
        _ header
        _ hide
        _ state
        _ on
        next
endcode

code colonnoname, ':noname'
        _ state
        _ on
        _ here
        _ dup
        _ cellplus
        _ comma
        next
endcode

code semi, ';', IMMEDIATE
        _lit 0xc3                       ; RET
        _ ccomma
        _ state
        _ off
        _ reveal
        next
endcode

code exit_, 'exit'
        _ rfrom
        _ drop
        next
endcode

code dotid, '.id'
        _ count
        _ type
        next
endcode

code ?line, '?line'                     ; n --
; F83
; "Move to left margin on next line if we will be past the right margin
; after printing n characters."
        _ nout
        _ fetch
        _ plus
        pushd 80                        ; REVIEW right margin
        _ gt
        _if ?line1
        _ cr
        _then ?line1
        next
endcode

code paren_scode, '(;code)'
        pop     rax                     ; return address
        inc     rax                     ; skip past ret to get to start of does> code
        pushd   rax                     ; -- does>-code
        _ latest                        ; -- does>-code nfa
        _ namefrom                      ; -- does>-code cfa
        _ tocode                        ; -- does>-code code-addr
        ; we want to patch this code with a call to the code after does>
        _ here
        _ tor                           ; -- does>-code code-addr       r: -- here
        _ dp
        _ store                         ; -- does>-code
        _ commacall
        _ rfrom
        _ dp
        _ store
        next
endcode

code does, 'does>', IMMEDIATE
        _lit paren_scode                ; postpone (;code)
        _ commacall
        _lit $0c3                       ; next,
        _ ccomma                        ; --
        _lit docreate
        _ here
        _lit 9
        _ dup
        _ allot
        _ cmove
        next
endcode

code here, 'here'
        _ dp
        _ fetch
        next
endcode

code pad, 'pad'
        _ here
        add     rbx, 512
        next
endcode

variable tick_syspad, "'syspad", 0

code syspad, 'syspad'
        pushrbx
        mov     rbx, [tick_syspad_data]
        next
endcode

code latest, 'latest'                   ; -- nfa
        _ last
        _ fetch
        next
endcode

code lit, '(lit)'
        pushrbx
        pop     rax                     ; return address
        mov     rbx, [rax]
        add     rax, BYTES_PER_CELL
        jmp     rax
endcode

code literal, 'literal', IMMEDIATE
        pushd   lit
        _ commacall
        _ comma
        next
endcode

code postpone, 'postpone', IMMEDIATE    ; "<spaces>name" --
; CORE 6.1.2033
; compilation only
        _ tick
        _ dup
        _ immediate?
        _if postpone1
        _ tocode
        _ commacall
        _else postpone1
        _ tocode
        _lit lit
        _ commacall
        _ comma
        _lit commacall
        _ commacall
        _then postpone1
        next
endcode

code words, 'words'
        _ zero
        _ tor
        _ latest
        _ dup
        _ dotid
        _ space
        _ rfrom
        _ oneplus
        _ tor
        _ ntolink
words_loop:
        _ fetch
        _ ?dup
        _if words1
        _ dup
        _ cfetch
        _ ?line
        _ dup
        _ dotid
        _ space
        _ rfrom
        _ oneplus
        _ tor
        _ ntolink
        jmp     words_loop
        _then words1
        _ cr
        _ rfrom
        _ dot
        _dotq "words"
        next
endcode
