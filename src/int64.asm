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

; 2 cells: object header, raw value

%macro  _int64_raw_value 0              ; int64 -- raw-value
        _slot1
%endmacro

%macro  _int64_set_raw_value 0          ; raw-value int64 --
        _set_slot1
%endmacro

%define __this_int64_raw_value this_slot1

%macro  _this_int64_raw_value 0         ; -- raw-value
        _this_slot1
%endmacro

%macro  _this_int64_set_raw_value 0     ; raw-value --
        _this_set_slot1
%endmacro

; ### int64?
code int64?, 'int64?'                   ; handle -- ?
        _ deref                         ; -- raw-object/0
        test    rbx, rbx
        jz      .1
        movzx   eax, word [rbx]
        cmp     eax, TYPECODE_INT64
        jne     .1
        mov     ebx, t_value
        _return
.1:
        mov     ebx, f_value
        next
endcode

; ### check_int64
code check_int64, 'check_int64'         ; handle -- raw-int64
        _dup
        _ deref
        test    rbx, rbx
        jz      .error
        movzx   eax, word [rbx]
        cmp     eax, TYPECODE_INT64
        jne     .error
        _nip
        _int64_raw_value
        next
.error:
        _drop
        _ error_not_int64
        next
endcode

; ### <int64>
code new_int64, '<int64>'               ; raw-int64 -- int64
; 2 cells: object header, raw value
        _lit 2
        _cells
        _ raw_allocate

        push    this_register
        mov     this_register, rbx
        poprbx

        xor     eax, eax
        mov     [this_register], rax

        _this_object_set_raw_typecode TYPECODE_INT64

        _this_int64_set_raw_value

        pushrbx
        mov     rbx, this_register      ; -- int64
        pop     this_register

        ; return handle
        _ new_handle                    ; -- handle

        next
endcode

; ### fixnum>int64
code fixnum_to_int64, 'fixnum>int64'  ; fixnum -- int64
        _check_fixnum
        _ new_int64
        next
endcode

; ### raw_int64_to_hex
code raw_int64_to_hex, 'raw_int64_to_hex', SYMBOL_INTERNAL      ; raw-int64 -- string

        _lit 32
        _ new_sbuf_untagged             ; handle

        push    r12
        push    this_register

        mov     this_register, [rbx]    ; raw address of string buffer
        poprbx                          ; -- int64

        mov     r12, rbx                ; raw int64 in r12
        poprbx                          ; --

        align   DEFAULT_CODE_ALIGNMENT
.1:
        mov     edx, r12d
        and     edx, 0xf

        mov     rcx, hexchars
        mov     dl, [rcx + rdx]

        pushrbx
        movzx   ebx, dl
        _ this_sbuf_push_raw_unsafe

        shr     r12, 4

        test    r12, r12
        jnz     .1

        _ this_sbuf_reverse
        _ this_sbuf_to_string

        pop     this_register
        pop     r12

        next
endcode

; ### int64>string
code int64_to_string, 'int64>string'    ; int64 -- string
        _ check_int64
        _ raw_int64_to_decimal
        next
endcode

; ### int64>hex
code int64_to_hex, 'int64>hex'          ; int64 -- string
        _ check_int64
        _ raw_int64_to_hex
        next
endcode

; ### max-int64
code max_int64, 'max-int64'             ; -- int64
        pushrbx
        xor     ebx, ebx
        sub     rbx, 1
        _ new_int64
        next
endcode
