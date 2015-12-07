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

; ### state
; "STATE is true when in compilation state, false otherwise. The true value
; in STATE is non-zero, but is otherwise implementation-defined."
variable state, 'state', 0              ; CORE, TOOLS EXT

; ### state@
code statefetch, 'state@'
        pushrbx
        mov     rbx, [state_data]
        next
endcode

; ### [
code lbrack, '[', IMMEDIATE
        _ flush_compilation_queue
        xor     eax, eax
        mov     [state_data], rax
        next
endcode

; ### ]
code rbrack, ']'
        xor     eax, eax
        dec     rax
        mov     [state_data], rax
        next
endcode

; ### ?stack
code ?stack, '?stack'
        cmp     rbp, [sp0_data]
        ja      .1
        next
.1:
        mov     rbp, [sp0_data]
        _cquote "Stack underflow"
        _ msg
        _ store
        _lit -4
        _ throw
        next
endcode

; ### ?enough
code ?enough, '?enough'                 ; n --
        _ depth
        _oneminus
        _ ugt
        _if .1
        _cquote "Not enough parameters"
        _ msg
        _ store
        _lit -4                         ; Forth 2012 Table 9.1 stack underflow
        _ throw
        _then .1
        next
endcode

; ### interpret-do-defined
code interpret_do_defined, 'interpret-do-defined'       ; xt flag --
        _drop
        _ execute
        next
endcode

; ### compile-do-defined
code compile_do_defined, 'compile-do-defined'           ; xt flag --
        _ zlt
        _if .1
        ; not immediate
        _ compilecomma
        _else .1
        ; immediate
;         _ flush_compilation_queue
        _ execute
        _then .1
        next
endcode

; ### interpret-do-literal
code interpret_do_literal, 'interpret-do-literal'
        _ number
        _ double?
        _zeq_if .3
        _drop
        _then .3
        next
endcode

; ### compile-do-literal
code compile_do_literal, 'compile-do-literal'
        _ number
;         _ flush_compilation_queue
        _ double?
        _if .2
        _ flush_compilation_queue
        _ twoliteral
        _else .2
        _drop
        _ literal
        _then .2
        next
endcode

; ### interpret1
code interpret1, 'interpret1'
        _ find
        _ ?dup
        _if .1
        _ interpret_do_defined
        _else .1                        ; -- c-addr
        _ interpret_do_literal
        _then .1
        next
endcode

; ### compile1
code compile1, 'compile1'
        _ find_local                    ; -- $addr-or-index flag
        _if .3
        _ flush_compilation_queue
        _ compile_local
        _else .3
        _ find
        _ ?dup
        _if .1
        _ compile_do_defined
        _else .1                        ; -- c-addr
        _ compile_do_literal
        _then .1
        _then .3
        next
endcode

; ### interpret
code interpret, 'interpret'             ; --
        _begin .7
        _ ?stack
        _ blword
        _dupcfetch
        _while .7
        _ statefetch
        _if .2
        _ compile1
        _else .2
        _ interpret1
        _then .2
        _repeat .7
        _drop
        next
endcode
