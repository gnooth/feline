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

; ### unused
code unused, 'unused'                   ; -- u
; CORE EXT
        _ limit
        _fetch
        _ dp
        _fetch
        _ minus
        next
endcode

; ### .used
code dotused, '.used'                   ; u --
        _lit 8
        _ udotr
        _dotq " bytes used"
        next
endcode

; ### .free
code dotfree, '.free'                   ; u --
        _lit 12
        _ udotr
        _dotq " bytes free"
        next
endcode

; ### room
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

; Header layout in code area:
;   code ptr    8 bytes
;   comp field  8 bytes
;   link ptr    8 bytes
;   data ptr    8 bytes         REVIEW addr for >body
;   flags       1 byte
;   inline      1 byte          number of bytes of code to copy
;   name        1-256 bytes
;   padding     0-7 bytes       for alignment
;   body is in data area

; ### >comp
code tocomp, '>comp'
        add     rbx, BYTES_PER_CELL
        next
endcode

; ### >comp!
code tocompstore, '>comp!'              ; xt1 xt2 --
        _ tocomp
        _ store
        next
endcode

; ### n>link
inline ntolink, 'n>link'
        _ntolink
endinline

; ### l>name
code ltoname, 'l>name'
        add     rbx, BYTES_PER_CELL * 4 + 2
        next
endcode

; ### >link
code tolink, '>link'
        add     rbx, BYTES_PER_CELL * 2
        next
endcode

; ### link>
code linkfrom, 'link>'
        sub     rbx, BYTES_PER_CELL * 2
        next
endcode

; ### >body
code tobody, '>body'                    ; xt -- a-addr
; CORE
; "a-addr is the data-field address corresponding to xt. An ambiguous condition
; exists if xt is not for a word defined via CREATE."
; "Rationale:a-addr is the address that HERE would have returned had it been
; executed immediately after the execution of the CREATE that defined xt."
        add     rbx, BYTES_PER_CELL * 3
        mov     rbx, [rbx]
        next
endcode

; ### >flags
code toflags, '>flags'                  ; xt -- addr
        add     rbx, BYTES_PER_CELL * 4
        next
endcode

; ### flags
code flags, 'flags'                     ; xt -- flags
        _ toflags
        _ cfetch
        next
endcode

; ### >inline
code toinline, '>inline'                ; xt -- addr
        add     rbx, BYTES_PER_CELL * 4 + 1
        next
endcode

; ### >view
code toview, '>view'                    ; xt -- addr
        add     rbx, BYTES_PER_CELL * 4 + 2
        next
endcode

; ### >name
code toname, '>name'
        add     rbx, BYTES_PER_CELL * 6 + 2
        next
endcode

; ### name>
code namefrom, 'name>'
        sub     rbx, BYTES_PER_CELL * 6 + 2
        next
endcode

; ### n>flags
code nametoflags, 'n>flags'
        sub     rbx, BYTES_PER_CELL * 2 + 2
        next
endcode

; ### >code
code tocode, '>code'
        mov     rbx, [rbx]
        next
endcode

; ### immediate
code immediate, 'immediate'
        _ latest
        _ nametoflags
        _dup
        _cfetch
        _lit IMMEDIATE
        _ or
        _ swap
        _ cstore
        next
endcode

; ### immediate?
code immediate?, 'immediate?'           ; xt -- flag
        _ flags
        _lit IMMEDIATE
        _ and
        _ zne
        next
endcode

; ### inline?
code inline?, 'inline?'                 ; xt -- flag
        _ toinline
        _cfetch
        _ zne
        next
endcode

; ### hide
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

; ### reveal
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

; ### ,
code comma, ','
        _ here
        _ store
        _ cell
        _ dp
        _ plusstore
        next
endcode

; ### c,
code ccomma, 'c,'
        _ here
        _ cstore
        _ one
        _ dp
        _ plusstore
        next
endcode

; ### allot
code allot, 'allot'                     ; n --
; CORE
        _ dp
        _ plusstore
        next
endcode

; ### ,c
code commac, ',c'
        _ here_c
        _ store
        _ cell
        _ cp
        _ plusstore
        next
endcode

; ### c,c
code ccommac, 'c,c'
        _ here_c
        _ cstore
        _ one
        _ cp
        _ plusstore
        next
endcode

; ### allot-c
code allot_c, 'allot-c'
        _ cp
        _ plusstore
        next
endcode

; ### header
code header, 'header'                   ; "spaces<name>" --
        _ parse_name                    ; -- c-addr u
        _ quoteheader
        next
endcode

