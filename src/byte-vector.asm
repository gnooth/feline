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

; 4 cells: object header, raw length, raw data address, raw capacity
%define BYTE_VECTOR_SIZE                        4 * BYTES_PER_CELL

%define BYTE_VECTOR_RAW_LENGTH_OFFSET           8
%define BYTE_VECTOR_RAW_DATA_ADDRESS_OFFSET     16
%define BYTE_VECTOR_RAW_CAPACITY_OFFSET         24

; ### byte-vector?
code byte_vector?, 'byte-vector?'       ; x -> x/nil
; If x is a byte-vector, returns x unchanged. If x is not a byte-vector,
; returns nil.
        cmp     bl, HANDLE_TAG
        jne     .no
        mov     rax, rbx
        shr     rax, HANDLE_TAG_BITS
        mov     rax, [rax]
        cmp     word [rax], TYPECODE_BYTE_VECTOR
        jne     .no
        next
.no:
%if NIL = 0
        xor     ebx, ebx
%else
        mov     ebx, NIL
%endif
        next
endcode

; ### check_byte_vector
code check_byte_vector, 'check_byte_vector' ; byte-vector -> ^byte-vector
        cmp     bl, HANDLE_TAG
        jne     error_not_byte_vector
        mov     rax, rbx
        shr     rbx, HANDLE_TAG_BITS
        mov     rbx, [rbx]
        cmp     word [rbx], TYPECODE_BYTE_VECTOR
        jne     .error
        next
.error:
        mov     rbx, rax
        jmp     error_not_byte_vector
endcode

; ### verify-byte_vector
code verify_byte_vector, 'verify-byte-vector'     ; byte_vector -> byte_vector
; Returns argument unchanged.
        cmp     bl, HANDLE_TAG
        jne     error_not_byte_vector
        mov     rax, rbx
        shr     rax, HANDLE_TAG_BITS
        mov     rax, [rax]
        cmp     word [rax], TYPECODE_BYTE_VECTOR
        jne     error_not_byte_vector
        next
endcode

; ### error-not-byte-vector
code error_not_byte_vector, 'error-not-byte-vector' ; x ->
        _quote "a byte-vector"
        _ format_type_error
        next
endcode

; ### make-byte-vector
code make_byte_vector, 'make-byte-vector' ; capacity -> byte-vector

        _check_index                    ; -> raw-capacity (in rbx)

        ; rbx: requested capacity (untagged)
        ; round up
        add     rbx, 0x0f
        and     bl, 0xf0

        mov     arg0_register, BYTE_VECTOR_SIZE
        _ feline_malloc                 ; returns address in rax
        _dup
        mov     rbx, rax                ; -> raw-capacity ^vector

        mov     qword [rbx], TYPECODE_BYTE_VECTOR

        mov     arg0_register, [rbp]    ; raw capacity (bytes) in arg0_register
        _ feline_malloc                 ; returns raw address in rax

        mov     [rbx + BYTE_VECTOR_RAW_DATA_ADDRESS_OFFSET], rax

        mov     rax, [rbp]
        _nip                            ; -> ^byte-vector
        mov     [rbx + BYTE_VECTOR_RAW_CAPACITY_OFFSET], rax
        mov     qword [rbx + BYTE_VECTOR_RAW_LENGTH_OFFSET], 0

        ; REVIEW
        ; initialize all elements to 0
        mov     arg0_register, [rbx + BYTE_VECTOR_RAW_DATA_ADDRESS_OFFSET]
        xor     arg1_register, arg1_register
        mov     arg2_register, [rbx + BYTE_VECTOR_RAW_CAPACITY_OFFSET]
        sar     arg2_register, 3        ; convert bytes to cells

        _ fill_cells

        _ new_handle                    ; -> vector

        next
endcode

; ### destroy_byte_vector
code destroy_byte_vector, 'destroy_byte_vector', SYMBOL_INTERNAL ; ^vector -> void

        mov     arg0_register, [rbx + BYTE_VECTOR_RAW_DATA_ADDRESS_OFFSET]
        xcall   free

        ; zero out object header
        mov     qword [rbx], 0

        _feline_free
        next
