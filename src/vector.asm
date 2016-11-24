; Copyright (C) 2015-2016 Peter Graves <gnooth@gmail.com>

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

; ### vector?
code vector?, 'vector?'                 ; handle -- ?
        _dup
        _ handle?
        _tagged_if .1
        _handle_to_object_unsafe        ; -- object
        _dup_if .2
        _object_type                    ; -- object-type
        _lit OBJECT_TYPE_VECTOR
        _eq?
        _return
        _then .2
        _then .1
        mov     ebx, f_value
        next
endcode

; ### error-not-vector
code error_not_vector, 'error-not-vector' ; x --
        ; REVIEW
        _error "not a vector"
        next
endcode

; ### check-vector
code check_vector, 'check-vector'       ; handle -- vector
        _dup
        _ handle?
        _tagged_if .1
        _handle_to_object_unsafe        ; -- object/0
        _dup_if .2
        _dup
        _object_type                    ; -- object object-type
        _lit OBJECT_TYPE_VECTOR
        _equal
        _if .3
        _return
        _then .3
        _then .2
        _then .1

        _ error_not_vector
        next
endcode

; ### verify-vector
code verify_vector, 'verify-vector'     ; handle -- handle
; Returns argument unchanged.
        _dup
        _ handle?
        _tagged_if .1
        _dup
        _handle_to_object_unsafe        ; -- handle object/0
        _dup_if .2
        _object_type                    ; -- object object-type
        _lit OBJECT_TYPE_VECTOR
        _equal
        _if .3
        _return
        _then .3
        _then .2
        _then .1

        _ error_not_vector

        next
endcode

; ### vector-length
code vector_length, 'vector-length'     ; vector -- length
        _ check_vector
        _vector_length
        _tag_fixnum
        next
endcode

; ### vector-set-length
code vector_set_length, 'vector-set-length' ; tagged-new-length handle --
        _ check_vector                  ; -- tagged-new-length vector
        push    this_register
        mov     this_register, rbx
        poprbx                          ; -- tagged-new-length
        _untag_fixnum                   ; -- new-length
        _dup
        _this_vector_capacity
        _ugt
        _if .1                          ; -- new-length
        _dup
        _this
        _ vector_ensure_capacity
        _then .1                        ; -- new-length
        _dup
        _this_vector_length
        _ugt
        _if .2                          ; -- new-length
        ; initialize new cells to f
        _dup
        _this_vector_length
        _?do .3
        _f
        _i
        _this_vector_set_nth_unsafe
        _loop .3
        _then .2
        _this_vector_set_length
        pop     this_register
        next
endcode

; ### vector-delete-all
code vector_delete_all, 'vector-delete-all' ; handle --
        _ check_vector
        _zero
        _swap                           ; -- 0 vector
        _vector_set_length
        next
endcode

; ### vector-data
code vector_data, 'vector-data'         ; vector -- data-address
        _ check_vector
        _vector_data
        next
endcode

; ### <vector>
code new_vector, '<vector>'             ; capacity -- handle

        _check_fixnum

new_vector_untagged:

        _lit 4
        _ allocate_cells
        push    this_register
        mov     this_register, rbx
        poprbx                          ; -- capacity
        _this_object_set_type OBJECT_TYPE_VECTOR
        _this_object_set_flags OBJECT_ALLOCATED_BIT
        _dup
        _ allocate_cells                ; -- capacity data-address
        _this_vector_set_data
        _this_vector_set_capacity

        ; initialize all allocated cells to f
        mov     rax, f_value            ; element in rax
        _this_vector_capacity
        popd    rcx                     ; capacity in rcx
%ifdef WIN64
        push    rdi
%endif
        _this_vector_data
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

; ### ~vector
code destroy_vector, '~vector'          ; handle --
        _ check_vector                  ; -- vector
        _ destroy_vector_unchecked
        next
endcode

; ### ~vector-unchecked
code destroy_vector_unchecked, '~vector-unchecked' ; vector --
        _dup
        _vector_data
        _ ifree                         ; -- vector

        _ in_gc?
        _zeq_if .1
        _dup
        _ release_handle_for_object
        _then .1

        ; Zero out the object header so it won't look like a valid object
        ; after it has been destroyed.
        xor     eax, eax
        mov     [rbx], rax

        _ ifree

        next
