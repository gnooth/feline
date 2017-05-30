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
        _slot1
%endmacro

%macro  _type_set_typecode 0            ; typecode type --
        _set_slot1
%endmacro

%macro  _this_type_typecode 0           ; -- typecode
        _this_slot1
%endmacro

%macro  _this_type_set_typecode 0       ; typecode --
        _this_set_slot1
%endmacro

; ### type?
code type?, 'type?'                     ; handle -- ?
        _ deref                         ; -- raw-object/0
        test    rbx, rbx
        jz      .1
        movzx   eax, word [rbx]
        cmp     eax, OBJECT_TYPE_TYPE
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
        cmp     eax, OBJECT_TYPE_TYPE
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

        _this_object_set_raw_type_number OBJECT_TYPE_TYPE

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

        _add_type "Type", OBJECT_TYPE_TYPE
        _add_type "Fixnum", OBJECT_TYPE_FIXNUM
        _add_type "Boolean", OBJECT_TYPE_F
        _add_type "Vector", OBJECT_TYPE_VECTOR
        _add_type "String", OBJECT_TYPE_STRING
        _add_type "Sbuf", OBJECT_TYPE_SBUF
        _add_type "Array", OBJECT_TYPE_ARRAY
        _add_type "Hashtable", OBJECT_TYPE_HASHTABLE
        _add_type "Bignum", OBJECT_TYPE_BIGNUM
        _add_type "Symbol", OBJECT_TYPE_SYMBOL
        _add_type "Vocab", OBJECT_TYPE_VOCAB
        _add_type "Quotation", OBJECT_TYPE_QUOTATION
        _add_type "Wrapper", OBJECT_TYPE_WRAPPER
        _add_type "Tuple", OBJECT_TYPE_TUPLE
        _add_type "Curry", OBJECT_TYPE_CURRY
        _add_type "Slice", OBJECT_TYPE_SLICE
        _add_type "Range", OBJECT_TYPE_RANGE
        _add_type "Lexer", OBJECT_TYPE_LEXER
        _add_type "Float", OBJECT_TYPE_FLOAT
        _add_type "Iterator", OBJECT_TYPE_ITERATOR

        next
endcode

; ### make-type-symbol
code make_type_symbol, 'make-type-symbol'       ; type --
        _dup
        _ check_type
        _type_name
        _ feline_vocab
        _ new_symbol                    ; type symbol --
        _tuck
        _ symbol_set_value              ; symbol --

        _dup
        _ new_wrapper
        _lit S_symbol_value
        _ two_array
        _ array_to_quotation
        _over
        _ symbol_set_def

        _ compile_word
        next
endcode

; ### initialize-type-symbols
code initialize_type_symbols, 'initialize-type-symbols'
        _ types
        _lit S_make_type_symbol
        _ vector_each
        next
endcode

; ### type>string
code type_to_string, 'type>string'      ; type --string
        _ check_type
        _type_name
        next
endcode
