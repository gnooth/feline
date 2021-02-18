; Copyright (C) 2017-2021 Peter Graves <gnooth@gmail.com>

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

; 4 cells: object header, type symbol, raw typecode, layout

%macro  _type_symbol 0                  ; type -> symbol
        _slot1
%endmacro

%macro  _type_set_symbol 0              ; symbol type ->
        _set_slot1
%endmacro

%macro  _this_type_symbol 0             ; -> symbol
        _this_slot1
%endmacro

%macro  _this_type_set_symbol 0         ; symbol ->
        _this_set_slot1
%endmacro

%macro  _type_raw_typecode 0            ; type -> raw-typecode
        _slot2
%endmacro

%macro  _type_set_raw_typecode 0        ; raw-typecode type ->
        _set_slot2
%endmacro

%macro  _this_type_raw_typecode 0       ; -> raw-typecode
        _this_slot2
%endmacro

%macro  _this_type_set_raw_typecode 0   ; raw-typecode ->
        _this_set_slot2
%endmacro

%macro  _type_layout 0                  ; type -> layout
        _slot3
%endmacro

%macro  _type_set_layout 0              ; layout type ->
        _set_slot3
%endmacro

%macro  _this_type_layout 0             ; -> layout
        _this_slot3
%endmacro

%macro  _this_type_set_layout 0         ; layout ->
        _this_set_slot3
%endmacro

; ### type?
code type?, 'type?'                 ; x -> x/nil
; If x is a type, returns x unchanged. If x is not a type, returns nil.
        cmp     bl, HANDLE_TAG
        jne     .not_a_type
        mov     rax, rbx
        shr     rax, HANDLE_TAG_BITS
        mov     rax, [rax]
        cmp     word [rax], TYPECODE_TYPE
        jne     .not_a_type
        next
.not_a_type:
        mov     ebx, NIL
        next
endcode

; ### check-type
code check_type, 'check-type'           ; handle -> type
        _dup
        _ deref
        test    rbx, rbx
        jz      .error
        movzx   eax, word [rbx]
        cmp     eax, TYPECODE_TYPE
        jne     .error
        _nip
        next
.error:
        _drop
        _ error_not_type
        next
endcode

; ### verify-type
code verify_type, 'verify-type'         ; type -> type
        cmp     bl, HANDLE_TAG
        jne     error_not_type
        mov     rax, rbx
        _handle_to_object_unsafe
        test    rbx, rbx
        jz      error_empty_handle
        _object_raw_typecode
        cmp     rbx, TYPECODE_TYPE
        mov     rbx, rax
        jne     error_not_type
        next
endcode

; ### make-type
code make_type, 'make-type'             ; symbol typecode -> type
; 4 slots: object header, symbol, typecode, layout

        _check_fixnum                   ; -> symbol raw-typecode

        _lit 4
        _ raw_allocate_cells

        push    this_register
        mov     this_register, rbx
        poprbx                          ; -> symbol raw-typecode

        _this_object_set_raw_typecode TYPECODE_TYPE

        _this_object_set_flags OBJECT_ALLOCATED_BIT

        _this_type_set_raw_typecode     ; -> symbol

        _dup
        _this_type_set_symbol

        _f
        _this_type_set_layout

        pushrbx
        mov     rbx, this_register      ; -> symbol raw-object-address
        pop     this_register

        _ new_handle                    ; -> symbol type

        _twodup
        _swap
        _ symbol_set_value              ; -> symbol type

        _over                           ; -> symbol type symbol
        _ new_wrapper
        _symbol symbol_value
        _ two_array
        _ array_to_quotation            ; -> symbol type quotation
        _pick                           ; -> symbol type quotation symbol
        _ symbol_set_def                ; -> symbol type
        _swap
        _ compile_word

        next
endcode

; ### make-tuple-type
code make_tuple_type, 'make-tuple-type' ; symbol slots -> type
        _swap
        _ next_typecode
        _duptor
        _ make_type
        _tuck
        _ type_set_layout
        _dup
        _rfrom
        _ types
        _ vector_set_nth
        next
endcode

asm_global types_

; ### types
code types, 'types'                     ; -> sequence
        _dup
        mov     rbx, [types_]
        next
endcode

; ### type-name-from-typecode
code type_name_from_typecode, 'type-name-from-typecode' ; fixnum -> string
        _ types
        _ vector_nth
        _ type_name
        next
endcode

; ### add_builtin_type
code add_builtin_type, 'add_builtin_type', SYMBOL_INTERNAL ; name typecode ->
        _tor                            ; -> name       r: -> typecode
        _ new_symbol_in_current_vocab   ; -> symbol
        _rfetch
        _ make_type                     ; -> type
        _rfrom                          ; -> type typecode
        _ types
        _ vector_set_nth
        next
endcode

%macro  _add_type 2                     ; name raw-typecode -> void
        _quote %1
        _lit tagged_fixnum(%2)
        _ add_builtin_type
%endmacro