endcode

; ### vector_resize
subroutine vector_resize                ; vector new-capacity --
        _swap
        push    this_register
        mov     this_register, rbx
        poprbx                          ; -- new-capacity
        _this_vector_data               ; -- new-capacity data-address
        _over                           ; -- new-capacity data-address new-capacity
        _cells
        _ resize                        ; -- new-capacity new-data-address
        _this_vector_set_data
        _this_vector_set_capacity
        pop     this_register
        ret
endsub

; ### vector_ensure_capacity
subroutine vector_ensure_capacity       ; u vector --
        _twodup                         ; -- u vector u vector
        _vector_capacity                ; -- u vector u capacity
        _ugt
        _if .1                          ; -- u vector
        _dup                            ; -- u vector vector
        _vector_capacity                ; -- u vector capacity
        _twostar                        ; -- u vector capacity*2
        _ rot                           ; -- vector capacity*2 u
        _ max                           ; -- vector new-capacity
        _ vector_resize
        _else .1
        _2drop
        _then .1
        ret
endsub

; ### vector-nth-unsafe
code vector_nth_unsafe, 'vector-nth-unsafe' ; index handle -- element
        _swap
        _untag_fixnum
        _swap
        _handle_to_object_unsafe
        _vector_nth_unsafe
        next
endcode

; ### vector-nth
code vector_nth, 'vector-nth'           ; index handle -- element

        _swap
        _untag_fixnum
        _swap

vector_nth_untagged:
        _ check_vector

        _twodup
        _vector_length
        _ult
        _if .1
        _vector_nth_unsafe
        _return
        _then .1

        _2drop
        _error "vector-nth index out of range"
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
        _vector_length                  ; -- vector untagged-length
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

        _this_vector_capacity
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
        _this_vector_length
        _?do .2
        _f
        _i
        _this_vector_set_nth_unsafe
        _loop .2

.1:
        _dup
        _oneplus
        _this_vector_length
        _ max
        _this_vector_set_length

        _this_vector_set_nth_unsafe

        pop     this_register
        next
endcode

; ### vector-insert-nth!
code vector_insert_nth_destructive, 'vector-insert-nth!' ; element n vector --
        _ check_vector

        _swap
        _untag_fixnum
        _swap

        push    this_register
        mov     this_register, rbx      ; -- element n vector

        _twodup                         ; -- element n vector n vector
        _vector_length                  ; -- element n vector n length
        _ugt                            ; -- element n vector
        _if .1
        _error "vector-insert-nth! n > length"
        _then .1

        _dup                            ; -- element n vector vector
        _vector_length                  ; -- element n vector length
        _oneplus                        ; -- element n vector length+1
        _over                           ; -- element n vector length+1 vector
        _ vector_ensure_capacity        ; -- element n vector

        _vector_data                    ; -- element n data-address
        _over                           ; -- element n data-address n
        _duptor                         ; -- element n data-address n           r: -- n
        _cells
        _plus                           ; -- element n addr
        _dup
        _cellplus                       ; -- element n addr addr+8
        _this
        _vector_length
        _rfrom
        _minus
        _cells                          ; -- element n addr addr+8 #bytes
        _ cmoveup                       ; -- element n

        _this_vector_length             ; -- element n length
        _oneplus                        ; -- element n length+1
        _this_vector_set_length         ; -- element n

        _this_vector_set_nth_unsafe     ; ---

        pop     this_register
        next
endcode

