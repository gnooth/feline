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

; 3 cells: object header, sequence, raw index

%macro  _iterator_sequence 0
        _slot1
%endmacro

%macro  _this_iterator_sequence 0
        _this_slot1
%endmacro

%macro  _this_iterator_set_sequence 0
        _this_set_slot1
%endmacro

%macro  _this_iterator_raw_index 0
        _this_slot2
%endmacro

%macro  _this_iterator_set_raw_index 0
        _this_set_slot2
%endmacro

%macro  _iterator_index 0
        _slot2
        _tag_fixnum
%endmacro

%macro  _this_iterator_index 0
        _this_slot2
        _tag_fixnum
%endmacro

; ### iterator?
code iterator?, 'iterator?'             ; handle -- ?
        _dup
        _ handle?
        _tagged_if .1
        _handle_to_object_unsafe        ; -- object
        _dup_if .2
        _object_type                    ; -- object-type
        _eq? OBJECT_TYPE_ITERATOR
        _return
        _then .2
        _then .1
        mov     ebx, f_value
        next
endcode

; ### error-not-iterator
code error_not_iterator, 'error-not-iterator' ; x --
        ; REVIEW
        _error "not a iterator"
        next
endcode

; ### verify-iterator
code verify_iterator, 'verify-iterator' ; iterator -- iterator
        _dup
        _ iterator?
        _tagged_if .1
        _return
        _then .1

        _ error_not_iterator
        next
endcode

; ### check-iterator
code check_iterator, 'check-iterator'   ; x -- raw-iterator
        _ deref
        test    rbx, rbx
        jz      error_not_iterator
        movzx   eax, word [rbx]
        cmp     eax, OBJECT_TYPE_ITERATOR
        jne     error_not_lexer
        next
endcode

; ### iterator-sequence
code iterator_sequence, 'iterator-sequence'     ; iterator -- sequence
        _ check_iterator
        _iterator_sequence
        next
endcode

; ### iterator-index
code iterator_index, 'iterator-index'   ; iterator -- index
        _ check_iterator
        _iterator_index
        next
endcode

; ### <iterator>
code new_iterator, '<iterator>'         ; sequence -- iterator
; 3 cells: object header, string, raw index, line, line start, file

        _lit 3
        _ allocate_cells

        push    this_register
        mov     this_register, rbx
        poprbx

        _this_object_set_type OBJECT_TYPE_ITERATOR

        _this_iterator_set_sequence

        pushrbx
        mov     rbx, this_register      ; -- iterator

        pop     this_register

        ; return handle
        _ new_handle                    ; -- handle

        next
endcode

; ### next
code iterator_next, 'next'              ; iterator -- element/f

        _ check_iterator

        push    this_register
        mov     this_register, rbx
        poprbx

        _this_iterator_raw_index
        _this_iterator_sequence
        _ length
        _untag_fixnum
        _ult_if .1

        _this_iterator_index
        _this_iterator_sequence
        _ nth_unsafe

        _this_iterator_raw_index
        _oneplus
        _this_iterator_set_raw_index

        _else .1
        _f
        _then .1

        pop     this_register

        next
endcode

; ### iterator>string
code iterator_to_string, 'iterator>string'      ; iterator -- string

        _ verify_iterator

        _quote "iterator{ "
        _ string_to_sbuf        ; -- iterator sbuf

        _over                   ; -- iterator sbuf iterator
        _ iterator_sequence
        _ object_to_string
        _over
        _ sbuf_append_string    ; -- iterator sbuf

        _over
        _ iterator_index
        _ fixnum_to_string
        _over
        _ sbuf_append_string

        _quote " }"
        _over
        _ sbuf_append_string

        _ sbuf_to_string

        next
endcode
