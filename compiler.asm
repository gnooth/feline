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

variable pending_literal, 'pending-literal', 0

value pending_literal?, 'pending-literal?', 0

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

; ### combine-literal?
value combine_literal?, 'combine-literal?', 0

; ### literal
code literal, 'literal', IMMEDIATE      ; n --
; CORE
; "Interpretation semantics for this word are undefined."
        _ ?comp
        _ flush_compilation_queue
        _ combine_literal?
        _if .1
        _ ?cr
        _dotq "literal "
        _ dup
        _ dot
        _ pending_literal
        _ store
        _ true
        _to pending_literal?
        _else .1
        _ iliteral
        _then .1
        next
endcode

; ### flush-pending-literal
code flush_pending_literal, 'flush-pending-literal'
        _ pending_literal?
        _if .1
        _ ?cr
        _dotq "flush-pending-literal "
        _ pending_literal
        _ fetch
        _ dup
        _ dot
        _ iliteral

        ; REVIEW
        _ zero
        _ pending_literal
        _ store

        _clear pending_literal?
        _then .1
        next
endcode

; ### (flush-compilation-queue)
code iflush_compilation_queue, '(flush-compilation-queue)'
        _ flush_pending_literal
        next
endcode

; ### clear-compilation-queue
deferred clear_compilation_queue, 'clear-compilation-queue', noop

; ### flush-compilation-queue
deferred flush_compilation_queue, 'flush-compilation-queue', noop

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
        _lit push_tos_top
        _lit push_tos_end - push_tos_top
        _ paren_copy_code
        next
push_tos_top:
        pushrbx
push_tos_end:
endcode

; ### pop-tos,
code pop_tos_comma, 'pop-tos,'
        _lit pop_tos_top
        _lit pop_tos_end - pop_tos_top
        _ paren_copy_code
        next
pop_tos_top:
        poprbx
pop_tos_end:
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

; ### (compile,)
code parencompilecomma, '(compile,)'    ; xt --
        _ dup                           ; -- xt xt
        _tocomp                         ; -- xt >comp
        _fetch                          ; -- xt xt-comp
        _ ?dup
        _if .1
        _ execute
        _return
        _then .1
        _ flush_compilation_queue
        _ dup                           ; -- xt xt
        _toinline                       ; -- xt >inline
        _cfetch                         ; -- xt #bytes
        _if .2                          ; -- xt
        _ copy_code
        _return
        _then .2
        ; default behavior
        _ xt_commacall
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
        _abortq "Stack changed"
.1:
        next
endcode

; ### :
code colon, ':'
        _ clear_compilation_queue
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

; ### :noname
code colonnoname, ':noname'
        _ clear_compilation_queue
        _ here_c                        ; xt to be returned

        _ dup
        _ two
        _cells
        _ plus                          ; addr of start of code
        _ dup
        _ last_code
        _ store
        _ commac

        _lit xt_commacall_xt            ; comp field
        _ commac

        _ zero
        _to using_locals?

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
