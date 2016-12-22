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
code lookup_method, 'lookup-method'     ; object methods-vector -- object raw-code-address/0
; Returns untagged 0 if no method.
        _tor                            ; -- object
        _dup
        _ object_type                   ; -- object tagged-type-number

        _dup
        _tagged_if_not .1
        _error "no object type"
        _then .1

        _rfrom                          ; -- object tagged-type-number vector
        _twodup
        _ vector_length
        _ fixnum_lt
        _tagged_if .2                   ; -- object n vector
        _ vector_nth_unsafe             ; -- object method/0
        _else .2
        _2drop                          ; -- object
        _zero                           ; -- object 0
        _then .2
        next
endcode

; ### do-generic
code do_generic, 'do-generic'   ; methods-vector --
        _ lookup_method         ; -- raw-code-address/0
        _dup
        _if .1
        mov     rax, rbx
        poprbx
        call    rax
        _else .1
        _drop
        _error "no method"
        _then .1
        next
endcode

%macro generic 2
        code %1, %2
        ; REVIEW
        ; We need to do something like this for calls from asm to work.
        _lit S_%1
        _ call_symbol
        next
        endcode
%endmacro

; ### initialize-generic-function
code initialize_generic_function, 'initialize-generic-function' ; symbol --
        _lit 10
        _ new_vector_untagged   ; -- symbol methods-vector
        _lit S_do_generic
        _ two_array             ; -- symbol array
        _ array_to_quotation    ; -- symbol quotation
        _over
        _ symbol_set_def        ; -- symbol
        _ compile_word
        next
endcode

; ### add-method
code add_method, 'add-method'   ; method-symbol untagged-type-number generic-symbol --
        _ symbol_def
        _ quotation_array
        _ array_first           ; -- method-symbol untagged-type-number methods-vector

        _ verify_vector

        _ rot
        _ symbol_raw_code_address
        _ rrot

        _ vector_set_nth_untagged
        next
endcode

; ### hashcode
generic hashcode, 'hashcode'

; ### equal?
generic equal?, 'equal?'

; ### f-equal?
code f_equal?, 'f-equal?'
        _2drop
        _f
        next
endcode

; ### length
generic length, 'length'

; ### push
generic push, 'push'

; ### nth
generic nth, 'nth'

; ### nth-unsafe
generic nth_unsafe, 'nth-unsafe'

; ### set-nth
generic set_nth, 'set-nth'

; ### new-sequence
generic new_sequence, 'new-sequence'    ; len seq -- new-seq

%macro _initialize_generic_function 1   ; generic-asm-name --
        _lit S_%1
        _ initialize_generic_function
%endmacro

%macro _add_method 3 ; generic-asm-name, object-type, method-asm-name
        _lit S_%3
        _lit %2
        _lit S_%1
        _ add_method
%endmacro

; ### initialize-generic-functions
code initialize_generic_functions, 'initialize-generic-functions' ; --

        ; hashcode
        _initialize_generic_function hashcode
        _add_method hashcode, OBJECT_TYPE_STRING, string_hashcode
        _add_method hashcode, OBJECT_TYPE_SYMBOL, symbol_hashcode

        ; equal?
        _initialize_generic_function equal?
        _add_method equal?, OBJECT_TYPE_FIXNUM, fixnum_equal?
        _add_method equal?, OBJECT_TYPE_ARRAY, array_equal?
        _add_method equal?, OBJECT_TYPE_VECTOR, vector_equal?
        _add_method equal?, OBJECT_TYPE_STRING, string_equal?
        _add_method equal?, OBJECT_TYPE_SYMBOL, symbol_equal?
        _add_method equal?, OBJECT_TYPE_F, f_equal?
        _add_method equal?, OBJECT_TYPE_BIGNUM, bignum_equal?

        ; length
        _initialize_generic_function length
        _add_method length, OBJECT_TYPE_STRING, string_length
        _add_method length, OBJECT_TYPE_SBUF, sbuf_length
        _add_method length, OBJECT_TYPE_ARRAY, array_length
        _add_method length, OBJECT_TYPE_VECTOR, vector_length
        _add_method length, OBJECT_TYPE_SLICE, slice_length
        _add_method length, OBJECT_TYPE_RANGE, range_length

        ; push
        _initialize_generic_function push
        _add_method push, OBJECT_TYPE_VECTOR, vector_push
        _add_method push, OBJECT_TYPE_SBUF, sbuf_push

        ; nth
        _initialize_generic_function nth
        _add_method nth, OBJECT_TYPE_ARRAY, array_nth
        _add_method nth, OBJECT_TYPE_VECTOR, vector_nth
        _add_method nth, OBJECT_TYPE_STRING, string_nth
        _add_method nth, OBJECT_TYPE_SBUF, sbuf_nth
        _add_method nth, OBJECT_TYPE_SLICE, slice_nth

        ; nth-unsafe
        _initialize_generic_function nth_unsafe
        _add_method nth_unsafe, OBJECT_TYPE_STRING, string_nth_unsafe
        _add_method nth_unsafe, OBJECT_TYPE_SBUF, sbuf_nth_unsafe
        _add_method nth_unsafe, OBJECT_TYPE_ARRAY, array_nth_unsafe
        _add_method nth_unsafe, OBJECT_TYPE_VECTOR, vector_nth_unsafe
        _add_method nth_unsafe, OBJECT_TYPE_SLICE, slice_nth_unsafe
        _add_method nth_unsafe, OBJECT_TYPE_RANGE, range_nth_unsafe

        ; set-nth
        _initialize_generic_function set_nth
        _add_method set_nth, OBJECT_TYPE_ARRAY, array_set_nth
        _add_method set_nth, OBJECT_TYPE_VECTOR, vector_set_nth

        ; new-sequence
        _initialize_generic_function new_sequence
        _add_method new_sequence, OBJECT_TYPE_ARRAY, array_new_sequence
        _add_method new_sequence, OBJECT_TYPE_VECTOR, vector_new_sequence

        next
endcode
