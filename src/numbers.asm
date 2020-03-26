; Copyright (C) 2016-2020 Peter Graves <gnooth@gmail.com>

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

; ### raw_int64_equal?
code raw_int64_equal?, 'raw_int64_equal?', SYMBOL_INTERNAL      ; number raw-int64 -- ?

        _swap                           ; -- raw-int64 number

        _dup
        _ object_raw_typecode
        mov     rax, rbx
        poprbx

        cmp     rax, TYPECODE_FIXNUM
        je      .1
        cmp     rax, TYPECODE_INT64
        je      .2
        cmp     rax, TYPECODE_UINT64
        je      .3
        cmp     rax, TYPECODE_FLOAT
        je      .4

        _nip
        mov     ebx, f_value
        _return

.1:
        ; fixnum
        _untag_fixnum
        _eq?
        _return

.2:
        ; int64
        _ int64_raw_value
        _eq?
        _return

.3:
        ; uint64
        _ uint64_raw_value
        _eq?
        _return

.4:
        ; float
        _swap
        _ raw_int64_to_float
        _ float_equal?
        next
endcode

; ### raw_uint64_equal?
code raw_uint64_equal?, 'raw_uint64_equal?', SYMBOL_INTERNAL    ; number raw-uint64 -- ?

        _swap                           ; -- raw-uint64 number

        _dup
        _ object_raw_typecode
        mov     rax, rbx
        poprbx

        cmp     rax, TYPECODE_FIXNUM
        je      .1
        cmp     rax, TYPECODE_INT64
        je      .2
        cmp     rax, TYPECODE_UINT64
        je      .3
        cmp     rax, TYPECODE_FLOAT
        je      .4

        _nip
        mov     ebx, f_value
        _return

.1:
        ; fixnum
        _untag_fixnum
        test    rbx, rbx
        js      .5
        _eq?
        _return

.2:
        ; int64
        _ int64_raw_value
        test    rbx, rbx
        js      .5
        _eq?
        _return

.3:
        ; uint64
        _ uint64_raw_value
        _eq?
        _return

.4:
        ; float
        _swap
        _ raw_uint64_to_float
        _ float_equal?
        _return

.5:
        _nip
        mov     rbx, f_value
        next
endcode

; ### fixnum-equal?
code fixnum_equal?, 'fixnum-equal?'     ; x y -- ?
        _ check_fixnum
        _ raw_int64_equal?
        next
endcode

; ### int64-equal?
code int64_equal?, 'int64-equal?'       ; x y -- ?
        _ check_int64
        _ raw_int64_equal?
        next
endcode

; ### uint64-equal?
code uint64_equal?, 'uint64-equal?'     ; x y -- ?
        _ check_uint64
        _ raw_uint64_equal?
        next
endcode

; ### float-float-equal?
code float_float_equal?, 'float-float-equal?'   ; x y -- ?

        _debug_?enough 2

        _ float_raw_value
        _swap
        _ float_raw_value
        _eq?
        next
endcode

; ### float-equal?
code float_equal?, 'float-equal?'       ; x float -- ?

        _debug_?enough 2

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

; ### fixnum-fixnum<
code fixnum_fixnum_lt, 'fixnum-fixnum<' ; fixnum1 fixnum2 -- ?
        _check_fixnum
        _swap
        _check_fixnum
        _swap

        mov     eax, t_value
        cmp     [rbp], rbx
        mov     ebx, f_value
        cmovl   ebx, eax
        lea     rbp, [rbp + BYTES_PER_CELL]
        next
endcode

; ### int64-fixnum<
code int64_fixnum_lt, 'int64-fixnum<'   ; int64 fixnum -- ?
        _check_fixnum
        _swap
        _ check_int64
        _swap
        _ raw_int64_int64_lt
        next
endcode

; ### float-fixnum<
code float_fixnum_lt, 'float-fixnum<'   ; float fixnum -- ?
        _ fixnum_to_float
        _ float_float_lt
        next
endcode

; ### fixnum<
code fixnum_lt, 'fixnum<'               ; number fixnum -> ?

        ; last arg must be a fixnum
        _verify_fixnum

        ; dispatch on type of first arg
        test    byte [rbp], FIXNUM_TAG
        jz      .1
        mov     eax, TRUE
        cmp     [rbp], rbx
        mov     ebx, NIL
        cmovl   ebx, eax
        lea     rbp, [rbp + BYTES_PER_CELL]
        next

