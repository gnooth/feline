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
;   data ptr    8 bytes         pfa
;   flags       1 byte
;   type        1 byte
;   inline      1 byte          number of bytes of code to copy
;   sourcefile  8 bytes         pointer to source file name
;   line number 8 bytes         source line number
;   name        1-256 bytes
;   padding     0-7 bytes       for alignment
;   body is in data area

; ### >comp
inline tocomp, '>comp'
        _tocomp
endinline

; ### >comp!
code tocompstore, '>comp!'              ; xt1 xt2 --
        _tocomp
        _ store
        next
endcode

; ### n>link
inline ntolink, 'n>link'
        _ntolink
endinline

; ### l>name
inline ltoname, 'l>name'
        _ltoname
endinline

; ### >link
inline tolink, '>link'
        _tolink
endinline

; ### link>
inline linkfrom, 'link>'
        _linkfrom
endinline

; ### >body
inline tobody, '>body'                  ; xt -- a-addr
; CORE
; "a-addr is the data-field address corresponding to xt. An ambiguous condition
; exists if xt is not for a word defined via CREATE."
; "Rationale: a-addr is the address that HERE would have returned had it been
; executed immediately after the execution of the CREATE that defined xt."
        _tobody
endinline

; ### >flags
inline toflags, '>flags'                ; xt -- addr
        _toflags
endinline

; ### flags
code flags, 'flags'                     ; xt -- flags
        _toflags
        _cfetch
        next
endcode

; ### >inline
inline toinline, '>inline'              ; xt -- addr
        _toinline
endinline

; ### >type
inline totype, '>type'                  ; xt -- addr
        _totype
endinline

; ### >view
inline toview, '>view'                  ; xt -- addr
        _toview
endinline

; ### >name
inline toname, '>name'
        _toname
endinline

; ### name>
inline namefrom, 'name>'
        _namefrom
endinline

; ### n>flags
inline nametoflags, 'n>flags'
        _nametoflags
endinline

; ### n>type
inline nametotype, 'n>type'
        _nametotype
endinline

; ### >code
inline tocode, '>code'                  ; xt -- code-addr
        _tocode
endinline

; ### immediate
code immediate, 'immediate'
        _ latest
        _nametoflags
        _dupcfetch
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
        _toinline
        _cfetch
        _ zne
        next
endcode

; ### hide
code hide, 'hide'
        _ latest
        _dupcfetch
        _lit $80
        _ or
        _ swap
        _ cstore
        next
endcode

; ### reveal
code reveal, 'reveal'
        _ latest
        _dupcfetch
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
        _lit 1
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
code ccommac, 'c,c'                     ; char --
        _ here_c
        _ cstore
        _lit 1
        _ cp
        _ plusstore
        next
endcode

; ### allot-c
code allot_c, 'allot-c'                 ; n --
        add     rbx, [cp_data]
        mov     [cp_data], rbx
        poprbx
        next
endcode

; ### warning
variable warning, 'warning', -1

; ### header
code header, 'header'                   ; "spaces<name>" --
        _ parse_name                    ; -- c-addr u
        _ quoteheader
        next
endcode

; ### "header
code quoteheader, '"header'             ; c-addr u --
        _ warning
        _fetch
        _if .1
        _ twodup
        _ get_current
        _ search_wordlist
        _if .2
        _ drop
        _ ?cr
        _ twodup
        _ type
        _dotq " isn't unique "
        _then .2
        _then .1

        _zero                          ; code field (will be patched)
        _ comma
        _zero                          ; comp field
        _ comma
        _ current
        _ fetch                         ; -- c-addr u wid
        _ fetch                         ; -- c-addr u link
        _ comma

;         _ align_data
;         _ here                          ; data field address for >body
;         _ commac
        _ here
        _tor                            ; -- r: addr-to-be-patched
        _zero
        _ comma                         ; pfa (will be patched)

        _zero                           ; flag
        _ ccomma                        ; -- c-addr u
        _zero
        _ ccomma                        ; inline size
        _zero
        _ ccomma                        ; type

        _ source_filename
        _fetch
        _ comma
        _ source_line_number
        _fetch
        _ comma

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

        _ align_data
        _ here
        _rfrom                          ; addr-to-be-patched
        _ store

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
; 32-bit store, increment CP
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
        _zero
        _ ccomma
        _repeat align1
        next
