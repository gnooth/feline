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

; ### ?comp
code ?comp, '?comp'
        mov     rax, [state_data]
        test    rax, rax
        jnz     .1
        _cquote "Attempt to interpret a compile-only word"
        _to msg
        _lit    -14                     ; "interpreting a compile-only word"
        _ throw
.1:
        next
endcode

; ### noop
code noop, 'noop'
        next
endcode

; ### (literal)
code iliteral, '(literal)'              ; n --
        _ compile_pushrbx
        _dup
        _lit $100000000
        _ult
        _if .1
        _ccommac $0bb
        _ lcommac
        _else .1
        _ccommac $48
        _ccommac $0bb
        _ commac
        _then .1
        next
endcode

; ### literal
code literal, 'literal', IMMEDIATE      ; n --
; CORE
; "Interpretation semantics for this word are undefined."
        _ ?comp
;         _ flush_compilation_queue
        _ opt
        _if .1
        _ cq_add_literal
        _else .1
        _ iliteral
        _then .1
        next
endcode

; ### (copy-code)
code paren_copy_code, '(copy-code)'     ; code-addr size --
        _ here_c
        _over
        _ allot_c
        _swap
        _ cmove
        next
endcode

; ### copy-code
code copy_code, 'copy-code'             ; xt --
        _dup                            ; -- xt xt
        _toinline                       ; -- xt addr
        _cfetch                         ; -- xt size
        _swap                           ; -- size xt
        _tocode                         ; -- size code-address
        _swap                           ; -- code-address size
        _ paren_copy_code
        next
endcode

; OPTIMIZE-PUSHRBX

; DROP (poprbx) followed immediately by DUP (pushrbx) looks like this:

;         mov     rbx, [rbp]              ; DROP (poprbx)
;         lea     rbp, [rbp+8]
;         mov     [rbp-8], rbx            ; DUP (pushrbx)
;         lea     rbp, [rbp-8]

; This can be reduced to a single instruction:

;         mov     rbx, [rbp]

; COMPILE-PUSHRBX looks for the 8-byte sequence POPRBX-BYTES immediately
; preceding HERE-C:

;         mov     rbx, [rbp]              ; 48 8b 5d 00
;         lea     rbp, [rbp+8]            ; 48 8d 6d 08
; HERE-C:

; If it finds the POPRBX-BYTES sequence, COMPILE-PUSHRBX simply backs up
; HERE-C by 4 bytes:

;         mov     rbx, [rbp]
; HERE-C:

; No new code needs to be added.

; If the POPRBX-BYTES sequence is not found, the pushrbx code is compiled
; inline as usual.

; Note that we can't do the optimization if it would delete code at the
; target of a forward branch:

;         mov     rbx, [rbp]              ; DROP (poprbx)
;         lea     rbp, [rbp+8]
; target:
;         mov     [rbp-8], rbx            ; DUP (pushrbx)
;         lea     rbp, [rbp-8]

; So we check that HERE-C is not equal to LAST-BRANCH-TARGET (which is set
; by THEN).

; ### pushrbx-bytes
constant pushrbx_bytes, 'pushrbx-bytes', $0f86d8d48f85d8948

; ### poprbx-bytes
constant poprbx_bytes, 'poprbx-bytes', $086d8d48005d8b48

; ### optimize-pushrbx
; returns true if optimization was performed
code optimize_pushrbx, 'optimize-pushrbx'       ; -- flag
        _ here_c
        _cellminus
        _dup
        _ origin_c
        _ ge
        _if .1
        _fetch
        _ poprbx_bytes
        _ equal
        _if .2
        _ here_c
        _ last_branch_target
        _notequal
        _if .3
        _lit -4
        _ allot_c
        _true
        _return
        _then .3
        _then .2
        _else .1
        _drop
        _then .1
        _false
        next
endcode

