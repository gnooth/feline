; Copyright (C) 2017 Peter Graves <gnooth@gmail.com>

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

; 3 cells: object header, name, typecode

%macro  _type_name 0                    ; type -- name
        _slot1
%endmacro

%macro  _type_set_name 0                ; name type --
        _set_slot1
%endmacro

%macro  _this_type_name 0               ; -- name
        _this_slot1
%endmacro

%macro  _this_type_set_name 0           ; name --
        _this_set_slot1
%endmacro

%macro  _type_typecode 0                ; type -- typecode
        _slot2
%endmacro

%macro  _type_set_typecode 0            ; typecode type --
        _set_slot2
%endmacro

%macro  _this_type_typecode 0           ; -- typecode
        _this_slot2
%endmacro

%macro  _this_type_set_typecode 0       ; typecode --
        _this_set_slot2
%endmacro

; ### type?
code type?, 'type?'                     ; handle -- ?
        _ deref                         ; -- raw-object/0
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
code check_type, 'check-type'           ; handle -- type
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

; ### make-type
code make_type, 'make-type', SYMBOL_PRIMITIVE | SYMBOL_PRIVATE
; name typecode -- type
        _lit 3
        _ raw_allocate_cells

        push    this_register
        mov     this_register, rbx
        poprbx                          ; -- name typecode

        _this_object_set_raw_typecode TYPECODE_TYPE

        _this_object_set_flags OBJECT_ALLOCATED_BIT

        _this_type_set_typecode

        _this_type_set_name

        pushrbx
        mov     rbx, this_register      ; -- type

        ; return handle
        _ new_handle                    ; -- handle

        pop     this_register

        next
endcode

feline_global types, 'types'

%macro _add_type 2      ; name, raw typecode
        _quote %1
        _lit %2
        _ make_type     ; -- type
        _lit %2
        _ types
        _ vector_set_nth_untagged
%endmacro

; ### initialize-types
code initialize_types, 'initialize-types', SYMBOL_PRIMITIVE | SYMBOL_PRIVATE    ; --
        _lit 64
        _ new_vector_untagged
        _to_global types

        _add_type "type", TYPECODE_TYPE
        _add_type "fixnum", TYPECODE_FIXNUM
        _add_type "boolean", TYPECODE_BOOLEAN
        _add_type "vector", TYPECODE_VECTOR
        _add_type "string", TYPECODE_STRING
        _add_type "sbuf", TYPECODE_SBUF
        _add_type "array", TYPECODE_ARRAY
        _add_type "hashtable", TYPECODE_HASHTABLE
        _add_type "bignum", TYPECODE_BIGNUM
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

        next
endcode

; ### make-type-symbol
code make_type_symbol, 'make-type-symbol'       ; type --
        _dup
        _ check_type
        _type_name
        _ feline_vocab
        _ ensure_symbol                 ; type symbol --

        _quote "type"
        _ swap                          ; type "type" symbol --
        _ symbol_set_prop

        next
endcode

; ### initialize-type-symbols
code initialize_type_symbols, 'initialize-type-symbols'
        _ types
        _lit S_make_type_symbol
        _ vector_each
        next
endcode

; ### find-type
code find_type, 'find-type'             ; string -- type
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

; ### type-typecode
code type_typecode, 'type-typecode'     ; type -- typecode
        _ check_type
        _type_typecode
        _tag_fixnum
        next
endcode

; ### type>string
code type_to_string, 'type>string'      ; type --string
        _ check_type
        _type_name
        next
endcode
