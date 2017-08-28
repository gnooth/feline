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

%macro  _uint64_raw_value 0             ; uint64 -- raw-value
        _slot1
%endmacro

%macro  _uint64_set_raw_value 0         ; raw-value uint64 --
        _set_slot1
%endmacro

%define __this_uint64_raw_value this_slot1

%macro  _this_uint64_raw_value 0        ; -- raw-value
        _this_slot1
%endmacro

%macro  _this_uint64_set_raw_value 0    ; raw-value --
        _this_set_slot1
%endmacro

; ### uint64?
code uint64?, 'uint64?'                 ; handle -- ?
        _ deref                         ; -- raw-object/0
        test    rbx, rbx
        jz      .1
        movzx   eax, word [rbx]
        cmp     eax, TYPECODE_UINT64
        jne     .1
        mov     ebx, t_value
        _return
.1:
        mov     ebx, f_value
        next
endcode

; ### check_uint64
code check_uint64, 'check_uint64'       ; handle -- raw-uint64
        _dup
        _ deref
        test    rbx, rbx
        jz      .error
        movzx   eax, word [rbx]
        cmp     eax, TYPECODE_UINT64
        jne     .error
        _nip
        _uint64_raw_value
        next
.error:
        _drop
        _ error_not_uint64
        next
endcode

; ### uint64_raw_value
code uint64_raw_value, 'uint64_raw_value', SYMBOL_INTERNAL      ; handle -- raw-uint64
        _ deref
        _uint64_raw_value
        next
endcode

%if 0
; ### new_uint64
code new_uint64, 'new_uint64', SYMBOL_INTERNAL  ; raw-uint64 -- uint64
; 2 cells: object header, raw value
        _lit 2
        _cells
        _ raw_allocate

        push    this_register
        mov     this_register, rbx
        poprbx

        xor     eax, eax
        mov     [this_register], rax

        _this_object_set_raw_typecode TYPECODE_UINT64

        _this_uint64_set_raw_value

        pushrbx
        mov     rbx, this_register      ; -- uint64
        pop     this_register

        ; return handle
        _ new_handle                    ; -- handle

        next
endcode
%endif

; ### new_uint64
code new_uint64, 'new_uint64', SYMBOL_INTERNAL  ; raw-uint64 -- uint64

        ; 2 cells: object header, raw value
        mov     arg0_register, 2 * BYTES_PER_CELL

        call    __raw_allocate

        mov     qword [rax], TYPECODE_UINT64
        mov     [rax + BYTES_PER_CELL], rbx

        ; return handle
        mov     rbx, rax
        _ new_handle

        next
endcode

; ### normalize_unsigned
code normalize_unsigned, 'normalize_unsigned', SYMBOL_INTERNAL  ; raw-int64 -- fixnum-or-uint64
        mov     rcx, MOST_POSITIVE_FIXNUM
        cmp     rbx, rcx
        ja      new_uint64
        _tag_fixnum
        next
endcode

; ### fixnum>uint64
code fixnum_to_uint64, 'fixnum>uint64'  ; fixnum -- uint64
        _check_fixnum
        _ new_uint64
        next
endcode

; ### int64>uint64
code int64_to_uint64, 'int64>uint64'    ; int64 -- uint64
        _ check_int64
        _ new_uint64
        next
endcode

; ### uint64-negate
code uint64_negate, 'uint64-negate'     ; n -- -n
        _ check_uint64
        mov     rax, MOST_POSITIVE_INT64
        add     rax, 1
        cmp     rbx, rax
        ja      .1
        neg     rbx
        _ normalize
        _return
.1:
        _ raw_uint64_to_float
        _ float_negate
        next
endcode

; ### raw_uint64_to_decimal
code raw_uint64_to_decimal, 'raw_uint64_to_decimal', SYMBOL_INTERNAL    ; raw-uint64 -- string

        _lit 32
        _ new_sbuf_untagged             ; handle

        push    this_register

        mov     this_register, [rbx]    ; raw address of string buffer
        poprbx                          ; -- uint64

        mov     rax, rbx                ; raw uint64 in rax

        align   DEFAULT_CODE_ALIGNMENT
.1:
        xor     edx, edx                ; zero-extend rax into rdx:rax

        mov     ecx, 10
        div     rcx                     ; quotient in rax, remainder in rdx

        push    rax

        add     edx, '0'
        pushrbx
        mov     ebx, edx

        _ this_sbuf_push_raw_unsafe

        pop     rax

        test    rax, rax
        jnz     .1

        _drop

.2:
        _ this_sbuf_reverse
        _ this_sbuf_to_string

        pop     this_register

        next
endcode

section .data
        align   DEFAULT_DATA_ALIGNMENT
hexchars:
        db      '0123456789abcdef'


; ### raw_uint64_to_hex
code raw_uint64_to_hex, 'raw_uint64_to_hex', SYMBOL_INTERNAL    ; raw-uint64 -- string

        _lit 32
        _ new_sbuf_untagged             ; handle

        push    r12
        push    this_register

        mov     this_register, [rbx]    ; raw address of string buffer
        poprbx                          ; -- uint64

        mov     r12, rbx                ; raw uint64 in r12
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

; ### uint64>string
code uint64_to_string, 'uint64>string'  ; uint64 -- string
        _ check_uint64
        _ raw_uint64_to_decimal
        next
endcode

; ### uint64>hex
code uint64_to_hex, 'uint64>hex'        ; uint64 -- string
        _ check_uint64
        _ raw_uint64_to_hex
        next
endcode

; ### max-uint64
code max_uint64, 'max-uint64'           ; -- uint64
        pushrbx
        xor     ebx, ebx
        sub     rbx, 1
        _ new_uint64
        next
endcode
