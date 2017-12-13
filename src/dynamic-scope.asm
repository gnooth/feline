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

asm_global dynamic_scope_, f_value

%macro _get_dynamic_scope 0
        pushrbx
        mov     rbx, [dynamic_scope_]
%endmacro

; ### get-dynamic-scope
code get_dynamic_scope, 'get-dynamic-scope'     ; -- vector
        _get_dynamic_scope
        next
endcode

asm_global primordial_bindings_, f_value

%macro _primordial_bindings 0
        pushrbx
        mov     rbx, [primordial_bindings_]
%endmacro

; ### initialize_dynamic_scope
code initialize_dynamic_scope, 'initialize_dynamic_scope', SYMBOL_INTERNAL

        _lit 16
        _ new_hashtable_untagged
        mov     [primordial_bindings_], rbx
        _drop

        _lit primordial_bindings_
        _ gc_add_root

        _lit 16
        _ new_vector_untagged
        mov     [dynamic_scope_], rbx
        _drop

        _lit dynamic_scope_
        _ gc_add_root

        _primordial_bindings
        _get_dynamic_scope
        _ vector_push

        next
endcode

; ### begin-dynamic-scope
code begin_dynamic_scope, 'begin-dynamic-scope' ; --
        _lit 4
        _ new_hashtable_untagged
        _get_dynamic_scope
        _ vector_push
        next
endcode

; ### end-dynamic-scope
code end_dynamic_scope, 'end-dynamic-scope'     ; --
        _get_dynamic_scope
        _ vector_pop_star
        next
endcode

; ### verify-special
code verify_special, 'verify-special'   ; special -- special
        _dup
        _ symbol_special?
        cmp     rbx, f_value
        _drop
        je      .error
        next
.error:
        _error "not a special"
        next
endcode

; ### set
code set, 'set'                         ; value special --
        _ verify_special
        _get_dynamic_scope
        _ vector_last
        _ hashtable_set_at
        next
endcode

; ### set-default
code set_default, 'set-default'         ; value special --
        _ verify_special
        _get_dynamic_scope
        _ vector_first
        _ hashtable_set_at
        next
endcode

; ### with-dynamic-scope
code with_dynamic_scope, 'with-dynamic-scope'   ; quot --
        _ begin_dynamic_scope

        ; protect quotation from gc
        push    rbx

        _ callable_raw_code_address
        mov     rax, rbx
        poprbx
        call    rax

        ; drop quotation
        pop     rax

        _ end_dynamic_scope
        next
endcode

; ### find-in-scope
code find_in_scope, 'find-in-scope'     ; special scope -- value/f ?
        _ hashtable_at_star
        next
endcode

; ### get
code get, 'get'                         ; special -- value

        _ verify_special

        _tor
        _get_dynamic_scope

        _dup
        _ vector_length
        _lit tagged_fixnum(1)
        _ fixnum_minus                  ; -- vector index
        _dup
        _lit tagged_zero
        _ fixnum_lt
        _tagged_if .1
        _3drop
        _rdrop
        _f
        _return
        _then .1

.top:                                   ; -- vector index       r: -- variable
        _twodup
        _swap
        _ vector_nth                    ; -- vector index
        _rfetch
        _swap                           ; -- vector index variable scope
        _ find_in_scope                 ; -- vector index value/f ?
        _tagged_if .2
        ; found
        _2nip
        _rdrop
        _return
        _then .2                        ; -- vector index f

        _drop                           ; -- vector index

        _lit tagged_fixnum(1)
        _ generic_minus                 ; -- vector index-1
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
