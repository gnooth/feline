; Copyright (C) 2015-2021 Peter Graves <gnooth@gmail.com>

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

%define ARRAY_RAW_LENGTH_OFFSET     8

%macro  _array_raw_length 0             ; array -- untagged-length
        _slot1
%endmacro

%macro  _this_array_raw_length 0        ; -- untagged-length
        _this_slot1
%endmacro

; Arrays store their data inline starting at this offset.
%define ARRAY_DATA_OFFSET       16

%macro  _array_nth_unsafe 0             ; untagged-index array -> element
        mov     rax, [rbp]              ; rax: untagged index
        _nip
        mov     rbx, [rbx + ARRAY_DATA_OFFSET + rax * BYTES_PER_CELL]
%endmacro

%macro  _this_array_nth_unsafe 0        ; untagged-index -> element
        mov     rbx, [this_register + ARRAY_DATA_OFFSET + rbx * BYTES_PER_CELL ]
%endmacro

%macro  _this_array_set_nth_unsafe 0    ; element untagged-index -> void
        mov     rax, [rbp]              ; rax: element
        mov     [this_register + ARRAY_DATA_OFFSET + rbx * BYTES_PER_CELL], rax
        _2drop
%endmacro

; ### array?
code array?, 'array?'                   ; x -> x/nil
; If x is an array, returns x unchanged. Otherwise, returns nil.
        cmp     bl, HANDLE_TAG
        jne     .not_an_array
        mov     rax, rbx
        shr     rax, HANDLE_TAG_BITS
        mov     rax, [rax]
        cmp     word [rax], TYPECODE_ARRAY
        jne     .not_an_array
        next
.not_an_array:
        mov     ebx, NIL
        next
endcode

; ### check_array
code check_array, 'check_array'         ; x -> ^array
        cmp     bl, HANDLE_TAG
        jne     error_not_array
        mov     rax, rbx
        shr     rbx, HANDLE_TAG_BITS
        mov     rbx, [rbx]              ; rbx: ^x
        cmp     word [rbx], TYPECODE_ARRAY
        jne     .error
        next
.error:
        mov     rbx, rax
        jmp     error_not_array
endcode

; ### verify-array
code verify_array, 'verify-array'       ; array -> array
; Returns argument unchanged.
        cmp     bl, HANDLE_TAG
        jne     error_not_array
        mov     rax, rbx
        shr     rax, HANDLE_TAG_BITS
        mov     rax, [rax]
        cmp     word [rax], TYPECODE_ARRAY
        jne     error_not_array
        next
endcode

; ### error-not-array
code error_not_array, 'error-not-array' ; x ->
        _quote "an array"
        _ format_type_error
        next
endcode

; ### array_raw_length
code array_raw_length, 'array_raw_length', SYMBOL_INTERNAL
; array -- raw-length
        _ check_array
        _array_raw_length
        next
endcode

; ### array-length
code array_length, 'array-length'       ; array -> length
        _ check_array
        _array_raw_length
        _tag_fixnum
        next
endcode

; ### array-length-unsafe
code array_length_unsafe, 'array-length-unsafe' ; array -> length
        _handle_to_object_unsafe
        _array_raw_length
        _tag_fixnum
        next
endcode

; ### allocate_array
subroutine allocate_array
; call with untagged length in arg0_register
; returns ^array in rax
        push    arg0_register           ; save length
        add     arg0_register, 2        ; object header and length slot
        shl     arg0_register, 3        ; convert cells to bytes
        _os_malloc                      ; raw object address in rax
        pop     arg0_register           ; restore saved length
        mov     qword [rax], TYPECODE_ARRAY
        mov     [rax + ARRAY_RAW_LENGTH_OFFSET], arg0_register
        ret
endsub

; ### make-array/1
code make_array_1, 'make-array/1'       ; length -> array
        _check_index                    ; -> untagged-length
        mov     arg0_register, rbx
        _ allocate_array                ; returns raw object address in rax
        lea     arg0_register, [rax + ARRAY_DATA_OFFSET] ; data address
        mov     arg1_register, NIL      ; element
        mov     arg2_register, rbx      ; length
        mov     rbx, rax                ; object address
        _ fill_cells
        _ new_handle
        next
endcode

; ### make-array/2
code make_array_2, 'make-array/2'       ; length element -> array
        _swap
        _check_index                    ; -> element untagged-length
        mov     arg0_register, rbx
        _ allocate_array                ; returns raw object address in rax

        lea     arg0_register, [rax + ARRAY_DATA_OFFSET] ; data address
        mov     arg1_register, [rbp]    ; element
        mov     arg2_register, rbx      ; untagged length
        _nip

        ; must move array address into rbx before calling fill_cells
        mov     rbx, rax

        _ fill_cells
        _ new_handle
        next