endcode

; ### byte-vector-capacity
code byte_vector_capacity, 'byte-vector-capacity' ; byte-vector -> capacity
        _ check_byte_vector
        mov     rbx, [rbx + BYTE_VECTOR_RAW_CAPACITY_OFFSET]
        _tag_fixnum
        next
endcode

; ### byte-vector-length-unsafe
inline byte_vector_length_unsafe, 'byte-vector-length-unsafe' ; byte-vector -> length
        _handle_to_object_unsafe
        mov     rbx, [rbx + BYTE_VECTOR_RAW_LENGTH_OFFSET]
        _tag_fixnum
endinline

; ### byte-vector-length
code byte_vector_length, 'byte-vector-length' ; byte-vector -> length
        _ check_byte_vector
        mov     rbx, [rbx + BYTE_VECTOR_RAW_LENGTH_OFFSET]
        _tag_fixnum
        next
endcode

; ### byte-vector-data-address
code byte_vector_data_address, 'byte-vector-data-address' ; byte-vector -> fixnum
; unsafe
        _ check_byte_vector
        mov     rbx, [rbx + BYTE_VECTOR_RAW_DATA_ADDRESS_OFFSET]
        _tag_fixnum
        next
endcode

; ### byte-vector-nth-unsafe
code byte_vector_nth_unsafe, 'byte-vector-nth-unsafe' ; index byte-vector -> u8
        mov     rax, [rbp]              ; rax: index
        sar     rax, FIXNUM_TAG_BITS
        shr     rbx, HANDLE_TAG_BITS
        mov     rbx, [rbx]              ; rbx: ^byte-vector
        mov     rbx, [rbx + BYTE_VECTOR_RAW_DATA_ADDRESS_OFFSET]
        movzx   ebx, byte [rbx + rax]
        _nip
        _tag_fixnum
        next
endcode

; ### byte-vector-nth
code byte_vector_nth, 'byte-vector-nth' ; index byte-vector -> u8
        _check_index qword [rbp]
        _ check_byte_vector             ; -> untagged-index ^vector
        mov     rax, [rbp]              ; rax: untagged index
        cmp     rax, [rbx + BYTE_VECTOR_RAW_LENGTH_OFFSET]
        jge     .error                  ; index >= length
        mov     rbx, [rbx + BYTE_VECTOR_RAW_DATA_ADDRESS_OFFSET]
        _nip
        movzx   ebx, byte [rbx + rax]
        _tag_fixnum
        next
.error:
        ; -> raw-index vector
        mov     rbx, [rbx + BYTE_VECTOR_RAW_LENGTH_OFFSET]
        _tag_fixnum                     ; -> raw-index length
        mov     rax, [rbp]
        shl     rax, FIXNUM_TAG_BITS
        or      rax, FIXNUM_TAG
        mov     [rbp], rax              ; -> index length
        _quote "ERROR: the index %s is out of range for a byte-vector of length %s."
        _ format
        _ error
        next
endcode

; ### byte-vector-set-nth
code byte_vector_set_nth, 'byte-vector-set-nth' ; u8 index byte-vector -> void

        _ check_byte_vector

        push    this_register
        mov     this_register, rbx
        _drop                           ; -> u8 index

        _check_index                    ; -> u8 untagged-index

        cmp     rbx, [this_register + BYTE_VECTOR_RAW_CAPACITY_OFFSET]
        jl      .1

        ; -> u8 untagged-index
        _dup

        ; new capacity needs to be at least index + 1
        add     rbx, 1                  ; -> u8 untagged-index untagged-new-capacity

        _this                           ; -> u8 untagged-index untagged-new-capacity ^byte-vector
        _ byte_vector_ensure_capacity_unchecked ; -> u8 untagged-index

        _dup

        ; initialize new cells to untagged 0
        _dup
        mov     rbx, [this_register + BYTE_VECTOR_RAW_LENGTH_OFFSET] ; u8 untagged-index untagged-length

        _register_do_range .2
        _zero
        _i
        mov     rdx, [rbp]              ; rdx: untagged 0
        mov     rax, [this_register + BYTE_VECTOR_RAW_DATA_ADDRESS_OFFSET]
        mov     [rax + rbx], rdx
        _2drop
        _loop .2