endcode

; REVIEW
; ### aligned
code aligned, 'aligned'                 ; addr -- a-addr
; CORE
; "a-addr is the first aligned address greater than or equal to addr."
        add     rbx, 7
        and     rbx, -8
        next
endcode

; ### (create)
code paren_create, '(create)'
        _ align_data

        _ here_c
        _ latest
        _namefrom
        _ store

        _ push_tos_comma

        _ here                          ; -- pfa
        _lit $100000000
        _ ult
        _if .1
        ; 32-bit address
        _lit $0bb
        _ ccommac
        _ here
        _ lcommac
        _else .1
        ; 64-bit address
        _lit $48
        _ ccommac
        _lit $0bb
        _ ccommac
        _ here                          ; -- addr
        _ commac
        _then .1

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

; ### inline-latest
code inline_latest, 'inline-latest'     ; --
; make the most recent definition inline
        _ latest
        _namefrom
        _dup
        _tocode
        _ here_c
        _swapminus
        _oneminus                       ; don't include final $c3
        _ swap
        _toinline
        _ cstore
        next
endcode

; ### variable
code var, 'variable'
        _ create
        _zero
        _ comma
        _ inline_latest
        next
endcode

; ### 2variable
code twovar, '2variable'
        _ create
        _zero
        _ comma
        _zero
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
code constant_, 'constant'              ; x "<spaces>name" --
; CORE
        _ header                        ; -- x
        _ here_c
        _ latest
        _namefrom
        _ store                         ; -- x
        _lit doconst
        _lit doconst_end - doconst
        _ paren_copy_code               ; -- x
        _ here_c
        _cellminus
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
        _namefrom
        _ store                         ; -- x1 x2
        _lit doconst
        _lit doconst_end - doconst
        _ paren_copy_code               ; -- x1 x2
        _ swap                          ; -- x2 x1
        _ here_c
        _cellminus
        _ store                         ; -- x2
        _lit doconst
        _lit doconst_end - doconst
        _ paren_copy_code               ; -- x2
        _ here_c
        _cellminus
        _ store                         ; --
        _lit $0c3
        _ ccommac
        next
endcode

; ### exit
code exit_, 'exit', IMMEDIATE
; CORE
; "Interpretation semantics for this word are undefined."
        _ ?comp
        _ using_locals?
        _if .1
        _lit locals_leave_xt
        _ compilecomma
        _then .1
        _lit $0c3
        _ ccommac
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
        _namefrom
        _tocode                         ; code address of most recent definition

        add     rbx, 8                  ; skip over pushrbx (8 bytes)
        _dupcfetch
        _lit $48
        _ equal
        _if .1
        _lit 10
        _else .1
        _lit 5
        _then .1
        _plus
        _ cp
        _ store

        _ commacall
        _lit $0c3
        _ ccommac
        next
endcode

; ### does>
code does, 'does>', IMMEDIATE
; CORE
; "Interpretation semantics for this word are undefined."
        _ ?comp
        _ flush_compilation_queue
        _ end_locals
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

; ### latest
code latest, 'latest'                   ; -- nfa
        _ last
        _fetch
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
        _ ?comp
        _ flush_compilation_queue
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
; "Interpretation semantics for this word are undefined."
        _ ?comp
        _ flush_compilation_queue
        _ tick
        _ dup
        _ immediate?
        _if .1
        _tocode
        _ commacall
        _else .1
        _tocode
        _ iliteral
        _lit commacall
        _ commacall
        _then .1
        next
endcode

; ### [compile]
code bracketcompile, '[compile]', IMMEDIATE
; CORE EXT
; "This word is obsolescent and is included as a concession to existing
; implementations."
; "Interpretation semantics for this word are undefined."
        _ ?comp
        _ tick
        _ compilecomma
        next
endcode