.1:

        _over
        _ int64?
        _tagged_if .2
        _ int64_fixnum_lt
        _return
        _then .2

        _over
        _ float?
        _tagged_if .3
        _ float_fixnum_lt
        _return
        _then .3

        _drop
        _ error_not_number
        next
endcode

; ### raw_int64_int64_lt
code raw_int64_int64_lt, 'raw_int64_int64_lt', SYMBOL_INTERNAL
; x y -- ?
        mov     eax, t_value
        cmp     [rbp], rbx
        mov     ebx, f_value
        cmovl   ebx, eax
        lea     rbp, [rbp + BYTES_PER_CELL]
        next
endcode

; ### fixnum-int64<
code fixnum_int64_lt, 'fixnum-int64<'   ; x y -- ?
        _ check_int64
        _swap
        _check_fixnum
        _swap
        _ raw_int64_int64_lt
        next
endcode

; ### int64-int64<
code int64_int64_lt, 'int64-int64<'     ; x y -- ?
        _ check_int64
        _swap
        _ check_int64
        _swap
        _ raw_int64_int64_lt
        next
endcode

; ### int64<
code int64_lt, 'int64<'                 ; x y -- ?

        ; second arg must be int64
        _ verify_int64

        ; dispatch on type of first arg
        _over
        _ object_raw_typecode
        mov     rax, rbx
        poprbx                          ; -- x y

        cmp     rax, TYPECODE_FIXNUM
        je      fixnum_int64_lt

        cmp     rax, TYPECODE_INT64
        je      int64_int64_lt

        cmp     rax, TYPECODE_FLOAT
        jne     .1
        _ int64_to_float
        jmp     float_float_lt

.1:
        _drop
        _ error_not_number

        next
endcode

; ### float-float<
code float_float_lt, 'float-float<'     ; float1 float2 -- ?
        _ check_float
        _swap
        _ check_float
        _swap

        mov     arg1_register, rbx
        poprbx
        mov     arg0_register, rbx
        poprbx

        xcall c_float_float_lt

        pushrbx
        mov     rbx, rax

        next
endcode

; ### fixnum-float<
code fixnum_float_lt, 'fixnum-float<'   ; fixnum float -- ?
        _swap
        _ fixnum_to_float
        _swap
        _ float_float_lt
        next
endcode

; ### int64-float<
code int64_float_lt, 'int64-float<'     ; int64 float -- ?
        _swap
        _ int64_to_float
        _swap
        _ float_float_lt
        next
endcode

; ### float<
code float_lt, 'float<'                 ; x y -- ?

        ; second arg must be float
        _ verify_float

        ; dispatch on type of first arg
        _over
        _ object_raw_typecode
        mov     rax, rbx
        poprbx                          ; -- x y

        cmp     rax, TYPECODE_FIXNUM
        je      fixnum_float_lt

        cmp     rax, TYPECODE_INT64
        je      int64_float_lt

        cmp     rax, TYPECODE_FLOAT
        je      float_float_lt

        _drop
        _ error_not_number

        next
endcode

; ### fixnum-fixnum<=
code fixnum_fixnum_le, 'fixnum-fixnum<='        ; fixnum1 fixnum2 -- ?
        _check_fixnum
        _swap
        _check_fixnum
        _swap

        mov     eax, t_value
        cmp     [rbp], rbx
        mov     ebx, f_value
        cmovle  ebx, eax
        lea     rbp, [rbp + BYTES_PER_CELL]
        next
endcode

; ### int64-int64<=
code int64_int64_le, 'int64-int64<='    ; x y -- ?
        _ check_int64
        _swap
        _ check_int64
        _swap

        mov     eax, t_value
        cmp     [rbp], rbx
        mov     ebx, f_value
        cmovle  ebx, eax
        lea     rbp, [rbp + BYTES_PER_CELL]
        next
endcode

; ### int64-fixnum<=
code int64_fixnum_le, 'int64-fixnum<='          ; int64 fixnum -- ?
        _ fixnum_to_int64
        _ int64_int64_le
        next
endcode

; ### float-fixnum<=
code float_fixnum_le, 'float-fixnum<='          ; float fixnum -- ?
        _ fixnum_to_float
        _ float_float_le
        next
endcode

