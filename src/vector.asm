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
code vector?, 'vector?'                 ; handle -- flag
        _dup
        _ handle?
        _if .1
        _handle_to_object_unsafe        ; -- object
        _dup_if .2
        _object_type                    ; -- object-type
        _lit OBJECT_TYPE_VECTOR
        _equal
        _then .2
        _else .1
        xor     ebx, ebx
        _then .1
        next
endcode

; ### error-not-vector
code error_not_vector, 'error-not-vector' ; x --
        ; REVIEW
        _drop
        _true
        _abortq "not a vector"
        next
endcode

; ### check-vector
code check_vector, 'check-vector'       ; handle -- vector
        _dup
        _ handle?
        _if .1
        _handle_to_object_unsafe        ; -- object|0
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
        ; initialize new cells to 0
        _dup
        _this_vector_length
        _?do .3
        _lit 0
        _tag_fixnum
        _i
        _this_vector_set_nth_unsafe
        _loop .3
        _then .2
        _this_vector_set_length
        pop     this_register
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

%ifdef USE_TAGS
        _dup
        _fixnum?
        _if .1
        _untag_fixnum
        _then .1
%endif

new_vector_untagged:
        _lit 4
        _cells
        _ allocate_object
        _duptor                         ; -- capacity vector                    r: -- vector
        _lit 4
        _cells
        _ erase                         ; -- capacity                           r: -- vector
        _rfetch
        _lit OBJECT_TYPE_VECTOR
        _object_set_type                ; -- capacity
        _dup                            ; -- capacity capacity                  r: -- vector
        _cells
        _ iallocate                     ; -- capacity data-address              r: -- vector
        _rfetch                         ; -- capacity data-address vector       r: -- vector
        _swap                           ; -- capacity vector data-address       r: -- vector
        _vector_set_data                ; -- capacity                           r: -- vector
        _rfetch                         ; -- capacity vector                    r: -- vector
        _swap                           ; -- vector capacity                    r: -- vector
        _vector_set_capacity            ; --                                    r: -- vector
        _rfrom                          ; -- vector

        ; return handle of allocated object
        _ new_handle                    ; -- handle

        next
endcode

; ### ~vector
code destroy_vector, '~vector'          ; handle --
        _ check_vector                  ; -- vector|0
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

; ### vector-resize
code vector_resize, 'vector-resize'     ; vector new-capacity --
        _over                           ; -- vector new-capacity vector
        _vector_data                    ; -- vector new-capacity data-address
        _over                           ; -- vector new-capacity data-address new-capacity
        _cells
        _ resize                        ; -- vector new-capacity new-data-address ior
        _ throw                         ; -- vector new-capacity new-data-address
        _tor
        _over                           ; -- vector new-capacity vector         r: -- new-data-addr
        _swap
        _vector_set_capacity            ; -- vector                             r: -- new-data-addr
        _rfrom                          ; -- vector new-data-addr
        _vector_set_data
        next
endcode

; ### vector-ensure-capacity
code vector_ensure_capacity, 'vector-ensure-capacity'   ; u vector --
        _ twodup                        ; -- u vector u vector
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
        next
endcode

; ### vector-nth
code vector_nth, 'vector-nth'           ; index handle -- element

%ifdef USE_TAGS
        _swap
        _untag_fixnum
        _swap
%endif

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
        _true
        _abortq "vector-nth index out of range"
        next
endcode

; ### vector-check-index
code vector_check_index, 'vector-check-index' ; vector index -- flag
        _swap
        _ check_vector                  ; -- index vector
        _vector_length                  ; -- index length
        _ult                            ; -- flag
        next
endcode

; ### vector-ref
code vector_ref, 'vector-ref'           ; vector index -- element

%ifdef USE_TAGS
        _untag_fixnum
%endif

        _twodup
        _ vector_check_index
        _if .1
        _swap
        _ vector_data
        _swap
        _cells
        _plus
        _fetch
        _else .1
        _true
        _abortq "vector-ref index out of range"
        _then .1
        next
endcode

; ### vector-set-nth
code vector_set_nth, 'vector-set-nth'   ; element index vector --
        _ check_vector

        _twodup
        _vector_length
        _ult
        _if .1
        _vector_data
        _swap
        _cells
        _plus
        _store
        _else .1
        _true
        _abortq "vector-set-nth index out of range"
        _then .1
        next
endcode

; ### vector-set
code vector_set, 'vector-set'           ; vector index element --
        _ rrot                          ; -- element vector index

%ifdef USE_TAGS
        _untag_fixnum
