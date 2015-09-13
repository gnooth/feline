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

code local0, 'local0'                   ; -- x
        pushrbx
        mov     rbx, [r14]
        next
endcode

code local1, 'local1'                   ; -- x
        pushrbx
        mov     rbx, [r14 - BYTES_PER_CELL]
        next
endcode

code tolocal0, 'tolocal0'               ; x --
        mov     [r14], rbx
        poprbx
        next
endcode

code tolocal1, 'tolocal1'               ; x --
        mov     [r14 - BYTES_PER_CELL], rbx
        poprbx
        next
endcode

; ### using-locals?
value using_locals?, 'using-locals?', 0
; true at compile time if the current definition uses locals

; ### initialize-locals-stack
; FIXME this should be done at startup!
code initialize_locals_stack, 'initialize-locals-stack'
        ; idempotent
        _ lsp0
        _fetch
        _if .1
        _return
        _then .1

        _lit    4096                    ; REVIEW
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

; ### #locals
code nlocals, '#locals'                 ; -- n
; maximum number of local variables in a definition
        pushd   16
        next
endcode

; ### locals-defined
value locals_defined, 'locals-defined', 0

; ### .locals
code dotlocals, '.locals'
        _ ?cr
        _ locals_defined
        _ dot
        _dotq "local(s):"
        _ locals_defined
        _ zero
        _do .1
        _ ?cr
        _ locals_names
        _i
        _ cells
        _ plus
        _ fetch
        _ counttype
        _loop .1
        next
endcode

; ### find-local
code find_local, 'find-local'           ; $addr -- index flag
        _ locals_defined
        _ zero
        _do .1
        _ locals_names
        _i
        _ cells
        _ plus
        _ fetch                         ; -- $addr $addr2
        _ over                          ; -- $addr $addr2 $addr
        _ count
        _ rot
        _ count
        _ istrequal
        _if .2
        _ drop
        _i
        _ true
        _ ?cr
        _dotq "leaving..."
        _ paren_leave
        _then .2
        _loop .1
        _ ?cr
        _dotq "got to here"
        _ true
        _ equal
        _if .3
        _ true
        _else .3
        _ false
        _ false
        _then .3
        next
endcode

; ### initialize-frame
code initialize_frame, 'initialize-frame'
        _ initialize_locals_stack
        ; for now, just make a frame big enough for the maximum number of locals
        _ nlocals
        _ cells
        _duptor
        _ allocate
        _ drop                          ; REVIEW
        _ dup
        _to locals_names
        _rfrom
        _ erase
        _ zero
        _to locals_defined
        _ true
        _to using_locals?
        next
endcode

; ### local-init
inline local_init, 'local-init'         ; x --
        lea     r15, [r15 - BYTES_PER_CELL]     ; adjust lsp
        mov     [r15], rbx                      ; initialize local with value from tos
        poprbx                                  ; adjust stack
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

        _ locals_defined
        _ nlocals
        _ ult
        _if .3

        _lit local_init_xt
        _ compilecomma

        _ twodup
        _ ?cr
        _dotq "local "
        _ type

        _ save_string                   ; -- $addr
        _ locals_names
        _ locals_defined
        _ cells
        _ plus
        _ store
        _ one
        _plusto locals_defined

        _ ?cr
        _ locals_defined
        _ dot
        _dotq "local(s) defined"

        _else .3
        _abortq "Too many locals"       ; REVIEW
        _then .3

        next
endcode

; ### local
code local, 'local', IMMEDIATE
        _ parse_name                    ; -- c-addr u
        _ paren_local
        next
endcode