; ### fixnum-int64<=
code fixnum_int64_le, 'fixnum-int64<='          ; fixnum int64 -- ?
        _ check_int64
        _swap
        _ check_fixnum
        _swap
        mov     eax, t_value
        cmp     [rbp], rbx
        mov     ebx, f_value
        cmovle  ebx, eax
        lea     rbp, [rbp + BYTES_PER_CELL]
        next
endcode

; ### float-float<=
code float_float_le, 'float-float<='            ; float1 float2 -- ?
        _ check_float
        _swap
        _ check_float
        _swap

        mov     arg1_register, rbx
        poprbx
        mov     arg0_register, rbx
        poprbx

        xcall c_float_float_le

        pushrbx
        mov     rbx, rax

        next
endcode

; ### fixnum<=
code fixnum_le, 'fixnum<='      ; number fixnum -- ?

        ; second arg must be a fixnum
        _verify_fixnum

        ; dispatch on type of first arg
        mov     al, byte [rbp]
        and     al, FIXNUM_TAG_MASK
        cmp     al, FIXNUM_TAG
        jne     .1
        _ fixnum_fixnum_le
        _return

.1:

        _over
        _ int64?
        _tagged_if .2
        _ int64_fixnum_le
        _return
        _then .2

        _over
        _ float?
        _tagged_if .3
        _ float_fixnum_le
        _return
        _then .3

        _drop
        _ error_not_number
        next
endcode

; ### float-int64<=
code float_int64_le, 'float-int64<='    ; float int64 -- ?
        _ int64_to_float
        _ float_float_le
        next
endcode

; ### int64<=
code int64_le, 'int64<='                ; number int64 -- ?

        ; second arg must be int64
        _ verify_int64

        ; dispatch on type of first arg
        _over
        _ object_raw_typecode
        mov     rax, rbx
        poprbx                          ; -- x y

        cmp     rax, TYPECODE_FIXNUM
        je      fixnum_int64_le

        cmp     rax, TYPECODE_INT64
        je      int64_int64_le

        cmp     rax, TYPECODE_FLOAT
        je      float_int64_le

        _drop
        _ error_not_number

        next
endcode

; ### fixnum-float<=
code fixnum_float_le, 'fixnum-float<='          ; fixnum float -- ?
        _swap
        _ fixnum_to_float
        _swap
        _ float_float_le
        next
endcode

; ### int64-float<=
code int64_float_le, 'int64-float<='            ; int64 float -- ?
        _swap
        _ int64_to_float
        _swap
        _ float_float_le
        next
endcode

; ### float<=
code float_le, 'float<='                        ; number float -- ?

        _debug_?enough 2

        _ verify_float

        _over
        _ float?
        _tagged_if .1
        _ float_float_le
        _return
        _then .1

        _over_fixnum?_if .2
        _ fixnum_float_le
        _return
        _then .2

        _over
        _ int64?
        _tagged_if .3
        _ int64_float_le
        _return
        _then .3

        _drop
        _ error_not_number
        next
endcode

; ### fixnum-fixnum>
code fixnum_fixnum_gt, 'fixnum-fixnum>' ; fixnum1 fixnum2 -- ?
        _check_fixnum
        _swap
        _check_fixnum
        _swap
        _ raw_int64_int64_gt
        next
endcode

; ### int64-fixnum>
code int64_fixnum_gt, 'int64-fixnum>'   ; int64 fixnum -- ?
        _check_fixnum
        _swap
        _ check_int64
        _swap
        _ raw_int64_int64_gt
        next
endcode

; ### float-float>
code float_float_gt, 'float-float>'             ; float1 float2 -- ?
        _ check_float
        _swap
        _ check_float
        _swap

        mov     arg1_register, rbx
        poprbx
        mov     arg0_register, rbx
        poprbx

        xcall c_float_float_gt

        pushrbx
        mov     rbx, rax

        next
endcode

; ### float-fixnum>
code float_fixnum_gt, 'float-fixnum>'   ; float fixnum -- ?
        _ fixnum_to_float
        _ float_float_gt
        next
endcode

; ### fixnum>
code fixnum_gt, 'fixnum>'               ; number fixnum -- ?

        ; second arg must be a fixnum
        _verify_fixnum

        ; dispatch on type of first arg
        _over
        _ object_raw_typecode
        mov     rax, rbx
        poprbx                          ; -- x y

        cmp     rax, TYPECODE_FIXNUM
        je      fixnum_fixnum_gt

        cmp     rax, TYPECODE_INT64
        je      int64_fixnum_gt

        cmp     rax, TYPECODE_FLOAT
        jne     .1
        _ fixnum_to_float
        jmp     float_float_gt

