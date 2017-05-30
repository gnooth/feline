; Copyright (C) 2016-2017 Peter Graves <gnooth@gmail.com>

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

; 3 cells: object header, start, length

%macro  _range_start 0                  ; range -- start
        _slot1
%endmacro

%macro  _this_range_start 0             ; -- start
        _this_slot1
%endmacro

%macro  _this_range_set_start 0         ; start --
        _this_set_slot1
%endmacro

%macro  _range_length 0                 ; range -- length
        _slot2
%endmacro

%macro  _this_range_length 0            ; -- length
        _this_slot2
%endmacro

%macro  _this_range_set_length 0        ; length --
        _this_set_slot2
%endmacro

; ### range?
code range?, 'range?'                   ; handle -- ?
        _dup
        _ handle?
        _tagged_if .1
        _handle_to_object_unsafe        ; -- object
        _dup_if .2
        _object_raw_typecode
        _lit OBJECT_TYPE_RANGE
        _eq?
        _return
        _then .2
        _then .1
        mov     ebx, f_value
        next
endcode

; ### error-not-range
code error_not_range, 'error-not-range' ; x --
        _error "not a range"
        next
endcode

; ### check-range
code check_range, 'check-range' ; handle -- range
        _dup
        _ handle?
        _tagged_if .1
        _handle_to_object_unsafe        ; -- object/0
        _dup_if .2
        _dup
        _object_raw_typecode
        _lit OBJECT_TYPE_RANGE
        _equal
        _if .3
        _return
        _then .3
        _then .2
        _then .1

        _ error_not_range
        next
endcode

; ### <range>
code new_range, '<range>'               ; start length -- range
        _ verify_fixnum
        _swap
        _ verify_fixnum                 ; -- length start

        _lit 3
        _ raw_allocate_cells            ; -- length start object-address

        push    this_register
        mov     this_register, rbx
        poprbx                          ; -- length start

        _this_object_set_raw_typecode OBJECT_TYPE_RANGE

        _this_range_set_start           ; -- length

        _this_range_set_length          ; --

        pushrbx
        mov     rbx, this_register      ; -- symbol

        ; Return handle.
        _ new_handle                    ; -- handle

        pop     this_register
        next
endcode

; ### range-length
code range_length, 'range-length'       ; range -- length
        _ check_range
        _range_length
        next
endcode

; ### range-nth-unsafe
code range_nth_unsafe, 'range-nth-unsafe' ; n seq -- elt
        _ check_range
        push    this_register
        mov     this_register, rbx
        poprbx                          ; -- n
        _verify_fixnum
        _this_range_start
        _ generic_plus
        pop     this_register
        next
endcode

; ### range>string
code range_to_string, 'range>string'    ; range -- string
        _ check_range

        push    this_register
        mov     this_register, rbx
        poprbx                  ; --

        _quote "range{ "
        _ string_to_sbuf        ; -- sbuf

        _this_range_start
        _dup
        _ object_to_string
        _pick
        _ sbuf_append_string

        _quote " .. "
        _pick
        _ sbuf_append_string

        _this_range_length
        _ generic_plus
        _lit tagged_fixnum(1)
        _ generic_minus
        _ object_to_string
        _over
        _ sbuf_append_string

        _quote " }"
        _over
        _ sbuf_append_string
        _ sbuf_to_string

        pop     this_register
        next
endcode

; ### .range
code dot_range, '.range'                ; range --
        _ check_range

        push    this_register
        mov     this_register, rbx
        poprbx

        _write "range{ "

        _this_range_start
        _dup
        _ dot_object

        _write " .. "

        _this_range_length
        _ generic_plus
        _lit tagged_fixnum(1)
        _ generic_minus
        _ dot_object

        _write " }"

        pop     this_register
        next
endcode
