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

; ### name>link
inline name_to_link, 'name>link'
        _name_to_link
endinline

; ### name>code
inline name_to_code, 'name>code'
        _name_to_code
endinline

; ### l>name
inline ltoname, 'l>name'
        _ltoname
endinline

; ### >link
inline tolink, '>link'
        _tolink
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

; ### >code
inline tocode, '>code'                  ; xt -- code-addr
        _tocode
endinline

; ### immediate
code immediate, 'immediate'
        _ latest
        _nametoflags                    ; -- flags-addr
        or      byte [rbx], IMMEDIATE
        poprbx
        next
endcode

; ### immediate?
code immediate?, 'immediate?'           ; xt -- flag
        _ flags
        and     rbx, IMMEDIATE
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
code hide, 'hide'                       ; --
        _ latest                        ; -- nfa
        or      byte [rbx], $80
        poprbx
        next
endcode

; ### reveal
code reveal, 'reveal'                   ; --
        _ latest                        ; -- nfa
        and     byte [rbx], $7f
        poprbx
        next
endcode

; ### allot
code allot, 'allot'                     ; n --
; CORE
        add     rbx, [dp_data]          ; new value for here in rbx
        cmp     rbx, [origin_data]
        jb .1
        cmp     rbx, [limit_data]
        jae .1
        mov [dp_data], rbx
        poprbx
        ret
.1:
        _lit -8
        _ forth_throw
        next
endcode

; ### allot-c
code allot_c, 'allot-c'                 ; n --
        add     rbx, [cp_data]          ; new value for here-c in rbx
        cmp     rbx, [origin_c_data]
        jb .1
        cmp     rbx, [limit_c_data]
        jae .1
        mov [cp_data], rbx
        poprbx
        ret
.1:
        _lit -8
        _ forth_throw
        next
endcode

; ### ,
code comma, ','
        _ here
        _cell
        _ allot
        _ store
        next
endcode

; ### ,c
code commac, ',c'
        _ here_c
        _cell
        _ allot_c
        _ store
        next
endcode

; ### c,
code ccomma, 'c,'
        _ here
        _lit 1
        _ allot
        _ cstore
        next
endcode

; ### c,c
code ccommac, 'c,c'                     ; char --
        _ here_c
        _lit 1
        _ allot_c
        _ cstore
        next
endcode

; ### l,
code lcomma, 'l,'                       ; x --
; 32-bit store, increment DP
        _ here
        _lit 4
        _ allot
        _ lstore
        next
endcode

; ### l,c
code lcommac, 'l,c'                     ; x --
; 32-bit store, increment CP
        _ here_c
        _lit 4
        _ allot_c
        _ lstore
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

; ### .id
code dot_id, '.id'                      ; nfa --
        _ count

        ; REVIEW
        ; HIDE sets the high bit of the count byte.
        ; Mask it off so we don't type garbage in that situation.
        and     rbx, $7f

        _ type
        _ forth_space
        next
endcode

; ### here
code here, 'here'                       ; -- addr
; CORE
        pushrbx
        mov     rbx, [dp_data]
        next
endcode

; ### here-c
code here_c, 'here-c'
        pushrbx
        mov     rbx, [cp_data]
        next
endcode

; ### latest
code latest, 'latest'                   ; -- nfa
        _ last
        _fetch
        next
endcode

; ### latest-xt
; latest_xt is the xt of the word LATEST
code latestxt, 'latest-xt'              ; -- xt
        _ last
        _fetch
        _namefrom
        next
endcode

; REVIEW
; ### mov-tos,
code mov_tos_comma, 'mov-tos,'          ; compilation: x --
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
        _ compile_pushrbx
        _ mov_tos_comma
        _lit parentwoliteral
        _ commacall
        next
endcode

; ### in-dictionary-space?
code in_dictionary_space?, 'in-dictionary-space?' ; addr -- flag
        cmp     rbx, [origin_data]
        jb .1
        cmp     rbx, [dp_data]
        jae .1
        mov     ebx, 1
        _return
.1:
        xor     ebx, ebx
        next
endcode