; ### "header
code quoteheader, '"header'             ; c-addr u --
        _ zero                          ; code field (will be patched)
        _ commac
        _ zero                          ; comp field
        _ commac
        _ current
        _ fetch                         ; -- c-addr u wid
        _ fetch                         ; -- c-addr u link
        _ commac

        _ align_data
        _ here                          ; data field address for >body
        _ commac

        _ zero                          ; flag
        _ ccommac                       ; -- c-addr u
        _ zero
        _ ccommac                       ; inline size

        _ source_filename
        _fetch
        _ commac
        _ source_line_number
        _fetch
        _ commac

        _ here_c
        _ last
        _ store                         ; -- c-addr u
        _ here_c
        _ current
        _ fetch
        _ store
        _ here_c                        ; -- c-addr u here
        _ over
        _ oneplus
        _ allot_c
        _ place
        next
endcode

; ### l,
code lcomma, 'l,'                       ; x --
; 32-bit store, increment DP
        mov     rax, [dp_data]
        mov     [rax], ebx
        add     rax, 4
        mov     [dp_data], rax
        poprbx
        next
endcode

; ### l,c
code lcommac, 'l,c'                     ; x --
; 32-bit store, increment DP
        mov     rax, [cp_data]
        mov     [rax], ebx
        add     rax, 4
        mov     [cp_data], rax
        poprbx
        next
endcode

; ### align
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
; ### aligned
code aligned, 'aligned'                 ; addr -- a-addr
; CORE
        add     rbx, 7
        and     rbx, -8
        next
endcode

section .text
docreate:
        pushrbx
        db      $48                     ; mov rbx, 0
        db      $0bb
        dq      0                       ; 64-bit immediate value (to be patched)
docreate_end:

; ### (create)
code paren_create, '(create)'
        _ align_data
        _ here_c
        _ latest
        _ namefrom
        _ store
        _lit docreate
        _lit docreate_end - docreate
        _ paren_copy_code
        _ here                          ; -- addr
        _ here_c
        _ cellminus
        _ store
        _lit $0c3
        _ ccommac
        next
endcode

; ### create
code create, 'create'                   ; "<spaces>name" --
        _ header
        _ paren_create
        next
endcode

; ### "create
code quotecreate, '"create'
        _ quoteheader
        _ paren_create
        next
endcode

; ### variable
code var, 'variable'
        _ create
        _ zero
        _ comma
        next
endcode

; ### 2variable
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

; ### constant
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

; ### 2constant
code twoconstant, '2constant'           ; x1 x2 "<spaces>name" --
; DOUBLE
        _ header                        ; -- x1 x2
        _ here_c
        _ latest
        _ namefrom
        _ store                         ; -- x1 x2
        _lit doconst
        _lit doconst_end - doconst
        _ paren_copy_code               ; -- x1 x2
        _ swap                          ; -- x2 x1
        _ here_c
        _ cellminus
        _ store                         ; -- x2
        _lit doconst
        _lit doconst_end - doconst
        _ paren_copy_code               ; -- x2
        _ here_c
        _ cellminus
        _ store                         ; --
        _lit $0c3
        _ ccommac
        next
endcode

; ### recurse
code recurse, 'recurse', IMMEDIATE
        _ last_code
        _fetch
        _ commacall
        next
endcode

; ### exit
code exit_, 'exit'
        _ rfrom
        _ drop
        next
endcode

; ### .id
code dotid, '.id'
        _ count
        _ type
        _ space
        next
endcode

; ### ?line
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

; ### (;code)
code paren_scode, '(;code)'
        pop     rax                     ; return address
        inc     rax                     ; skip past RET to get to start of DOES> code
        pushd   rax                     ; -- does>-code
        _ latest
        _ namefrom
        _ tocode
        _lit docreate_end - docreate
        _ plus
        _ cp
        _ store
        _ commacall
        _lit $0c3
        _ ccommac
        next
endcode

; ### does>
code does, 'does>', IMMEDIATE
        _lit paren_scode                ; postpone (;code)
        _ commacall
        _lit $0c3                       ; next,
        _ ccommac                       ; --
        next
endcode

; ### here
code here, 'here'
        _ dp
        _fetch
        next
endcode

; ### here-c
code here_c, 'here-c'
        _ cp
        _fetch
        next
endcode

; ### pad
code pad, 'pad'
        _ here
        add     rbx, 512
        next
endcode

; ### latest
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
; ### push-tos,
code push_tos_comma, 'push-tos,'
        _lit push_tos
        _lit push_tos_end - push_tos
        _ paren_copy_code
        next
endcode

; ### literal
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
; ### mov-tos,
code mov_tos_comma, 'mov-tos,'      ; compilation: x --
        _lit $48
        _ ccommac
        _lit $0bb
        _ ccommac
        _ commac
        next
endcode

; ### (2literal)
code parentwoliteral, '(2literal)'      ; addr -- d
        _ twofetch
        next
endcode

; ### 2literal
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

; ### postpone
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

; ### [compile]
code bracketcompile, '[compile]', IMMEDIATE
        _ tick
        _ compilecomma
        next
endcode