; ### compile-pushrbx
code compile_pushrbx, 'compile-pushrbx' ; --
        _ optimize_pushrbx              ; -- flag
        _zeq_if .1
        _ pushrbx_bytes
        _ commac
        _then .1
        next
endcode

; ### compile-poprbx
code compile_poprbx, 'compile-poprbx'
        _ poprbx_bytes
        _ commac
        next
endcode

; ### ,call
code commacall, ',call'                 ; target-address --
        _ccommac $0e8
        _ here_c                        ; -- target-address here-c
        add     rbx, 4                  ; -- target-address here-c+4
        _ minus                         ; -- displacement
        _ lcommac
        next
endcode

; ### xt-,call
code xt_commacall, 'xt-,call'
        _tocode
        _ commacall
        next
endcode

; ### ,jmp
code commajmp, ',jmp'                   ; code --
        _ccommac $0e9
        _ here_c                        ; -- code here
        add     rbx, 4                  ; -- code here+4
        _ minus                         ; -- displacement
        _ lcommac
        next
endcode

; ### inline-or-call-xt
code inline_or_call_xt, 'inline-or-call-xt'     ; xt --
        _dup                            ; -- xt xt
        _toinline                       ; -- xt >inline
        _cfetch                         ; -- xt #bytes
        _if .1                          ; -- xt
        _ copy_code
        _else .1
        ; default behavior
        _ xt_commacall
        _then .1
        next
endcode

; ### compile-xt
code compile_xt, 'compile-xt'           ; xt --
        _ opt
        _zeq_if .1
        _ inline_or_call_xt
        _return
        _then .1

        _ statefetch
        _zeq_if .2
        _ inline_or_call_xt
        _return
        _then .2

        _ cq_add_xt
        next
endcode

; ### compile,
deferred compilecomma, 'compile,', compile_xt
; CORE EXT
; "Interpretation semantics for this word are undefined."

; ### last-code
; needed for RECURSE
variable last_code, 'last-code', 0

; ### recurse
code recurse, 'recurse', IMMEDIATE
; CORE
; "Interpretation semantics for this word are undefined."
        _ ?comp
        _ flush_compilation_queue
        _ last_code
        _fetch
        _ commacall
        next
endcode

; ### csp
variable csp, 'csp', 0

; ### !csp
code storecsp, '!csp'
        mov     [csp_data], rbp
        next
endcode

; ### ?csp
code ?csp, '?csp'
        cmp     [csp_data], rbp
        je      .1
        _cquote "Control structure mismatch"
        _to msg
        _lit -22                        ; "control structure mismatch"
        _ throw
.1:
        next
endcode

; ### :
code colon, ':'
        _ cq_clear
        _ header
        _ hide
        _ align_code
        _ here_c
        _dup
        _ last_code
        _ store
        _ latest
        _namefrom
        _ store
        _zeroto using_locals?
        _ rbrack
        _ storecsp
        next
endcode

; ### :noname
code colonnoname, ':noname'
        _ cq_clear
        _ align_data
        _ here                          ; xt to be returned
        _ noname_header
        _ here_c
        _ last_code
        _ store
        _zeroto using_locals?
        _ rbrack
        _ storecsp
        next
endcode

; ### end-definition
code end_definition, 'end-definition'
; CORE
        _ ?comp
        _ flush_compilation_queue
        _ ?csp
        _ end_locals
        _ccommac $0c3                   ; RET
        _ lbrack
        _ reveal
        next
endcode

; ### ;
deferred semi, ';', end_definition, IMMEDIATE

; ### synonym
code synonym, 'synonym'                 ; "<spaces>newname" "<spaces>oldname" --
; TOOLS EXT
        _ create
        _ hide
        _ tick
        _ latest
        _set_xt
        _ reveal
        next
endcode

; ### import
code import, 'import'                   ; "<spaces>name" --
        _ tick                          ; -- xt
        _dup
        _toname
        _count
        _ create_word                   ; -- xt
        _ latest
        _set_xt
        next
endcode
