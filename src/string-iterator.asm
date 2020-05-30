; Copyright (C) 2018-2020 Peter Graves <gnooth@gmail.com>

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
%define STRING_ITERATOR_SIZE                    5 * BYTES_PER_CELL

%define STRING_ITERATOR_STRING_OFFSET           8

%define STRING_ITERATOR_RAW_INDEX_OFFSET        16

%define STRING_ITERATOR_RAW_LENGTH_OFFSET       24

%define STRING_ITERATOR_RAW_DATA_ADDRESS_OFFSET 32

; ### string-iterator?
code string_iterator?, 'string-iterator?'       ; x -> x/nil
; If x is a string-iterator, returns x unchanged.
; If x is not a string-iterator, returns nil.
        cmp     bl, HANDLE_TAG
        jne     .not_a_string_iterator
        mov     rax, rbx
        shr     rax, HANDLE_TAG_BITS
        mov     rax, [rax]
        cmp     word [rax], TYPECODE_STRING_ITERATOR
        jne     .not_a_string_iterator
        next
.not_a_string_iterator:
        mov     ebx, NIL
        next
endcode

; ### verify-string-iterator
code verify_string_iterator, 'verify-string-iterator'   ; iterator -> iterator
; Returns argument unchanged.
        cmp     bl, HANDLE_TAG
        jne     error_not_string_iterator
        mov     rax, rbx
        shr     rax, HANDLE_TAG_BITS
        mov     rax, [rax]
        cmp     word [rax], TYPECODE_STRING_ITERATOR
        jne     error_not_string_iterator
        next
endcode

; ### check-string-iterator
code check_string_iterator, 'check_string_iterator'     ; iterator -> ^iterator
        cmp     bl, HANDLE_TAG
        jne     error_not_string_iterator
        mov     rax, rbx
        shr     rbx, HANDLE_TAG_BITS
        mov     rbx, [rbx]              ; rbx: ^iterator
        cmp     word [rbx], TYPECODE_STRING_ITERATOR
        jne     .error
        next
.error:
        mov     rbx, rax
        jmp     error_not_string_iterator
endcode

; ### error-not-string-iterator
code error_not_string_iterator, 'error-not-string-iterator'     ; x ->
        _quote "a string-iterator"
        _ format_type_error
        next
endcode

; ### string-iterator-string
code string_iterator_string, 'string-iterator-string'   ; iterator -> string
        _ check_string_iterator
        mov     rbx, [rbx + STRING_ITERATOR_STRING_OFFSET]
        next
endcode

; ### string-iterator-index
code string_iterator_index, 'string-iterator-index'     ; iterator -> index
        _ check_string_iterator
        mov     rbx, [rbx + STRING_ITERATOR_RAW_INDEX_OFFSET]
        _tag_fixnum
        next
endcode

; ### make-string-iterator
code make_string_iterator, 'make-string-iterator'       ; string -> iterator
; 5 cells: object header, string, raw index, raw length, raw data address

        ; allocate memory for the iterator object
        mov     arg0_register, FIXNUM_HASHTABLE_SIZE
        _ feline_malloc                 ; returns raw address in rax

        mov     qword [rax], TYPECODE_STRING_ITERATOR

        mov     qword [rax + STRING_ITERATOR_RAW_INDEX_OFFSET], -1

        mov     [rax + STRING_ITERATOR_STRING_OFFSET], rbx

        push    rax
        _ check_string                  ; -> ^string
        pop     rax

        mov     rdx, [rbx + STRING_RAW_LENGTH_OFFSET]
        mov     [rax + STRING_ITERATOR_RAW_LENGTH_OFFSET], rdx

        lea     rdx, [rbx + STRING_RAW_DATA_OFFSET]
        mov     [rax + STRING_ITERATOR_RAW_DATA_ADDRESS_OFFSET], rdx

        mov     rbx, rax

        ; return handle
        _ new_handle                    ; -> iterator

        next
endcode

; ### string-iterator-next
code string_iterator_next, 'string-iterator-next'       ; iterator -> char/nil
        _ check_string_iterator

        mov     rax, [rbx + STRING_ITERATOR_RAW_INDEX_OFFSET]
        add     rax, 1
        cmp     rax, [rbx + STRING_ITERATOR_RAW_LENGTH_OFFSET]
        jge     .end

        mov     [rbx + STRING_ITERATOR_RAW_INDEX_OFFSET], rax
        add     rax, [rbx + STRING_ITERATOR_RAW_DATA_ADDRESS_OFFSET]
        movzx   ebx, byte [rax]
        _tag_char
        next

.end:
        mov     rax, [rbx + STRING_ITERATOR_RAW_LENGTH_OFFSET]
        mov     [rbx + STRING_ITERATOR_RAW_INDEX_OFFSET], rax
        mov     ebx, NIL
        next
endcode

; ### string-iterator-peek
code string_iterator_peek, 'string-iterator-peek'       ; iterator -> element/nil
        _ check_string_iterator

        mov     rax, [rbx + STRING_ITERATOR_RAW_INDEX_OFFSET]
        add     rax, 1
        cmp     rax, [rbx + STRING_ITERATOR_RAW_LENGTH_OFFSET]
        jge     .end

        add     rax, [rbx + STRING_ITERATOR_RAW_DATA_ADDRESS_OFFSET]
        movzx   ebx, byte [rax]
        _tag_char
        next

.end:
        mov     ebx, NIL
        next
endcode

; ### string-iterator-skip
code string_interator_skip, 'string-iterator-skip' ; fixnum string-iterator -> void
        _ check_string_iterator

        mov     rax, [rbp]
        test    al, FIXNUM_TAG
        jz      error_not_fixnum_rax
        sar     rax, FIXNUM_TAG_BITS ; rax = number of bytes to skip

        ; the only valid negative index is -1
        mov     rdx, -1

        ; add number of bytes to skip to raw index to get new index
        add     rax, qword [rbx + STRING_ITERATOR_RAW_INDEX_OFFSET] ; rax = new index

        ; if rax < 0, set rax = -1
        cmovl   rax, rdx

        mov     rdx, qword [rbx + STRING_ITERATOR_RAW_LENGTH_OFFSET] ; rdx = string length

        ; new index (in rax) is -1 or >= 0
        cmp     rax, rdx

        ; if new index > string length, set new index = string length
        cmovg   rax, rdx

        ; move new index into its slot
        mov     qword [rbx + STRING_ITERATOR_RAW_INDEX_OFFSET], rax
        _2drop
        next
endcode

; ### string-iterator-skip-to-end
code string_iterator_skip_to_end, 'string-iterator-skip-to-end' ; string-iterator -> void
        _ check_string_iterator
        mov     rax, [rbx + STRING_ITERATOR_RAW_LENGTH_OFFSET]
        mov     [rbx + STRING_ITERATOR_RAW_INDEX_OFFSET], rax
        _drop
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