.1:
        push    rbx
        mov     rbx, [rbp]              ; rbx: untagged index
        _ check_u8                      ; bl: untagged u8
        mov     dl, bl                  ; dl: untagged u8
        pop     rbx                     ; rbx: untagged index

        _dup
        add     rbx, 1
        _dup
        mov     rbx, [this_register + BYTE_VECTOR_RAW_LENGTH_OFFSET]
        _max
        mov     [this_register + BYTE_VECTOR_RAW_LENGTH_OFFSET], rbx
        _drop

        mov     rax, [this_register + BYTE_VECTOR_RAW_DATA_ADDRESS_OFFSET]
        mov     [rax + rbx], dl
        _2drop

        pop     this_register
        next
endcode

; ### byte-vector-ensure-capacity
code byte_vector_ensure_capacity, 'byte-vector-ensure-capacity' ; capacity vector -> void
        _ check_byte_vector
        _check_index qword [rbp]        ; -> untagged-capacity ^vector

byte_vector_ensure_capacity_unchecked:
        mov     rax, [rbx + BYTE_VECTOR_RAW_CAPACITY_OFFSET] ; existing capacity in rax
        cmp     rax, [rbp]              ; compare with requested capacity in [rbp]
        jge     twodrop                 ; nothing to do

        ; need to grow
        shl     rax, 1                  ; double existing capacity
        cmp     rax, [rbp]              ; must also be >= requested capacity
        jge     .1
        mov     rax, [rbp]              ; otherwise use requested capacity
.1:
        push    rax                     ; save new capacity
        mov     arg0_register, [rbx + BYTE_VECTOR_RAW_DATA_ADDRESS_OFFSET]
        mov     arg1_register, rax      ; new capacity
        xcall   realloc
        test    rax, rax
        jz      .error

        ; success
        mov     [rbx + BYTE_VECTOR_RAW_DATA_ADDRESS_OFFSET], rax
        pop     rax                     ; new capacity
        mov     [rbx + BYTE_VECTOR_RAW_CAPACITY_OFFSET], rax
        _2drop
        next

.error:
        _error "ERROR: unable to grow capacity"
        next
endcode

; ### byte-vector-push
code byte_vector_push, 'byte-vector-push' ; u8 byte-vector -> void

        _ check_byte_vector             ; rbx: ^byte-vector

        push    rbx
        mov     rbx, [rbp]
        _ check_u8
        mov     dl, bl                  ; dl: untagged u8
        pop     rbx                     ; rbx: ^byte-vector

        mov     rax, [rbx + BYTE_VECTOR_RAW_LENGTH_OFFSET] ; rax: raw length
        cmp     rax, [rbx + BYTE_VECTOR_RAW_CAPACITY_OFFSET]
        jge     .1                      ; length >= capacity
        mov     rcx, [rbx + BYTE_VECTOR_RAW_DATA_ADDRESS_OFFSET]
        mov     [rcx + rax], dl
        add     qword [rbx + BYTE_VECTOR_RAW_LENGTH_OFFSET], 1
        jmp     twodrop
.1:
        ; need to grow capacity
        _dup
        mov     rbx, [rbx + BYTE_VECTOR_RAW_LENGTH_OFFSET]
        add     rbx, 1
        _over
        _ byte_vector_ensure_capacity_unchecked

        mov     rax, [rbx + BYTE_VECTOR_RAW_LENGTH_OFFSET] ; raw length in rax
        mov     rdx, [rbp]              ; element in rdx
        mov     rcx, [rbx + BYTE_VECTOR_RAW_DATA_ADDRESS_OFFSET]
        mov     [rcx + rax], rdx
        add     qword [rbx + BYTE_VECTOR_RAW_LENGTH_OFFSET], 1
        jmp     twodrop
endcode

; ### byte-vector->string
code byte_vector_to_string, 'byte-vector->string' ; byte-vector -> string
        _ verify_byte_vector
        _quote "BV{ "
        _ string_to_sbuf        ; -> vector sbuf
        _swap                   ; -> sbuf vector
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
