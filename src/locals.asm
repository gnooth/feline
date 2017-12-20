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

asm_global lp0_value, 0

%macro _lp0 0
        pushrbx
        mov     rbx, [lp0_value]
%endmacro

; ### lp0
code lp0, 'lp0'         ; -- tagged-address
        _lp0
        _tag_fixnum
        next
endcode

%macro  _lpstore 0
        popd    r14
%endmacro

%macro  _lpfetch 0
        pushd   r14
%endmacro

; ### lp@
code lpfetch, 'lp@'     ; -- tagged-address
        _lpfetch
        _tag_fixnum
        next
endcode

; ### using-locals?
value using_locals?, 'using-locals?', 0
; true at compile time if the current definition uses locals

; ### initialize-locals-stack
code initialize_locals_stack, 'initialize-locals-stack'
        ; idempotent
        _lp0
        _if .1
        _return
        _then .1

        _lit    4096                    ; REVIEW
        _dup
        _ raw_allocate
        _plus
        mov     [lp0_value], rbx
        _lpstore
        next
endcode

; ### free-locals-stack
code free_locals_stack, 'free-locals-stack'
; called by BYE to make sure we're freeing all allocated memory
        _lp0
        _?dup
        _if .1
        _lit 4096
        _minus
        _ raw_free
        _then .1
        next
endcode

; ### locals-enter
always_inline locals_enter, 'locals-enter'
        _locals_enter
endinline

; ### locals-leave
always_inline locals_leave, 'locals-leave'
        _locals_leave
endinline

; ### local-names
feline_global local_names, 'local-names'

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
