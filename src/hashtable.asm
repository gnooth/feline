; Copyright (C) 2016-2020 Peter Graves <gnooth@gmail.com>

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

; 8 cells (object header, count, deleted, capacity, data address,
; hash function, test function, raw mask)

%macro  _hashtable_raw_count 0          ; hashtable -- count
        _slot1
%endmacro

%macro  _this_hashtable_raw_count 0     ; -- count
        _this_slot1
%endmacro

%macro  _this_hashtable_set_raw_count 0 ; count --
        _this_set_slot1
%endmacro

%macro  _this_hashtable_increment_raw_count 0   ; --
        add     qword [this_register + BYTES_PER_CELL * 1], 1
%endmacro

%macro  _this_hashtable_deleted 0       ; -- deleted
        _this_slot2
%endmacro

%macro  _this_hashtable_set_deleted 0   ; deleted --
        _this_set_slot2
%endmacro

%macro  _hashtable_raw_capacity 0       ; hashtable -- untagged-capacity
        _slot3
%endmacro

%define this_hashtable_raw_capacity     this_slot3

%macro  _this_hashtable_raw_capacity 0  ; -- untagged-capacity
        _this_slot3
%endmacro

%macro  _this_hashtable_set_raw_capacity 0      ; untagged-capacity --
        _this_set_slot3
%endmacro

%macro  _hashtable_data 0               ; hashtable -- data-address
        _slot4
%endmacro

%define this_hashtable_data_address     this_slot4

%macro  _this_hashtable_data 0          ; -- data-address
        _this_slot4
%endmacro

%macro  _this_hashtable_set_data 0      ; data-address --
        _this_set_slot4
%endmacro

%macro  _this_hashtable_nth_key 0       ; n -- key
        shl     rbx, 4                  ; convert index to byte offset
        mov     rax, this_hashtable_data_address
        mov     rbx, [rax + rbx]
%endmacro

%macro  _this_hashtable_nth_value 0     ; n -- value
        shl     rbx, 4                  ; convert index to byte offset
        mov     rax, this_hashtable_data_address
        mov     rbx, [rax + rbx + BYTES_PER_CELL]
%endmacro

%macro  _this_hashtable_set_nth_key 0   ; key n --
        shl     rbx, 4                  ; convert index to byte offset
        _this_hashtable_data            ; -- key offset data-address
        _plus
        _store
%endmacro

%macro  _this_hashtable_set_nth_value 0 ; value n --
        shl     rbx, 4                  ; convert index to byte offset
        _this_hashtable_data            ; -- value offset data-address
        _plus
        add     rbx, BYTES_PER_CELL
        _store
%endmacro

%define this_hashtable_hash_function    this_slot5

%macro  _this_hashtable_hash_function 0
        _this_slot5
%endmacro

%macro  _hashtable_set_hash_function 0
        _set_slot5
%endmacro

%macro  _this_hashtable_set_hash_function 0
        _this_set_slot5
%endmacro

%define this_hashtable_test_function    this_slot6

%macro  _hashtable_set_test_function 0
        _set_slot6
%endmacro

%macro  _this_hashtable_test_function 0
        _this_slot6
%endmacro

%macro  _this_hashtable_set_test_function 0
        _this_set_slot6
%endmacro

%define this_hashtable_raw_mask         this_slot7

%macro  _hashtable_raw_mask 0           ; -- raw-mask
        _slot7
%endmacro

%macro  _this_hashtable_set_raw_mask 0  ; raw-mask --
        _this_set_slot7
%endmacro

; ### hashtable?
code hashtable?, 'hashtable?'           ; x -- ?
        _dup
        _ handle?
        _tagged_if .1
        _handle_to_object_unsafe        ; -- object
        _dup_if .2
        _object_raw_typecode
        _eq? TYPECODE_HASHTABLE
        _return
        _then .2
        _then .1
        mov     ebx, f_value
        next
endcode

; ### check_hashtable
code check_hashtable, 'check_hashtable' ; handle -> ^hashtable
        cmp     bl, HANDLE_TAG
        jne     .error2
        mov     rdx, rbx                ; copy argument in case there is an error
        _handle_to_object_unsafe
%ifdef DEBUG
        test    rbx, rbx
        jz      error_empty_handle
%endif
        cmp     word [rbx], TYPECODE_HASHTABLE
        jne     .error1
        next
.error1:
        mov     rbx, rdx                ; restore original argument
.error2:
        jmp     error_not_hashtable
endcode

; ### verify-hashtable
code verify_hashtable, 'verify-hashtable'       ; handle -- handle
        _dup
        _ deref
        test    rbx, rbx
        jz      .error
        _object_raw_typecode_eax
        cmp     eax, TYPECODE_HASHTABLE
        jne     .error
        _drop
        next
.error:
        _drop
        _ error_not_hashtable
        next
