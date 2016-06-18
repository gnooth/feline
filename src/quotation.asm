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

%macro  _quotation_array 0              ; quotation -- array
        _slot1
%endmacro

%macro  _this_quotation_array 0         ; -- array
        _this_slot1
%endmacro

%macro  _this_quotation_set_array 0     ; array --
        _this_set_slot1
%endmacro

%macro  _quotation_code 0               ; quotation -- code
        _slot2
%endmacro

%macro  _this_quotation_code 0          ; -- code
        _this_slot2
%endmacro

%macro  _this_quotation_set_code 0      ; code --
        _this_set_slot2
%endmacro

; ### quotation?
code quotation?, 'quotation?'           ; handle -- t|f
        _dup
        _ handle?
        _if .1
        _handle_to_object_unsafe        ; -- object
        _dup_if .2
        _object_type                    ; -- object-type
        _lit OBJECT_TYPE_QUOTATION
        _eq?
        _return
        _then .2
        _then .1
        mov     ebx, f_value
        next
endcode

; ### error-not-quotation
code error_not_quotation, 'error-not-quotation' ; x --
        ; REVIEW
        _drop
        _true
        _abortq "not a quotation"
        next
endcode

; ### check-quotation
code check_quotation, 'check-quotation' ; handle -- quotation
        _dup
        _ handle?
        _if .1
        _handle_to_object_unsafe        ; -- object|0
        _dup_if .2
        _dup
        _object_type                    ; -- object object-type
        _lit OBJECT_TYPE_QUOTATION
        _equal
        _if .3
        _return
        _then .3
        _then .2
        _then .1

        _ error_not_quotation
        next
endcode

; ### array>quotation
code array_to_quotation, 'array>quotation' ; array -- quotation
; 3 cells: object header, array, code
        _lit 3                          ; -- array 3
        _cells                          ; -- array 24
        _dup                            ; -- array 24 24
        _ allocate_object               ; -- array 24 object-address
        push    this_register
        mov     this_register, rbx      ; -- array 24 object-address
        _swap
        _ erase                         ; -- array

        _this_object_set_type OBJECT_TYPE_QUOTATION

        _this_quotation_set_array

        _zero
        _this_quotation_set_code

        pushrbx
        mov     rbx, this_register      ; -- quotation

        ; Return handle.
        _ new_handle                    ; -- handle

        pop     this_register
        next
endcode

; ### quotation-array
code quotation_array, 'quotation-array' ; quotation -- array
        _ check_quotation
        _quotation_array
        next
endcode
