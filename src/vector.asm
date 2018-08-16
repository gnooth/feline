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

%define vector_raw_length_slot  qword [rbx + BYTES_PER_CELL]

%macro  _vector_raw_length 0            ; vector -- untagged-length
        _slot1
%endmacro

%macro  _vector_set_raw_length 0        ; untagged-length vector --
        _set_slot1
%endmacro

%define this_vector_raw_length this_slot1

%macro  _this_vector_raw_length 0       ; -- untagged-length
        _this_slot1
%endmacro

%macro  _this_vector_set_raw_length 0   ; untagged-length --
        _this_set_slot1
%endmacro

%define vector_raw_data_address_slot    qword [rbx + BYTES_PER_CELL * 2]

%macro  _vector_raw_data_address 0      ; vector -- raw-data-address
        _slot2
%endmacro

%macro  _vector_set_raw_data_address 0  ; raw-data-address vector --
        _set_slot2
%endmacro

%define this_vector_raw_data_address this_slot2

%macro  _this_vector_raw_data_address 0 ; -- raw-data-address
        _this_slot2
%endmacro

%macro  _this_vector_set_raw_data_address 0     ; raw-data-address --
        _this_set_slot2
%endmacro

%define vector_raw_capacity_slot        qword [rbx + BYTES_PER_CELL * 3]

%macro  _vector_raw_capacity 0          ; vector -- raw-capacity
        _slot3
%endmacro

%macro  _vector_set_raw_capacity 0      ; raw-capacity vector --
        _set_slot3
%endmacro

%define this_vector_raw_capacity this_slot3

%macro  _this_vector_raw_capacity 0     ; -- raw-capacity
        _this_slot3
%endmacro

%macro  _this_vector_set_raw_capacity 0 ; raw-capacity --
        _this_set_slot3
%endmacro

%macro  _vector_nth_unsafe 0            ; index vector -- element
        mov     rax, [rbp]              ; untagged index in rax
        _vector_raw_data_address
        _nip
        mov     rbx, [rbx + BYTES_PER_CELL * rax]
%endmacro

%macro  _this_vector_nth_unsafe 0       ; index -- element
        mov     rax, this_vector_raw_data_address
        mov     rbx, [rax + BYTES_PER_CELL * rbx]
%endmacro

%macro  _this_vector_set_nth_unsafe 0   ; element index --
        mov     rdx, [rbp]
        mov     rax, this_vector_raw_data_address
        mov     [rax + BYTES_PER_CELL * rbx], rdx
        _2drop
%endmacro

; ### vector?
code vector?, 'vector?'                 ; handle -- ?
        _ deref                         ; -- raw-object/0
        test    rbx, rbx
        jz      .1
        _object_raw_typecode_eax
        cmp     eax, TYPECODE_VECTOR
        jne     .1
        mov     ebx, t_value
        _return
.1:
        mov     ebx, f_value
        next
endcode

; ### check_vector
code check_vector, 'check_vector', SYMBOL_INTERNAL      ; handle -- vector
        _dup
        _ deref
        test    rbx, rbx
        jz      .error
        _object_raw_typecode_eax
        cmp     eax, TYPECODE_VECTOR
        jne     .error
        _nip
        next
.error:
        _drop
        _ error_not_vector
        next
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
code vector_capacity, 'vector-capacity' ; vector -- capacity
        _ check_vector
        _vector_raw_capacity
        _tag_fixnum
        next
endcode

; ### vector_raw_length
code vector_raw_length, 'vector_raw_length', SYMBOL_INTERNAL
; vector -- raw-length
        _ check_vector
        _vector_raw_length
        next
endcode

; ### vector-length
code vector_length, 'vector-length'     ; vector -- length
        _ check_vector
        _vector_raw_length
        _tag_fixnum
        next
endcode

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
        _ vector_ensure_capacity
        _then .1                        ; -- new-length
        _dup
        _this_vector_raw_length
        _ugt
        _if .2                          ; -- new-length
        ; initialize new cells to f
        _dup
        _this_vector_raw_length
        _register_do_range .3
        _f
        _i
        _this_vector_set_nth_unsafe
        _loop .3
        _then .2
        _this_vector_set_raw_length
        pop     this_register
        next
endcode