endcode

; ### vector->array
code vector_to_array, 'vector->array'   ; vector -> array
        _ check_vector                  ; -> ^vector

        mov     arg0_register, [rbx + VECTOR_RAW_LENGTH_OFFSET]
        _ allocate_array                ; returns raw object address in rax

        mov     arg0_register, [rbx + VECTOR_RAW_DATA_ADDRESS_OFFSET] ; source
        lea     arg1_register, [rax + ARRAY_DATA_OFFSET] ; destination
        mov     arg2_register, [rax + ARRAY_RAW_LENGTH_OFFSET] ; length

        ; must move array address into rbx before calling copy_cells!
        mov     rbx, rax

        _ copy_cells

        _ new_handle

        next
endcode

; ### 1array
code one_array, '1array'                ; x -> array
        mov     arg0_register, 1        ; untagged length in arg0_register
        _ allocate_array                ; returns untagged address in rax
        mov     [rax + ARRAY_DATA_OFFSET], rbx
        mov     rbx, rax
        _ new_handle
        next
endcode

; ### 2array
code two_array, '2array'                ; x y -> array
        mov     arg0_register, 2        ; untagged length in arg0_register
        _ allocate_array                ; returns untagged address in rax
        mov     rdx, [rbp]              ; x in rdx
        _nip
        mov     [rax + ARRAY_DATA_OFFSET], rdx
        mov     [rax + ARRAY_DATA_OFFSET + BYTES_PER_CELL], rbx ; y
        mov     rbx, rax
        _ new_handle
        next
endcode

; ### 3array
code three_array, '3array'              ; x y z -> array
        mov     arg0_register, 3        ; untagged length in arg0_register
        _ allocate_array                ; returns untagged address in rax
        mov     rdx, [rbp + BYTES_PER_CELL] ; x
        mov     rcx, [rbp]              ; y
        _2nip
        mov     [rax + ARRAY_DATA_OFFSET], rdx
        mov     [rax + ARRAY_DATA_OFFSET + BYTES_PER_CELL], rcx
        mov     [rax + ARRAY_DATA_OFFSET + BYTES_PER_CELL * 2], rbx ; z
        mov     rbx, rax
        _ new_handle
        next
endcode

; ### 4array
code four_array, '4array'               ; w x y z -> array
        mov     arg0_register, 4        ; untagged length in arg0_register
        _ allocate_array                ; returns untagged address in rax
%ifdef WIN64
        push    rsi                     ; rsi is callee-saved on Windows
%endif
        mov     rsi, [rbp + BYTES_PER_CELL * 2 ] ; w
        mov     rdx, [rbp + BYTES_PER_CELL] ; x
        mov     rcx, [rbp]              ; y
        _3nip
        mov     [rax + ARRAY_DATA_OFFSET], rsi
        mov     [rax + ARRAY_DATA_OFFSET + BYTES_PER_CELL], rdx
        mov     [rax + ARRAY_DATA_OFFSET + BYTES_PER_CELL * 2], rcx
        mov     [rax + ARRAY_DATA_OFFSET + BYTES_PER_CELL * 3], rbx ; z
        mov     rbx, rax
%ifdef WIN64
        pop    rsi
%endif
        _ new_handle
        next
endcode

; ### array-new-sequence
code array_new_sequence, 'array-new-sequence' ; len seq -- newseq
        _drop
        _ make_array_1
        next
endcode

; ### array-nth-unsafe
code array_nth_unsafe, 'array-nth-unsafe' ; index array -> element

        _handle_to_object_unsafe        ; rbx: ^array

        mov     rax, [rbp]
        sar     rax, FIXNUM_TAG_BITS    ; rax: untagged index

        ; rbx: ^array
        mov     rbx, [rbx + ARRAY_DATA_OFFSET + rax * BYTES_PER_CELL]
        _nip
        next
endcode

; ### array-nth
code array_nth, 'array-nth'             ; index array -> element

        _ check_array                   ; rbx: ^array

        mov     rax, [rbp]
        test    al, FIXNUM_TAG
        jz      .error_not_index
        test    rax, rax
        js      .error_not_index
        sar     rax, FIXNUM_TAG_BITS    ; rax: untagged index

        ; rbx: ^array
        cmp     rax, [rbx + ARRAY_RAW_LENGTH_OFFSET]
        jge     error_array_index_out_of_bounds
        mov     rbx, [rbx + ARRAY_DATA_OFFSET + rax * BYTES_PER_CELL]
        _nip
        next

.error_not_index:
        mov     rbx, rax
        _ error_not_index
        next
endcode

