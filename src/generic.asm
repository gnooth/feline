; Copyright (C) 2016-2018 Peter Graves <gnooth@gmail.com>

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

%macro  _gf_name 0                      ; gf -- symbol
        _slot3
%endmacro

%macro  _this_gf_set_name 0             ; symbol --
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

        _this_gf_set_name

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

; ### generic-function-name
code generic_function_name, 'generic-function-name'     ; gf -- symbol
        _ check_generic_function
        _gf_name
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

; ### generic-function-to-string
code generic_function_to_string, 'generic-function-to-string'   ; generic-function -> string

        _ verify_generic_function
        _quote "<generic-function "
        _ string_to_sbuf                ; -> gf sbuf

        _over                           ; -> gf sbuf generic
        _ generic_function_name
        _ symbol_name                   ; -> gf sbuf name
        _ quote_string
        _over
        _ sbuf_append_string            ; -> gf sbuf

        _quote " 0x"
        _over
        _ sbuf_append_string

        _swap
        _ object_address
        _ to_hex
        _over
        _ sbuf_append_string

        _quote ">"
        _over
        _ sbuf_append_string

        _ sbuf_to_string

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

; ### do_generic
code do_generic, 'do_generic', SYMBOL_INTERNAL  ; object dispatch-table --
        _lookup_method                  ; -- object raw-code-address/f
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
.1:                                     ; -- object f
        mov     rbx, [rsp]
        _tag_fixnum                     ; -- object return-address
        _ error_no_method
        next
endcode

%macro  generic 2
        code %1, %2, SYMBOL_GENERIC
        pushrbx
        mov     rbx, [S_%1_symbol_value]
        call    do_generic
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

; ### find-method
code find_method, 'find-method'         ; symbol-or-type symbol-or-gf -- method

        _debug_?enough 2

        _dup
        _ symbol?
        _tagged_if .1
        _dup
        _ generic?
        _tagged_if .2
        _ symbol_def
        _else .2
        _ error_not_generic_function
        _return
        _then .2
        _then .1

        _debug_?enough 2

        _swap
        _dup
        _ symbol?
        _tagged_if .3
        _ symbol_name
        _ find_type
        _then .3
        _ type_typecode
        _swap

        _ generic_function_methods
        _ verify_hashtable
        _ hashtable_at

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
        _over
        _ method_typecode
        _pick
        _ method_generic_function       ; -- method callable typecode gf
        _ generic_function_methods
        _ verify_hashtable
        _ hashtable_set_at

        _dup
        _ method_callable
        _ callable_raw_code_address     ; -- method method-raw-code-address
        _swap                           ; -- method-raw-code-address method
        _dup
        _ method_typecode               ; -- method-raw-code-address method typecode
        _swap

        _ method_generic_function       ; -- method-raw-code-address typecode gf

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

; ### 1+
generic generic_oneplus, '1+'           ; x y -- z

; ### 1-
generic generic_oneminus, '1-'          ; x y -- z

; ### *
generic generic_multiply, '*'           ; x y -- z

; ### /
generic generic_divide, '/'             ; x y -- z

; ### /i
generic generic_divide_truncate, '/i'   ; x y -- z

; ### abs
generic generic_abs, 'abs'              ; x -- y

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
generic to_float, '>float'

; ### stream-write-char
generic stream_write_char, 'stream-write-char'  ; char stream -> void

; ### stream-write-char-escaped
generic stream_write_char_escaped, 'stream-write-char-escaped'  ; char stream -> void

; ### stream-write-string
generic stream_write_string, 'stream-write-string'      ; string stream -> void

; ### stream-write-string-escaped
generic stream_write_string_escaped, 'stream-write-string-escaped'      ; string stream -> void

; ### stream-output-column
generic stream_output_column, 'stream-output-column'    ; stream -> fixnum

; ### stream-nl
generic stream_nl, 'stream-nl'          ; stream -> void