; ### vector-delete-all
code vector_delete_all, 'vector-delete-all' ; handle --
        _ check_vector
        _zero
        _swap                           ; -- 0 vector
        _vector_set_raw_length
        next
endcode

; ### <vector>
code new_vector, '<vector>'             ; capacity -- handle

        _check_index                    ; -- raw-capacity

new_vector_untagged:

        _lit 4
        _ raw_allocate_cells
        push    this_register
        mov     this_register, rbx
        poprbx                          ; -- raw-capacity
        _this_object_set_raw_typecode TYPECODE_VECTOR
        _this_object_set_flags OBJECT_ALLOCATED_BIT
        _dup
        _ raw_allocate_cells            ; -- raw-capacity raw-data-address
        _this_vector_set_raw_data_address
        _this_vector_set_raw_capacity   ; --

        ; initialize all allocated cells to f
        mov     rax, f_value            ; element in rax
        _this_vector_raw_capacity
        popd    rcx                     ; capacity in rcx
%ifdef WIN64
        push    rdi
%endif
        _this_vector_raw_data_address
        popd    rdi
        rep     stosq
%ifdef WIN64
        pop     rdi
%endif

        pushrbx
        mov     rbx, this_register      ; -- vector

        ; return handle
        _ new_handle                    ; -- handle

        pop     this_register
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

; ### vector_ensure_capacity
code vector_ensure_capacity, 'vector_ensure_capacity', SYMBOL_INTERNAL  ; raw-capacity raw-vector -> void

        push    this_register
        mov     this_register, rbx
        poprbx                          ; -> raw-capacity

        cmp     this_vector_raw_capacity, rbx
        jge     .nothing_to_do

        _this_vector_raw_capacity
        _twostar
        _max
        _this_vector_raw_data_address
        _over
        _cells
        _ raw_realloc
        _this_vector_set_raw_data_address
        _this_vector_set_raw_capacity

        pop     this_register
        next

.nothing_to_do:
        _drop
        pop     this_register
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
        cmp     rax, vector_raw_length_slot
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

; ### vector-set-nth
code vector_set_nth, 'vector-set-nth'   ; element index vector --

        _verify_index qword [rbp]
        _untag_fixnum qword [rbp]

vector_set_nth_untagged:

        _ check_vector

        push    this_register
        mov     this_register, rbx
        poprbx                          ; -- element untagged-index

        _this_vector_raw_capacity
        cmp     [rbp], rbx
        poprbx
        jl      .1

        ; -- element untagged-index
        _dup

        ; new capacity needs to be at least index + 1
        _oneplus

        _this
        _ vector_ensure_capacity        ; -- element untagged-index

        ; initialize new cells to f
        _dup
        _this_vector_raw_length
        _register_do_range .2
        _f
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
code vector_insert_nth, 'vector-insert-nth'     ; element n vector --
        _ check_vector

        _verify_index qword [rbp]
        _untag_fixnum qword [rbp]

        push    this_register
        mov     this_register, rbx      ; -- element n vector

        _twodup                         ; -- element n vector n vector
        _vector_raw_length              ; -- element n vector n length
        _ugt                            ; -- element n vector
        _if .1
        _error "vector-insert-nth! n > length"
        _then .1

        _dup                            ; -- element n vector vector
        _vector_raw_length              ; -- element n vector length
        _oneplus                        ; -- element n vector length+1
        _over                           ; -- element n vector length+1 vector
        _ vector_ensure_capacity        ; -- element n vector

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
        _ move_cells_up

        _this_vector_raw_length         ; -- element n length
        _oneplus                        ; -- element n length+1
        _this_vector_set_raw_length     ; -- element n

        _this_vector_set_nth_unsafe     ; ---

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
        _ move_cells_down

        _zero
        _this_vector_raw_data_address
        _this_vector_raw_length
        _oneminus
        _cells
        _plus
        _store

        sub     this_vector_raw_length, 1

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
code vector_remove_mutating, 'vector-remove!'   ; element vector -- vector
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

; ### vector-adjoin
code vector_adjoin, 'vector-adjoin'     ; element set --
        _dupd
        _ vector_remove_mutating
        _ vector_push
        next
endcode

; ### vector-push
code vector_push, 'vector-push'         ; element handle --

        _ check_vector                  ; -- element vector

