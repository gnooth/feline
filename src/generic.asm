; Copyright (C) 2016-2017 Peter Graves <gnooth@gmail.com>

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

%macro  _lookup_method 0        ; object dispatch-table -- object raw-code-address/f
; return f if no method
        _over
        _ object_typecode
        _swap                   ; -- object object-type dispatch-table
        _ hashtable_at          ; -- object raw-code-address/f
%endmacro

; ### lookup-method
code lookup_method, 'lookup-method'     ; object dispatch-table -- object raw-code-address/f
        _lookup_method
        next
endcode

; ### do-generic
code do_generic, 'do-generic'   ; object dispatch-table --
        _lookup_method
        cmp     rbx, f_value
        je      .1
        mov     rax, rbx
        poprbx
        jmp     rax
.1:
        _error "no method"
        next
endcode

%macro generic 2
        code %1, %2, SYMBOL_GENERIC
        pushrbx
        mov     rbx, [S_%1_symbol_value]
        jmp     do_generic
        next
        endcode
%endmacro

; ### make-fixnum-hashtable
code make_fixnum_hashtable, 'make-fixnum-hashtable'     ; -- hashtable
; Return a new hashtable with hash and test functions suitable for fixnum keys.

        _lit 2
        _ new_hashtable_untagged

        _lit S_fixnum_hashcode
        _ symbol_raw_code_address
        _over
        _ hashtable_set_hash_function

        _lit S_eq?
        _ symbol_raw_code_address
        _over
        _ hashtable_set_test_function

        next
endcode

; ### initialize-generic-function
code initialize_generic_function, 'initialize-generic-function' ; symbol --

        _ make_fixnum_hashtable

        ; the dispatch table lives in the generic symbol's value slot
        _swap
        _ symbol_set_value              ; --
        next
endcode

%macro _initialize_generic_function 1   ; generic-asm-name --
        _lit S_%1
        _ initialize_generic_function
%endmacro

; ### add-method
code add_method, 'add-method'   ; method-raw-code-address tagged-typecode generic-symbol --
        ; the dispatch table lives in the generic symbol's value slot
        _ symbol_value          ; -- method-raw-code-address tagged-typecode dispatch-table
        _ verify_hashtable
        _ hashtable_set_at
        next
endcode

; ### install-method
code install_method, 'install-method'   ; method --
        _dup
        _ method_callable
        _ callable_raw_code_address     ; -- method method-raw-code-address
        _swap                           ; -- method-raw-code-address method
        _dup
        _ method_typecode               ; -- method-raw-code-address method typecode
        _swap
        _ method_generic                ; -- method-raw-code-address tagged-typecode generic-symbol
        _ add_method
        next
endcode

%macro _add_method 3            ; generic-asm-name, raw-typecode, method-asm-name
        _lit %2                         ; -- raw-typecde
        _tag_fixnum                     ; -- tagged-typecode
        _lit S_%1                       ; -- tagged-typecode generic-symbol
        _ new_method                    ; -- method
        _lit S_%3                       ; -- method method-symbol
        _over
        _ method_set_callable           ; -- method
        _ install_method                ; --
%endmacro

; ### hashcode
generic generic_hashcode, 'hashcode'

; ### equal?
generic equal?, 'equal?'

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

; ### +
generic generic_plus, '+'               ; x y -- z

; ### -
generic generic_minus, '-'              ; x y -- z

; ### *
generic generic_multiply, '*'           ; x y -- z

; ### /
generic generic_divide, '/'             ; x y -- z

; ### /i
generic generic_divide_truncate, '/i'   ; x y -- z

; ### mod
generic generic_mod, 'mod'              ; x y -- z

; ### negate
generic generic_negate, 'negate'        ; n -- -n

; ### <
generic generic_lt, '<'                 ; x y -- ?

; ### >
generic generic_gt, '>'                 ; x y -- ?

; ### <=
generic generic_le, '<='                ; x y -- ?

