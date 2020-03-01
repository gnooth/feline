; Copyright (C) 2016-2020 Peter Graves <gnooth@gmail.com>

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

%macro  _gf_raw_code_address 0          ; gf -> raw-code-address
        _slot1
%endmacro

%macro  _gf_set_raw_code_address 0      ; raw-code-address gf ->
        _set_slot1
%endmacro

%macro  _this_gf_set_raw_code_address 0 ; raw-code-address ->
        _this_set_slot1
%endmacro

%macro  _gf_raw_code_size 0             ; gf -> raw-code-size
        _slot2
%endmacro

%macro  _gf_set_raw_code_size 0         ; raw-code-size gf ->
        _set_slot2
%endmacro

%macro  _this_gf_set_raw_code_size 0    ; raw-code-size ->
        _this_set_slot2
%endmacro

%macro  _gf_name 0                      ; gf -> symbol
        _slot3
%endmacro

%macro  _this_gf_set_name 0             ; symbol ->
        _this_set_slot3
%endmacro

%macro  _gf_methods 0                   ; gf -> methods
        _slot4
%endmacro

%macro  _gf_set_methods 0               ; methods gf ->
        _set_slot4
%endmacro

%macro  _this_gf_set_methods 0          ; methods ->
        _this_set_slot4
%endmacro

%macro  _gf_dispatch 0                  ; gf -> dispatch
        _slot5
%endmacro

%macro  _gf_set_dispatch 0              ; dispatch gf ->
        _set_slot5
%endmacro

%macro  _this_gf_set_dispatch 0         ; dispatch ->
        _this_set_slot5
%endmacro

; ### generic-function?
code generic_function?, 'generic-function?'     ; handle -> ?
        _ deref                         ; -> raw-object/0
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
code check_generic_function, 'check-generic-function'   ; handle -> gf
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
code verify_generic_function, 'verify-generic-function' ; handle -> handle
        _dup
        _ generic_function?
        _tagged_if .1
        _return
        _then .1

        _ error_not_generic_function
        next
endcode

; ### <generic-function>
code new_generic_function, '<generic-function>' ; symbol -> gf
; 6 slots: object header, raw code address, raw code size, symbol, methods, dispatch

        _lit 6
        _ raw_allocate_cells

        push    this_register
        mov     this_register, rbx
        _drop

        _this_object_set_raw_typecode TYPECODE_GENERIC_FUNCTION

        _this_gf_set_name

        _nil
        _this_gf_set_methods

        _nil
        _this_gf_set_dispatch

        _dup
        mov     rbx, this_register
        pop     this_register

        _ new_handle

        next
endcode

; ### generic-function-name
code generic_function_name, 'generic-function-name'     ; gf -> symbol
        _ check_generic_function
        _gf_name
        next
endcode

; ### generic-function-methods
code generic_function_methods, 'generic-function-methods'       ; gf -> methods
        _ check_generic_function
        _gf_methods
        next
endcode

; ### generic-function-set-methods
code generic_function_set_methods, 'generic-function-set-methods'       ; methods gf ->
        _ check_generic_function
        _gf_set_methods
        next
endcode

; ### generic-function-dispatch
code generic_function_dispatch, 'generic-function-dispatch'     ; gf -> dispatch
        _ check_generic_function
        _gf_dispatch
        next
endcode

; ### generic-function-set-dispatch
code generic_function_set_dispatch, 'generic-function-set-dispatch'     ; dispatch gf ->
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

%define DEFAULT_METHOD tagged_fixnum(65535)

; ### set-default-method
code set_default_method, 'set-default-method' ; callable generic-symbol -> void
        _dup
        _ generic?
        _tagged_if .1
        _ symbol_def
        _ generic_function_dispatch
        _swap
        _ callable_raw_code_address
        _swap
        _lit DEFAULT_METHOD
        _swap
        _ hashtable_set_at
        _else .1
        _ error_not_generic_word
        _then .1
        next
endcode

