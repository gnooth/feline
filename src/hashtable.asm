; Copyright (C) 2016 Peter Graves <gnooth@gmail.com>

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

%macro  _hashtable_count 0              ; hashtable -- count
        _slot1
%endmacro

%macro  _this_hashtable_count 0         ; -- count
        _this_slot1
%endmacro

%macro  _this_hashtable_set_count 0     ; count --
        _this_set_slot1
%endmacro

%macro  _this_hashtable_deleted 0       ; -- deleted
        _this_slot2
%endmacro

%macro  _this_hashtable_set_deleted 0   ; deleted --
        _this_set_slot2
%endmacro

%macro  _hashtable_capacity 0           ; hashtable -- capacity
        _slot3
%endmacro

%macro  _this_hashtable_capacity 0      ; -- capacity
        _this_slot3
%endmacro

%macro  _this_hashtable_set_capacity 0  ; capacity --
        _this_set_slot3
%endmacro

%macro  _hashtable_data 0               ; hashtable -- data-address
        _slot4
%endmacro

%macro  _this_hashtable_data 0          ; -- data-address
        _this_slot4
%endmacro

%macro  _this_hashtable_mask 0          ; -- mask
        _this_hashtable_capacity
        _oneminus
%endmacro

%macro  _this_hashtable_set_data 0      ; data-address --
        _this_set_slot4
%endmacro

%macro  _this_hashtable_nth_key 0       ; n -- key
        shl     rbx, 4                  ; convert index to byte offset
        _this_hashtable_data            ; -- offset data-address
        _plus
        _fetch
%endmacro

%macro  _this_hashtable_set_nth_key 0   ; key n --
        shl     rbx, 4                  ; convert index to byte offset
        _this_hashtable_data            ; -- key offset data-address
        _plus
        _store
%endmacro

%macro  _this_hashtable_nth_value 0     ; n -- value
        shl     rbx, 4                  ; convert index to byte offset
        _this_hashtable_data            ; -- offset data-address
        _plus
        add     rbx, BYTES_PER_CELL
        _fetch
%endmacro

%macro  _this_hashtable_set_nth_value 0 ; value n --
        shl     rbx, 4                  ; convert index to byte offset
        _this_hashtable_data            ; -- value offset data-address
        _plus
        add     rbx, BYTES_PER_CELL
        _store
%endmacro

; ### hashtable?
code hashtable?, 'hashtable?'           ; handle -- t|f
        _dup
        _ handle?
        _if .1
        _handle_to_object_unsafe        ; -- object
        _dup_if .2
        _object_type                    ; -- object-type
        _lit OBJECT_TYPE_HASHTABLE
        _feline_equal
        _return
        _then .2
        _then .1
        mov     ebx, f_value
        next
endcode

; ### error-not-hashtable
code error_not_hashtable, 'error-not-hashtable' ; x --
        ; REVIEW
        _drop
        _true
        _abortq "not a hashtable"
        next
endcode

; ### check-hashtable
code check_hashtable, 'check-hashtable' ; handle -- hashtable
        _dup
        _ handle?
        _if .1
        _handle_to_object_unsafe        ; -- object|0
        _dup_if .2
        _dup
        _object_type                    ; -- object object-type
        _lit OBJECT_TYPE_HASHTABLE
        _equal
        _if .3
        _return
        _then .3
        _then .2
        _then .1

        _ error_not_hashtable
        next
endcode

; ### hashtable-count
code hashtable_count, 'hashtable-count' ; hashtable -- count
        _ check_hashtable
        _hashtable_count
        _tag_fixnum
        next
endcode

; ### hashtable-capacity
code hashtable_capacity, 'hashtable-capacity' ; hashtable -- capacity
; Return value is tagged.
        _ check_hashtable
        _hashtable_capacity
        _tag_fixnum
        next
endcode

; ### hashtable-keys
code hashtable_keys, 'hashtable-keys'   ; hashtable -- keys
        _ check_hashtable               ; -- hashtable

hashtable_keys_unchecked:
        push    this_register
        mov     this_register, rbx
        _hashtable_count
        _ new_vector_untagged           ; -- handle-to-vector
        _this_hashtable_capacity
        _zero
        _?do .1
        _i
        _this_hashtable_nth_key
        _dup
        _tagged_if .2
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
code hashtable_values, 'hashtable-values' ; hashtable -- values
        _ check_hashtable               ; -- hashtable

hashtable_values_unchecked:
        push    this_register
        mov     this_register, rbx
        _hashtable_count
        _ new_vector_untagged           ; -- handle-to-vector
        _this_hashtable_capacity
        _zero
        _?do .1
        _i
        _this_hashtable_nth_key
        _tagged_if .2
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
code next_power_of_2, 'next-power-of-2' ; m -- n
; Argument and return value are tagged fixnums.
        _ check_fixnum
        _lit 2
        _begin .1
        _twodup
        _ugt
        _while .1
        _twostar
        _repeat .1
        _nip
        _tag_fixnum
        next
endcode

; ### <hashtable>
code new_hashtable, '<hashtable>'       ; fixnum -- hashtable

        _ next_power_of_2               ; -- fixnum
        _untag_fixnum

        ; 5 cells (object header, count, deleted, capacity, data address)
        _lit 5                          ; -- n 5
        _cells                          ; -- n 40
        _dup                            ; -- n 40 40
        _ allocate_object               ; -- n 40 object-address
        push    this_register
        mov     this_register, rbx      ; -- n 40 object-address
        _swap
        _ erase                         ; -- n

        _this_object_set_type OBJECT_TYPE_HASHTABLE

        ; FIXME calculate capacity (must be power of 2)
        _dup
        _this_hashtable_set_capacity    ; -- n

        ; each entry occupies two cells (key, value)
        shl     rbx, 4                  ; -- n*16
        _ iallocate                     ; -- data-address
        _this_hashtable_set_data        ; --

        _this_hashtable_capacity
        _twostar
        _zero
        _?do .1
        _f
        _this_hashtable_data
        _i
        _cells
        _plus
        _store
        _loop .1

        pushrbx
        mov     rbx, this_register      ; -- hashtable

        ; Return handle.
        _ new_handle                    ; -- handle

        pop     this_register
        next
