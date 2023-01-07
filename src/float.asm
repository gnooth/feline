; Copyright (C) 2017-2023 Peter Graves <gnooth@gmail.com>

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

; ### float?
code float?, 'float?'                   ; handle -- ?
        _ deref                         ; -- raw-object/0
        test    rbx, rbx
        jz      .1
        movzx   eax, word [rbx]
        cmp     eax, TYPECODE_FLOAT
        jne     .1
        mov     ebx, t_value
        _return
.1:
        mov     ebx, f_value
        next
endcode

; ### verify-float
code verify_float, 'verify-float'       ; x -> x
; Returns argument unchanged.
        cmp     bl, HANDLE_TAG
        jne     error_not_float
        mov     rax, rbx
        shr     rax, HANDLE_TAG_BITS
        mov     rax, [rax]
        cmp     word [rax], TYPECODE_FLOAT
        jne     error_not_float
        next
endcode

; ### check_float
code check_float, 'check_float'         ; x -> raw-float
        cmp     bl, HANDLE_TAG
        jne     error_not_float
        mov     rax, rbx
        shr     rbx, HANDLE_TAG_BITS
        mov     rbx, [rbx]
        cmp     word [rbx], TYPECODE_FLOAT
        jne     .error
        next
.error:
        mov     rbx, rax
        jmp     error_not_float
endcode

%macro _float_raw_value 0               ; raw-float -- raw-value
        _slot1
%endmacro

; ### float_raw_value
code float_raw_value, 'float_raw_value', SYMBOL_INTERNAL
; float -- raw-value
        _ check_float
        _float_raw_value
        next
endcode

; ### string>float
code string_to_float, 'string>float'    ; string -- float/f

        _ string_from                   ; -- raw-data-address raw-length

        mov     arg1_register, rbx      ; length
        mov     arg0_register, [rbp]    ; address
        _nip

        xcall   c_string_to_float

        cmp     rax, f_value
        mov     rbx, rax
        jnz     new_handle

        _rep_return
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

        _tagged_char '.'
        _over
        _ string_find_char
        _tagged_if_not .1
        _quote ".0"
        _ string_append
        _then .1

        next
endcode

; ### raw_int64_to_float
code raw_int64_to_float, 'raw_int64_to_float', SYMBOL_INTERNAL
        mov     arg0_register, rbx
        xcall   c_raw_int64_to_float
        mov     rbx, rax
        _ new_handle
        next
endcode

; ### raw_uint64_to_float
code raw_uint64_to_float, 'raw_uint64_to_float', SYMBOL_INTERNAL
        mov     arg0_register, rbx
        xcall   c_raw_uint64_to_float
        mov     rbx, rax
        _ new_handle
        next
endcode

; ### fixnum>float
code fixnum_to_float, 'fixnum>float'
        _check_fixnum
        _ raw_int64_to_float
        next
endcode

; ### int64>float
code int64_to_float, 'int64>float'
        _ check_int64
        _ raw_int64_to_float
        next
endcode

; ### pi
code pi, 'pi'                           ; -- float
        pushrbx
        xcall   c_pi
        mov     rbx, rax
        _ new_handle
        next
endcode

; ### float-float+
code float_float_plus, 'float-float+'   ; float1 float2 -> sum
        _ check_float
        _swap
        _ check_float
        mov     arg0_register, rbx
        poprbx
        mov     arg1_register, rbx
        xcall   c_float_float_plus
        mov     rbx, rax
        _ new_handle
        next
endcode

; ### fixnum-float+
code fixnum_float_plus, 'fixnum-float+' ; fixnum float -- sum
        _swap
        _ fixnum_to_float
        _ float_float_plus
        next
endcode

; ### int64-float+
code int64_float_plus, 'int64-float+'   ; int64 float -- sum
        _swap
        _ int64_to_float
        _ float_float_plus
        next
endcode

; ### float+
code float_plus, 'float+'               ; number float -- sum

        ; second arg must be a float
        _ verify_float

        ; dispatch on type of first arg
        _over
        _ object_raw_typecode
        mov     rax, rbx
        poprbx

        cmp     rax, TYPECODE_FIXNUM
        je      fixnum_float_plus

        cmp     rax, TYPECODE_INT64
        je      int64_float_plus

        cmp     rax, TYPECODE_FLOAT
        je      float_float_plus

        _drop
        _ error_not_number
        next
