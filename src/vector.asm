; Copyright (C) 2015-2020 Peter Graves <gnooth@gmail.com>

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

; 4 cells (object header, raw length, raw data address, raw capacity
%define VECTOR_SIZE                     4 * BYTES_PER_CELL

%define VECTOR_RAW_LENGTH_OFFSET        8
%define VECTOR_RAW_DATA_ADDRESS_OFFSET  16
%define VECTOR_RAW_CAPACITY_OFFSET      24

%macro  _vector_raw_length 0            ; ^vector -> raw-length
        _slot 1
%endmacro

%macro  _this_vector_raw_length 0       ; -> raw-length
        _this_slot 1
%endmacro

%macro  _this_vector_set_raw_length 0   ; raw-length -> void
        _this_set_slot 1
%endmacro

%macro  _vector_raw_data_address 0      ; ^vector -> raw-data-address
        _slot 2
%endmacro

%macro  _this_vector_raw_data_address 0 ; -> raw-data-address
        _this_slot 2
%endmacro

%macro  _this_vector_set_raw_data_address 0 ; raw-data-address -> void
        _this_set_slot 2
%endmacro

%macro  _vector_raw_capacity 0          ; ^vector -> raw-capacity
        _slot 3
%endmacro

%macro  _this_vector_raw_capacity 0     ; -> raw-capacity
        _this_slot 3
%endmacro

%macro  _this_vector_set_raw_capacity 0 ; raw-capacity -> void
        _this_set_slot 3
%endmacro

%macro  _vector_nth_unsafe 0            ; index ^vector -> element
        mov     rax, [rbp]              ; untagged index in rax
        _vector_raw_data_address
        _nip
        mov     rbx, [rbx + BYTES_PER_CELL * rax]
%endmacro

%macro  _this_vector_nth_unsafe 0       ; index -> element
        mov     rax, [this_register + VECTOR_RAW_DATA_ADDRESS_OFFSET]
        mov     rbx, [rax + BYTES_PER_CELL * rbx]
%endmacro

%macro  _this_vector_set_nth_unsafe 0   ; element index -> void
        mov     rdx, [rbp]
        mov     rax, [this_register + VECTOR_RAW_DATA_ADDRESS_OFFSET]
        mov     [rax + BYTES_PER_CELL * rbx], rdx
        _2drop
%endmacro

; ### vector?
code vector?, 'vector?'                 ; x -> ?
        cmp     bl, HANDLE_TAG
        jne     .not_a_vector
        _handle_to_object_unsafe
%ifdef DEBUG
        test    rbx, rbx
        jz      error_empty_handle
%endif
        cmp     word [rbx], TYPECODE_VECTOR
        jne     .not_a_vector
        mov     ebx, t_value
        next
.not_a_vector:
        mov     ebx, f_value
        next
endcode

; ### check_vector
code check_vector, 'check_vector'       ; handle -> ^vector
        cmp     bl, HANDLE_TAG
        jne     .error2
        mov     rdx, rbx                ; copy argument in case there is an error
        _handle_to_object_unsafe
%ifdef DEBUG
        test    rbx, rbx
        jz      error_empty_handle
%endif
        cmp     word [rbx], TYPECODE_VECTOR
        jne     .error1
        next
.error1:
        mov     rbx, rdx                ; restore original argument
.error2:
        jmp     error_not_vector
endcode

; ### verify-vector
code verify_vector, 'verify-vector'     ; handle -- handle
; returns argument unchanged
        _dup
        _ deref
        test    rbx, rbx
        jz      .error
        _object_raw_typecode_eax
        cmp     eax, TYPECODE_VECTOR
        jne     .error
        _drop
        next
.error:
        _drop
        _ error_not_vector
        next
endcode

; ### vector-capacity
code vector_capacity, 'vector-capacity' ; vector -> capacity
        _ check_vector
        _vector_raw_capacity
        _tag_fixnum
        next
endcode

; ### vector_raw_length
code vector_raw_length, 'vector_raw_length', SYMBOL_INTERNAL ; vector -> raw-length
        _ check_vector
        _vector_raw_length
        next
endcode

; ### vector-length
code vector_length, 'vector-length'     ; vector -> length
        _ check_vector
        _vector_raw_length
        _tag_fixnum
        next
endcode

; ### vector-length-unsafe
inline vector_length_unsafe, 'vector-length-unsafe' ; vector -> length
        _handle_to_object_unsafe
        _vector_raw_length
        _tag_fixnum
endinline

; ### vector-set-length
code vector_set_length, 'vector-set-length' ; tagged-new-length handle --
        _ check_vector                  ; -- tagged-new-length vector
        push    this_register
        mov     this_register, rbx
        poprbx                          ; -- tagged-new-length
        _check_index                    ; -- new-length
        _dup
        _this_vector_raw_capacity
        _ugt
        _if .1                          ; -- new-length
        _dup
        _this
        _ vector_ensure_capacity_unchecked
        _then .1                        ; -- new-length
        _dup
        _this_vector_raw_length
        _ugt
        _if .2                          ; -- new-length
        ; initialize new cells to f
        _dup
        _this_vector_raw_length
        _register_do_range .3
        _nil
        _i
        _this_vector_set_nth_unsafe
        _loop .3
        _then .2
        _this_vector_set_raw_length
        pop     this_register
        next
endcode

; ### vector-delete-all
code vector_delete_all, 'vector-delete-all' ; vector -> void
        _ check_vector
        mov     qword [rbx + VECTOR_RAW_LENGTH_OFFSET], 0
        _drop
        next
endcode

; ### make-vector
code make_vector, 'make-vector'         ; capacity -> vector

        _check_index                    ; -> raw-capacity (in rbx)

make_vector_unchecked:

        mov     arg0_register, VECTOR_SIZE
        _ feline_malloc                 ; returns address in rax
        _dup
        mov     rbx, rax                ; -> raw-capacity ^vector

        mov     word [rbx], TYPECODE_VECTOR

        mov     arg0_register, [rbp]    ; raw capacity (cells) in arg0_register
        shl     arg0_register, 3        ; convert cells to bytes
        _ feline_malloc                 ; returns raw address in rax

        mov     [rbx + VECTOR_RAW_DATA_ADDRESS_OFFSET], rax

        mov     rax, [rbp]
        _nip                            ; -> ^vector
        mov     [rbx + VECTOR_RAW_CAPACITY_OFFSET], rax
        mov     qword [rbx + VECTOR_RAW_LENGTH_OFFSET], 0

        ; REVIEW
        ; initialize all allocated cells to nil
        mov     arg0_register, [rbx + VECTOR_RAW_DATA_ADDRESS_OFFSET]
        mov     arg1_register, NIL
        mov     arg2_register, [rbx + VECTOR_RAW_CAPACITY_OFFSET]
        _ fill_cells

        _ new_handle                    ; -> vector

        next
endcode

; ### <vector>
; Deprecated. Use make-vector.
code new_vector, '<vector>'             ; capacity -> handle

        jmp     make_vector

        _check_index                    ; -> raw-capacity

new_vector_untagged:

        jmp     make_vector_unchecked

        next
endcode

; ### vector-new-sequence
code vector_new_sequence, 'vector-new-sequence' ; len seq -- newseq
        _drop
        _ new_vector
        next
endcode

; ### destroy_vector_unchecked
code destroy_vector_unchecked, 'destroy_vector_unchecked', SYMBOL_INTERNAL
; vector --

        _dup
        _vector_raw_data_address
        _ raw_free

        ; zero out object header
        xor     eax, eax
        mov     [rbx], rax

        _ raw_free
        next
endcode

; ### vector_grow_capacity
code vector_grow_capacity, 'vector-grow-capacity'       ; new-capacity vector -> void
        _ check_vector
        push    this_register
        mov     this_register, rbx
        _drop
        _check_index                    ; -> untagged-new-capacity

        ; untagged new capacity is in rbx
        cmp     [this_register + VECTOR_RAW_CAPACITY_OFFSET], rbx
        jge     .nothing_to_do

        mov     arg0_register, [this_register + VECTOR_RAW_DATA_ADDRESS_OFFSET]
        mov     arg1_register, rbx      ; untagged new capacity
        xcall   realloc                 ; returns address or 0 in rax
        test    rax, rax
        jz      .error

        ; success
        mov     [this_register + VECTOR_RAW_DATA_ADDRESS_OFFSET], rax
        mov     [this_register + VECTOR_RAW_CAPACITY_OFFSET], rbx

.nothing_to_do:
        _drop
        pop     this_register
        next

.error:
        _error "ERROR: unable to grow capacity"
        next
endcode

; ### vector-ensure-capacity
code vector_ensure_capacity, 'vector-ensure-capacity' ; capacity vector -> void
        _ check_vector
        _check_index qword [rbp]        ; -> untagged-capacity ^vector

vector_ensure_capacity_unchecked:
        mov     rax, [rbx + VECTOR_RAW_CAPACITY_OFFSET] ; existing capacity in rax
        cmp     rax, [rbp]              ; compare with requested capacity in [rbp]
        jge     .nothing_to_do

        ; need to grow
        shl     rax, 1                  ; double existing capacity
        cmp     rax, [rbp]              ; must also be >= requested capacity
        jge     .1
        mov     rax, [rbp]              ; otherwise use requested capacity
.1:
        push    rax                     ; save new capacity
        mov     arg0_register, [rbx + VECTOR_RAW_DATA_ADDRESS_OFFSET]
        mov     arg1_register, rax      ; new capacity
        shl     arg1_register, 3        ; convert cells to bytes
        xcall   realloc
        test    rax, rax
        jz      .error

        ; success
        mov     [rbx + VECTOR_RAW_DATA_ADDRESS_OFFSET], rax
        pop     rax                     ; new capacity
        mov     [rbx + VECTOR_RAW_CAPACITY_OFFSET], rax

.nothing_to_do:
        _2drop
        next

.error:
        _error "ERROR: unable to grow capacity"
        next
endcode

; ### vector-nth-unsafe
code vector_nth_unsafe, 'vector-nth-unsafe'     ; index handle -> element
        _untag_fixnum qword [rbp]
        _handle_to_object_unsafe
        _vector_nth_unsafe
        next
endcode

; ### vector-nth
code vector_nth, 'vector-nth'           ; index handle -- element

        _check_index qword [rbp]

vector_nth_untagged:

        _ check_vector

        mov     rax, [rbp]              ; raw index in rax
        cmp     rax, [rbx + VECTOR_RAW_LENGTH_OFFSET]
        jge     .error                  ; index >= length
        _vector_raw_data_address
        _nip
        mov     rbx, [rbx + BYTES_PER_CELL * rax]
        next

.error:
        ; -- raw-index vector
        _vector_raw_length
        _tag_fixnum
        _swap
        _tag_fixnum
        _swap
        _quote "ERROR: the index %s is out of range for a vector of length %s."
        _ format
        _ error
        next
endcode

; ### vector-?nth
code vector_?nth, 'vector-?nth'         ; index vector -- element/f

        _ check_vector

        push    this_register
        mov     this_register, rbx
        poprbx                          ; -- index

        _check_index                    ; -- raw-index

        _this_vector_raw_length         ; -- raw-index raw-length
        cmp     [rbp], rbx
        poprbx                          ; -- raw-index
        jae .1                          ; branch if index >= length (unsigned comparison)
        _this_vector_nth_unsafe
        pop     this_register
        next
.1:
        mov     rbx, f_value
        pop     this_register
        next
endcode

; ### vector-first
code vector_first, 'vector-first'       ; handle -- element
        _zero
        _swap
        _ vector_nth_untagged
        next
endcode

; ### vector-second
code vector_second, 'vector-second'     ; handle -- element
        _lit 1
        _swap
        _ vector_nth_untagged
        next
endcode

; ### vector-last
code vector_last, 'vector-last'         ; handle -- element
        _ check_vector
        _dup
        _vector_raw_length              ; -- vector untagged-length
        _oneminus
        _dup
        _zge
        _if .1
        _swap
        _vector_nth_unsafe
        _else .1
        _drop
        _error "vector-last vector is empty"
        _then .1
        next
endcode

; ### vector-?last
code vector_?last, 'vector-?last'       ; vector -> element/f
        _ check_vector
        mov     rax, [rbx + VECTOR_RAW_LENGTH_OFFSET]
        sub     rax, 1
        js      .empty
        _vector_raw_data_address
        mov     rbx, [rbx + BYTES_PER_CELL * rax]
        next
.empty:
        mov     ebx, NIL
        next
endcode

; ### vector-set-last
code vector_set_last, 'vector-set-last' ; element vector -> void
        _ check_vector
        mov     rax, [rbx + VECTOR_RAW_LENGTH_OFFSET]
        sub     rax, 1
        js      error_vector_index_out_of_bounds
        mov     rdx, [rbp]
        _vector_raw_data_address
        mov     [rbx + BYTES_PER_CELL * rax], rdx
        _2drop
        next
endcode

; ### vector-set-nth
code vector_set_nth, 'vector-set-nth'   ; element index vector -> void

        _ check_vector

        push    this_register
        mov     this_register, rbx
        poprbx                          ; -> element index

        _check_index

        cmp     rbx, [this_register + VECTOR_RAW_CAPACITY_OFFSET]
        jl      .1

        ; -- element untagged-index
        _dup

        ; new capacity needs to be at least index + 1
        _oneplus

        _this
        _ vector_ensure_capacity_unchecked      ; -> element untagged-index

        ; initialize new cells to nil
        _dup
        _this_vector_raw_length
        _register_do_range .2
        _nil
        _i
        _this_vector_set_nth_unsafe
        _loop .2

.1:
        _dup
        _oneplus
        _this_vector_raw_length
        _max
        _this_vector_set_raw_length

        _this_vector_set_nth_unsafe

        pop     this_register
        next
endcode

; ### vector-insert-nth
code vector_insert_nth, 'vector-insert-nth'     ; element n vector -> void
        _ check_vector

        _check_index qword [rbp]

        push    this_register
        mov     this_register, rbx      ; -- element n vector

        _twodup                         ; -- element n vector n vector
        _vector_raw_length              ; -- element n vector n length
        _ugt                            ; -- element n vector
        _if .1
        _error "vector-insert-nth n > length"
        _then .1

        _dup                            ; -- element n vector vector
        _vector_raw_length              ; -- element n vector length
        _oneplus                        ; -- element n vector length+1
        _over                           ; -- element n vector length+1 vector
        _ vector_ensure_capacity_unchecked      ; -> element n vector

        _vector_raw_data_address        ; -- element n raw-data-address
        _over                           ; -- element n raw-data-address n
        _duptor                         ; -- element n raw-data-address n           r: -- n
        _cells
        _plus                           ; -- element n addr
        _dup
        _cellplus                       ; -- element n addr addr+8
        _this
        _vector_raw_length
        _rfrom
        _minus                          ; -- element n addr addr+8 #cells

        mov     arg2_register, rbx                      ; count
        mov     arg1_register, [rbp]                    ; destination
        mov     arg0_register, [rbp + BYTES_PER_CELL]   ; source
        _3drop
        _ move_cells

        ; update length
        add     qword [this_register + VECTOR_RAW_LENGTH_OFFSET], 1

        ; -> element n
        _this_vector_set_nth_unsafe     ; -> empty

        pop     this_register
        next
endcode

; ### vector-remove-nth!
code vector_remove_nth_mutating, 'vector-remove-nth!'   ; n vector --

        _ check_bounds

        _ check_vector

        push    this_register
        mov     this_register, rbx
        poprbx

        _untag_fixnum

        _this_vector_raw_data_address   ; -- n addr
        _swap                           ; -- addr n
        _duptor                         ; -- addr n                     r: -- n
        _oneplus
        _cells
        _plus                           ; -- addr2
        _dup                            ; -- addr2 addr2
        _cellminus                      ; -- addr2 addr2-8
        _this_vector_raw_length
        _oneminus                       ; -- addr2 addr2-8 len-1        r: -- n
        _rfrom                          ; -- addr2 addr2-8 len-1 n
        _minus                          ; -- addr2 addr2-8 len-1-n

        mov     arg2_register, rbx                      ; count
        mov     arg1_register, [rbp]                    ; destination
        mov     arg0_register, [rbp + BYTES_PER_CELL]   ; source
        mov     rbx, [rbp + BYTES_PER_CELL * 2]
        lea     rbp, [rbp + BYTES_PER_CELL * 3]
        _ move_cells

        _zero
        _this_vector_raw_data_address
        _this_vector_raw_length
        _oneminus
        _cells
        _plus
        _store

        sub     qword [this_register + VECTOR_RAW_LENGTH_OFFSET], 1

        pop     this_register
        next
endcode

; ### vector-remove
code vector_remove, 'vector-remove'     ; element vector -- new-vector
        _ check_vector

        push    this_register
        mov     this_register, rbx
        poprbx                          ; -- element

        _lit 16
        _ new_vector_untagged
        _swap                           ; -- new-vector element

        _this_vector_raw_length
        _register_do_times .1
        _raw_loop_index
        _this_vector_nth_unsafe
        _twodup
        _ feline_equal
        _tagged_if_not .2
        _pick
        _ vector_push
        _else .2
        _drop
        _then .2

        _loop .1

        _drop                           ; -- new-vector

        pop     this_register
        next
endcode

; ### vector-remove!
code vector_remove_mutating, 'vector-remove!' ; element vector -- vector
        ; save handle
        _duptor

        _ check_vector

        push    this_register
        mov     this_register, rbx
        poprbx                          ; -- element-to-be-removed

        _lit 0                          ; -- element-to-be-removed count
        _swap                           ; -- count element-to-be-removed

        _this_vector_raw_length
        _register_do_times .1
        _raw_loop_index
        _this_vector_nth_unsafe         ; -- count element-to-be-removed current-element

        _twodup
        _ feline_equal
        _tagged_if .2

        ; remove current element
        _drop

        _else .2

        ; keep current element
        _pick                           ; -- count element-to-be-removed current-element count
        _this_vector_set_nth_unsafe     ; -- count element-to-be-removed

        ; increment count
        add     qword [rbp], 1

        _then .2

        _loop .1                        ; -- count element-to-be-removed

        _drop                           ; -- count
        _this_vector_set_raw_length

        pop     this_register

        ; return handle
        _rfrom

        next
endcode

; ### vector-remove-eq!
code vector_remove_eq_mutating, 'vector-remove-eq!' ; element vector -> vector
        ; save handle
        _duptor

        _ check_vector

        push    this_register
        mov     this_register, rbx
        poprbx                          ; -> element-to-be-removed

        _lit 0                          ; -> element-to-be-removed count
        _swap                           ; -> count element-to-be-removed

        _this_vector_raw_length
        _register_do_times .1
        _raw_loop_index
        _this_vector_nth_unsafe         ; -> count element-to-be-removed current-element

        cmp     rbx, [rbp]
        jne     .2
        ; remove current element
        _drop
        jmp     .3
.2:
        ; keep current element
        _pick                           ; -> count element-to-be-removed current-element count
        _this_vector_set_nth_unsafe     ; -> count element-to-be-removed

        ; increment count
        add     qword [rbp], 1
.3:
        _loop .1                        ; -> count element-to-be-removed

        _drop                           ; -> count
        _this_vector_set_raw_length

        pop     this_register

        ; return handle
        _rfrom

        next
endcode

; ### vector-adjoin
code vector_adjoin, 'vector-adjoin'     ; element vector -> void
        _dupd
        _ vector_remove_mutating
        _ vector_push
        next
endcode

; ### vector_push_internal
subroutine vector_push_internal         ; element ^vector -> void
        mov     rax, [rbx + VECTOR_RAW_LENGTH_OFFSET]
        cmp     rax, [rbx + VECTOR_RAW_CAPACITY_OFFSET]
        jge     .1                      ; length >= capacity
        mov     rdx, [rbp]              ; element in rdx
        mov     rcx, [rbx + VECTOR_RAW_DATA_ADDRESS_OFFSET]
        mov     [rcx + BYTES_PER_CELL * rax], rdx
        add     qword [rbx + VECTOR_RAW_LENGTH_OFFSET], 1
        jmp     twodrop
.1:
        ; need to grow capacity
        _dup
        _vector_raw_length
        _oneplus
        _over
        _ vector_ensure_capacity_unchecked

        mov     rax, [rbx + VECTOR_RAW_LENGTH_OFFSET] ; raw length in rax
        mov     rdx, [rbp]              ; element in rdx
        mov     rcx, [rbx + VECTOR_RAW_DATA_ADDRESS_OFFSET]
        mov     [rcx + BYTES_PER_CELL * rax], rdx
        add     qword [rbx + VECTOR_RAW_LENGTH_OFFSET], 1
        jmp     twodrop
endsub

; ### vector-push
code vector_push, 'vector-push'         ; element handle -> void
        _ check_vector                  ; -> element ^vector
        jmp     vector_push_internal
endcode

; ### vector-push-all
code vector_push_all, 'vector-push-all' ; seq vector --
        _ verify_vector
        _swap
        _quotation .1
        _over
        _ vector_push
        _end_quotation .1
        _ each
        _drop
        next
endcode

; ### error-empty-vector
code error_empty_vector, 'error-empty-vector'
        _quote "ERROR: %s: the vector is empty."
        _ format
        _ error
        next
endcode

; ### vector-pop
code vector_pop, 'vector-pop'           ; vector -> element
; error if vector is empty

        _ check_vector                  ; ^vector in rbx

vector_pop_unchecked:
        mov     rax, [rbx + VECTOR_RAW_LENGTH_OFFSET]
        sub     rax, 1
        js      .error
        mov     [rbx + VECTOR_RAW_LENGTH_OFFSET], rax
        mov     rdx, [rbx + VECTOR_RAW_DATA_ADDRESS_OFFSET]
        mov     rbx, [rdx + BYTES_PER_CELL * rax]
        next

.error:
        _drop
        _quote "vector-pop"
        _ error_empty_vector
        next
endcode

; ### vector_?pop_internal
subroutine vector_?pop_internal         ; ^vector -> element/nil
        mov     rax, [rbx + VECTOR_RAW_LENGTH_OFFSET]
        sub     rax, 1
        js      .1
        mov     [rbx + VECTOR_RAW_LENGTH_OFFSET], rax
        mov     rdx, [rbx + VECTOR_RAW_DATA_ADDRESS_OFFSET]
        mov     rbx, qword [rdx + rax * BYTES_PER_CELL]
        ret
.1:
        mov     ebx, NIL
        ret
endsub

; ### vector-?pop
code vector_?pop, 'vector-?pop'         ; handle -> element/nil
        _ check_vector                  ; -> vector
        jmp     vector_?pop_internal
endcode

; ### vector-pop*
code vector_pop_star, 'vector-pop*'     ; handle --

        _ check_vector                  ; -- vector

        push    this_register
        mov     this_register, rbx

        _vector_raw_length
        _oneminus
        _dup
        _zge
        _if .1
        _this_vector_set_raw_length

        ; mark cell empty
        _nil
        _this_vector_raw_length
        _this_vector_set_nth_unsafe

        pop     this_register
        _return
        _then .1

        _drop
        pop     this_register
        _error "vector-pop* vector is empty"

        next
endcode

; ### vector-equal?
code vector_equal?, 'vector-equal?'     ; vector1 vector2 -- ?
        _twodup

        _ vector?
        _tagged_if_not .1
        _3drop
        _nil
        _return
        _then .1

        _ vector?
        _tagged_if_not .2
        _2drop
        _nil
        _return
        _then .2

        _ sequence_equal
        next
endcode

; ### vector-reverse!
code vector_reverse_in_place, 'vector-reverse!'         ; vector -- vector
        _duptor
        _ check_vector

        push    this_register
        mov     this_register, rbx
        poprbx

        _this_vector_raw_length

        ; divide by 2
        shr     rbx, 1

        _register_do_times .1

        _i
        _this_vector_nth_unsafe         ; -- char1

        _this_vector_raw_length
        _oneminus
        _i
        _minus
        _this_vector_nth_unsafe         ; -- char1 char2

        _i
        _this_vector_set_nth_unsafe

        _this_vector_raw_length
        _oneminus
        _i
        _minus
        _this_vector_set_nth_unsafe

        _loop .1

        pop     this_register
        _rfrom
        next
endcode

; ### vector_each_internal
subroutine vector_each_internal ; vector raw-code-address ->

        _swap
        _ check_vector                  ; -> code-address vector

        push    this_register
        mov     this_register, rbx
        push    r12
        mov     r12, [rbp]              ; code address in r12
        _2drop                          ; adjust stack
        _this_vector_raw_length
        _do_times .1
        _raw_loop_index
        _this_vector_nth_unsafe         ; -> element
        call    r12
        _loop .1
        pop     r12
        pop     this_register

        ret
endsub

; ### vector-each
code vector_each, 'vector-each'         ; vector callable --

        ; protect callable from gc
        push    rbx

        ; protect vector from gc
        push    qword [rbp]

        _ callable_raw_code_address     ; -- vector code-address

        _swap
        _ check_vector                  ; -- code-address vector

        push    this_register
        mov     this_register, rbx
        push    r12
        mov     r12, [rbp]              ; code address in r12
        _2drop                          ; adjust stack
        _this_vector_raw_length
        _do_times .1
        _raw_loop_index
        _this_vector_nth_unsafe         ; -- element
        call    r12
        _loop .1
        pop     r12
        pop     this_register

        ; drop vector
        pop     rax

        ; drop callable
        pop     rax

        next
endcode

; ### vector-all?
code vector_all?, 'vector-all?'         ; vector callable -> ?

        ; protect callable from gc
        push    rbx

        _ callable_raw_code_address     ; -> vector code-address

        _swap
        _ check_vector                  ; -> code-address vector

        push    this_register
        mov     this_register, rbx
        push    r12
        mov     r12, [rbp]              ; code address in r12
        _2drop                          ; adjust stack

        _true                           ; initialize return value

        _this_vector_raw_length
        _do_times .1
        _raw_loop_index
        _this_vector_nth_unsafe         ; -> true element
        call    r12                     ; -> true ?
        cmp     rbx, NIL
        _drop                           ; -> true
        jne     .2
        mov     rbx, NIL                ; -> nil
        _leave .1
.2:
        _loop .1
        pop     r12
        pop     this_register

        ; drop callable
        pop     rax

        next
endcode

; ### vector-each-index
code vector_each_index, 'vector-each-index' ; vector quotation-or-xt --
        _ callable_raw_code_address     ; -- vector code-address

        _swap
        _ check_vector                  ; -- code-address vector

        push    this_register
        mov     this_register, rbx
        push    r12
        mov     r12, [rbp]              ; code address in r12
        _2drop                          ; adjust stack
        _this_vector_raw_length
        _zero
        _?do .1
        _i                              ; -- i
        _this_vector_nth_unsafe         ; -- element
        _i                              ; -- element i
        _tag_fixnum                     ; -- element index
        call    r12
        _loop .1                        ; --
        pop     r12
        pop     this_register
        next
endcode

; ### vector-find-string
code vector_find_string, 'vector-find-string' ; string vector -> index/string ?
        _ check_vector

        push    this_register
        mov     this_register, rbx

        _vector_raw_length
        _register_do_times .1
        _i
        _this_vector_nth_unsafe         ; -> string element
        _over
        _ string_equal?                 ; -> string ?
        _tagged_if .2
        ; found it!
        _drop                           ; ->
        _i
        _tag_fixnum
        _true                           ; -> index true
        _unloop
        jmp     .exit
        _then .2
        _loop .1                        ; -> string

        ; not found
        _nil                            ; -> string nil

.exit:
        pop     this_register
        next
endcode

; ### vector>string
code vector_to_string, 'vector>string'  ; vector -- string
        _quote "vector{ "
        _ string_to_sbuf        ; -- vector sbuf
        _swap                   ; -- sbuf vector
        _quotation .1
        _ object_to_string
        _over
        _ sbuf_append_string
        _lit tagged_char(32)
        _over
        _ sbuf_push
        _end_quotation .1
        _ vector_each
        _tagged_char('}')
        _over
        _ sbuf_push
        _ sbuf_to_string
        next
endcode