; ### vector-remove-nth!
code vector_remove_nth_destructive, 'vector-remove-nth!' ; n handle --

        _swap
        _untag_fixnum
        _swap

        _ check_vector

        push    this_register
        mov     this_register, rbx

        _twodup
        _vector_length                  ; -- n vector n length
        _zero                           ; -- n vector n length 0
        _swap                           ; -- n vector n 0 length
        _ within                        ; -- n vector flag
        _zeq_if .1
        _error "vector-remove-nth n > length - 1" ; -- n vector
        _then .1

        _vector_data                    ; -- n addr
        _swap                           ; -- addr n
        _duptor                         ; -- addr n                     r: -- n
        _oneplus
        _cells
        _plus                           ; -- addr2
        _dup                            ; -- addr2 addr2
        _cellminus                      ; -- addr2 addr2-8
        _this
        _vector_length
        _oneminus                       ; -- addr2 addr2-8 len-1        r: -- n
        _rfrom                          ; -- addr2 addr2-8 len-1 n
        _minus                          ; -- addr2 addr2-8 len-1-n
        _cells                          ; -- addr2 addr2-8 #bytes
        _ cmove

        _zero
        _this_vector_data
        _this_vector_length
        _oneminus
        _cells
        _plus
        _store

        _this_vector_length
        _oneminus
        _this_vector_set_length

        pop     this_register
        next
endcode

; ### vector-push
code vector_push, 'vector-push'         ; element handle --

        _ check_vector

vector_push_unchecked:

        push    this_register           ; save callee-saved register
        mov     this_register, rbx      ; vector in this_register

        _vector_length                  ; -- element length
        _dup                            ; -- element length length
        _oneplus                        ; -- element length length+1
        _dup                            ; -- element length length+1 length+1
        _this                           ; -- element length length+1 length+1 this
        _ vector_ensure_capacity        ; -- element length length+1
        _this_vector_set_length         ; -- element length
        _this_vector_set_nth_unsafe     ; --

        pop     this_register           ; restore callee-saved register
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

        _vector_length
        _oneminus
        _dup
        _zge
        _if .1
        _dup
        _this_vector_set_length
        _this_vector_nth_unsafe         ; -- element

        ; mark cell empty
        _f
        _this_vector_length
        _this_vector_set_nth_unsafe

        pop     this_register
        _return
        _then .1

        _drop
        pop     this_register
        _error "vector-pop vector is empty"

        next
endcode

; ### vector-pop*
code vector_pop_star, 'vector-pop*'     ; handle --

        _ check_vector                  ; -- vector

        push    this_register
        mov     this_register, rbx

        _vector_length
        _oneminus
        _dup
        _zge
        _if .1
        _this_vector_set_length

        ; mark cell empty
        _f
        _this_vector_length
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

; ### vector-each
code vector_each, 'vector-each'         ; vector quotation-or-xt --

        _ callable_code_address         ; -- vector code-address

        _swap
        _ check_vector                  ; -- code-address vector

        push    this_register
        mov     this_register, rbx
        push    r12
        mov     r12, [rbp]              ; code address in r12
        _2drop                          ; adjust stack
        _this_vector_length
        _zero
        _?do .1
        _i
        _this_vector_nth_unsafe         ; -- element
        call    r12
        _loop .1
        pop     r12
        pop     this_register
        next
endcode

; ### vector-each-index
code vector_each_index, 'vector-each-index' ; vector quotation-or-xt --
        _ callable_code_address         ; -- vector code-address

        _swap
        _ check_vector                  ; -- code-address vector

        push    this_register
        mov     this_register, rbx
        push    r12
        mov     r12, [rbp]              ; code address in r12
        _2drop                          ; adjust stack
        _this_vector_length
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
code vector_find_string, 'vector-find-string' ; string vector -- index ?
        _ check_vector

        push    this_register
        mov     this_register, rbx

        _vector_length
        _zero
        _?do .1
        _i
        _this_vector_nth_unsafe         ; -- string element
        _over
        _ string_equal?                 ; -- string ?
        _tagged_if .2
        ; found it!
        _drop
        _i
        _tag_fixnum
        _t
        _unloop
        jmp     .exit
        _then .2
        _loop .1

        ; not found
        _drop
        _f
        _f

.exit:
        pop     this_register
        next
endcode

; ### .vector
code dot_vector, '.vector'              ; vector --
        _ check_vector

        push    this_register
        mov     this_register, rbx

        _write "V{ "
        _vector_length
        _zero
        _?do .1
        _i
        _this_vector_nth_unsafe
        _ dot_object
        _ space
        _loop .1
        _write "}"

        pop     this_register
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