; ### >=
generic generic_ge, '>='                ; x y -- ?

; ### write
generic generic_write, 'write'          ; string/sbuf --

; ### substring
generic substring, 'substring'          ; from to string/sbuf -- substring

; ### >float
generic generic_coerce_to_float, '>float'

; ### initialize-generic-functions
code initialize_generic_functions, 'initialize-generic-functions' ; --

        ; hashcode
        _initialize_generic_function generic_hashcode
        _add_method generic_hashcode, TYPECODE_FIXNUM, fixnum_hashcode
        _add_method generic_hashcode, TYPECODE_STRING, string_hashcode
        _add_method generic_hashcode, TYPECODE_SYMBOL, symbol_hashcode

        ; equal?
        _initialize_generic_function equal?
        _add_method equal?, TYPECODE_FIXNUM, fixnum_equal?
        _add_method equal?, TYPECODE_ARRAY, array_equal?
        _add_method equal?, TYPECODE_VECTOR, vector_equal?
        _add_method equal?, TYPECODE_STRING, string_equal?
        _add_method equal?, TYPECODE_SYMBOL, symbol_equal?
        _add_method equal?, TYPECODE_BOOLEAN, boolean_equal?
        _add_method equal?, TYPECODE_BIGNUM, bignum_equal?
        _add_method equal?, TYPECODE_FLOAT, float_equal?

        ; length
        _initialize_generic_function length
        _add_method length, TYPECODE_STRING, string_length
        _add_method length, TYPECODE_SBUF, sbuf_length
        _add_method length, TYPECODE_ARRAY, array_length
        _add_method length, TYPECODE_VECTOR, vector_length
        _add_method length, TYPECODE_SLICE, slice_length
        _add_method length, TYPECODE_RANGE, range_length
        _add_method length, TYPECODE_QUOTATION, quotation_length
        _add_method length, TYPECODE_CURRY, curry_length

        ; push
        _initialize_generic_function push
        _add_method push, TYPECODE_VECTOR, vector_push
        _add_method push, TYPECODE_SBUF, sbuf_push

        ; nth
        _initialize_generic_function nth
        _add_method nth, TYPECODE_ARRAY, array_nth
        _add_method nth, TYPECODE_VECTOR, vector_nth
        _add_method nth, TYPECODE_STRING, string_nth
        _add_method nth, TYPECODE_SBUF, sbuf_nth
        _add_method nth, TYPECODE_SLICE, slice_nth
        _add_method nth, TYPECODE_QUOTATION, quotation_nth
        _add_method nth, TYPECODE_CURRY, curry_nth

        ; nth-unsafe
        _initialize_generic_function nth_unsafe
        _add_method nth_unsafe, TYPECODE_STRING, string_nth_unsafe
        _add_method nth_unsafe, TYPECODE_SBUF, sbuf_nth_unsafe
        _add_method nth_unsafe, TYPECODE_ARRAY, array_nth_unsafe
        _add_method nth_unsafe, TYPECODE_VECTOR, vector_nth_unsafe
        _add_method nth_unsafe, TYPECODE_SLICE, slice_nth_unsafe
        _add_method nth_unsafe, TYPECODE_RANGE, range_nth_unsafe
        _add_method nth_unsafe, TYPECODE_QUOTATION, quotation_nth_unsafe
        _add_method nth_unsafe, TYPECODE_CURRY, curry_nth_unsafe

        ; set-nth
        _initialize_generic_function set_nth
        _add_method set_nth, TYPECODE_ARRAY, array_set_nth
        _add_method set_nth, TYPECODE_VECTOR, vector_set_nth

        ; new-sequence
        _initialize_generic_function new_sequence
        _add_method new_sequence, TYPECODE_ARRAY, array_new_sequence
        _add_method new_sequence, TYPECODE_VECTOR, vector_new_sequence

        ; +
        _initialize_generic_function generic_plus
        _add_method generic_plus, TYPECODE_FIXNUM, fixnum_plus
        _add_method generic_plus, TYPECODE_BIGNUM, bignum_plus
        _add_method generic_plus, TYPECODE_FLOAT, float_plus

        ; -
        _initialize_generic_function generic_minus
        _add_method generic_minus, TYPECODE_FIXNUM, fixnum_minus
        _add_method generic_minus, TYPECODE_BIGNUM, bignum_minus
        _add_method generic_minus, TYPECODE_FLOAT, float_minus

        ; *
        _initialize_generic_function generic_multiply
        _add_method generic_multiply, TYPECODE_FIXNUM, fixnum_multiply
        _add_method generic_multiply, TYPECODE_BIGNUM, bignum_multiply
        _add_method generic_multiply, TYPECODE_FLOAT, float_multiply

        ; /
        _initialize_generic_function generic_divide
        _add_method generic_divide, TYPECODE_FIXNUM, fixnum_divide_float
        _add_method generic_divide, TYPECODE_BIGNUM, bignum_divide_float
        _add_method generic_divide, TYPECODE_FLOAT, float_divide

        ; /i
        _initialize_generic_function generic_divide_truncate
        _add_method generic_divide_truncate, TYPECODE_FIXNUM, fixnum_divide_truncate
        _add_method generic_divide_truncate, TYPECODE_BIGNUM, bignum_divide_truncate
        _add_method generic_divide_truncate, TYPECODE_FLOAT, float_divide_truncate

        ; mod
        _initialize_generic_function generic_mod
        _add_method generic_mod, TYPECODE_FIXNUM, fixnum_mod
        _add_method generic_mod, TYPECODE_BIGNUM, bignum_mod

        ; negate
        _initialize_generic_function generic_negate
        _add_method generic_negate, TYPECODE_FIXNUM, fixnum_negate
        _add_method generic_negate, TYPECODE_BIGNUM, bignum_negate
        _add_method generic_negate, TYPECODE_FLOAT, float_negate

        ; <
        _initialize_generic_function generic_lt
        _add_method generic_lt, TYPECODE_FIXNUM, fixnum_lt
        _add_method generic_lt, TYPECODE_BIGNUM, bignum_lt
        _add_method generic_lt, TYPECODE_FLOAT, float_lt

        ; >
        _initialize_generic_function generic_gt
        _add_method generic_gt, TYPECODE_FIXNUM, fixnum_gt
        _add_method generic_gt, TYPECODE_BIGNUM, bignum_gt
        _add_method generic_gt, TYPECODE_FLOAT, float_gt

        ; <=
        _initialize_generic_function generic_le
        _add_method generic_le, TYPECODE_FIXNUM, fixnum_le
        _add_method generic_le, TYPECODE_BIGNUM, bignum_le
        _add_method generic_le, TYPECODE_FLOAT, float_le

        ; >=
        _initialize_generic_function generic_ge
        _add_method generic_ge, TYPECODE_FIXNUM, fixnum_ge
        _add_method generic_ge, TYPECODE_BIGNUM, bignum_ge
        _add_method generic_ge, TYPECODE_FLOAT, float_ge

        ; write
        _initialize_generic_function generic_write
        _add_method generic_write, TYPECODE_STRING, write_string
        _add_method generic_write, TYPECODE_SBUF, write_sbuf

        ; substring
        _initialize_generic_function substring
        _add_method substring, TYPECODE_STRING, string_substring
        _add_method substring, TYPECODE_SBUF, sbuf_substring

        ; >float
        _initialize_generic_function generic_coerce_to_float
        _add_method generic_coerce_to_float, TYPECODE_FIXNUM, fixnum_to_float
        _add_method generic_coerce_to_float, TYPECODE_BIGNUM, bignum_to_float
        _add_method generic_coerce_to_float, TYPECODE_STRING, string_to_float

        next
endcode
