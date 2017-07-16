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

; 6 slots: object header, raw code address, raw code size, symbol, methods, dispatch

%macro  _gf_raw_code_address 0          ; gf -- raw-code-address
        _slot1
%endmacro

%macro  _gf_set_raw_code_address 0      ; raw-code-address gf --
        _set_slot1
%endmacro

%macro  _this_gf_set_raw_code_address 0 ; raw-code-address --
        _this_set_slot1
%endmacro

%macro  _gf_raw_code_size 0             ; gf -- raw-code-size
        _slot2
%endmacro

%macro  _gf_set_raw_code_size 0         ; raw-code-size gf --
        _set_slot2
%endmacro

%macro  _this_gf_set_raw_code_size 0    ; raw-code-size --
        _this_set_slot2
%endmacro

%macro  _gf_symbol 0                    ; gf -- symbol
        _slot3
%endmacro

%macro  _gf_set_symbol 0                ; symbol gf --
        _set_slot3
%endmacro

%macro  _this_gf_set_symbol 0           ; symbol --
        _this_set_slot3
%endmacro

%macro  _gf_methods 0                   ; gf -- methods
        _slot4
%endmacro

%macro  _gf_set_methods 0               ; methods gf --
        _set_slot4
%endmacro

%macro  _this_gf_set_methods 0          ; methods --
        _this_set_slot4
%endmacro

%macro  _gf_dispatch 0                  ; gf -- dispatch
        _slot5
%endmacro

%macro  _gf_set_dispatch 0              ; dispatch gf --
        _set_slot5
%endmacro

%macro  _this_gf_set_dispatch 0         ; dispatch --
        _this_set_slot5
%endmacro

; ### generic-function?
code generic_function?, 'generic-function?'     ; handle -- ?
        _ deref                         ; -- raw-object/0
        test    rbx, rbx
        jz      .1
        movzx   eax, word [rbx]
        cmp     eax, TYPECODE_GENERIC_FUNCTION
        jne     .1
        mov     ebx, t_value
        _return
.1:
        mov     ebx, f_value
        next
endcode

; ### check-generic-function
code check_generic_function, 'check-generic-function'   ; handle -- gf
        _dup
        _ deref
        test    rbx, rbx
        jz      .error
        movzx   eax, word [rbx]
        cmp     eax, TYPECODE_GENERIC_FUNCTION
        jne     .error
        _nip
        next
.error:
        _drop
        _ error_not_generic_function
        next
endcode

; ### verify-generic-function
code verify_generic_function, 'verify-generic-function' ; handle -- handle
        _dup
        _ generic_function?
        _tagged_if .1
        _return
        _then .1

        _ error_not_generic_function
        next
endcode

; ### <generic_function>
code new_generic_function, '<generic-function>' ; symbol -- gf
; 6 slots: object header, raw code address, raw code size, symbol, methods, dispatch

        _lit 6
        _ raw_allocate_cells

        push    this_register
        mov     this_register, rbx
        poprbx

        _this_object_set_raw_typecode TYPECODE_GENERIC_FUNCTION

        _this_gf_set_symbol

        _f
        _this_gf_set_methods

        _f
        _this_gf_set_dispatch

        pushrbx
        mov     rbx, this_register
        pop     this_register

        _ new_handle

        next
endcode

; ### generic-function-symbol
code generic_function_symbol, 'generic-function-symbol' ; gf -- symbol
        _ check_generic_function
        _gf_symbol
        next
endcode

; ### generic-function-methods
code generic_function_methods, 'generic-function-methods'       ; gf -- methods
        _ check_generic_function
        _gf_methods
        next
endcode

; ### generic-function-set-methods
code generic_function_set_methods, 'generic-function-set-methods'       ; methods gf --
        _ check_generic_function
        _gf_set_methods
        next
endcode

; ### generic-function-dispatch
code generic_function_dispatch, 'generic-function-dispatch'     ; gf -- dispatch
        _ check_generic_function
        _gf_dispatch
        next
endcode

; ### generic-function-set-dispatch
code generic_function_set_dispatch, 'generic-function-set-dispatch'     ; dispatch gf --
        _ check_generic_function
        _gf_set_dispatch
        next
endcode

; ### generic-function>string
code generic_function_to_string, 'generic-function>string'      ; gf -- string
        _ check_generic_function
        _gf_symbol
        _ symbol_name
        _quote "#'"
        _swap
        _ concat
        next
endcode

%macro  _lookup_method 0        ; object dispatch-table -- object raw-code-address/f
; return f if no method
        _over
        _ object_typecode
        _swap                   ; -- object typecode dispatch-table
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
%ifdef DEBUG
        call    rax
        _return
%else
        jmp     rax
%endif
.1:
        _error "no method"
        next
endcode

%macro generic 2
        code %1, %2, SYMBOL_GENERIC
        pushrbx
        mov     rbx, [S_%1_symbol_value]
%ifdef DEBUG
        call    do_generic
%else
        jmp     do_generic
%endif
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
code initialize_generic_function, 'initialize-generic-function' ; generic-symbol --

        _dup
        _ new_generic_function          ; -- symbol gf

        ; methods
        _ make_fixnum_hashtable
        _over
        _ generic_function_set_methods

        ; dispatch
        _ make_fixnum_hashtable
        _over
        _ generic_function_set_dispatch ; -- symbol gf

        _dup
        _ generic_function_dispatch
        _pick
        _ symbol_set_value

        _swap
        _ symbol_set_def                ; --

        next
endcode

%macro _initialize_generic_function 1   ; generic-asm-name --
        _lit S_%1
        _ initialize_generic_function