endcode

; ### float-float-
code float_float_minus, 'float-float-'   ; float1 float2 -- difference
        _ check_float
        _swap
        _ check_float
        mov     arg0_register, rbx
        poprbx
        mov     arg1_register, rbx
        poprbx
        xcall   c_float_float_minus
        pushrbx
        mov     rbx, rax
        _ new_handle
        next
endcode

; ### fixnum-float-
code fixnum_float_minus, 'fixnum-float-'        ; fixnum float -- difference
        _swap
        _ fixnum_to_float
        _swap
        _ float_float_minus
        next
endcode

; ### int64-float-
code int64_float_minus, 'int64-float-'  ; int64 float -- difference
        _swap
        _ int64_to_float
        _swap
        _ float_float_minus
        next
endcode

; ### float-
code float_minus, 'float-'              ; number float -- difference

        ; second arg must be a float
        _ verify_float

        ; dispatch on type of first arg
        _over
        _ object_raw_typecode
        mov     rax, rbx
        poprbx

        cmp     rax, TYPECODE_FIXNUM
        je      fixnum_float_minus

        cmp     rax, TYPECODE_INT64
        je      int64_float_minus

        cmp     rax, TYPECODE_FLOAT
        je      float_float_minus

        _drop
        _ error_not_number
        next
endcode

; ### float-float*
code float_float_multiply, 'float-float*'       ; x y -- z
        _ check_float
        _swap
        _ check_float
        mov     arg0_register, rbx
        poprbx
        mov     arg1_register, rbx
        poprbx
        xcall   c_float_float_multiply
        pushrbx
        mov     rbx, rax
        _ new_handle
        next
endcode

; ### fixnum-float*
code fixnum_float_multiply, 'fixnum-float*'     ; x y -- z
        _swap
        _ fixnum_to_float
        _ float_float_multiply
        next
endcode

; ### int64-float*
code int64_float_multiply, 'int64-float*'       ; x y -- z
        _swap
        _ int64_to_float
        _ float_float_multiply
        next
endcode

; ### float*
code float_multiply, 'float*'          ; x y -- z

        ; second arg must be a float
        _ verify_float

        ; dispatch on type of first arg
        _over
        _ object_raw_typecode
        mov     rax, rbx
        poprbx

        cmp     rax, TYPECODE_FIXNUM
        je      fixnum_float_multiply

        cmp     rax, TYPECODE_INT64
        je      int64_float_multiply

        cmp     rax, TYPECODE_FLOAT
        je      float_float_multiply

        _drop
        _ error_not_number

        next
endcode

; ### fixnum-float/f
code fixnum_float_divide, 'fixnum-float/f'      ; x y -- z
        _swap
        _ fixnum_to_float
        _swap
        _ float_float_divide
        next
endcode

; ### int64-float/f
code int64_float_divide, 'int64-float/f'        ; x y -- z
        _swap
        _ int64_to_float
        _swap
        _ float_float_divide
        next
endcode

; ### float-float/f
code float_float_divide, 'float-float/f'        ; x y -- z
        _ check_float
        _swap
        _ check_float
        mov     arg0_register, rbx
        poprbx
        mov     arg1_register, rbx
        poprbx
        xcall   c_float_float_divide
        pushrbx
        mov     rbx, rax
        _ new_handle
        next
endcode

; ### float/f
code float_divide, 'float/f'            ; x y -- z

        ; second arg must be a float
        _ verify_float

        ; dispatch on type of first arg
        _over
        _ object_raw_typecode
        mov     rax, rbx
        poprbx

        cmp     rax, TYPECODE_FIXNUM
        je      fixnum_float_divide

        cmp     rax, TYPECODE_INT64
        je      int64_float_divide

        cmp     rax, TYPECODE_FLOAT
        je      float_float_divide

        _drop
        _ error_not_number

        next
endcode

; ### float-floor
code float_floor, 'float-floor'         ; x -- y
        _dup                            ; -- handle handle
        _ check_float                   ; -- handle pointer

        mov     arg0_register, rbx
        xcall   c_float_floor

        ; If c_float_floor returns its argument (a pointer) here, return x,
        ; which is already a valid handle wrapping that pointer. If we wrap
        ; the pointer again here, we'll run into a double free in gc later.
        cmp     rbx, rax
        poprbx
        jne      .1
        _rep_return