.1:
        _drop
        _ error_not_number
        next
endcode

; ### raw_int64_int64_gt
code raw_int64_int64_gt, 'raw_int64_int64_gt', SYMBOL_INTERNAL
; x y -- ?
        mov     eax, t_value
        cmp     [rbp], rbx
        mov     ebx, f_value
        cmovg   ebx, eax
        lea     rbp, [rbp + BYTES_PER_CELL]
        next
endcode

; ### fixnum-int64>
code fixnum_int64_gt, 'fixnum-int64>'   ; x y -- ?
        _ check_int64
        _swap
        _check_fixnum
        _swap
        _ raw_int64_int64_gt
        next
endcode

; ### int64-int64>
code int64_int64_gt, 'int64-int64>'     ; x y -- ?
        _ check_int64
        _swap
        _ check_int64
        _swap
        _ raw_int64_int64_gt
        next
endcode

; ### int64>
code int64_gt, 'int64>'                 ; x y -- ?

        ; second arg must be int64
        _ verify_int64

        ; dispatch on type of first arg
        _over
        _ object_raw_typecode
        mov     rax, rbx
        poprbx                          ; -- x y

        cmp     rax, TYPECODE_FIXNUM
        je      fixnum_int64_gt

        cmp     rax, TYPECODE_INT64
        je      int64_int64_gt

        cmp     rax, TYPECODE_FLOAT
        jne     .1
        _ int64_to_float
        jmp     float_float_gt

.1:
        _drop
        _ error_not_number

        next
endcode

; ### fixnum-float>
code fixnum_float_gt, 'fixnum-float>'   ; fixnum float -- ?
        _swap
        _ fixnum_to_float
        _swap
        _ float_float_gt
        next
endcode

; ### int64-float>
code int64_float_gt, 'int64-float>'     ; int64 float -- ?
        _swap
        _ int64_to_float
        _swap
        _ float_float_gt
        next
endcode

; ### float>
code float_gt, 'float>'                 ; x y -- ?

        ; second arg must be float
        _ verify_float

        ; dispatch on type of first arg
        _over
        _ object_raw_typecode
        mov     rax, rbx
        poprbx                          ; -- x y

        cmp     rax, TYPECODE_FIXNUM
        je      fixnum_float_gt

        cmp     rax, TYPECODE_INT64
        je      int64_float_gt

        cmp     rax, TYPECODE_FLOAT
        je      float_float_gt

        _drop
        _ error_not_number

        next
endcode

; ### fixnum-int64>=
code fixnum_int64_ge, 'fixnum-int64>='          ; fixnum int64 -- ?
        _ check_int64
        _swap
        _ check_fixnum
        _swap
        mov     eax, t_value
        cmp     [rbp], rbx
        mov     ebx, f_value
        cmovge  ebx, eax
        lea     rbp, [rbp + BYTES_PER_CELL]
        next
endcode

; ### int64-int64>=
code int64_int64_ge, 'int64-int64>='    ; x y -- ?
        _ check_int64
        _swap
        _ check_int64
        _swap

        mov     eax, t_value
        cmp     [rbp], rbx
        mov     ebx, f_value
        cmovge  ebx, eax
        lea     rbp, [rbp + BYTES_PER_CELL]
        next
endcode

; ### float-int64>=
code float_int64_ge, 'float-int64>='    ; float int64 -- ?
        _ int64_to_float
        _ float_float_ge
        next
endcode

; ### int64>=
code int64_ge, 'int64>='                ; number int64 -- ?

        ; second arg must be int64
        _ verify_int64

        ; dispatch on type of first arg
        _over
        _ object_raw_typecode
        mov     rax, rbx
        poprbx                          ; -- x y

        cmp     rax, TYPECODE_FIXNUM
        je      fixnum_int64_ge

        cmp     rax, TYPECODE_INT64
        je      int64_int64_ge

        cmp     rax, TYPECODE_FLOAT
        je      float_int64_ge

        _drop
        _ error_not_number

        next
endcode

; ### raw_int64_int64_ge
code raw_int64_int64_ge, 'raw_int64_int64_ge', SYMBOL_INTERNAL
; x y -- ?
        mov     eax, t_value
        cmp     [rbp], rbx
        mov     ebx, f_value
        cmovge  ebx, eax
        lea     rbp, [rbp + BYTES_PER_CELL]
        next