endcode

; ### hashtable-count
code hashtable_count, 'hashtable-count'         ; hashtable -- count
        _ check_hashtable
        _hashtable_raw_count
        _tag_fixnum
        next
endcode

; ### hashtable-capacity
code hashtable_capacity, 'hashtable-capacity'   ; hashtable -- capacity
; Return value is tagged.
        _ check_hashtable
        _hashtable_raw_capacity
        _tag_fixnum
        next
endcode

; ### hashtable-set-hash-function
code hashtable_set_hash_function, 'hashtable-set-hash-function' ; hash-function hashtable --
        _ check_hashtable
        _hashtable_set_hash_function
        next
endcode

; ### hashtable-set-test-function
code hashtable_set_test_function, 'hashtable-set-test-function' ; test-function hashtable --
        _ check_hashtable
        _hashtable_set_test_function
        next
endcode

; ### empty-or-deleted?
code empty_or_deleted?, 'empty-or-deleted?'     ; x -> ?
        cmp     rbx, f_value
        je     .2
.1:
        cmp     rbx, S_deleted_marker
        je      .2
        mov     rbx, f_value
        next
.2:
        mov     rbx, t_value
        next
endcode

; ### hashtable-keys
code hashtable_keys, 'hashtable-keys'   ; hashtable -- keys
        _ check_hashtable               ; -- hashtable

hashtable_keys_unchecked:
        push    this_register
        mov     this_register, rbx
        _hashtable_raw_count
        _ new_vector_untagged           ; -- handle-to-vector
        _this_hashtable_raw_capacity
        _register_do_times .1
        _i
        _this_hashtable_nth_key
        _dup
        _ empty_or_deleted?
        _tagged_if_not .2
        _over
        _ vector_push
        _else .2
        _drop
        _then .2
        _loop .1
        pop     this_register
        next
endcode

; ### hashtable-values
code hashtable_values, 'hashtable-values'       ; hashtable -- values
        _ check_hashtable               ; -- hashtable

hashtable_values_unchecked:
        push    this_register
        mov     this_register, rbx
        _hashtable_raw_count
        _ new_vector_untagged           ; -- handle-to-vector
        _this_hashtable_raw_capacity
        _register_do_times .1
        _i
        _this_hashtable_nth_key
        _ empty_or_deleted?
        _tagged_if_not .2
        _i
        _this_hashtable_nth_value
        _over
        _ vector_push
        _then .2
        _loop .1
        pop     this_register
        next
endcode

; ### next-power-of-2
code next_power_of_2, 'next-power-of-2' ; m -> n
; Argument and return value are tagged fixnums.
; We don't check for overflow.
        _check_fixnum
        _lit 2
.1:
        cmp     rbx, qword [rbp]        ; m is in [rbp]
        jge     .2

        shl     rbx, 1
        jmp     .1
.2:
        _nip
        _tag_fixnum
        next
endcode

; ### <hashtable>
code new_hashtable, '<hashtable>'       ; fixnum -- hashtable

        _ next_power_of_2               ; -- fixnum
        _untag_fixnum

new_hashtable_untagged:

        ; 8 cells (object header, count, deleted, capacity, data address,
        ; hash function, test function, raw mask)
        _lit 8
        _ raw_allocate_cells
        push    this_register
        mov     this_register, rbx
        poprbx

        _this_object_set_raw_typecode TYPECODE_HASHTABLE

        _dup
        _this_hashtable_set_raw_capacity        ; -- n

        _dup
        _oneminus
        _this_hashtable_set_raw_mask

        ; each entry occupies two cells (key, value)
        shl     rbx, 4                  ; -- n*16
        _ raw_allocate                  ; -- data-address
        _this_hashtable_set_data        ; --

        _this_hashtable_raw_capacity
        _twostar
        _register_do_times .1
        _f
        _this_hashtable_data
        _i
        _cells
        _plus
        _store
        _loop .1

        _symbol generic_hashcode
        _ symbol_raw_code_address
        _this_hashtable_set_hash_function

        _symbol feline_equal
        _ symbol_raw_code_address
        _this_hashtable_set_test_function

        pushrbx
        mov     rbx, this_register      ; -- hashtable

        ; return handle
        _ new_handle                    ; -- handle

        pop     this_register
        next
endcode

; ### destroy_hashtable_unchecked
code destroy_hashtable_unchecked, 'destroy_hashtable_unchecked', SYMBOL_INTERNAL
; hashtable --

        _dup
        _hashtable_data
        _ raw_free                      ; -- hashtable

        ; zero out object header
        xor     eax, eax
        mov     [rbx], rax

        _ raw_free
        next
endcode

%macro  _mask_index 0
        and     rbx, this_hashtable_raw_mask
%endmacro

