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

; ### lsp0
variable lsp0, 'lsp0', 0

; ### lsp@
code lspfetch, 'lsp@'
        pushd   r15
        next
endcode

; ### lsp!
code lspstore, 'lsp!'
        popd    r15
        next
endcode

; ### using-locals?
value using_locals?, 'using-locals?', 0 
; true at compile time if the current definition uses locals

; ### initialize-locals-stack
code initialize_locals_stack, 'initialize-locals-stack'
        _lit    4096
        _ dup
        _ allocate
        _ drop                          ; REVIEW
        _ plus
        _ dup
        _ lsp0
        _ store
        _ lspstore
        next
endcode

; ### locals-enter
inline locals_enter, 'locals-enter'
        push    r15                     ; lsp
        push    r14                     ; frame pointer
        mov     r14, r15
endinline

; ### locals-leave
inline locals_leave, 'locals-leave'
        pop     r14
        pop     r15
endinline

; ### locals-names
value locals_names, 'locals-names', 0

; ### initialize-frame
code initialize_frame, 'initialize-frame'
        _lit 16
        _ cells
        _ allocate
        _ drop                          ; REVIEW
        _to locals_names
        _ true
        _to using_locals?
        next
endcode

; ### local-init
inline local_init, 'local-init'
;         sub     r15, BYTES_PER_CELL
        lea     r15, [r15 - BYTES_PER_CELL]
        mov     [r15], rbx
        poprbx
endinline

; ### (local)
code paren_local, '(local)'             ; c-addr u --
; LOCALS 13.6.1.0086
        _ using_locals?
        _zeq_if .1
        ; first local in this definition
        _ lspfetch
        _zeq_if .2
        _ initialize_locals_stack
        _then .2
        _ initialize_frame
        _lit locals_enter_xt
        _ compilecomma
        _then .1

        _lit local_init_xt
        _ compilecomma

        _ ?cr
        _dotq "local "
        _ type

        next
endcode

; ### local
code local, 'local', IMMEDIATE
        _ parse_name                    ; -- c-addr u
        _ paren_local
        next
endcode
