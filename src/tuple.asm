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

; ### tuple?
code tuple?, 'tuple?'                   ; handle -- ?
        _dup
        _ handle?
        _tagged_if .1
        _handle_to_object_unsafe        ; -- object
        _dup_if .2
        _object_type                    ; -- object-type
        _lit OBJECT_TYPE_TUPLE
        _eq?
        _return
        _then .2
        _then .1
        mov     ebx, f_value
        next
endcode

; ### error-not-tuple
code error_not_tuple, 'error-not-tuple' ; x --
        ; REVIEW
        _error "not a tuple"
        next
endcode

; ### check-tuple
code check_tuple, 'check-tuple'         ; handle -- tuple
        _dup
        _ handle?
        _tagged_if .1
        _handle_to_object_unsafe        ; -- object/0
        _dup_if .2
        _dup
        _object_type                    ; -- object object-type
        _lit OBJECT_TYPE_TUPLE
        _equal
        _if .3
        _return
        _then .3
        _then .2
        _then .1

        _ error_not_tuple
        next
endcode

; ### tuple-layout
code tuple_layout, 'tuple-layout'       ; class-symbol -- layout
        _quote "layout"
        _swap
        _ symbol_prop
        next
endcode

%macro _tuple_layout_of 0               ; tuple -- layout
        _slot 1
%endmacro

; ### layout-of
code layout_of, 'layout-of'             ; tuple -- layout
        _ check_tuple
        _tuple_layout_of
        next
endcode

; ### tuple-size
code tuple_size, 'tuple-size'           ; tuple -- size
; Return number of defined slots.
        _ check_tuple
tuple_size_unchecked:
        _tuple_layout_of
        _ array_second
        next
endcode

; ### <tuple>
code new_tuple, '<tuple>'               ; class-symbol -- handle

        _ tuple_layout                  ; -- layout

        _dup
        _ second
        _ check_fixnum
        _dup
        ; Slot 0 is object header, slot 1 is class.
        add     rbx, 2
        _ allocate_cells                ; -- layout untagged-size tuple

        push    this_register
        popd    this_register           ; -- layout untagged-size

        _this_object_set_type OBJECT_TYPE_TUPLE

        ; Initialize slots to f.
        mov     rax, f_value
        popd    rcx                     ; length in rcx
        mov     rdi, this_register
        add     rdi, 16
        rep     stosq

        ; -- layout
        _this_set_slot1                 ; --

        pushrbx
        mov     rbx, this_register      ; -- tuple

        ; Return handle of allocated array.
        _ new_handle                    ; -- handle

        pop     this_register
        next
endcode

; ### new
code new, 'new'                         ; class-symbol -- tuple
        _ new_tuple
        next
endcode

; ### .tuple
code dot_tuple, '.tuple'                ; tuple --
        _ check_tuple

        push    this_register
        popd    this_register

        _write "T{ "

        _this_slot 1                    ; -- layout
        _dup
        _ first
        _ dot_object

        _ second
        _untag_fixnum
        _zero
        _?do .1
        _i
        add     rbx, 2
        _this_nth_slot
        _ dot_object
        _loop .1
        _write "}"

        pop     this_register
        next
endcode