.1:
        mov     rbx, rax
        and     al, FIXNUM_TAG_MASK
        cmp     al, FIXNUM_TAG
        jne     new_handle
        _rep_return
endcode

; ### float-truncate
code float_truncate, 'float-truncate'   ; x -- y
        _dup
        _ check_float

        mov     arg0_register, rbx
        xcall   c_float_truncate

        ; If c_float_truncate returns its argument (a pointer) here, return x,
        ; which is already a valid handle wrapping that pointer. If we wrap
        ; the pointer again here, we'll run into a double free in gc later.
        cmp     rbx, rax
        poprbx
        jne     .1
        _rep_return

.1:
        mov     rbx, rax
        and     al, FIXNUM_TAG_MASK
        cmp     al, FIXNUM_TAG
        jne     new_handle
        _rep_return
endcode

; ### float/i
code float_divide_truncate, 'float/i'   ; x y -- z
        _ float_divide
        _ float_truncate
        next
endcode

; ### float-negate
code float_negate, 'float-negate'               ; n -- -n
        _ check_float
        mov     arg0_register, rbx
        poprbx
        xcall   c_float_negate
        pushrbx
        mov     rbx, rax
        _ new_handle
        next
endcode

; ### float-negative?
code float_negative?, 'float-negative?' ; x -- ?
        _ float_raw_value
        test    rbx, rbx
        mov     ebx, f_value
        mov     eax, t_value
        cmovs   ebx, eax
        next
endcode

; ### float-abs
code float_abs, 'float-abs'             ; x -- y
        _dup
        _ float_negative?
        _tagged_if .1
        _ float_negate
        _then .1
        next
endcode

; ### float-sqrt
code float_sqrt, 'float-sqrt'           ; x -- y
        _dup
        _ float_negative?
        _tagged_if .1
        _error "ERROR: sqrt is not yet implemented for negative numbers."
        _return
        _then .1

        _handle_to_object_unsafe
        mov     arg0_register, rbx
        xcall   c_float_sqrt
        mov     rbx, rax
        _ new_handle
        next
endcode

; ### sqrt
code generic_sqrt, 'sqrt'               ; x -- y
        _dup_fixnum?_if .1
        _ fixnum_to_float
        _ float_sqrt
        _return
        _then .1

        _dup
        _ float?
        _tagged_if .2
        _ float_sqrt
        _return
        _then .2

        _dup
        _ int64?
        _tagged_if .3
        _ int64_to_float
        _ float_sqrt
        _return
        _then .3

        _ error_not_number
        next
endcode

; ### float-significand
code float_significand, 'float-significand'     ; float -- fixnum
        _ check_float
        _float_raw_value

        ; mask off fraction bits
        mov     rax, $0fffffffffffff
        and     rbx, rax

        ; add implicit leading bit
        add     rax, 1                  ; rax = $10000000000000
        or      rbx, rax

        _tag_fixnum
        next
endcode

; ### float_raw_exponent
code float_raw_exponent, 'float_raw_exponent', SYMBOL_INTERNAL
; float -- raw-exponent

        _ check_float
        _float_raw_value

        shr     rbx, 52
        and     rbx, 0b011111111111

        next
endcode

; ### float-sign
code float_sign, 'float-sign'           ; float -- +1/-1
        _debug_?enough 1
        _ check_float
        _float_raw_value

        mov     eax, 1
        shr     rbx, 63                 ; rbx = 0 if positive, 1 if negative
        neg     rbx                     ; rbx = 0 if positive, -1 if negative
        cmovns  rbx, rax

        _tag_fixnum
        next
endcode

; ### integer-decode-float
code integer_decode_float, 'integer-decode-float'       ; float -- significand exponent sign
        _duptor
        _ float_significand
        _rfetch
        _ float_raw_exponent
        sub     rbx, 1075
        _tag_fixnum
        _rfrom
        _ float_sign
        next
endcode

; ### float-distance
code float_distance, 'float-distance'   ; float1 float2 -- distance
        _ float_raw_value
        _swap
        _ float_raw_value
        sub     rbx, [rbp]
        _nip

        ; return absolute value
        test    rbx, rbx
        jns     .1
        neg     rbx

.1:
        _ normalize

        next
endcode