%macro  _this_hashtable_raw_start_index_for_key 0       ; key -- start-index
        call    this_hashtable_hash_function
        _untag_fixnum
        _mask_index
%endmacro

; ### this_hashtable_find_index_for_key
code this_hashtable_find_index_for_key, 'this_hashtable_find_index_for_key', SYMBOL_INTERNAL
; key -- tagged-index/f ?
; must be called with the raw address of the hashtable in this_register (r15)

        _dup
        _this_hashtable_raw_start_index_for_key ; -- key raw-start-index
        _dup                                    ; -- key raw-start-index raw-start-index
        mov     rax, this_hashtable_raw_capacity
        add     qword [rbp], rax                ; -- key raw-end-index raw-start-index

        _register_do_range .1           ; -- key

        _raw_loop_index
        _mask_index
        _this_hashtable_nth_key         ; -- key nth-key

        cmp     rbx, f_value
        jne     .2
        ; found empty slot
        _2drop
        _raw_loop_index
        _mask_index
        _tag_fixnum
        _f
        _unloop
        _return
.2:
        _over                           ; -- key nth-key key
        call    this_hashtable_test_function    ; -- key ?

        _tagged_if .3                   ; -- key
        ; found key
        mov     rbx, index_register
        _mask_index
        _tag_fixnum
        _t
        _unloop
        _return
        _then .3                        ; -- key start-index

        _loop .1

        mov     ebx, f_value
        _dup

        next
endcode

; ### find-index-for-key
code find_index_for_key, 'find-index-for-key'   ; key hashtable -- tagged-index/f ?

        _ check_hashtable               ; -- key raw-hashtable

find_index_for_key_unchecked:

        push    this_register
        mov     this_register, rbx
        poprbx                          ; -- key
        _ this_hashtable_find_index_for_key
        pop     this_register

        next
endcode

; ### at*
code hashtable_at_star, 'at*'           ; key hashtable -- value/f ?
        _ check_hashtable
        push    this_register
        mov     this_register, rbx
        poprbx                                  ; -- key
        _ this_hashtable_find_index_for_key     ; -- tagged-index/f ?
        _tagged_if .1
        _untag_fixnum
        _this_hashtable_nth_value
        _t
        _else .1
        _drop
        _f
        _f
        _then .1
        pop     this_register
        next
endcode

; ### at
code hashtable_at, 'at'                 ; key hashtable -- value
        _ check_hashtable
        push    this_register
        mov     this_register, rbx
        poprbx                                  ; -- key
        _ this_hashtable_find_index_for_key     ; -- tagged-index/f ?
        cmp     rbx, f_value
        je      .1
        _drop
        _untag_fixnum
        _this_hashtable_nth_value
        pop     this_register
        _return
.1:                                     ; -- f f
        _nip
        pop     this_register
        next
endcode

%macro _this_hashtable_set_nth_pair 0   ; -- value key index
        _tuck
        _this_hashtable_set_nth_key
        _this_hashtable_set_nth_value
%endmacro

; ### set-at
code hashtable_set_at, 'set-at'         ; value key handle --

        _ check_hashtable               ; -- value key hashtable

        _dup
        _hashtable_raw_count
        _lit 3
        _star
        _over
        _hashtable_raw_capacity
        _twostar
        cmp     [rbp], rbx
        _2drop
        jle     .1
        _dup
        _ hashtable_grow_unchecked
.1:

hashtable_set_at_unchecked:

        push    this_register
        mov     this_register, rbx      ; -- value key hashtable
        poprbx                          ; -- value key
        _dup
        _ this_hashtable_find_index_for_key     ; -- value key tagged-index ?
        _tagged_if_not .2
        ; key was not found
        ; we're adding an entry
        _this_hashtable_increment_raw_count
        _then .2                        ; -- value key tagged-index
        _untag_fixnum
        _this_hashtable_set_nth_pair
        pop     this_register

        next
endcode

; ### delete-at
code delete_at, 'delete-at'     ; key handle --

        _ check_hashtable       ; -- key hashtable

        push    this_register
        mov     this_register, rbx      ; -- key hashtable

        _ find_index_for_key_unchecked  ; -- tagged-index/f ?

        _tagged_if .1

        ; -- tagged-index
        _ deleted_marker
        _ deleted_marker
        _ rot
        _untag_fixnum
        _this_hashtable_set_nth_pair

        _else .1

        ; not found
        _drop

        _then .1

        pop     this_register
        next
endcode

; ### hashtable-grow
code hashtable_grow, 'hashtable-grow'   ; hashtable --
        _ check_hashtable               ; -- hashtable