%endmacro

; ### add-method-to-dispatch-table
code add_method_to_dispatch_table, 'add-method-to-dispatch-table'
; method-raw-code-address tagged-typecode generic-symbol --
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

        _ method_generic_function       ; -- method-raw-code-address tagged-typecode gf

        _ generic_function_dispatch
        _ verify_hashtable
        _ hashtable_set_at

        next
endcode

%macro _add_method 3            ; generic-asm-name, raw-typecode, method-asm-name
        _lit %2                         ; -- raw-typecode
        _tag_fixnum                     ; -- tagged-typecode
        _lit S_%1                       ; -- tagged-typecode generic-symbol
        _ symbol_def                    ; -- tagged-typecode generic-function
%ifdef DEBUG
        _ verify_generic_function
%endif
        _lit S_%3                       ; -- tagged-typecode generic-function callable
        _ new_method                    ; -- method
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
%ifdef FELINE_FEATURE_BIGNUMS
        _add_method equal?, TYPECODE_BIGNUM, bignum_equal?
%endif
        _add_method equal?, TYPECODE_FLOAT, float_equal?
        _add_method equal?, TYPECODE_INT64, int64_equal?

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
%ifdef FELINE_FEATURE_BIGNUMS
        _add_method generic_plus, TYPECODE_BIGNUM, bignum_plus
%endif
        _add_method generic_plus, TYPECODE_FLOAT, float_plus

        ; -
        _initialize_generic_function generic_minus
        _add_method generic_minus, TYPECODE_FIXNUM, fixnum_minus
%ifdef FELINE_FEATURE_BIGNUMS
        _add_method generic_minus, TYPECODE_BIGNUM, bignum_minus
%endif
        _add_method generic_minus, TYPECODE_FLOAT, float_minus

        ; *
        _initialize_generic_function generic_multiply
        _add_method generic_multiply, TYPECODE_FIXNUM, fixnum_multiply
%ifdef FELINE_FEATURE_BIGNUMS
        _add_method generic_multiply, TYPECODE_BIGNUM, bignum_multiply
%endif
        _add_method generic_multiply, TYPECODE_FLOAT, float_multiply

        ; /
        _initialize_generic_function generic_divide
        _add_method generic_divide, TYPECODE_FIXNUM, fixnum_divide_float
%ifdef FELINE_FEATURE_BIGNUMS
        _add_method generic_divide, TYPECODE_BIGNUM, bignum_divide_float
%endif
        _add_method generic_divide, TYPECODE_FLOAT, float_divide

        ; /i
        _initialize_generic_function generic_divide_truncate
        _add_method generic_divide_truncate, TYPECODE_FIXNUM, fixnum_divide_truncate
%ifdef FELINE_FEATURE_BIGNUMS
        _add_method generic_divide_truncate, TYPECODE_BIGNUM, bignum_divide_truncate
%endif
        _add_method generic_divide_truncate, TYPECODE_FLOAT, float_divide_truncate

        ; mod
        _initialize_generic_function generic_mod
        _add_method generic_mod, TYPECODE_FIXNUM, fixnum_mod
%ifdef FELINE_FEATURE_BIGNUMS
        _add_method generic_mod, TYPECODE_BIGNUM, bignum_mod
%endif

        ; negate
        _initialize_generic_function generic_negate
        _add_method generic_negate, TYPECODE_FIXNUM, fixnum_negate
%ifdef FELINE_FEATURE_BIGNUMS
        _add_method generic_negate, TYPECODE_BIGNUM, bignum_negate
%endif
        _add_method generic_negate, TYPECODE_FLOAT, float_negate
        _add_method generic_negate, TYPECODE_INT64, int64_negate

        ; <
        _initialize_generic_function generic_lt
        _add_method generic_lt, TYPECODE_FIXNUM, fixnum_lt
%ifdef FELINE_FEATURE_BIGNUMS
        _add_method generic_lt, TYPECODE_BIGNUM, bignum_lt
%endif
        _add_method generic_lt, TYPECODE_FLOAT, float_lt

        ; >
        _initialize_generic_function generic_gt
        _add_method generic_gt, TYPECODE_FIXNUM, fixnum_gt
%ifdef FELINE_FEATURE_BIGNUMS
        _add_method generic_gt, TYPECODE_BIGNUM, bignum_gt
%endif
        _add_method generic_gt, TYPECODE_FLOAT, float_gt

        ; <=
        _initialize_generic_function generic_le
        _add_method generic_le, TYPECODE_FIXNUM, fixnum_le
%ifdef FELINE_FEATURE_BIGNUMS
        _add_method generic_le, TYPECODE_BIGNUM, bignum_le
%endif
        _add_method generic_le, TYPECODE_FLOAT, float_le
        _add_method generic_le, TYPECODE_INT64, int64_le

        ; >=
        _initialize_generic_function generic_ge
        _add_method generic_ge, TYPECODE_FIXNUM, fixnum_ge
%ifdef FELINE_FEATURE_BIGNUMS
        _add_method generic_ge, TYPECODE_BIGNUM, bignum_ge
%endif
        _add_method generic_ge, TYPECODE_FLOAT, float_ge
        _add_method generic_ge, TYPECODE_INT64, int64_ge

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
%ifdef FELINE_FEATURE_BIGNUMS
        _add_method generic_coerce_to_float, TYPECODE_BIGNUM, bignum_to_float
%endif
        _add_method generic_coerce_to_float, TYPECODE_FLOAT, identity
        _add_method generic_coerce_to_float, TYPECODE_STRING, string_to_float

        next
endcode
