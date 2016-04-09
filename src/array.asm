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

; ### array?
code array?, 'array?'                   ; handle -- flag
        _dup
        _ handle?
        _if .1
        _handle_to_object_unsafe        ; -- object
        _dup_if .2
        _object_type                    ; -- object-type
        _lit OBJECT_TYPE_ARRAY
        _equal
        _then .2
        _else .1
        xor     ebx, ebx
        _then .1
        next
endcode

; ### error-not-array
code error_not_array, 'error-not-array' ; x --
        ; REVIEW
        _drop
        _true
        _abortq "not a array"
        next
endcode

; ### check-array
code check_array, 'check-array'         ; handle -- array
        _dup
        _ handle?
        _if .1
        _handle_to_object_unsafe        ; -- object|0
        _dup_if .2
        _dup
        _object_type                    ; -- object object-type
        _lit OBJECT_TYPE_ARRAY
        _equal
        _if .3
        _return
        _then .3
        _then .2
        _then .1

        _ error_not_array
        next
endcode

; ### array-length
code array_length, 'array-length'       ; array -- length
        _ check_array
        _array_length
        next
endcode

; ### <array>
code new_array, '<array>'               ; length element -- handle
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

        _this_object_set_type OBJECT_TYPE_ARRAY
        _this_object_set_flags OBJECT_ALLOCATED_BIT

        _over                           ; -- length element length
        _this_array_set_length          ; -- length element

;         _swap
;         _zero
;         _?do .1                         ; -- element
;         _dup
;         _i
;         _this_array_set_nth_unsafe
;         _loop .1

        popd    rax                     ; element in rax
        popd    rcx                     ; length in rcx
        mov     rdi, this_register
        add     rdi, 16
        rep     stosq

        pushrbx
        mov     rbx, this_register      ; -- array

        ; Return handle of allocated array.
        _ new_handle                    ; -- handle

        pop     this_register
        next
endcode

; ### ~array
code destroy_array, '~array'            ; handle --
        _ check_array                   ; -- array|0
        _ destroy_array_unchecked
        next
endcode

; ### ~array-unchecked
code destroy_array_unchecked, '~array-unchecked' ; array --
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

; ### array-nth
code array_nth, 'array-nth'             ; index handle -- element
        _ check_array

        _twodup
        _array_length
        _ult
        _if .1
        _array_nth_unsafe
        _return
        _then .1

        _2drop
        _true
        _abortq "array-nth index out of range"
        next
endcode

; ### array-set-nth
code array_set_nth, 'array-set-nth'     ; element index handle --
        _ check_array

        _twodup
        _array_length
        _ult
        _if .1
        _array_data
        _swap
        _cells
        _plus
        _store
        _else .1
        _true
        _abortq "array-set-nth index out of range"
        _then .1
        next
endcode

; ### 2array
code two_array, '2array'                ; x y -- handle
        _lit 2
        _lit 0
        _ new_array                     ; -- x y handle
        _duptor
        _lit 1
        _swap
        _ array_set_nth
        _lit 0
        _rfetch
        _ array_set_nth
        _rfrom
        next
endcode

; ### array-first
code array_first, 'array-first'         ; handle -- element
        _zero
        _swap
        _ array_nth
        next
endcode

; ### array-second
code array_second, 'array-second'       ; handle -- element
        _lit 1
        _swap
        _ array_nth
        next
endcode

; ### .array
code dot_array, '.array'                ; array --
        _ check_array

        push    this_register
        mov     this_register, rbx

        _dotq "{ "
        _array_length
        _zero
        _?do .1
        _i
        _this_array_nth_unsafe
        _ dot_object
        _loop .1
        _dotq "}"

        pop     this_register
        next
endcode
