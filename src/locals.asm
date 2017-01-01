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

; ### #locals
; maximum number of local variables in a definition
; "A system implementing the Locals word set shall support the
; declaration of at least sixteen locals in a definition."
constant nlocals, '#locals', MAX_LOCALS

; ### lp0
value lp0, 'lp0', 0

; ### lp!
code lpstore, 'lp!'
        popd    r14
        next
endcode

; ### lp@
code lpfetch, 'lp@'
        pushd   r14
        next
endcode

; ### using-locals?
value using_locals?, 'using-locals?', 0
; true at compile time if the current definition uses locals

; ### initialize-locals-stack
code initialize_locals_stack, 'initialize-locals-stack'
        ; idempotent
        _ lp0
        _if .1
        _return
        _then .1

        _lit    4096                    ; REVIEW
        _dup
        _ iallocate
        _plus
        _dup
        _to lp0
        _ lpstore
        next
endcode

; ### free-locals-stack
code free_locals_stack, 'free-locals-stack'
; called by BYE to make sure we're freeing all allocated memory
        _ lp0
        _?dup
        _if .1
        _lit 4096
        _minus
        _ ifree
        _then .1
        next
endcode

; ### locals-enter
inline locals_enter, 'locals-enter'
        _locals_enter
endinline

; ### locals-leave
inline locals_leave, 'locals-leave'
        _locals_leave
endinline

; ### local-names
value local_names, 'local-names', 0

; ### locals-defined
code locals_defined, 'locals-defined'   ; -- n
; Returned value is untagged.
        _ local_names
        _?dup_if .1
        _ vector_length
        _untag_fixnum
        _else .1
        _zero
        _then .1
        next
endcode

; ### initialize-local-names
code initialize_local_names, 'initialize-local-names'
        ; allow for maximum number of locals
        _ nlocals
        _ new_vector_untagged
        _to local_names

        _true
        _to using_locals?
        next
endcode

; ### delete-local-names
code delete_local_names, 'delete-local-names'
        _zeroto local_names
        next
endcode