%endif

        _ twodup
        _ vector_check_index
        _if .1                          ; -- element vector index
        _ swap
        _ vector_data
        _ swap
        _cells
        _plus
        _ store
        _else .1
        _true
        _abortq "vector-set index out of range"
        _then .1
        next
endcode

; ### vector-insert-nth
code vector_insert_nth, 'vector-insert-nth' ; element n vector --
        _ check_vector

        push    this_register
        mov     this_register, rbx      ; -- element n vector

        _twodup                         ; -- element n vector n vector
        _vector_length                  ; -- element n vector n length
        _ugt                            ; -- element n vector
        _abortq "vector-insert-nth n > length"

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

        _this                           ; -- element n vector
        _dup                            ; -- element n vector vector
        _vector_length                  ; -- element n vector length
        _oneplus                        ; -- element n vector length+1
        _vector_set_length              ; -- element n

        _this                           ; -- element n vector
        _vector_set_nth_unsafe          ; ---

        pop     this_register
        next
endcode

; ### vector-remove-nth
code vector_remove_nth, 'vector-remove-nth' ; n handle --

%ifdef USE_TAGS
        _swap
        _untag_fixnum
        _swap
%endif

        _ check_vector

        push    this_register
        mov     this_register, rbx

        _twodup
        _vector_length                  ; -- n vector n length
        _zero                           ; -- n vector n length 0
        _swap                           ; -- n vector n 0 length
        _ within                        ; -- n vector flag
        _zeq
        _abortq "vector-remove-nth n > length - 1" ; -- n vector

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
        _this
        _vector_data
        _this
        _vector_length
        _oneminus
        _cells
        _plus
        _store

        _this
        _dup
        _vector_length
        _oneminus
        _vector_set_length

        pop     this_register
        next
endcode

; ### vector-push-unchecked
code vector_push_unchecked, 'vector-push-unchecked' ; element vector --
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

; ### vector-push
code vector_push, 'vector-push'         ; element handle --
        _ check_vector
        _ vector_push_unchecked
        next
endcode

; ### vector-pop-unchecked              ; vector -- element
code vector_pop_unchecked, 'vector-pop-unchecked'
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
        pop     this_register
        _else .1
        _drop
        pop     this_register
        _true
        _abortq "vector-pop-unchecked vector is empty"
        _then .1

        next
endcode

; ### vector-pop
code vector_pop, 'vector-pop'           ; handle -- element
        _ check_vector                  ; -- vector
        _ vector_pop_unchecked
        next
endcode

; ### vector-each
code vector_each, 'vector-each'         ; vector xt --
        _swap
        _ check_vector

        push    this_register
        mov     this_register, rbx
        _vector_length
        _zero
        _?do .1
        _i
        _this_vector_nth_unsafe         ; -- xt element
        _over                           ; -- xt element xt
        _execute
        _loop .1                        ; -- xt
        _drop
        pop     this_register
        next
endcode

; ### vector-each-index
code vector_each_index, 'vector-each-index' ; vector quot: ( element index -- ) --
        _swap
        _ check_vector

        push    this_register
        mov     this_register, rbx
        _vector_length
        _zero
        _?do .1
        _i                              ; -- xt i
        _this_vector_nth_unsafe         ; -- xt element
        _i                              ; -- xt element i
        _tag_fixnum                     ; -- xt element index
        _lit 2
        _pick
        _execute
        _loop .1                        ; -- xt
        _drop
        pop     this_register
        next
endcode

; ### vector-find-string
code vector_find_string, 'vector-find-string' ; string vector -- index flag
        _ check_vector

        push    this_register
        mov     this_register, rbx

        _vector_length
        _zero
        _?do .1
        _i
        _this_vector_nth_unsafe         ; -- string element
        _over
        _ string_equal?                 ; -- string flag
        _untag_fixnum
        _if .2
        ; found it!
        _drop
        _i
        _tag_fixnum
        _true
        _tag_fixnum
        _unloop
        jmp     .exit
        _then .2
        _loop .1

        ; not found
        _drop
        _zero
        _tag_fixnum
        _false
        _tag_fixnum

.exit:
        pop     this_register
        next
endcode

; ### .vector
code dot_vector, '.vector'              ; vector --
        _ check_vector

        push    this_register
        mov     this_register, rbx

        _dotq "{ "
        _vector_length
        _zero
        _?do .1
        _i
        _this
        _vector_nth_unsafe
        _ dot_object
        _loop .1
        _dotq "}"

        pop     this_register
        next
endcode
