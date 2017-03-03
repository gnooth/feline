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

; 4 cells: object header, seq, start-index, length

%macro  _slice_seq 0                    ; slice -- seq
        _slot1
%endmacro

%macro  _this_slice_seq 0               ; -- seq
        _this_slot1
%endmacro

%macro  _this_slice_set_seq 0           ; seq --
        _this_set_slot1
%endmacro

%macro  _slice_start_index 0            ; slice -- start-index
        _slot2
%endmacro

%macro  _slice_set_start_index 0        ; start-index slice --
        _set_slot2
%endmacro

%macro  _this_slice_set_start_index 0   ; start-index --
        _this_set_slot2
%endmacro

%macro  _slice_length 0                 ; slice -- length
        _slot3
%endmacro

%macro  _slice_set_length 0             ; length slice --
        _set_slot3
%endmacro

%macro  _this_slice_set_length 0        ; length --
        _this_set_slot3
%endmacro

; ### slice?
code slice?, 'slice?'                   ; handle -- ?
        _dup
        _ handle?
        _tagged_if .1
        _handle_to_object_unsafe        ; -- object
        _dup_if .2
        _object_type                    ; -- object-type
        _lit OBJECT_TYPE_SLICE
        _eq?
        _return
        _then .2
        _then .1
        mov     ebx, f_value
        next
endcode

; ### error-not-slice
code error_not_slice, 'error-not-slice' ; x --
        _error "not a slice"
        next
endcode

; ### verify-slice
code verify_slice, 'verify-slice'       ; handle -- handle
        _dup
        _ slice?
        _tagged_if .1
        _return
        _then .1

        _ error_not_slice
        next
endcode

; ### check-slice
code check_slice, 'check-slice' ; handle -- slice
        _dup
        _ handle?
        _tagged_if .1
        _handle_to_object_unsafe        ; -- object|0
        _dup_if .2
        _dup
        _object_type                    ; -- object object-type
        _lit OBJECT_TYPE_SLICE
        _equal
        _if .3
        _return
        _then .3
        _then .2
        _then .1

        _ error_not_slice
        next
endcode

; ### <slice>
code new_slice, '<slice>'               ; from to seq -- slice
        _lit 4
        _ allocate_cells                ; -- from to seq object-address

        push    this_register
        mov     this_register, rbx
        poprbx                          ; -- from to seq

        _this_object_set_type OBJECT_TYPE_SLICE

        _this_slice_set_seq             ; -- from to

        _over
        _this_slice_set_start_index     ; -- from to

        _swap
        _ feline_minus
        _this_slice_set_length

        pushrbx
        mov     rbx, this_register      ; -- slice

        ; return handle
        _ new_handle                    ; -- handle

        pop     this_register
        next
endcode

; ### slice-length
code slice_length, 'slice-length'       ; slice -- length
        _ check_slice
        _slice_length
        next
endcode

; ### slice-nth-unsafe
code slice_nth_unsafe, 'slice-nth-unsafe' ; n slice -- element
        _handle_to_object_unsafe        ; -- n slice slice
        _dup                            ; -- n slice slice
        _slice_seq                      ; -- n slice
        _tor
        _slice_start_index              ; -- n start-index
        _ plus
        _rfrom
        _ nth
        next
endcode

; ### slice-nth
code slice_nth, 'slice-nth'             ; n slice -- element
        _ check_slice                   ; -- n slice
        _twodup
        _slice_length
        _ fixnum_lt
        _tagged_if .1
        _dup                            ; -- n slice slice
        _slice_seq                      ; -- n slice
        _tor
        _slice_start_index              ; -- n start-index
        _ plus
        _rfrom
        _ nth
        _else .1
        _error "slice-nth index out of range"
        _then .1
        next
endcode

; ### slice>string
code slice_to_string, 'slice>string'    ; slice -- string

        _ verify_slice
        _quote "{ "
        _ string_to_sbuf
        _swap                           ; -- sbuf slice
        _dup
        _ slice_length
        _untag_fixnum
        _register_do_times .1
        _tagged_loop_index
        _over
        _ slice_nth_unsafe
        _ object_to_string
        _pick
        _ sbuf_append_string
        _lit tagged_char(32)
        _pick
        _ sbuf_push
        _loop .1
        _drop
        _lit tagged_char('}')
        _over
        _ sbuf_push
        _ sbuf_to_string

        next
endcode

; ### .slice
code dot_slice, '.slice'                ; slice --
        _write "{ "
        _dup
        _ slice_length
        _untag_fixnum
        _zero
        _?do .1
        _i
        _tag_fixnum
        _over
        _ slice_nth_unsafe
        _ dot_object
        _ space
        _loop .1
        _drop
        _write_char '}'
        next
endcode