; ### initialize_types
code initialize_types, 'initialize_types', SYMBOL_INTERNAL
        _lit types_
        _ gc_add_root

        _lit 64
        _ new_vector_untagged
        mov     [types_], rbx
        _drop

        _add_type "unknown", TYPECODE_UNKNOWN
        _add_type "fixnum", TYPECODE_FIXNUM
        _add_type "boolean", TYPECODE_BOOLEAN
        _add_type "vector", TYPECODE_VECTOR
        _add_type "string", TYPECODE_STRING
        _add_type "sbuf", TYPECODE_SBUF
        _add_type "array", TYPECODE_ARRAY
        _add_type "hashtable", TYPECODE_HASHTABLE
        _add_type "char", TYPECODE_CHAR
        _add_type "symbol", TYPECODE_SYMBOL
        _add_type "vocab", TYPECODE_VOCAB
        _add_type "quotation", TYPECODE_QUOTATION
        _add_type "wrapper", TYPECODE_WRAPPER
        _add_type "tuple", TYPECODE_TUPLE
        _add_type "slice", TYPECODE_SLICE
        _add_type "range", TYPECODE_RANGE
        _add_type "lexer", TYPECODE_LEXER
        _add_type "float", TYPECODE_FLOAT
        _add_type "iterator", TYPECODE_ITERATOR
        _add_type "method", TYPECODE_METHOD
        _add_type "generic-function", TYPECODE_GENERIC_FUNCTION
        _add_type "uint64", TYPECODE_UINT64
        _add_type "int64", TYPECODE_INT64
        _add_type "type", TYPECODE_TYPE
        _add_type "keyword", TYPECODE_KEYWORD
        _add_type "thread", TYPECODE_THREAD
        _add_type "mutex", TYPECODE_MUTEX
        _add_type "string-iterator", TYPECODE_STRING_ITERATOR
        _add_type "slot", TYPECODE_SLOT
        _add_type "file-output-stream", TYPECODE_FILE_OUTPUT_STREAM
        _add_type "string-output-stream", TYPECODE_STRING_OUTPUT_STREAM
        _add_type "fixnum-hashtable", TYPECODE_FIXNUM_HASHTABLE
        _add_type "equal-hashtable", TYPECODE_EQUAL_HASHTABLE
        _add_type "string-slice", TYPECODE_STRING_SLICE
        _add_type "bit-array", TYPECODE_BIT_ARRAY
        _add_type "byte-vector", TYPECODE_BYTE_VECTOR
        _add_type "lvar", TYPECODE_LVAR

        next
endcode

; ### type-symbol
code type_symbol, 'type-symbol'         ; type -> symbol
        _ check_type
        _type_symbol
        next
endcode

; ### type-name
code type_name, 'type-name'             ; type -> string
        _ type_symbol
        _ symbol_name
        next
endcode

; ### type_raw_typecode
code type_raw_typecode, 'type_raw_typecode'     ; type -> raw-typecode
        _ check_type
        _type_raw_typecode
        next
endcode

; ### type-typecode
code type_typecode, 'type-typecode'     ; type -> tagged-typecode
        _ check_type
        _type_raw_typecode
        _tag_fixnum
        next
endcode

; ### type-layout
code type_layout, 'type-layout'         ; type -> layout
        _ check_type
        _type_layout
        next
endcode

; ### type-set-layout
code type_set_layout, 'type-set-layout' ; layout type -> void
        _ check_type
        _type_set_layout
        next
endcode

; ### raw_typecode_to_type
code raw_typecode_to_type, 'raw_typecode_to_type', SYMBOL_INTERNAL
; raw-typecode -> type
        _ types
        _ vector_nth_untagged
        next
endcode

; ### typecode->type
code typecode_to_type, 'typecode->type' ; typecode -> type
        _check_index
        _ types
        _ vector_nth_untagged
        next
endcode

; ### must-find-type
code must_find_type, 'must-find-type'   ; string -> type

        _duptor                         ; -> string     r: -> string

        _ find_name                     ; -> symbol/string ?
        _tagged_if .1                   ; -> symbol
        _ symbol_value                  ; -> x
        _dup
        _ type?                         ; -> x ?
        _tagged_if .2                   ; -> type       r: -> string
        _rdrop                          ; -> type       r: -> void
        _return
        _then .2
        _then .1

        _drop

        _rfrom

        _quote "ERROR: `%s` is not the name of a type."
        _ format
        _ error

        next
endcode

; ### type->string
code type_to_string, 'type->string'     ; type -> string

        _ verify_type
        _quote "<type "
        _ string_to_sbuf                ; -> type sbuf

        _over                           ; -> type sbuf type
        _ type_symbol
        _ symbol_name                   ; -> type sbuf string
        _ quote_string
        _over
        _ sbuf_append_string            ; -> type sbuf

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

; ### as-type
code as_type, 'as-type'                 ; x -> type
        _dup
        _ type?
        _tagged_if .1
        _return
        _then .1

        _dup
        _ symbol?
        _tagged_if .2
        _dup
        _ symbol_value
        _dup
        _ type?
        _tagged_if .3
        _nip
        _return
        _then .3
        _drop
        _then .2

        _quote "ERROR: the value `%S` does not name a type."
        _ format
        _ error

        next
endcode
