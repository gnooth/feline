; Copyright (C) 2017 Peter Graves <gnooth@gmail.com>

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

; ### sin
code math_sin, 'sin'                    ; x -- y
        _dup
        _ object_raw_typecode
        mov     rax, rbx
        poprbx

        cmp     rax, TYPECODE_FIXNUM
        je      .1
        cmp     rax, TYPECODE_INT64
        je      .2
        cmp     rax, TYPECODE_FLOAT
        je      .3

        _ error_not_number
        _return

.1:
        ; fixnum
        _ fixnum_to_float
        jmp     .3

.2:
        ; int64
        _ int64_to_float
        ; fall through...
.3:
        ; float
        _handle_to_object_unsafe
        mov     arg0_register, rbx
        xcall c_float_sin
        mov     rbx, rax
        _ new_handle
        next
endcode
