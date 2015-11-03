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

; ### #locals
code nlocals, '#locals'                 ; -- n
; maximum number of local variables in a definition
; "A system implementing the Locals word set shall support the
; declaration of at least sixteen locals in a definition."
        pushd 16
        next
endcode

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
        _ iallocate
        _ plus
        _ dup
        _ lsp0
        _ store
        _ lspstore
        next
endcode

; ### free-locals-stack
code free_locals_stack, 'free-locals-stack'
; called by BYE to make sure we're freeing all allocated memorys
        _ lsp0
        _fetch
        _ ?dup
        _if .1
        _lit 4096
        _ minus
        _ ifree
        _then .1
        next
endcode

; ### locals-enter
inline locals_enter, 'locals-enter'
        push    r15                     ; lsp
        push    r14                     ; frame pointer
        lea     r14, [r15 - BYTES_PER_CELL];
endinline

; ### locals-leave
inline locals_leave, 'locals-leave'
        pop     r14
        pop     r15
endinline

; ### local-names
value local_names, 'local-names', 0

; ### locals-defined
value locals_defined, 'locals-defined', 0

; ### find-local
code find_local, 'find-local'           ; found:        $addr -- index true
                                        ; not found:    $addr -- $addr false
        _ using_locals?
        _zeq_if .1
        _ false
        _return
        _then .1

        _ locals_defined
        _zero
        _do .2
        _ local_names
        _i
        _cells
        _plus
        _fetch                          ; -- $addr $addr2
        _ over                          ; -- $addr $addr2 $addr
        _ count
        _ rot
        _ count
        _ istrequal
        _if .3
        ; found it!
        _drop
        _i
        _ true
        _unloop
        _return
        _then .3
        _loop .2

        ; not found
        _ false
        next
endcode

; ### compile-local
code compile_local, 'compile-local'     ; index --
        _ push_tos_comma
        _lit $49
        _ ccommac
        _lit $8b
        _ ccommac
        _lit $5e
        _ ccommac
        _cells
        _negate
        _ ccommac
        next
endcode

; ### compile-to-local
code compile_to_local, 'compile-to-local,'      ; index --
        _lit $49
        _ ccommac
        _lit $89
        _ ccommac
        _lit $5e
        _ ccommac                       ; mov [r14 + 0], rbx
        _cells
        _negate
        _ ccommac                       ; 8-bit displacement
        _ pop_tos_comma
        next
endcode

; ### compile-+to-local
code compile_plusto_local, 'compile-+to-local,' ; index --
        _lit $49
        _ ccommac
        _lit $01
        _ ccommac
        _lit $5e
        _ ccommac                       ; add [r14 + 0], rbx
        _cells
        _negate
        _ ccommac                       ; 8-bit displacement
        _ pop_tos_comma
        next
endcode

; ### initialize-local-names
code initialize_local_names, 'initialize-local-names'
        _ initialize_locals_stack
        ; allow for maximum number of locals
        _ nlocals
        _cells
        _duptor
        _ iallocate
        _ dup
        _to local_names
        _rfrom
        _ erase
        _zero
        _to locals_defined
        _ true
        _to using_locals?
        next
endcode

; ### delete-local-names
code delete_local_names, 'delete-local-names'
        _ local_names
        _if .1
        _ locals_defined
        _zero
        _?do .2
        _ local_names
        _i
        _cells
        _plus
        _fetch
        _ ?dup
        _if .3
        _ ifree
        _then .3
        _loop .2
        _ local_names
        _ ifree
        _zero
        _to local_names
        _zero
        _to locals_defined
        _then .1
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
        ; "If u is zero, the message is 'last local' and c-addr has
        ; no significance."
        _ ?dup
        _zeq_if .1
        _drop
        _return
        _then .1

        _ using_locals?
        _zeq_if .2
        ; first local in this definition
        _ lspfetch
        _zeq_if .3
        _ initialize_locals_stack
        _then .3
        _ initialize_local_names
        _lit locals_enter_xt
        _ copy_code                     ; must be inline!
        _then .2

        _ locals_defined
        _ nlocals
        _ ult
        _if .4

        _ save_string                   ; -- $addr
        _ local_names
        _ locals_defined
        _cells
        _ plus
        _ store
        _lit 1
        _plusto locals_defined

        _lit local_init_xt
        _ copy_code                     ; must be inline!

        _else .4
        _abortq "Too many locals"       ; REVIEW
        _then .4

        next
endcode

; ### local
code local, 'local', IMMEDIATE
        _ flush_compilation_queue
        _ parse_name                    ; -- c-addr u
        _ paren_local
        next
endcode

; ### end-locals
code end_locals, 'end-locals'           ; --
; called by ; and DOES>
        _ ?comp
        _ using_locals?
        _if .1
        _lit locals_leave_xt
        _ copy_code                     ; must be inline!
        _ delete_local_names
        _zero
        _to using_locals?
        _then .1
        next
endcode
