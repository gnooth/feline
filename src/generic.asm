; Copyright (C) 2016 Peter Graves <gnooth@gmail.com>

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

; ### lookup-method
code lookup_method, 'lookup-method'     ; object methods-vector -- object xt
        _tor
        _dup
        _ object_type
        _untag_fixnum
        _rfrom
        _ vector_nth_untagged
        next
endcode

; ### do-generic
code do_generic, 'do-generic'
        _fetch
        _ lookup_method
        _execute
        next
endcode

%macro generic 2
        code %1, %2
        section .data
        global  %1_data
        align   DEFAULT_DATA_ALIGNMENT
%1_data:
        dq      0                       ; address of methods vector (will be patched)
        section .text
        pushrbx
        mov     ebx, %1_data            ; REVIEW assumes 32-bit address
        call    do_generic
        next
%endmacro

; ### initialize-generic-function
code initialize_generic_function, 'initialize-generic-function' ; xt --
        _tobody
        _tor
        _lit 10
        _ new_vector_untagged
        _rfetch
        _store
        _rfrom
        _ gc_add_root
        next
endcode

; ### add-method
code add_method, 'add-method'           ; -- method-xt untagged-type-number generic-xt
        _tobody
        _fetch                          ; -- method-xt untagged-type-number methods-vector
        _ vector_set_nth_untagged
        next
endcode

generic length, 'length'
generic push, 'push'
generic nth, 'nth'

; ### initialize-generic-functions
code initialize_generic_functions, 'initialize-generic-functions' ; --
        _lit length_xt
        _ initialize_generic_function

        _lit string_length_xt
        _lit OBJECT_TYPE_STRING
        _lit length_xt
        _ add_method

        _lit sbuf_length_xt
        _lit OBJECT_TYPE_SBUF
        _lit length_xt
        _ add_method

        _lit array_length_xt
        _lit OBJECT_TYPE_ARRAY
        _lit length_xt
        _ add_method

        _lit vector_length_xt
        _lit OBJECT_TYPE_VECTOR
        _lit length_xt
        _ add_method

        _lit push_xt
        _ initialize_generic_function

        _lit vector_push_xt
        _lit OBJECT_TYPE_VECTOR
        _lit push_xt
        _ add_method

        _lit sbuf_push_xt
        _lit OBJECT_TYPE_SBUF
        _lit push_xt
        _ add_method

        _lit nth_xt
        _ initialize_generic_function

        _lit array_nth_xt
        _lit OBJECT_TYPE_ARRAY
        _lit nth_xt
        _ add_method

        _lit vector_nth_xt
        _lit OBJECT_TYPE_VECTOR
        _lit nth_xt
        _ add_method

        _lit string_nth_xt
        _lit OBJECT_TYPE_STRING
        _lit nth_xt
        _ add_method

        _lit sbuf_nth_xt
        _lit OBJECT_TYPE_SBUF
        _lit nth_xt
        _ add_method

        next
endcode
