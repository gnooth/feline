; Copyright (C) 2012-2013 Peter Graves <gnooth@gmail.com>

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

code unused, 'unused'                   ; -- u
; CORE EXT
        _ limit
        _fetch
        _ dp
        _fetch
        _ minus
        next
endcode

code dotused, '.used'                   ; u --
        _lit 8
        _ udotr
        _dotq " bytes used"
        next
endcode

code dotfree, '.free'                   ; u --
        _lit 12
        _ udotr
        _dotq " bytes free"
        next
endcode

code room, 'room'
        _ ?cr
        _dotq "code: "
        _ here_c
        _ origin_c
        _fetch
        _ minus
        _ dotused
        _ limit_c
        _fetch
        _ here_c
        _ minus
        _ dotfree
        _ cr
        _dotq "data: "
        _ here
        _ origin
        _fetch
        _ minus
        _ dotused
        _ limit
        _fetch
        _ here
        _ minus
        _ dotfree
        next
endcode

; Header layout:
;   code ptr    8 bytes
;   comp field  8 bytes
;   link ptr    8 bytes
;   flags       1 byte
;   inline      1 byte          number of bytes of code to copy
;   name        1-256 bytes
;   padding     0-7 bytes       for alignment
;   body

code tocomp, '>comp'
        add     rbx, BYTES_PER_CELL
        next
endcode

code tocompstore, '>comp!'              ; xt1 xt2 --
        _ tocomp
        _ store
        next
endcode

code ntolink, 'n>link'
        sub     rbx, BYTES_PER_CELL + 2
        next
endcode

code ltoname, 'l>name'
        add     rbx, BYTES_PER_CELL + 2
        next
endcode

code tolink, '>link'
        add     rbx, BYTES_PER_CELL * 2
        next
endcode

code linkfrom, 'link>'
        sub     rbx, BYTES_PER_CELL * 2
        next
endcode

code toflags, '>flags'                  ; xt -- addr
        add     rbx, BYTES_PER_CELL * 3
        next
endcode

code flags, 'flags'                     ; xt -- flags
        _ toflags
        _ cfetch
        next
endcode

code toinline, '>inline'                ; xt -- addr
        add     rbx, BYTES_PER_CELL * 3 + 1
        next
endcode

code toname, '>name'
        add     rbx, BYTES_PER_CELL * 3 + 2
        next
endcode

code namefrom, 'name>'
        sub     rbx, BYTES_PER_CELL * 3 + 2
        next
endcode

code nametoflags, 'n>flags'
        sub     rbx, 2
        next
endcode

code tocode, '>code'
        mov     rbx, [rbx]
        next
endcode

code tobody, '>body'
        _ toname
        _ dup
        _cfetch
        _ oneplus
        _ plus
        _ aligned
        next
endcode

code immediate, 'immediate'
        _ latest
        _ nametoflags
        _ dup
        _cfetch
        _lit IMMEDIATE
        _ or
        _ swap
        _ cstore
        next
endcode

code immediate?, 'immediate?'           ; xt -- flag
        _ flags
        _lit IMMEDIATE
        _ and
        _ zne
        next
endcode

code inline?, 'inline?'                 ; xt -- flag
        _ toinline
        _cfetch
        _ zne
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

code comma, ','
        _ here
        _ store
        _ cell
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

code commac, ',c'
        _ here_c
        _ store
        _ cell
        _ cp
        _ plusstore
        next
endcode

code ccommac, 'c,c'
        _ here_c
        _ cstore
        _ one
        _ cp
        _ plusstore
        next
endcode

code allot_c, 'allot-c'
        _ cp
        _ plusstore
        next
endcode

code header, 'header'                   ; --
        _ parse_name                    ; -- c-addr u
        _ zero                          ; code field (will be patched)
        _ comma
        _ zero                          ; comp field
        _ comma
        _ current
        _ fetch                         ; -- c-addr u wid
        _ fetch                         ; -- c-addr u link
        _ comma
        _ zero                          ; flag
        _ ccomma                        ; -- c-addr u
        _ zero
        _ ccomma                        ; inline size
        _ here
        _ last
        _ store                         ; -- c-addr u
        _ here
        _ current
        _ fetch
        _ store
        _ here                          ; -- c-addr u here
        _ over
        _ oneplus
        _ allot
        _ place
        next
