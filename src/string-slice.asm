; Copyright (C) 2020 Peter Graves <gnooth@gmail.com>

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

; string slices are immutable

; 4 cells: object header, base string, raw data address, raw length
%define STRING_SLICE_SIZE                          4 * BYTES_PER_CELL

%define STRING_SLICE_BASE_STRING_OFFSET            8

%define STRING_SLICE_RAW_DATA_ADDRESS_OFFSET       16

%define STRING_SLICE_RAW_LENGTH_OFFSET             24

; ### string-slice?
code string_slice?, 'string-slice?'     ; x -> x/nil
; If x is a string-slice, returns x unchanged.
; If x is not a string-slice, returns nil.
        cmp     bl, HANDLE_TAG
        jne     .not_a_string_slice
        mov     rax, rbx
        shr     rax, HANDLE_TAG_BITS
        mov     rax, [rax]
        cmp     word [rax], TYPECODE_STRING_SLICE
        jne     .not_a_string_slice
        next
.not_a_string_slice:
        mov     ebx, NIL
        next
endcode

; ### verify-string-slice
code verify_string_slice, 'verify-string-slice' ; x -> x
; Returns argument unchanged.
        cmp     bl, HANDLE_TAG
        jne     error_not_string_slice
        mov     rax, rbx
        shr     rax, HANDLE_TAG_BITS
        mov     rax, [rax]
        cmp     word [rax], TYPECODE_STRING_SLICE
        jne     error_not_string_slice
        next
endcode

; ### check_string_slice
code check_string_slice, 'check_string_slice'   ; x -> ^x
        cmp     bl, HANDLE_TAG
        jne     error_not_string_slice
        mov     rax, rbx
        shr     rbx, HANDLE_TAG_BITS
        mov     rbx, [rbx]                      ; rbx: ^x
        cmp     word [rbx], TYPECODE_STRING_SLICE
        jne     .error
        next
.error:
        mov     rbx, rax
        jmp     error_not_string_slice
endcode

; ### error-not-string-slice
code error_not_string_slice, 'error-not-string-slice'   ; x -> void
        _quote "a string-slice"
        _ format_type_error
        next
endcode

; ### make-string-slice
code make_string_slice, 'make-string-slice'     ; from to string -> string-slice
        _ string_validate_slice                 ; -> from to string
        _ verify_string

        ; allocate memory for the string-slice object
        mov     arg0_register, STRING_SLICE_SIZE
        _ feline_malloc                         ; rax: ^string-slice

        mov     qword [rax], TYPECODE_STRING_SLICE
        mov     qword [rax + STRING_SLICE_BASE_STRING_OFFSET], rbx

        push    rax
        _ string_raw_data_address
        pop     rax

        ; rbx: string raw data address
        mov     rcx, [rbp + BYTES_PER_CELL]     ; rcx: from
        sar     rcx, FIXNUM_TAG_BITS

        mov     rdx, [rbp]                      ; rdx: to
        sar     rdx, FIXNUM_TAG_BITS

        _2nip

        add     rbx, rcx                ; rbx: data address + from
        mov     qword [rax + STRING_SLICE_RAW_DATA_ADDRESS_OFFSET], rbx

        sub     rdx, rcx                ; rdx: raw length
        mov     qword [rax + STRING_SLICE_RAW_LENGTH_OFFSET], rdx

        mov     rbx, rax                ; rbx: ^string-slice

        _ new_handle

        next
endcode

; ### string_slice_raw_parts
code string_slice_raw_parts, 'string_slice_raw_parts'
; string-slice -> raw-data-address raw-length
        _ check_string_slice
        mov     rax, [rbx + STRING_SLICE_RAW_LENGTH_OFFSET]
        mov     rbx, [rbx + STRING_SLICE_RAW_DATA_ADDRESS_OFFSET]
        _dup
        mov     rbx, rax
        next
endcode

; ### string-slice->string
code string_slice_to_string, 'string-slice->string'     ; string-slice -> string
        _ string_slice_raw_parts
        _ copy_to_string
        next
endcode

; ### quote-string-slice
code quote_string_slice, 'quote-string-slice'   ; string-slice -> quoted-string
        _ string_slice_to_string
        _ quote_string
        next
endcode
