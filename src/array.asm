; Copyright (C) 2015-2018 Peter Graves <gnooth@gmail.com>

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

%define ARRAY_LENGTH_OFFSET     8

%macro  _array_raw_length 0             ; array -- untagged-length
        _slot1
%endmacro

%macro  _this_array_raw_length 0        ; -- untagged-length
        _this_slot1
%endmacro

%macro  _this_array_set_raw_length 0    ; untagged-length --
        _this_set_slot1
%endmacro

; Arrays store their data inline starting at this + 16 bytes.
%define ARRAY_DATA_OFFSET       16

%macro _array_raw_data_address 0
        lea     rbx, [rbx + ARRAY_DATA_OFFSET]
%endmacro

%macro _this_array_raw_data_address 0
        pushrbx
        lea     rbx, [this_register + ARRAY_DATA_OFFSET]
%endmacro

%macro  _array_nth_unsafe 0             ; untagged-index array -- element
        mov     rax, [rbp]              ; untagged index in rax
        lea     rbp, [rbp + BYTES_PER_CELL]
        mov     rbx, [rbx + BYTES_PER_CELL*rax + ARRAY_DATA_OFFSET]
%endmacro

%macro  _this_array_nth_unsafe 0        ; untagged-index -- element
        mov     rbx, [this_register + BYTES_PER_CELL*rbx + ARRAY_DATA_OFFSET]
%endmacro

%macro  _array_set_nth_unsafe 0         ; element index array --
        _array_raw_data_address
        _swap
        _cells
        _plus
        _store
%endmacro

%macro  _this_array_set_nth_unsafe 0    ; element index --
        _cells
        _this_array_raw_data_address
        _plus
        _store
%endmacro

; ### array?
code array?, 'array?'                   ; handle -- ?
        _ deref                         ; -- array/0
        test    rbx, rbx
        jz      .1
        movzx   eax, word [rbx]
        cmp     eax, TYPECODE_ARRAY
        jne     .1
        mov     ebx, t_value
        _return
.1:
        mov     ebx, f_value
        next
endcode

; ### error-not-array
code error_not_array, 'error-not-array' ; x --
        ; REVIEW
        _error "not an array"
        next
endcode

; ### check-array
code check_array, 'check-array'         ; handle -- raw-array
        _ deref
        test    rbx, rbx
        jz      error_not_array
        movzx   eax, word [rbx]
        cmp     eax, TYPECODE_ARRAY
        jne     error_not_array
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

; ### allocate_array
subroutine allocate_array
; call with untagged length in arg0_register
; returns untagged address (not handle) of allocated object in rax
        push    arg0_register           ; save length
        add     arg0_register, 2        ; object header and length slot
        shl     arg0_register, 3        ; convert cells to bytes
        xcall   malloc                  ; raw object address in rax
        pop     arg0_register           ; restore saved length
        mov     qword [rax], TYPECODE_ARRAY
        mov     [rax + BYTES_PER_CELL], arg0_register
        ret
endsub

; ### make-array/1
code make_array_1, 'make-array/1'       ; length -> array
        _check_index                    ; -> untagged-length
        mov     arg0_register, rbx
        _ allocate_array                ; returns raw object address in rax
        lea     arg0_register, [rax + ARRAY_DATA_OFFSET] ; data address
        mov     arg1_register, f_value  ; element
        mov     arg2_register, rbx      ; length
        mov     rbx, rax                ; object address
        _ fill_cells
        _ new_handle
        next
endcode

; ### <array>
code new_array, '<array>'               ; length element -- handle

        _swap
        _check_index
        _swap

new_array_untagged:
        push    this_register

        _over                           ; -- length element length
        _cells
        _lit 16
        _plus                           ; -- length element total-size
        _ allocate_object               ; -- length element array
        popd    this_register           ; -- length element

        ; Zero all bits of object header.
        xor     eax, eax
        mov     [this_register], rax

        _this_object_set_raw_typecode TYPECODE_ARRAY
        _this_object_set_flags OBJECT_ALLOCATED_BIT

        _over                           ; -- length element length
        _this_array_set_raw_length      ; -- length element

        popd    rax                     ; element in rax
        popd    rcx                     ; length in rcx
%ifdef WIN64
        push    rdi
%endif
        lea     rdi, [this_register + ARRAY_DATA_OFFSET]
        rep     stosq
%ifdef WIN64
        pop     rdi