endcode

code lcomma, 'l,'                       ; x --
; 32-bit store, increment DP
        mov     rax, [dp_data]
        mov     [rax], ebx
        add     rax, 4
        mov     [dp_data], rax
        poprbx
        next
endcode

code lcommac, 'l,c'                     ; x --
; 32-bit store, increment DP
        mov     rax, [cp_data]
        mov     [rax], ebx
        add     rax, 4
        mov     [cp_data], rax
        poprbx
        next
endcode

code commacall, ',call'                 ; code --
        _lit $0e8
        _ ccommac
        _ here_c                        ; -- code here
        add     rbx, 4                  ; -- code here+4
        _ minus                         ; -- displacement
        _ lcommac
        next
endcode

code commajmp, ',jmp'                   ; code --
        _lit $0e9
        _ ccommac
        _ here_c                        ; -- code here
        add     rbx, 4                  ; -- code here+4
        _ minus                         ; -- displacement
        _ lcommac
        next
endcode

code align_data, 'align'
        _begin align1
        _ here
        _lit 8
        _ mod
        _while align1
        _ zero
        _ ccomma
        _repeat align1
        next
endcode

; REVIEW
code aligned, 'aligned'                 ; addr -- a-addr
; CORE
        add     rbx, 7
        and     rbx, -8
        next
endcode

section .text
dovariable:
        pushrbx
        db      $48                     ; mov rbx, 0
        db      $0bb
        dq      0                       ; 64-bit immediate value (to be patched)
dovariable_end:

code create, 'create'                   ; "<spaces>name" --
        _ header
        _ align_data
        _ here_c
        _ latest
        _ namefrom
        _ store
        _lit dovariable
        _lit dovariable_end - dovariable
        _ paren_copy_code
        _ here                          ; -- addr
        _ here_c
        _ cellminus
        _ store
        _lit $0c3
        _ ccommac
        next
endcode

code var, 'variable'
        _ create
        _ zero
        _ comma
        next
endcode

code twovar, '2variable'
        _ create
        _ zero
        _ comma
        _ zero
        _ comma
        next
endcode

section .text
doconst:
        pushrbx
        db      $48                     ; mov rbx, 0
        db      $0bb
        dq      0                       ; 64-bit immediate value (to be patched)
doconst_end:

code constant, 'constant'               ; x "<spaces>name" --
; CORE
        _ header                        ; -- x
        _ here_c
        _ latest
        _ namefrom
        _ store                         ; -- x
        _lit doconst
        _lit doconst_end - doconst
        _ paren_copy_code               ; -- x
        _ here_c
        _ cellminus
        _ store                         ; --
        _lit $0c3
        _ ccommac
        next
endcode

code paren_copy_code, '(copy-code)'     ; addr size --
        _ here_c
        _ over
        _ allot_c
        _ swap
        _ cmove
        next
endcode

code copy_code, 'copy-code'             ; xt --
        _ dup                           ; -- xt xt
        _ toinline                      ; -- xt addr
        _ cfetch                        ; -- xt size
        _ swap
        _ tocode
        _ swap                          ; -- code size
        _ paren_copy_code
        next
endcode

variable optimizing?, 'optimizing?', -1

code plusopt, '+opt'
        mov     qword [optimizing?_data], -1
        next
endcode

code minusopt, '-opt'
        mov     qword [optimizing?_data], 0
        next
endcode