; ### do-generic
code do_generic, 'do-generic'           ; object typecode dispatch-table ->

        push    rbx                     ; save dispatch table

        _ hashtable_at                  ; -> object raw-code-address/nil

        cmp     rbx, NIL
        je      .1
        _rdrop                          ; drop dispatch table
        mov     rax, rbx
        _drop
%ifdef DEBUG
        call    rax
        _return
%else
        jmp     rax
%endif

.1:                                     ; -> object f
        ; typecode lookup failed
        ; is there a default method?
        pop     rbx                     ; -> object dispatch-table
        _lit DEFAULT_METHOD
        _swap
        _ hashtable_at
        cmp     rbx, NIL
        je      .2
        mov     rax, rbx
        _drop
%ifdef DEBUG
        call    rax
        _return
%else
        jmp     rax
%endif

.2:
        mov     rbx, [rsp]
        _tag_fixnum                     ; -> object return-address
        _ error_no_method
        next
endcode

%macro  generic 2

        global %1_generic_function_dispatch_table
        section .data
        align   DEFAULT_DATA_ALIGNMENT
%1_generic_function_dispatch_table:
        dq      0

        code %1, %2, SYMBOL_GENERIC
        _dup
        _ object_typecode
        _dup
        mov     rbx, [%1_generic_function_dispatch_table]
        call    do_generic
        next
        endcode

%endmacro

; ### make-fixnum-hashtable/0
code make_fixnum_hashtable_0, 'make-fixnum-hashtable/0' ; -> hashtable
; return a new hashtable with hash and test functions suitable for fixnum keys

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
code initialize_generic_function, 'initialize-generic-function' ; generic-symbol -> gf

        _dup
        _ new_generic_function          ; -> symbol gf

        ; methods
        _ make_fixnum_hashtable_0
        _over
        _ generic_function_set_methods

        ; dispatch
        _ make_fixnum_hashtable_0
        _over
        _ generic_function_set_dispatch ; -> symbol gf

        _duptor
        _swap                           ; -> gf symbol
        _ symbol_set_def

        _rfrom

        next
endcode

; ### define-generic
code define_generic, 'define-generic'   ; symbol -> symbol

        _dup
        _ new_generic_function          ; -> symbol gf

        _tor                            ; -> symbol     r: -> gf

        ; methods
        _ make_fixnum_hashtable_0
        _rfetch
        _ generic_function_set_methods

        ; dispatch table
        _ make_fixnum_hashtable_0
        _rfetch
        _ generic_function_set_dispatch ; -> symbol

        _lit S_dup
        _lit S_object_typecode
        _rfetch
        _ generic_function_dispatch
        _lit S_do_generic
        _ four_array
        _ array_to_quotation
        _ compile_quotation             ; -> symbol quotation

        _dup
        _ quotation_code_address
        _pick
        _ symbol_set_code_address

        _ quotation_code_size
        _over
        _ symbol_set_code_size          ; -> symbol

        _rfrom                          ; -> symbol gf          r: -> void

        _over
        _ symbol_set_def

        _dup
        _ symbol_set_generic

        next
endcode

; ### find-method
code find_method, 'find-method'         ; symbol-or-type symbol-or-gf -> method/nil

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
        _ must_find_type
        _then .3
        _ type_typecode
        _swap

        _ generic_function_methods
        _ verify_hashtable
        _ hashtable_at

        next
endcode

%macro _initialize_generic_function 1
        _lit S_%1
        _ initialize_generic_function   ; -> gf
        _ generic_function_dispatch     ; -> hashtable
        mov     [%1_generic_function_dispatch_table], rbx
        _drop                           ; -> void
%endmacro

; ### install-method
code install_method, 'install-method'   ; method -> void

        ; add method to generic function's methods hashtable
        _duptor

        _dup                            ; -> method method
        _ method_typecode               ; -> method typecode
        _over
        _ method_generic_function
        _ generic_function_methods
        _ verify_hashtable              ; -> method typecode ht
        _ hashtable_set_at

        _rfrom                          ; -> method

        ; add method's raw code address to generic function's dispatch table
        _dup
        _ method_callable
        _ callable_raw_code_address     ; -> method raw-code-address
        _swap                           ; -> raw-code-address method
        _dup
        _ method_typecode               ; -> raw-code-address method typecode
        _swap

        _ method_generic_function       ; -> raw-code-address typecode gf

        _ generic_function_dispatch
        _ verify_hashtable
        _ hashtable_set_at

        next