vector_push_unchecked:

        mov     rax, vector_raw_length_slot     ; raw length in rax
        cmp     rax, vector_raw_capacity_slot
        jge     .1                      ; length >= capacity
        mov     rdx, [rbp]              ; element in rdx
        mov     rcx, vector_raw_data_address_slot
        mov     [rcx + BYTES_PER_CELL * rax], rdx
        add     vector_raw_length_slot, 1
        _2drop
        _return
.1:
        ; need to grow capacity
        _dup
        _vector_raw_length
        _oneplus
        _over
        _ vector_ensure_capacity

        mov     rax, vector_raw_length_slot     ; raw length in rax
        mov     rdx, [rbp]                      ; element in rdx
        mov     rcx, vector_raw_data_address_slot
        mov     [rcx + BYTES_PER_CELL * rax], rdx
        add     vector_raw_length_slot, 1
        _2drop
        next
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

; ### vector-pop
code vector_pop, 'vector-pop'           ; handle -- element

        _ check_vector                  ; -- vector

vector_pop_unchecked:

        push    this_register
        mov     this_register, rbx

        _vector_raw_length
        _oneminus
        _dup
        _zge
        _if .1
        _dup
        _this_vector_set_raw_length
        _this_vector_nth_unsafe         ; -- element

        ; mark cell empty
        _f
        _this_vector_raw_length
        _this_vector_set_nth_unsafe

        pop     this_register
        _return
        _then .1

        _drop
        pop     this_register
        _error "vector-pop vector is empty"

        next
endcode

; ### vector-?pop
code vector_?pop, 'vector-?pop'         ; handle -- element/f

        _ check_vector                  ; -- vector

vector_?pop_unchecked:

        mov     rax, vector_raw_length_slot
        test    rax, rax
        jz      .1
        sub     rax, 1
        mov     vector_raw_length_slot, rax
        mov     rdx, vector_raw_data_address_slot
        mov     rbx, qword [rdx + rax * BYTES_PER_CELL]
        mov     qword [rdx + rax * BYTES_PER_CELL], f_value
        _return
.1:
        mov     ebx, f_value
        next
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
        _f
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
        _f
        _return
        _then .1

        _ vector?
        _tagged_if_not .2
        _2drop
        _f
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

; ### vector-each
code vector_each, 'vector-each'         ; vector callable --

        ; protect callable from gc
        push    rbx

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

        ; drop callable
        pop     rax

        next
endcode

; ### vector-all?
code vector_all?, 'vector-all?'         ; vector callable -- ?

        ; protect callable from gc
        push    rbx

        _ callable_raw_code_address     ; -- vector code-address

        _swap
        _ check_vector                  ; -- code-address vector

        push    this_register
        mov     this_register, rbx
        push    r12
        mov     r12, [rbp]              ; code address in r12
        _2drop                          ; adjust stack

        _t                              ; initialize return value

        _this_vector_raw_length
        _do_times .1
        _raw_loop_index
        _this_vector_nth_unsafe         ; -- t element
        call    r12                     ; -- t ?
        cmp     rbx, f_value
        poprbx                          ; -- t
        jne     .2
        mov     rbx, f_value            ; -- f
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
code vector_find_string, 'vector-find-string' ; string vector -- index/string ?
        _ check_vector

        push    this_register
        mov     this_register, rbx

        _vector_raw_length
        _register_do_times .1
        _i
        _this_vector_nth_unsafe         ; -- string element
        _over
        _ string_equal?                 ; -- string ?
        _tagged_if .2
        ; found it!
        _drop                           ; --
        _i
        _tag_fixnum
        _t                              ; -- index t
        _unloop
        jmp     .exit
        _then .2
        _loop .1                        ; -- string

        ; not found
        _f                              ; -- string f

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

; ### vector-clone
code vector_clone, 'vector-clone'       ; old -- new
        _dup
        _ vector_length
        _ new_vector                    ; -- old new
        _swap

        _quotation .1
        _over
        _ vector_push
        _end_quotation .1

        _ vector_each
        next
endcode

; ### vector>array
code vector_to_array, 'vector>array'    ; vector -- array
        _dup
        _ vector_length
        _f
        _ new_array                     ; -- vector array
        _swap                           ; -- array vector

        _quotation .1
        ; -- array element index
        _pick
        ; -- array element index array
        _ array_set_nth
        _end_quotation .1               ; -- array vector quotation

        _ vector_each_index             ; -- array
        next
endcode