code parencompilecomma, '(compile,)'    ; xt --
; CORE EXT
; "Interpretation semantics for this word are undefined."
        _ optimizing?
        _fetch
        _if compilecomma1               ; -- xt
        _ dup                           ; -- xt xt
        _ tocomp                        ; -- xt >comp
        _fetch                          ; -- xt ct
        _ ?dup
        _if compilecomma2
        _ execute
        _return
        _then compilecomma2             ; -- xt
        _ dup                           ; -- xt xt
        _ toinline                      ; -- xt >inline
        _cfetch                         ; -- xt #bytes
        _if compilecomma3
        _ copy_code
        _return
        _then compilecomma3
        _then compilecomma1
        ; not optimizing
        _ tocode
        _ commacall
        next
endcode

deferred compilecomma, 'compile,', parencompilecomma

variable last_code, 'last-code', 0

variable csp, 'csp', 0

code storecsp, '!csp'
        mov     [csp_data], rbp
        next
endcode

code ?csp, '?csp'
        cmp     [csp_data], rbp
        je      .1
        _abortq "Stack changed"
.1:
        next
endcode

code colon, ':'
        _ header
        _ hide
        _ here_c
        _ dup
        _ last_code
        _ store
        _ latest
        _ namefrom
        _ store
        _ rbrack
        _ storecsp
        next
endcode

code colonnoname, ':noname'
        _ rbrack
        _ here                          ; address of xt to be created
        _ here_c                        ; code address
        _ dup
        _ last_code
        _ store
        _ comma
        _ zero                          ; comp field
        _ comma
        _ storecsp
        next
endcode

code semi, ';', IMMEDIATE
        _ ?csp
        _lit $0c3                       ; RET
        _ ccommac
        _ lbrack
        _ reveal
        next
endcode

code recurse, 'recurse', IMMEDIATE
        _ last_code
        _fetch
        _ commacall
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
        _ space
        next
endcode

code ?line, '?line'                     ; n --
; F83
; "Move to left margin on next line if we will be past the right margin
; after printing n characters."
        _ nout
        _fetch
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
        inc     rax                     ; skip past RET to get to start of DOES> code
        pushd   rax                     ; -- does>-code
        _ latest
        _ namefrom
        _ tocode
        _lit dovariable_end - dovariable
        _ plus
        _ cp
        _ store
        _ commacall
        _lit $0c3
        _ ccommac
        next
endcode

code does, 'does>', IMMEDIATE
        _lit paren_scode                ; postpone (;code)
        _ commacall
        _lit $0c3                       ; next,
        _ ccommac                       ; --
        next
endcode

code here, 'here'
        _ dp
        _fetch
        next
endcode

code here_c, 'here-c'
        _ cp
        _fetch
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
        _fetch
        next
endcode

section .text
push_tos:
        pushrbx
push_tos_end:

; REVIEW
code push_tos_comma, 'push-tos,'
        _lit push_tos
        _lit push_tos_end - push_tos
        _ paren_copy_code
        next
endcode

code literal, 'literal', IMMEDIATE
        _ push_tos_comma
        _lit $48
        _ ccommac
        _lit $0bb
        _ ccommac
        _ commac
        next
endcode

; REVIEW
code mov_tos_comma, 'mov-tos,'      ; compilation: x --
        _lit $48
        _ ccommac
        _lit $0bb
        _ ccommac
        _ commac
        next
endcode

code parentwoliteral, '(2literal)'      ; addr -- d
        _ twofetch
        next
endcode

code twoliteral, '2literal', IMMEDIATE  ; compilation: x1 x2 --         run-time: -- x1 x2
; DOUBLE
; "Interpretation semantics for this word are undefined."
        _ here
        _ rrot
        _ comma
        _ comma
        _ push_tos_comma
        _ mov_tos_comma
        _lit parentwoliteral
        _ commacall
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
        _ literal
        _lit commacall
        _ commacall
        _then postpone1
        next
endcode

code bracketcompile, '[compile]', IMMEDIATE
        _ tick
        _ compilecomma
        next
endcode

code words, 'words'
        _ zero
        _ tor
        _ latest
        _ dup
        _ dotid
        _ rfrom
        _ oneplus
        _ tor
        _ ntolink
words_loop:
        _fetch
        _ ?dup
        _if words1
        _ dup
        _ cfetch
        _ ?line
        _ dup
        _ dotid
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