endcode

%macro _add_method 3            ; generic-asm-name, raw-typecode, method-asm-name
        _lit %2                         ; -> raw-typecode
        _tag_fixnum                     ; -> tagged-typecode
        _lit S_%1                       ; -> tagged-typecode generic-symbol
        _ symbol_def                    ; -> tagged-typecode generic-function
%ifdef DEBUG
        _ verify_generic_function
%endif
        _lit S_%3                       ; -> tagged-typecode generic-function callable
        _ new_method                    ; -> method
        _ install_method                ; ->
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

; ### head
generic generic_head, 'head'

; ### tail
generic generic_tail, 'tail'

; ### new-sequence
generic new_sequence, 'new-sequence'    ; len seq -> new-seq

; ### +
generic generic_plus, '+'               ; x y -> z

; ### -
generic generic_minus, '-'              ; x y -> z

; ### *
generic generic_multiply, '*'           ; x y -> z

; ### /
generic generic_divide, '/'             ; x y -> z

; ### /i
generic generic_divide_truncate, '/i'   ; x y -> z

; ### abs
generic generic_abs, 'abs'              ; x -> y

; ### mod
generic generic_mod, 'mod'              ; x y -> z

; ### negate
generic generic_negate, 'negate'        ; n -> -n

; ### <
generic generic_lt, '<'                 ; x y -> ?

; ### >
generic generic_gt, '>'                 ; x y -> ?

; ### <=
generic generic_le, '<='                ; x y -> ?

; ### >=
generic generic_ge, '>='                ; x y -> ?

; ### write
generic generic_write, 'write'          ; string/sbuf ->

; ### substring
generic substring, 'substring'          ; from to string/sbuf -> substring

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

; ### object->string
generic object_to_string, 'object->string' ; object -> string

