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

; ### ?comp
code ?comp, '?comp'
        mov     rax, [state_data]
        test    rax, rax
        jnz     .1
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
        _ push_tos_comma
        _ dup
        _lit $100000000
        _ ult
        _if .1
        _lit $0bb
        _ ccommac
        _ lcommac
        _else .1
        _lit $48
        _ ccommac
        _lit $0bb
        _ ccommac
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
code paren_copy_code, '(copy-code)'     ; addr size --
        _ here_c
        _ over
        _ allot_c
        _ swap
        _ cmove
        next
endcode

; ### copy-code
code copy_code, 'copy-code'             ; xt --
        _ dup                           ; -- xt xt
        _toinline                       ; -- xt addr
        _cfetch                         ; -- xt size
        _ swap
        _tocode
        _ swap                          ; -- code size
        _ paren_copy_code
        next
endcode

; ### push-tos,
code push_tos_comma, 'push-tos,'
        _lit .1
        _lit .2 - .1
        _ paren_copy_code
        next
.1:
        pushrbx
.2:
endcode

; ### pop-tos,
code pop_tos_comma, 'pop-tos,'
        _lit .1
        _lit .2 - .1
        _ paren_copy_code
        next
.1:
        poprbx
.2:
endcode

; ### ,call
code commacall, ',call'                 ; code --
        _lit $0e8
        _ ccommac
        _ here_c                        ; -- code here
        add     rbx, 4                  ; -- code here+4
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
        _lit $0e9
        _ ccommac
        _ here_c                        ; -- code here
        add     rbx, 4                  ; -- code here+4
        _ minus                         ; -- displacement
        _ lcommac
        next
endcode

; ### inline-or-call-xt
code inline_or_call_xt, 'inline-or-call-xt'     ; xt --
        _ dup                           ; -- xt xt
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

; ### (compile,)
code parencompilecomma, '(compile,)'    ; xt --
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
deferred compilecomma, 'compile,', parencompilecomma
; CORE EXT
; "Interpretation semantics for this word are undefined."

; ### last-code
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
        _ msg
        _ store
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
        _ dup
        _ last_code
        _ store
        _ latest
        _namefrom
        _ store
        _ rbrack
        _ storecsp
        next
endcode

; ### :noname
code colonnoname, ':noname'
        _ cq_clear
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

; ### ;
code semi, ';', IMMEDIATE
; CORE
        _ ?comp
        _ flush_compilation_queue
        _ ?csp
        _ end_locals
        _lit $0c3                       ; RET
        _ ccommac
        _ lbrack
        _ reveal
        next
endcode