; ### stream-?nl
generic stream_?nl, 'stream-?nl'        ; stream -> void

; ### close
generic generic_close, 'close'          ; stream -> void

; ### initialize_generic_functions
code initialize_generic_functions, 'initialize_generic_functions', SYMBOL_INTERNAL      ; --

        ; hashcode
        _initialize_generic_function generic_hashcode
        _add_method generic_hashcode, TYPECODE_CHAR, char_hashcode
        _add_method generic_hashcode, TYPECODE_FIXNUM, fixnum_hashcode
        _add_method generic_hashcode, TYPECODE_STRING, string_hashcode
        _add_method generic_hashcode, TYPECODE_SYMBOL, symbol_hashcode

        ; equal?
        _initialize_generic_function equal?
        _add_method equal?, TYPECODE_CHAR, eq?
        _add_method equal?, TYPECODE_FIXNUM, fixnum_equal?
        _add_method equal?, TYPECODE_ARRAY, array_equal?
        _add_method equal?, TYPECODE_VECTOR, vector_equal?
        _add_method equal?, TYPECODE_STRING, string_equal?
        _add_method equal?, TYPECODE_SYMBOL, symbol_equal?
        _add_method equal?, TYPECODE_BOOLEAN, boolean_equal?
        _add_method equal?, TYPECODE_FLOAT, float_equal?
        _add_method equal?, TYPECODE_INT64, int64_equal?
        _add_method equal?, TYPECODE_UINT64, uint64_equal?
        _add_method equal?, TYPECODE_THREAD, eq?

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
        _add_method generic_plus, TYPECODE_INT64, int64_plus
        _add_method generic_plus, TYPECODE_FLOAT, float_plus

        ; -
        _initialize_generic_function generic_minus
        _add_method generic_minus, TYPECODE_FIXNUM, fixnum_minus
        _add_method generic_minus, TYPECODE_INT64, int64_minus
        _add_method generic_minus, TYPECODE_FLOAT, float_minus

        ; 1+
        _initialize_generic_function generic_oneplus
        _add_method generic_oneplus, TYPECODE_FIXNUM, fixnum_oneplus

        ; 1-
        _initialize_generic_function generic_oneminus
        _add_method generic_oneminus, TYPECODE_FIXNUM, fixnum_oneminus

        ; *
        _initialize_generic_function generic_multiply
        _add_method generic_multiply, TYPECODE_FIXNUM, fixnum_multiply
        _add_method generic_multiply, TYPECODE_INT64, int64_multiply
        _add_method generic_multiply, TYPECODE_FLOAT, float_multiply

        ; /
        _initialize_generic_function generic_divide
        _add_method generic_divide, TYPECODE_FIXNUM, fixnum_divide_float
        _add_method generic_divide, TYPECODE_INT64, int64_divide_float
        _add_method generic_divide, TYPECODE_FLOAT, float_divide

        ; /i
        _initialize_generic_function generic_divide_truncate
        _add_method generic_divide_truncate, TYPECODE_FIXNUM, fixnum_divide_truncate
        _add_method generic_divide_truncate, TYPECODE_INT64, int64_divide_truncate
        _add_method generic_divide_truncate, TYPECODE_FLOAT, float_divide_truncate

        ; abs
        _initialize_generic_function generic_abs
        _add_method generic_abs, TYPECODE_FIXNUM, fixnum_abs
        _add_method generic_abs, TYPECODE_INT64, int64_abs
        _add_method generic_abs, TYPECODE_FLOAT, float_abs

        ; mod
        _initialize_generic_function generic_mod
        _add_method generic_mod, TYPECODE_FIXNUM, fixnum_mod
        _add_method generic_mod, TYPECODE_INT64, int64_mod

        ; negate
        _initialize_generic_function generic_negate
        _add_method generic_negate, TYPECODE_FIXNUM, fixnum_negate
        _add_method generic_negate, TYPECODE_FLOAT, float_negate
        _add_method generic_negate, TYPECODE_INT64, int64_negate
        _add_method generic_negate, TYPECODE_UINT64, uint64_negate

        ; <
        _initialize_generic_function generic_lt
        _add_method generic_lt, TYPECODE_FIXNUM, fixnum_lt
        _add_method generic_lt, TYPECODE_INT64, int64_lt
        _add_method generic_lt, TYPECODE_FLOAT, float_lt

        ; >
        _initialize_generic_function generic_gt
        _add_method generic_gt, TYPECODE_FIXNUM, fixnum_gt
        _add_method generic_gt, TYPECODE_INT64, int64_gt
        _add_method generic_gt, TYPECODE_FLOAT, float_gt

        ; <=
        _initialize_generic_function generic_le
        _add_method generic_le, TYPECODE_FIXNUM, fixnum_le
        _add_method generic_le, TYPECODE_FLOAT, float_le
        _add_method generic_le, TYPECODE_INT64, int64_le

        ; >=
        _initialize_generic_function generic_ge
        _add_method generic_ge, TYPECODE_FIXNUM, fixnum_ge
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
        _initialize_generic_function to_float
        _add_method to_float, TYPECODE_FIXNUM, fixnum_to_float
        _add_method to_float, TYPECODE_INT64, int64_to_float
        _add_method to_float, TYPECODE_FLOAT, identity
        _add_method to_float, TYPECODE_STRING, string_to_float

        ; stream-write-char
        _initialize_generic_function stream_write_char
        _add_method stream_write_char, TYPECODE_FILE_OUTPUT_STREAM, file_output_stream_write_char
        _add_method stream_write_char, TYPECODE_STRING_OUTPUT_STREAM, string_output_stream_write_char

        ; stream-write-char-escaped
        _initialize_generic_function stream_write_char_escaped
        _add_method stream_write_char_escaped, TYPECODE_FILE_OUTPUT_STREAM, file_output_stream_write_char_escaped
        _add_method stream_write_char_escaped, TYPECODE_STRING_OUTPUT_STREAM, string_output_stream_write_char_escaped

        ; stream-write-string
        _initialize_generic_function stream_write_string
        _add_method stream_write_string, TYPECODE_FILE_OUTPUT_STREAM, file_output_stream_write_string
        _add_method stream_write_string, TYPECODE_STRING_OUTPUT_STREAM, string_output_stream_write_string

        ; stream-write-string-escaped
        _initialize_generic_function stream_write_string_escaped
        _add_method stream_write_string_escaped, TYPECODE_FILE_OUTPUT_STREAM, file_output_stream_write_string_escaped
        _add_method stream_write_string_escaped, TYPECODE_STRING_OUTPUT_STREAM, string_output_stream_write_string_escaped

        ; stream-output-column
        _initialize_generic_function stream_output_column
        _add_method stream_output_column, TYPECODE_FILE_OUTPUT_STREAM, file_output_stream_output_column
        _add_method stream_output_column, TYPECODE_STRING_OUTPUT_STREAM, string_output_stream_output_column

        ; stream-nl
        _initialize_generic_function stream_nl
        _add_method stream_nl, TYPECODE_FILE_OUTPUT_STREAM, file_output_stream_nl
        _add_method stream_nl, TYPECODE_STRING_OUTPUT_STREAM, string_output_stream_nl

        ; stream-?nl
        _initialize_generic_function stream_?nl
        _add_method stream_?nl, TYPECODE_FILE_OUTPUT_STREAM, file_output_stream_?nl
        _add_method stream_?nl, TYPECODE_STRING_OUTPUT_STREAM, string_output_stream_?nl

        ; close
        _initialize_generic_function generic_close
        _add_method generic_close, TYPECODE_FILE_OUTPUT_STREAM, file_output_stream_close
        _add_method generic_close, TYPECODE_STRING_OUTPUT_STREAM, string_output_stream_close

        next
endcode
