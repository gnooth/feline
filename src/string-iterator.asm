; Copyright (C) 2018 Peter Graves <gnooth@gmail.com>

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

; 5 cells: object header, string, raw index, raw length, raw data address

%define string_iterator_string_slot             qword [rbx + BYTES_PER_CELL]

%macro  _string_iterator_string 0
        _slot1
%endmacro

%macro  _this_string_iterator_string 0
        _this_slot1
%endmacro

%macro  _this_string_iterator_set_string 0
        _this_set_slot1
%endmacro

%define string_iterator_raw_index_slot          qword [rbx + BYTES_PER_CELL * 2]

%define this_string_iterator_raw_index_slot     qword [this_register + BYTES_PER_CELL * 2]

%macro  _string_iterator_raw_index 0
        _slot2
%endmacro

%macro  _this_string_iterator_raw_index 0
        _this_slot2
%endmacro

%macro  _this_string_iterator_set_raw_index 0
        _this_set_slot2
%endmacro

%macro  _string_iterator_index 0
        _slot2
        _tag_fixnum
%endmacro

%macro  _this_string_iterator_index 0
        _this_slot2
        _tag_fixnum
%endmacro

%define string_iterator_raw_length_slot         qword [rbx + BYTES_PER_CELL * 3]

%define this_string_iterator_raw_length_slot    qword [this_register + BYTES_PER_CELL * 3]

%macro  _string_iterator_raw_length 0
        _slot3
%endmacro

%macro  _this_string_iterator_raw_length 0
        _this_slot3
%endmacro

%macro  _this_string_iterator_set_raw_length 0
        _this_set_slot3
%endmacro

%define string_iterator_raw_data_address_slot           qword [rbx + BYTES_PER_CELL * 4]

%define this_string_iterator_raw_data_address_slot      qword [this_register + BYTES_PER_CELL * 4]

%macro  _string_iterator_raw_data_address 0
        _slot4
%endmacro

%macro  _this_string_iterator_raw_data_address 0
        _this_slot4
%endmacro

%macro  _this_string_iterator_set_raw_data_address 0
        _this_set_slot4
%endmacro

; ### string-iterator?
code string_iterator?, 'string-iterator?'       ; handle -> ?
        _dup
        _ handle?
        _tagged_if .1
        _handle_to_object_unsafe        ; -> object
        _dup_if .2
        _object_raw_typecode
        _eq? TYPECODE_STRING_ITERATOR
        _return
        _then .2
        _then .1
        mov     ebx, f_value
        next
endcode

; ### error-not-string-iterator
code error_not_string_iterator, 'error-not-string-iterator'     ; x ->
        ; REVIEW
        _error "not a string iterator"
        next
endcode

; ### verify-iterator
code verify_string_iterator, 'verify-iterator'  ; iterator -> iterator
        _dup
        _ string_iterator?
        _tagged_if .1
        _return
        _then .1

        _ error_not_string_iterator
        next
endcode

; ### check-string-iterator
code check_string_iterator, 'check-string-iterator'     ; x -> raw-iterator
        _ deref
        test    rbx, rbx
        jz      error_not_string_iterator
        movzx   eax, word [rbx]
        cmp     eax, TYPECODE_STRING_ITERATOR
        jne     error_not_string_iterator
        next
endcode

; ### string-iterator-string
code string_iterator_string, 'string-iterator-string'   ; iterator -> string
        _ check_string_iterator
        _string_iterator_string
        next
endcode

; ### string-iterator-index
code string_iterator_index, 'string-iterator-index'     ; iterator -> index
        _ check_string_iterator
        _string_iterator_index
        next
endcode

; ### <string-iterator>
code new_string_iterator, '<string-iterator>'   ; string -> iterator
; 5 cells: object header, string, raw index, raw length, raw data address

        _ verify_string

        _lit 5
        _ raw_allocate_cells

        push    this_register
        mov     this_register, rbx
        poprbx

        _this_object_set_raw_typecode TYPECODE_STRING_ITERATOR

        _dup
        _ string_raw_length
        _this_string_iterator_set_raw_length

        _dup
        _ string_raw_data_address
        _this_string_iterator_set_raw_data_address

        _this_string_iterator_set_string

        pushrbx
        mov     rbx, this_register      ; -> iterator

        pop     this_register

        ; return handle
        _ new_handle                    ; -> handle

        next
endcode

; ### string-iterator-next
code string_iterator_next, 'string-iterator-next'       ; iterator -> element/f
        _ check_string_iterator

        mov     rax, string_iterator_raw_index_slot
        cmp     rax, string_iterator_raw_length_slot
        jae     .not_ok

        add     rax, string_iterator_raw_data_address_slot
        add     string_iterator_raw_index_slot, 1
        movzx   ebx, byte [rax]
        _tag_char
        next

.not_ok:
        mov     ebx, f_value
        next
endcode

; ### string-iterator-skip
code string_interator_skip, 'string-iterator-skip'      ; fixnum string-iterator -> void
        _ check_string_iterator

        mov     rax, [rbp]
        test    al, FIXNUM_TAG
        jz      error_not_fixnum_rax
        sar     rax, FIXNUM_TAG_BITS

        add     string_iterator_raw_index_slot, rax
        _2drop

        next
endcode

; ### string-iterator>string
code string_iterator_to_string, 'string-iterator>string'        ; string-iterator -> string

        _ verify_string_iterator

        _quote "string-iterator{ "
        _ string_to_sbuf

        _over
        _ string_iterator_string
        _ object_to_string
        _over
        _ sbuf_append_string

        _lit tagged_char(32)
        _over
        _ sbuf_push

        _swap
        _ string_iterator_index
        _ fixnum_to_string
        _over
        _ sbuf_append_string

        _quote " }"
        _over
        _ sbuf_append_string

        _ sbuf_to_string

        next
endcode