; ### array-set-nth
code array_set_nth, 'array-set-nth'     ; element index array -> void

        _ check_array                   ; rbx: ^array

        mov     rax, [rbp]
        test    al, FIXNUM_TAG
        jz      .error_not_index
        test    rax, rax
        js      .error_not_index
        sar     rax, FIXNUM_TAG_BITS    ; rax: untagged index

        ; rbx: ^array
        cmp     rax, [rbx + ARRAY_RAW_LENGTH_OFFSET]
        jge     error_array_index_out_of_bounds
        mov     rdx, [rbp + BYTES_PER_CELL] ; rdx: element
        mov     qword [rbx + ARRAY_DATA_OFFSET + rax * BYTES_PER_CELL], rdx
        _3drop
        next

.error_not_index:
        mov     rbx, rax
        _ error_not_index
        next
endcode

; ### array-set-nth-unsafe
code array_set_nth_unsafe, 'array-set-nth-unsafe' ; element index array -> void

        _handle_to_object_unsafe        ; rbx: ^array

        mov     rax, [rbp]
        sar     rax, FIXNUM_TAG_BITS    ; rax: untagged index

        ; rbx: ^array
        mov     rdx, [rbp + BYTES_PER_CELL] ; rdx: element
        mov     qword [rbx + ARRAY_DATA_OFFSET + rax * BYTES_PER_CELL], rdx
        _3drop
        next
endcode

; ### array-first
code array_first, 'array-first'         ; handle -> element
        _ check_array
        mov     rax, [rbx + ARRAY_RAW_LENGTH_OFFSET]
        test    rax, rax
        jng     .error
        mov     rbx, [rbx + ARRAY_DATA_OFFSET]
        _return
.error:
        _error "array-first empty array"
        next
endcode

; ### array-second
code array_second, 'array-second'       ; array -> element
        _lit tagged_fixnum(1)
        _swap
        _ array_nth
        next
endcode

; ### array-third
code array_third, 'array-third'         ; array -> element
        _lit tagged_fixnum(2)
        _swap
        _ array_nth
        next
endcode

; ### array-?last
code array_?last, 'array-?last'         ; array -> element/nil
; return last element of array
; return nil if array is empty
        _ check_array
        mov     rax, [rbx + ARRAY_RAW_LENGTH_OFFSET]
        sub     rax, 1
        js      .empty
        mov     rbx, [rbx + ARRAY_DATA_OFFSET + BYTES_PER_CELL * rax]
        next
.empty:
        mov     ebx, NIL
        next
endcode

; ### array-each
code array_each, 'array-each'           ; array callable --

        ; protect callable from gc
        push    rbx

        _ callable_raw_code_address

        _swap
        _ check_array                   ; -- code-address array

        push    this_register
        mov     this_register, rbx
        push    r12
        mov     r12, [rbp]              ; address to call in r12
        _2drop                          ; adjust stack
        _this_array_raw_length
        _do_times .1
        _raw_loop_index
        _this_array_nth_unsafe          ; -- element
        call    r12
        _loop .1
        pop     r12
        pop     this_register

        ; drop callable
        pop     rax

        next
endcode

; ### map-array
code map_array, 'map-array'             ; array callable -- new-array

        ; protect callable from gc
        push    rbx

        _ callable_raw_code_address

        _swap                           ; -- code-address array

        _ check_array

        push    this_register
        popd    this_register           ; -- code-address

        push    r12
        popd    r12                     ; code address in r12

        _this_array_raw_length
        _tag_fixnum
        _ make_array_1                  ; -> new-array

        _this_array_raw_length
        _zero
        _?do .1
        _i
        _this_array_nth_unsafe
        call    r12                     ; -- new-array new-element
        _i
        _tag_fixnum                     ; -- new-array new-element i
        _pick                           ; -- new-array new-element i new-array
        _ array_set_nth

        _loop .1

        pop     r12
        pop     this_register

        ; drop callable
        pop     rax

        next
endcode

; ### array-equal?
code array_equal?, 'array-equal?'       ; array1 array2 -- ?
        _twodup

        _ array?
        _tagged_if_not .1
        _3drop
        _f
        _return
        _then .1

        _ array?
        _tagged_if_not .2
        _2drop
        _f
        _return
        _then .2

        _ sequence_equal
        next
endcode

; ### array>string
code array_to_string, 'array>string'    ; array -- string
        _quote "{ "
        _ string_to_sbuf
        _swap
        _quotation .1
        _ object_to_string
        _over
        _ sbuf_append_string
        _lit tagged_char(32)
        _over
        _ sbuf_push
        _end_quotation .1
        _ array_each
        _tagged_char('}')
        _over
        _ sbuf_push
        _ sbuf_to_string
        next
endcode