endcode

; ### ~hashtable
code destroy_hashtable, '~hashtable'    ; handle --
        _ check_hashtable               ; -- hashtable
        _ destroy_hashtable_unchecked
        next
endcode

; ### ~hashtable-unchecked
code destroy_hashtable_unchecked, '~hashtable-unchecked' ; hashtable --
        _dup
        _hashtable_data
        _ ifree                         ; -- hashtable

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

; ### hashtable-data-address
code hashtable_data_address, 'hashtable-data-address' ; ht -- data-address
; Return value is untagged.
        _ check_hashtable
        push    this_register
        popd    this_register
        _this_hashtable_data
        pop     this_register
        next
endcode

%macro  _this_hashtable_hash_at 0       ; key -- start-index
; For now, keys must be strings.
        _ force_hashcode
        _untag_fixnum
        _this_hashtable_mask
        _and
%endmacro

%macro  _wrap 0
        _this_hashtable_mask
        _and
%endmacro

%macro  _compute_index 0                ; start-index -- computed-index
        _i
        _plus
        _wrap
%endmacro

; ### find-index-for-key
code find_index_for_key, 'find-index-for-key' ; key hashtable -- tagged-index t|f

        _ check_hashtable

find_index_for_key_unchecked:
        push    this_register
        popd    this_register           ; -- key
        _dup
        _this_hashtable_hash_at         ; -- key start-index

        _this_hashtable_capacity
        _zero
        _?do .1

        _twodup                         ; -- key start-index key start-index
        _compute_index                  ; -- key start-index key computed-index

        _this_hashtable_nth_key         ; -- key start-index key nth-key

        _ string_equal?
        _tagged_if .2                   ; -- key start-index
        ; found key
        _nip
        _compute_index
        _tag_fixnum
        _t
        _leave
        _then .2                        ; -- key start-index

        _dup
        _compute_index
        _this_hashtable_nth_key
        _f
        _equal
        _if .3
        ; found empty slot
        _nip
        _compute_index
        _tag_fixnum
        _f
        _leave
        _then .3

        _loop .1

        pop     this_register
        next
endcode

; ### hashtable-nth-value
code hashtable_nth_value, 'hashtable-nth-value' ; n hashtable -- value
        _ check_hashtable               ; -- n hashtable
        push    this_register
        popd    this_register           ; -- n
        _ check_fixnum
        _this_hashtable_nth_value
        pop     this_register
        next
endcode

; ### at*
code at_star, 'at*'                     ; key hashtable -- value t|f
        _tuck                           ; -- hashtable key hashtable
        _ find_index_for_key            ; -- hashtable index t|f
        _tagged_if .1
        _swap
        _ hashtable_nth_value
        _t
        _else .1
        _2drop
        _f
        _f
        _then .1
        next
endcode

; ### at
code at_, 'at'                           ; key hashtable -- value
        _ at_star
        _drop
        next
endcode

%macro _this_hashtable_set_nth_pair 0   ; -- value key index
        _tuck
        _this_hashtable_set_nth_key
        _this_hashtable_set_nth_value
%endmacro

; ### set-at
code set_at, 'set-at'                   ; value key handle --

        _ check_hashtable               ; -- value key hashtable

        _dup
        _hashtable_count
        _lit 3
        _ star
        _over
        _hashtable_capacity
        _twostar
        _ugt
        _if .1
        _dup
        _ hashtable_grow_unchecked
        _then .1

set_at_unchecked:
        push    this_register
        mov     this_register, rbx      ; -- value key hashtable
        _twodup                         ; -- value key hashtable key hashtable
        _ find_index_for_key_unchecked  ; -- value key hashtable tagged-index t|f
        _ not
        _tagged_if .2
        ; key was not found
        ; we're adding an entry
        _this_hashtable_count
        _oneplus
        _this_hashtable_set_count
        _then .2                        ; -- value key hashtable tagged-index
        _nip                            ; -- value key tagged-index
        _untag_fixnum
        _this_hashtable_set_nth_pair
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
        _ ifree

        _this_hashtable_capacity        ; -- ... n
        ; double existing capacity
        _twostar
        _dup
        _this_hashtable_set_capacity
        ; 16 bytes per entry
        shl     rbx, 4                  ; -- ... n*16
        _ iallocate
        _this_hashtable_set_data        ; -- keys values

        _this_hashtable_capacity
        _twostar
        _zero
        _?do .1
        _f
        _this_hashtable_data
        _i
        _cells
        _plus
        _store
        _loop .1

        _this_hashtable_count           ; -- keys values count

        _zero
        _this_hashtable_set_count

        _zero
        _?do .2                         ; -- keys values
        _twodup
        _i                              ; -- keys values keys values i
        _tag_fixnum
        _swap
        _ nth                           ; -- keys values keys nth-value
        _swap                           ; -- keys values nth-value keys
        _i
        _tag_fixnum
        _swap
        _ nth                           ; -- keys values nth-value nth-key

        _this
        _ set_at_unchecked

        _loop .2                        ; -- keys values
        _2drop
        pop     this_register
        next
endcode