; ### initialize_generic_functions
code initialize_generic_functions, 'initialize_generic_functions', SYMBOL_INTERNAL ; ->

        ; hashcode
        _initialize_generic_function generic_hashcode
        _add_method generic_hashcode, TYPECODE_CHAR, char_hashcode
        _add_method generic_hashcode, TYPECODE_FIXNUM, fixnum_hashcode
        _add_method generic_hashcode, TYPECODE_STRING, string_hashcode
        _add_method generic_hashcode, TYPECODE_SYMBOL, symbol_hashcode
        _add_method generic_hashcode, TYPECODE_KEYWORD, keyword_hashcode

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
        _add_method equal?, TYPECODE_VOCAB, eq?
        _add_method equal?, TYPECODE_KEYWORD, eq?

        ; length
        _initialize_generic_function length
        _add_method length, TYPECODE_STRING, string_length_unsafe
        _add_method length, TYPECODE_SBUF, sbuf_length
        _add_method length, TYPECODE_ARRAY, array_length
        _add_method length, TYPECODE_VECTOR, vector_length_unsafe
        _add_method length, TYPECODE_SLICE, slice_length
        _add_method length, TYPECODE_RANGE, range_length
        _add_method length, TYPECODE_QUOTATION, quotation_length

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

        ; nth-unsafe
        _initialize_generic_function nth_unsafe
        _add_method nth_unsafe, TYPECODE_STRING, string_nth_unsafe
        _add_method nth_unsafe, TYPECODE_SBUF, sbuf_nth_unsafe
        _add_method nth_unsafe, TYPECODE_ARRAY, array_nth_unsafe
        _add_method nth_unsafe, TYPECODE_VECTOR, vector_nth_unsafe
        _add_method nth_unsafe, TYPECODE_SLICE, slice_nth_unsafe
        _add_method nth_unsafe, TYPECODE_RANGE, range_nth_unsafe
        _add_method nth_unsafe, TYPECODE_QUOTATION, quotation_nth_unsafe

        ; set-nth
        _initialize_generic_function set_nth
        _add_method set_nth, TYPECODE_ARRAY, array_set_nth
        _add_method set_nth, TYPECODE_VECTOR, vector_set_nth

        ; head
        _initialize_generic_function generic_head
        _add_method generic_head, TYPECODE_STRING, string_head

        ; tail
        _initialize_generic_function generic_tail
        _add_method generic_tail, TYPECODE_STRING, string_tail

        ; new-sequence
        _initialize_generic_function new_sequence
        _add_method new_sequence, TYPECODE_ARRAY, array_new_sequence
        _add_method new_sequence, TYPECODE_VECTOR, vector_new_sequence

        ; +
        _initialize_generic_function generic_plus
        _add_method generic_plus, TYPECODE_FIXNUM, fixnum_plus
        _add_method generic_plus, TYPECODE_INT64, int64_plus
        _add_method generic_plus, TYPECODE_FLOAT, float_plus
        ; REVIEW
        _add_method generic_plus, TYPECODE_STRING, string_append

        ; -
        _initialize_generic_function generic_minus
        _add_method generic_minus, TYPECODE_FIXNUM, fixnum_minus
        _add_method generic_minus, TYPECODE_INT64, int64_minus
        _add_method generic_minus, TYPECODE_FLOAT, float_minus

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

        ; object-to-string
        _initialize_generic_function object_to_string
        _add_method object_to_string, TYPECODE_BOOLEAN, boolean_to_string
        _add_method object_to_string, TYPECODE_STRING, quote_string
        _add_method object_to_string, TYPECODE_SBUF, sbuf_description
        _add_method object_to_string, TYPECODE_VECTOR, vector_to_string
        _add_method object_to_string, TYPECODE_ARRAY, array_to_string
        _add_method object_to_string, TYPECODE_FIXNUM, fixnum_to_string
        _add_method object_to_string, TYPECODE_HASHTABLE, hashtable_to_string
        _add_method object_to_string, TYPECODE_FIXNUM_HASHTABLE, fixnum_hashtable_to_string
        _add_method object_to_string, TYPECODE_SYMBOL, symbol_name
        _add_method object_to_string, TYPECODE_VOCAB, vocab_to_string
        _add_method object_to_string, TYPECODE_QUOTATION, quotation_to_string
        _add_method object_to_string, TYPECODE_WRAPPER, wrapper_to_string
        _add_method object_to_string, TYPECODE_SLICE, slice_to_string
        _add_method object_to_string, TYPECODE_RANGE, range_to_string
        _add_method object_to_string, TYPECODE_LEXER, lexer_to_string
        _add_method object_to_string, TYPECODE_FLOAT, float_to_string
        _add_method object_to_string, TYPECODE_ITERATOR, iterator_to_string
        _add_method object_to_string, TYPECODE_TYPE, type_to_string
        _add_method object_to_string, TYPECODE_METHOD, method_to_string
        _add_method object_to_string, TYPECODE_GENERIC_FUNCTION, generic_function_to_string
        _add_method object_to_string, TYPECODE_UINT64, uint64_to_string
        _add_method object_to_string, TYPECODE_INT64, int64_to_string
        _add_method object_to_string, TYPECODE_CHAR, char_to_string
        _add_method object_to_string, TYPECODE_KEYWORD, keyword_to_string
        _add_method object_to_string, TYPECODE_THREAD, thread_to_string
        _add_method object_to_string, TYPECODE_MUTEX, mutex_to_string
        _add_method object_to_string, TYPECODE_STRING_ITERATOR, string_iterator_to_string
        _add_method object_to_string, TYPECODE_SLOT, slot_to_string
        _add_method object_to_string, TYPECODE_FILE_OUTPUT_STREAM, file_output_stream_to_string
        _add_method object_to_string, TYPECODE_STRING_OUTPUT_STREAM, string_output_stream_to_string

        _lit S_object_to_string_default
        _lit S_object_to_string
        _ set_default_method
        next
endcode
