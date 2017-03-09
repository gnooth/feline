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

section .data
namestack_data:
        dq      0

%macro _get_namestack 0
        pushrbx
        mov     rbx, [namestack_data]
%endmacro

; ### get-namestack
code get_namestack, 'get-namestack'     ; -- namestack
        _get_namestack
        next
endcode

%macro _set_namestack 0
        mov     [namestack_data], rbx
        poprbx
%endmacro

; ### set-namestack
code set_namestack, 'set-namestack'     ; namestack --
        _set_namestack
        next
endcode

section .data
global_namespace_data:
        dq      0

%macro _global_namespace 0
        pushrbx
        mov     rbx, [global_namespace_data]
%endmacro

; ### global
code global_namespace, 'global'         ; -- namespace
        _global_namespace
        next
endcode

%macro _set_global_namespace 0
        mov     [global_namespace_data], rbx
        poprbx
%endmacro

; ### initialize-globals
code initialize_globals, 'initialize-globals'
        _lit 16
        _ new_hashtable_untagged
        _set_global_namespace
        _lit global_namespace_data
        _ gc_add_root

        _lit 16
        _ new_vector_untagged
        _set_namestack
        _lit namestack_data
        _ gc_add_root

        _global_namespace
        _get_namestack
        _ vector_push
        next
endcode

; ### set-global
code set_global, 'set-global'           ; value variable --
        _global_namespace
        _ set_at
        next
endcode

; ### get-global
code get_global, 'get-global'           ; variable -- value
        _global_namespace
        _ at_
        next
endcode

; ### begin-scope
code begin_scope, 'begin-scope'         ; --
        _lit 4
        _ new_hashtable_untagged
        _get_namestack
        _ vector_push
        next
endcode

; ### end-scope
code end_scope, 'end-scope'             ; --
        _get_namestack
        _ vector_pop_star
        next
endcode

; ### set
code set, 'set'                         ; value variable --
        _get_namestack
        _ vector_last
        _ set_at
        next
endcode

; ### with-scope
code with_scope, 'with-scope'           ; quot --
        _ begin_scope

        ; protect quotation from gc
        push    rbx

        _ callable_code_address
        mov     rax, rbx
        poprbx
        call    rax

        ; drop quotation
        pop     rax

        _ end_scope
        next
endcode

; ### find-in-scope
code find_in_scope, 'find-in-scope'     ; variable scope -- value/f ?
        _ at_star
        next
endcode

; ### get
code get, 'get'                         ; variable -- value
        _tor
        _get_namestack

        _dup
        _ vector_length
        _lit tagged_fixnum(1)
        _ fixnum_minus                  ; -- namestack index
        _dup
        _lit tagged_zero
        _ fixnum_lt
        _tagged_if .1
        _3drop
        _rdrop
        _f
        _return
        _then .1

.top:                                   ; -- namestack index       r: -- variable
        _twodup
        _swap
        _ vector_nth                    ; -- namestack index
        _rfetch
        _swap                           ; -- namestack index variable scope
        _ find_in_scope                 ; -- namestack index value/f ?
        _tagged_if .2
        ; found
        _2nip
        _rdrop
        _return
        _then .2                        ; -- namestack index f

        _drop                           ; -- namestack index

        _lit tagged_fixnum(1)
        _ generic_minus                 ; -- namestack index-1
        _dup
        _lit tagged_zero
        _ fixnum_lt
        _tagged_if .3
        _2drop
        _rdrop

        _f

        _return
        _then .3

        jmp     .top

        next
endcode