hashtable_grow_unchecked:
        push    this_register
        mov     this_register, rbx

        _dup
        _ hashtable_keys_unchecked
        _swap
        _ hashtable_values_unchecked    ; -- keys values

        _this_hashtable_data
        _ raw_free

        _this_hashtable_raw_capacity    ; -- ... n
        ; double existing capacity
        _twostar
        _dup
        _this_hashtable_set_raw_capacity
        _dup
        _oneminus
        _this_hashtable_set_raw_mask
        ; 16 bytes per entry
        shl     rbx, 4                  ; -- ... n*16
        _ raw_allocate
        _this_hashtable_set_data        ; -- keys values

        _this_hashtable_raw_capacity
        _twostar
        _register_do_times .1
        _f
        _this_hashtable_data
        _i
        _cells
        _plus
        _store
        _loop .1

        ; reset count
        _zero
        _this_hashtable_set_raw_count

        _dup
        _ vector_length
        _untag_fixnum
        _register_do_times .2

        ; value
        _tagged_loop_index
        _over
        _ vector_nth                    ; -- keys values nth-value

        ; key
        _pick                           ; -- keys values nth-value keys
        _tagged_loop_index
        _swap
        _ vector_nth                    ; -- keys values nth-value nth-key

        _this
        _ hashtable_set_at_unchecked

        _loop .2                        ; -- keys values
        _2drop
        pop     this_register
        next
endcode

; ### hash-combine
code hash_combine, 'hash-combine'       ; hash1 hash2 -> combined

        sar     rbx, FIXNUM_TAG_BITS    ; hash2 (untagged) in rbx
        mov     rax, [rbp]
        sar     rax, FIXNUM_TAG_BITS    ; hash1 (untagged) in rax
        lea     rbp, [rbp + BYTES_PER_CELL]

        mov     rdx, 0x9e3779b97f4a7800
        add     rbx, rdx

        mov     rdx, rax
        shl     rdx, 6
        add     rbx, rdx

        mov     rdx, rax
        sar     rdx, 2
        add     rbx, rdx

        xor     rbx, rax

        mov     rax, MOST_POSITIVE_FIXNUM
        and     rbx, rax

        _tag_fixnum

        next
endcode

; ### mix
code mix, 'mix'                         ; x y -> z
; sbcl target-sxhash.lisp:
;
; (defun mix (x y)
;   (declare (optimize (speed 3)))
;   (declare (type (and fixnum unsigned-byte) x y))
;   (let* ((mul (logand 3622009729038463111 sb-xc:most-positive-fixnum))
;          (xor (logand 608948948376289905 sb-xc:most-positive-fixnum))
;          (xy (logand (+ (* x mul) y) sb-xc:most-positive-fixnum)))
;     (logand (logxor xor xy (ash xy -5)) sb-xc:most-positive-fixnum)))

        sar     rbx, FIXNUM_TAG_BITS    ; rbx: y (untagged)
        mov     rcx, [rbp]
        sar     rcx, FIXNUM_TAG_BITS    ; rcx: x (untagged)
        lea     rbp, [rbp + BYTES_PER_CELL]

        mov     rax, rcx                        ; rax: x
        mov     rdx, 3622009729038463111        ; rdx: mul
        mul     rdx                             ; rax: (* x mul)

        add     rax, rbx                        ; rax: (+ (* x mul) y)
        mov     rdx, MOST_POSITIVE_FIXNUM
        and     rax, rdx                        ; rax: (logand (+ (* x mul) y) m-p-f)

        mov     rdx, rax                        ; rdx: xy
        shr     rdx, 5                          ; rdx: (ash xy -5)

        mov     r8, 608948948376289905          ; r8: xor
        xor     rax, r8                         ; rax: (logxor xor xy)
        xor     rax, rdx                        ; rax: (logxor xor xy (ash xy -1))

        mov     rdx, MOST_POSITIVE_FIXNUM
        and     rax, rdx                        ; rax: (logand (logxor xor xy (ash xy -1)) m-p-f)

        mov     rbx, rax

        _tag_fixnum

        next
endcode

; ### hashtable>string
code hashtable_to_string, 'hashtable>string'    ; hashtable -- string
        _ check_hashtable

        push    this_register
        mov     this_register, rbx
        poprbx

        _quote "H{"
        _ string_to_sbuf
        _this_hashtable_raw_capacity

        _register_do_times .1

        _raw_loop_index
        _this_hashtable_nth_key
        _dup
        _tagged_if .2
        _quote " { "
        _pick
        _ sbuf_append_string
        _ object_to_string
        _over
        _ sbuf_append_string
        _lit tagged_char(32)
        _over
        _ sbuf_push
        _raw_loop_index
        _this_hashtable_nth_value
        _ object_to_string
        _over
        _ sbuf_append_string
        _quote " }"
        _over
        _ sbuf_append_string
        _else .2
        _drop
        _then .2

        _loop .1

        pop     this_register

        _quote " }"
        _over
        _ sbuf_append_string
        _ sbuf_to_string

        next
endcode
