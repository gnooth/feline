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

; 2 cells (object header, raw length)
%define BIT_ARRAY_SIZE  2 * BYTES_PER_CELL

; ### bit-array?
code bit_array?, 'bit-array?'           ; x -> x/nil
; If x is a bit-array, returns x unchanged. If x is not a bit-array, returns nil.
        cmp     bl, HANDLE_TAG
        jne     .not_a_bit_array
        mov     rax, rbx
        shr     rax, HANDLE_TAG_BITS
        mov     rax, [rax]
        cmp     word [rax], TYPECODE_BIT_ARRAY
        jne     .not_a_bit_array
        next
.not_a_bit_array:
        mov     ebx, NIL
        next
endcode

; ### check_bit_array
code check_bit_array, 'check_bit_array' ; x -> ^array
        cmp     bl, HANDLE_TAG
        jne     error_not_bit_array
        mov     rax, rbx
        shr     rbx, HANDLE_TAG_BITS
        mov     rbx, [rbx]              ; rbx: ^x
        cmp     word [rbx], TYPECODE_BIT_ARRAY
        jne     .error
        next
.error:
        mov     rbx, rax
        jmp     error_not_bit_array
endcode

; ### verify-bit-array
code verify_bit_array, 'verify-bit-array' ; bit-array -> bit-array
; Returns argument unchanged.
        cmp     bl, HANDLE_TAG
        jne     error_not_bit_array
        mov     rax, rbx
        shr     rax, HANDLE_TAG_BITS
        mov     rax, [rax]
        cmp     word [rax], TYPECODE_BIT_ARRAY
        jne     error_not_bit_array
        next
endcode

; ### error-not-bit-array
code error_not_bit_array, 'error-not-bit-array' ; x ->
        _quote "a bit-array"
        _ format_type_error
        next
endcode

; ### bit-array-length
code bit_array_length, 'bit-array-length' ; bit-array -> length
        _ check_bit_array
        _array_raw_length
        _tag_fixnum
        next
endcode

%define BIT_ARRAY_SHIFT 3
%define BIT_ARRAY_MASK  7

%macro _bits_to_bytes 1
        add     %1, BIT_ARRAY_MASK
        sar     %1, BIT_ARRAY_SHIFT
%endmacro

; ### make-bit-array
code make_bit_array, 'make-bit-array'   ; fixnum -> bit-array
        _check_index                    ; rbx: raw length in bits
        push    rbx

        _bits_to_bytes rbx              ; rbx: untagged length in bytes
        add     rbx, BIT_ARRAY_SIZE     ; add 2 slots (object header and raw length)
        mov     arg0_register, rbx
        _ feline_malloc                 ; rax: ^bit-array
        mov     qword [rax], TYPECODE_BIT_ARRAY
        pop     rbx                     ; rbx: raw length in bits
        mov     [rax + ARRAY_RAW_LENGTH_OFFSET], rbx

        lea     arg0_register, [rax + ARRAY_DATA_OFFSET] ; data address

        _bits_to_bytes rbx
        mov     arg1_register, rbx

        ; move array address into rbx before calling zero_bytes
        mov     rbx, rax                ; rbx: object address

        _ zero_bytes
        _ new_handle
        next
endcode

subroutine bit_array_nth_impl
; rbx: raw-bit-index
; rax: ^bit-array
        mov     r8, rbx                 ; r8: raw bit index
        sar     r8, BIT_ARRAY_SHIFT     ; r8: raw byte index
        mov     dl, [rax + ARRAY_DATA_OFFSET + r8] ; get byte in dl
        and     bl, BIT_ARRAY_MASK      ; bl: raw bit index within byte (0-7)
        mov     cl, bl                  ; cl: count for shift
        shr     dl, cl
        and     dl, 0b00000001
        mov     bl, dl
        _tag_fixnum
        ret
endsub

; ### bit-array-nth-unsafe
code bit_array_nth_unsafe, 'bit-array-nth-unsafe' ; index bit-array -> element
        _handle_to_object_unsafe
        mov     rax, rbx                ; rax: ^bit-array
        _drop
        _untag_fixnum                   ; rbx: raw index
        _ bit_array_nth_impl
        next
endcode

; ### bit-array-nth
code bit_array_nth, 'bit-array-nth'     ; index bit-array -> element
        _ check_bit_array               ; -> index ^bit-array
        mov     rax, rbx                ; rax: ^bit-array
        _drop
        _check_index
        cmp     rbx, [rax + ARRAY_RAW_LENGTH_OFFSET]
        jge     .error
        _ bit_array_nth_impl
        next
.error:
        _error "bit-array-nth index out of range"
        next
endcode

; ### set-bit
code set_bit, 'set-bit'                 ; index bit-array -> void
        _ check_bit_array               ; -> index ^bit-array
        mov     rax, rbx                ; rax: ^bit-array
        _drop                           ; -> index
        _check_index                    ; -> untagged-index
        cmp     rbx, [rax + ARRAY_RAW_LENGTH_OFFSET]
        jge     .error

        mov     r8, rbx                 ; r8: untagged bit index
        sar     r8, BIT_ARRAY_SHIFT     ; r8: untagged byte index

        mov     dl, [rax + ARRAY_DATA_OFFSET + r8] ; get relevant byte in dl

        ; rbx: untagged bit index
        and     rbx, BIT_ARRAY_MASK
        mov     cl, bl
        mov     bl, 1
        shl     bl, cl
        or      dl, bl
        mov     [rax + ARRAY_DATA_OFFSET + r8], dl
        _drop
        next
.error:
        _error "set-bit index out of range"
        next
endcode

; ### clear-bit
code clear_bit, 'clear-bit'             ; index bit-array -> void
        _ check_bit_array               ; -> index ^bit-array
        mov     rax, rbx                ; rax: ^bit-array
        _drop                           ; -> index
        _check_index                    ; -> untagged-index
        cmp     rbx, [rax + ARRAY_RAW_LENGTH_OFFSET]
        jge     .error

        mov     r8, rbx                 ; r8: untagged bit index
        sar     r8, BIT_ARRAY_SHIFT     ; r8: untagged byte index

        mov     dl, [rax + ARRAY_DATA_OFFSET + r8] ; get relevant byte in dl

        ; rbx: untagged bit index
        and     rbx, BIT_ARRAY_MASK
        mov     cl, bl
        mov     bl, 1
        shl     bl, cl
        not     bl
        and     dl, bl
        mov     [rax + ARRAY_DATA_OFFSET + r8], dl
        _drop
        next
.error:
        _error "clear-bit index out of range"
        next
endcode

; ### bit-array->string
code bit_array_to_string, 'bit-array->string' ; bit-array -> string
        _quote "?{ "
        _ string_to_sbuf
        _swap                           ; -> sbuf bit-array

        _quotation .1
        _ object_to_string
        _over
        _ sbuf_append_string
        _lit tagged_char(32)
        _over
        _ sbuf_push
        _end_quotation .1

        _ each

        _tagged_char('}')
        _over
        _ sbuf_push
        _ sbuf_to_string
        next
endcode
