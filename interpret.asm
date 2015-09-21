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

; ### do-defined
code do_defined, 'do-defined'           ; xt flag --
        _ statefetch
        _if .1
        _ zgt
        _if .2
        ; immediate word
        _ flush_compilation_queue
        _ execute
        _else .2
        _ compilecomma
        _then .2
        _else .1
        _drop
        _ execute
        _ ?stack
        _then .1
        next
endcode

; ### interpret
code interpret, 'interpret'             ; --
        _begin interp0
        _ blchar
        _ word_                         ; -- $addr
        _dupcfetch                      ; -- $addr len
        _zeq_if .1
        ; end of input
        _ drop                          ; --
        _return
        _then .1                        ; -- $addr

        _ statefetch
        _if .2
        _ dup                           ; -- $addr $addr

        _ find_local                    ; -- $addr index flag

        _if .3
        _nip
        _ compile_local
        jmp     interp0_begin
        _else .3
        _ drop
        _then .3
        _then .2

        _ find
        _ ?dup
        _if interp2
        _ do_defined
        _else interp2                   ; -- c-addr
        _ number
        _ statefetch
        _if interp3
        _ flush_compilation_queue
        _ double?
        _if interp4
        _ twoliteral
        _else interp4
        _ drop
        _ literal
        _then interp4
        _else interp3
        _ double?
        _zeq_if .6
        _ drop
        _then .6
        _then interp3
        _then interp2
        _again interp0
        next
endcode
