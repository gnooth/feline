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

; ### float?
code float?, 'float?'                   ; handle -- ?
        _ deref                         ; -- raw-object/0
        test    rbx, rbx
        jz      .1
        movzx   eax, word [rbx]
        cmp     eax, OBJECT_TYPE_FLOAT
        jne     .1
        mov     ebx, t_value
        _return
.1:
        mov     ebx, f_value
        next
endcode

; ### check-float
code check_float, 'check-float'       ; handle -- raw-float
        _ deref
        test    rbx, rbx
        jz      error_not_float
        movzx   eax, word [rbx]
        cmp     eax, OBJECT_TYPE_FLOAT
        jne     error_not_float
        next
endcode

; ### string>float
code string_to_float, 'string>float'    ; string -- float
        _ string_raw_data_address
        mov     arg0_register, rbx
        poprbx
        xcall   c_string_to_float
        pushrbx
        mov     rbx, rax                ; -- raw-float
        _ new_handle
        next
endcode

; ### float>string
code float_to_string, 'float>string'    ; float -- string
        _ check_float                   ; -- raw-float
        _lit 256
        _dup
        _ raw_allocate                  ; -- raw-float 256 buf

        ; save the address of the temporary buffer so it can be freed below
        _duptor

        ; cell c_float_to_string(char *buf, size_t size, struct double_float *p)
        mov     arg0_register, rbx
        poprbx
        mov     arg1_register, rbx
        poprbx
        mov     arg2_register, rbx
        poprbx

        xcall   c_float_to_string

        pushrbx
        mov     rbx, rax

        _ zcount
        _ copy_to_string

        ; free temporary buffer
        _rfrom
        _ raw_free

        next
endcode

; ### pi
code pi, 'pi'                   ; -- float
        pushrbx
        xcall   c_pi
        mov     rbx, rax
        _ new_handle
        next
endcode

; ### float-float+
code float_float_plus, 'float-float+'   ; float1 float2 -- sum
        _ check_float
        _swap
        _ check_float
        mov     arg0_register, rbx
        poprbx
        mov     arg1_register, rbx
        poprbx
        xcall   c_float_add_float
        pushrbx
        mov     rbx, rax
        _ new_handle
        next
endcode
