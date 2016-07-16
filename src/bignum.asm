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

%macro  _bignum_value 0                 ; bignum -- untagged-value
        _slot1
%endmacro

%macro  _bignum_set_value 0             ; untagged-value bignum --
        _set_slot1
%endmacro

%macro  _this_bignum_set_value 0        ; untagged-value --
        _this_set_slot1
%endmacro

; ### bignum?
code bignum?, 'bignum?'                 ; handle -- t|f
        _dup
        _ handle?
        _if .1
        _handle_to_object_unsafe        ; -- object
        _dup_if .2
        _object_type                    ; -- object-type
        _lit OBJECT_TYPE_BIGNUM
        _eq?
        _return
        _then .2
        _then .1
        mov     ebx, f_value
        next
endcode

; ### error-not-bignum
code error_not_bignum, 'error-not-bignum' ; x --
        ; REVIEW
        _drop
        _true
        _abortq "not a bignum"
        next
endcode

; ### check-bignum
code check_bignum, 'check-bignum'       ; handle -- bignum
        _dup
        _ handle?
        _if .1
        _handle_to_object_unsafe        ; -- object|0
        _dup_if .2
        _dup
        _object_type                    ; -- object object-type
        _lit OBJECT_TYPE_BIGNUM
        _equal
        _if .3
        _return
        _then .3
        _then .2
        _then .1

        _ error_not_bignum
        next
endcode

; ### >bignum
code to_bignum, '>bignum'               ; untagged -- x
        push    this_register

        ; 2 cells (header, value)
        _lit 16
        _ allocate_object               ; -- x bignum
        popd    this_register           ; -- x

        ; Zero all bits of object header.
        xor     eax, eax
        mov     [this_register], rax

        _this_object_set_type OBJECT_TYPE_BIGNUM
        _this_bignum_set_value

        _this                           ; -- bignum

        ; Return handle of allocated string.
        _ new_handle                    ; -- handle

        pop     this_register
        next
endcode

; ### fixnum>bignum
code fixnum_to_bignum, 'fixnum>bignum'  ; x -- y
        _untag_fixnum
        _ to_bignum
        next
endcode

; ### bignum>string
code bignum_to_string, 'bignum>string'  ; handle-to-bignum -- string
        _ check_bignum                  ; -- bignum
        _bignum_value
        _ basefetch
        _tor
        _ decimal
        _ paren_dot
        _ copy_to_string
        _rfrom
        _ basestore
        next
endcode

; ### bignum=
code bignum_equal, 'bignum='            ; x y -- ?
        _ check_bignum
        _bignum_value
        _swap
        _ check_bignum
        _bignum_value
        _equal
        _tag_boolean
        next
endcode

; ### bignum+
code bignum_plus, 'bignum+'             ; x y -- z
        _ check_bignum
        _bignum_value
        _swap
        _ check_bignum
        _bignum_value
        _plus                           ; -- untagged-value
        _ to_bignum
        next
endcode