%endif

        pushrbx
        mov     rbx, this_register      ; -- array

        ; Return handle of allocated array.
        _ new_handle                    ; -- handle

        pop     this_register
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
code three_array, '3array'              ; x y z -- handle
        _lit 3
        _lit 0
        _ new_array_untagged            ; -- x y z handle
        _duptor
        _handle_to_object_unsafe        ; -- x y z array
        push    this_register
        popd    this_register           ; -- x y z
%ifdef WIN64
        push    rdi
%endif
        lea     rdi, [this_register + ARRAY_DATA_OFFSET]
        mov     rax, [rbp + BYTES_PER_CELL]
        stosq
        mov     rax, [rbp]
        stosq
        mov     [rdi], rbx
%ifdef WIN64
        pop     rdi
%endif
        _3drop
        pop     this_register
        _rfrom
        next
endcode

; ### 4array
code four_array, '4array'               ; w x y z -- handle
        _lit 4
        _lit 0
        _ new_array_untagged            ; -- w x y z handle
        _duptor
        _handle_to_object_unsafe        ; -- w x y z array
        push    this_register
        popd    this_register           ; -- w x y z
%ifdef WIN64
        push    rdi
%endif
        lea     rdi, [this_register + ARRAY_DATA_OFFSET]
        mov     rax, [rbp + BYTES_PER_CELL * 2]
        stosq
        mov     rax, [rbp + BYTES_PER_CELL]
        stosq
        mov     rax, [rbp]
        stosq
        mov     [rdi], rbx
%ifdef WIN64
        pop     rdi
%endif
        _4drop
        pop     this_register
        _rfrom
        next
endcode

; ### array-new-sequence
code array_new_sequence, 'array-new-sequence' ; len seq -- newseq
        _drop
        _f
        _ new_array
        next
endcode

; ### array-nth-unsafe
code array_nth_unsafe, 'array-nth-unsafe' ; index handle -- element
        _untag_fixnum qword [rbp]
        _handle_to_object_unsafe
        _array_nth_unsafe
        next
endcode

; ### array-nth
code array_nth, 'array-nth'             ; index handle -- element

        _check_fixnum qword [rbp]       ; -- untagged-index handle

array_nth_untagged:
        _ check_array                   ; -- untagged-index array
        push    this_register
        mov     this_register, rbx
        poprbx                          ; -- untagged-index
        cmp     rbx, [this_register + ARRAY_LENGTH_OFFSET]
        jae     .error
        _this_array_nth_unsafe
        pop     this_register
        _return
.error:
        pop     this_register
        _error "array-nth index out of range"
        next
endcode

; ### array-set-nth
code array_set_nth, 'array-set-nth'     ; element index handle --

        _untag_fixnum qword [rbp]

array_set_nth_untagged:
        _ check_array

        _twodup
        _array_raw_length
        _ult
        _if .2
        _array_raw_data_address
        _swap
        _cells
        _plus
        _store
        _else .2
        _error "array-set-nth index out of range"
        _then .2
        next
endcode

; ### array-first
code array_first, 'array-first'         ; handle -- element
        _ check_array
        mov     rax, [rbx + ARRAY_LENGTH_OFFSET]
        test    rax, rax
        jng     .error
        mov     rbx, [rbx + ARRAY_DATA_OFFSET]
        _return
.error:
        _error "array-first empty array"
        next
endcode

; ### array-second
code array_second, 'array-second'       ; handle -- element
        _lit 1
        _swap
        _ array_nth_untagged
        next
endcode

; ### array-third
code array_third, 'array-third'         ; handle -- element
        _lit 2
        _swap
        _ array_nth_untagged
        next
endcode

; ### array-?last
code array_?last, 'array-?last'         ; array -> element/f
; return last element of array
; return f if array is empty
        _ check_array
        mov     rax, [rbx + ARRAY_LENGTH_OFFSET]
        sub     rax, 1
        js      .empty
        mov     rbx, [rbx + ARRAY_DATA_OFFSET + BYTES_PER_CELL * rax]
        next
.empty:
        mov     ebx, f_value
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
        _f
        _ new_array_untagged            ; -- new-array

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

; ### .array
code dot_array, '.array'                ; array --
        _ check_array

        push    this_register
        mov     this_register, rbx

        _write "{ "
        _array_raw_length
        _zero
        _?do .1
        _i
        _this_array_nth_unsafe
        _ dot_object
        _ space
        _loop .1
        _write "}"

        pop     this_register
        next
endcode
