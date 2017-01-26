; Copyright (C) 2012-2017 Peter Graves <gnooth@gmail.com>

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

; maximum number of local variables in a definition
%define MAX_LOCALS      16

%macro  _locals_enter 0
        push    r14
        lea     r14, [r14 - BYTES_PER_CELL * MAX_LOCALS];
%endmacro

%macro  _locals_leave 0
        pop     r14
%endmacro

; ### lp0
value lp0, 'lp0', 0

%macro  _lpstore 0
        popd    r14
%endmacro

%macro  _lpfetch 0
        pushd   r14
%endmacro

; ### lp!
code lpstore, 'lp!'
        _lpstore
        next
endcode

; ### lp@
code lpfetch, 'lp@'
        _lpfetch
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
        _lpstore
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
feline_global local_names, 'local-names'

; ### locals-defined
code locals_defined, 'locals-defined'   ; -- n
; return value is untagged
        _ local_names
        _tagged_if .1
        _ local_names
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
        _lit MAX_LOCALS
        _ new_vector_untagged
        _to_global local_names

        _true
        _to using_locals?
        next
endcode

; ### delete-local-names
code delete_local_names, 'delete-local-names'
        _f
        _to_global local_names
        next
endcode
