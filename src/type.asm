; Copyright (C) 2017-2018 Peter Graves <gnooth@gmail.com>

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
code type?, 'type?'                     ; handle -> ?
        _ deref                         ; -> raw-object/0
        test    rbx, rbx
        jz      .1
        movzx   eax, word [rbx]
        cmp     eax, TYPECODE_TYPE
        jne     .1
        mov     ebx, t_value
        _return
.1:
        mov     ebx, f_value
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
code verify_type, 'verify-type'         ; type -- type
        _dup
        _ deref
        test    rbx, rbx
        jz      .error
        _object_raw_typecode_eax
        cmp     eax, TYPECODE_TYPE
        jne     .error
        _drop
        next
.error:
        _drop
        _ error_not_type
        next
endcode

; ### make-type
code make_type, 'make-type'             ; symbol typecode -> type

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

        _tuck                           ; -> type symbol type
        _ one_quotation                 ; -> type symbol quotation
        _over                           ; -> type symbol quotation symbol
        _ symbol_set_def                ; -> type symbol
        _ compile_word

        next
endcode

; ### make-tuple-type
code make_tuple_type, 'make-tuple-type' ; symbol slots -> type
        _swap
        _ next_raw_typecode
        _duptor
        _tag_fixnum
        _ make_type
        _tuck
        _ type_set_layout
        _dup
        _rfrom
        _ types
        _ vector_set_nth_untagged
        next
endcode

asm_global types_, f_value

; ### types
code types, 'types'                     ; -> sequence
        pushrbx
        mov     rbx, [types_]
        next
endcode

; ### add_builtin_type
code add_builtin_type, 'add_builtin_type', SYMBOL_INTERNAL      ; name typecode ->

        _tor                            ; -> name       r: -> typecode

        _ new_symbol_in_current_vocab   ; -> symbol

        _rfetch
        _ make_type                     ; -> type

        _rfrom                          ; -> type typecode
        _untag_fixnum
        _ types
        _ vector_set_nth_untagged

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
        poprbx

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
        _add_type "curry", TYPECODE_CURRY
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
        _add_type "slot-definition", TYPECODE_SLOT_DEFINITION
        _add_type "file-output-stream", TYPECODE_FILE_OUTPUT_STREAM

        next
endcode

; ### type-symbol
code type_symbol, 'type-symbol'         ; type -> symbol
        _ check_type
        _type_symbol
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

; ### typecode>type
code typecode_to_type, 'typecode>type'  ; typecode -> type
        _check_index
        _ types
        _ vector_nth_untagged
        next
endcode

; ### find-type
code find_type, 'find-type'             ; string -> type
        _ find_name
        _tagged_if .1
        _quote "type"
        _swap
        _ symbol_prop
        _dup
        _ type?
        _tagged_if .2
        _return
        _then .2
        _then .1

        _error "can't find type"

        next
endcode

; ### type>string
code type_to_string, 'type>string'      ; type -> string
        _ check_type
        _type_symbol
        _ symbol_name
        next
endcode