endcode

; ### fixnum-fixnum>=
code fixnum_fixnum_ge, 'fixnum-fixnum>='        ; fixnum1 fixnum2 -- ?
        _check_fixnum
        _swap
        _check_fixnum
        _swap
        _ raw_int64_int64_ge
        next
endcode

; ### int64-fixnum>=
code int64_fixnum_ge, 'int64-fixnum>='  ; x y -- ?
        _check_fixnum
        _swap
        _ check_int64
        _swap
        _ raw_int64_int64_ge
        next
endcode

; ### float-fixnum>=
code float_fixnum_ge, 'float-fixnum>='          ; float fixnum -- ?
        _ fixnum_to_float
        _ float_float_ge
        next
endcode

; ### fixnum>=
code fixnum_ge, 'fixnum>='                      ; number fixnum -- ?

        ; second arg must be a fixnum
        _verify_fixnum

        ; dispatch on type of first arg
        _over
        _ object_raw_typecode
        mov     rax, rbx
        poprbx                          ; -- x y

        cmp     rax, TYPECODE_FIXNUM
        je      fixnum_fixnum_ge

        cmp     rax, TYPECODE_INT64
        je      int64_fixnum_ge

        cmp     rax, TYPECODE_FLOAT
        jne     .1
        _ fixnum_to_float
        jmp     float_float_ge

.1:
        _drop
        _ error_not_number
        next
endcode

; ### fixnum-float>=
code fixnum_float_ge, 'fixnum-float>='  ; fixnum float -- ?
        _swap
        _ fixnum_to_float
        _swap
        _ float_float_ge
        next
endcode

; ### int64-float>=
code int64_float_ge, 'int64-float>='    ; int64 float -- ?
        _swap
        _ int64_to_float
        _swap
        _ float_float_ge
        next
endcode

; ### float-float>=
code float_float_ge, 'float-float>='            ; float1 float2 -- ?
        _ check_float
        _swap
        _ check_float
        _swap

        mov     arg1_register, rbx
        poprbx
        mov     arg0_register, rbx
        poprbx

        xcall c_float_float_ge

        pushrbx
        mov     rbx, rax

        next
endcode

; ### float>=
code float_ge, 'float>='                ; number float -- ?

        ; second arg must be a float
        _ verify_float

        ; dispatch on type of first arg
        _over
        _ object_raw_typecode
        mov     rax, rbx
        poprbx                          ; -- x y

        cmp     rax, TYPECODE_FIXNUM
        je      fixnum_float_ge

        cmp     rax, TYPECODE_INT64
        je      int64_float_ge

        cmp     rax, TYPECODE_FLOAT
        je      float_float_ge

        _drop
        _ error_not_number
        next
endcode

; ### negative?
code negative?, 'negative?'             ; number -- ?
        test    bl, FIXNUM_TAG
        jz      .1
        test    rbx, rbx
        mov     eax, t_value
        mov     ebx, f_value
        cmovs   ebx, eax
        next

.1:
        ; not a fixnum
        cmp     bl, HANDLE_TAG
        jne     error_not_number

        _handle_to_object_unsafe

        test    rbx, rbx
        jz      error_empty_handle

        _object_raw_typecode_eax

        cmp     eax, TYPECODE_INT64
        je      .2
        cmp     eax, TYPECODE_UINT64
        je      .3
        cmp     eax, TYPECODE_FLOAT
        je      .4

        _ error_not_number
        next

.2:
        ; int64
        _int64_raw_value
        test    rbx, rbx
        mov     eax, t_value
        mov     ebx, f_value
        cmovs   ebx, eax
        next

.3:
        ; uint64
        mov     ebx, f_value
        next

.4:
        ; float
        _float_raw_value
        test    rbx, rbx
        mov     eax, t_value
        mov     ebx, f_value
        cmovs   ebx, eax
        next
endcode

; ### between?
code between?, 'between?'               ; n min max -- ?
; returns t if min <= n <= max
        _pick
        _ generic_ge
        _tagged_if .1
        _ generic_ge
        _else .1
        _drop
        mov     ebx, f_value
        _then .1
        next
endcode

; ### within?
code within?, 'within?'                 ; n min max -- ?
; returns t if min <= n < max
        _pick
        _ generic_gt
        _tagged_if .1
        _ generic_ge
        _else .1
        _drop
        mov     ebx, f_value
        _then .1
        next
endcode
