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
code verify_float, 'verify-float'       ; x -- x
        _dup
        _ deref
        test    rbx, rbx
        jz      .error
        movzx   eax, word [rbx]
        cmp     eax, TYPECODE_FLOAT
        jne     .error
        _drop
        _return
.error:
        _drop                           ; -- x
        jmp     error_not_float
        next
endcode

; ### check-float
code check_float, 'check-float'         ; x -- raw-float
        _dup
        _ deref
        test    rbx, rbx
        jz      .error
        movzx   eax, word [rbx]
        cmp     eax, TYPECODE_FLOAT
        jne     .error
        _nip
        _return
.error:
        _drop                           ; -- x
        jmp     error_not_float
        next
endcode

%macro _float_raw_value 0               ; raw-float -- raw-value
        _slot1
%endmacro

; ### float-raw-value
code float_raw_value, 'float_raw_value', SYMBOL_INTERNAL
; float -- raw-value
        _ check_float
        _float_raw_value
        next
endcode

; ### float-float-equal?
code float_float_equal?, 'float-float-equal?'   ; x y -- ?
        _ float_raw_value
        _swap
        _ float_raw_value
        _eq?
        next
endcode

; ### float-equal?
code float_equal?, 'float-equal?'       ; x float -- ?
        _ verify_float
        _swap

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

        _nip
        mov     ebx, f_value
        _return

.1:
        ; fixnum
        _ fixnum_to_float
        _ float_float_equal?
        _return

.2:
        ; int64
        _ int64_to_float
        _ float_float_equal?
        _return

.3:
        ; float
        _ float_float_equal?
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
        _ concat
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

%ifdef FELINE_FEATURE_BIGNUMS
; ### bignum>float
code bignum_to_float, 'bignum>float'
        _ check_bignum
        mov     arg0_register, rbx
        xcall   c_bignum_to_float
        mov     rbx, rax
        _ new_handle
        next
endcode
%endif

%ifdef FELINE_FEATURE_BIGNUMS
; ### float>integer
code float_to_integer, 'float>integer'
        _ check_float
        mov     arg0_register, rbx
        xcall   c_float_truncate
        mov     rbx, rax
        next
endcode
%endif

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
        xcall   c_float_float_plus
        pushrbx
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
        _ verify_float

        _over
        _ float?
        _tagged_if .1
        _ float_float_divide
        _return
        _then .1

        _over_fixnum?_if .2
        _swap
        _ fixnum_to_float
        _swap
        _ float_float_divide
        _return
        _then .2

%ifdef FELINE_FEATURE_BIGNUMS
        _over
        _ bignum?
        _tagged_if .3
        _swap
        _ bignum_to_float
        _swap
        _ float_float_divide
        _return
        _then .3
%endif

        _drop
        _ error_not_number

        next
endcode

; ### float/i
code float_divide_truncate, 'float/i'           ; x y -- z
        _ float_divide
%ifdef FELINE_FEATURE_BIGNUMS
        _ float_to_integer
%endif
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

; ### float-neg?
code float_neg?, 'float-neg?'                   ; x -- ?
        _ check_float
        _slot1
        test    rbx, rbx
        mov     ebx, f_value
        mov     eax, t_value
        cmovs   ebx, eax
        next
endcode

; ### float-sqrt
code float_sqrt, 'float-sqrt'                   ; x -- y
        _dup
        _ float_neg?
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
code generic_sqrt, 'sqrt'                       ; x -- y
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

%ifdef FELINE_FEATURE_BIGNUMS
        _dup
        _ bignum?
        _tagged_if .3
        _ bignum_to_float
        _ float_sqrt
        _return
        _then .3
%endif
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
