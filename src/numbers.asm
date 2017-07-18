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

; ### fixnum-equal?
code fixnum_equal?, 'fixnum-equal?'     ; x y -- ?
        _verify_fixnum

        cmp     rbx, [rbp]
        jne     .1
        _nip
        mov     ebx, t_value
        _return

.1:

%ifdef FELINE_FEATURE_BIGNUMS
        _over
        _ bignum?
        _tagged_if .2
        _ fixnum_to_bignum
        _ bignum_equal?
        _return
        _then .2
%endif

        _over
        _ float?
        _tagged_if .3
        _ fixnum_to_float
        _ float_equal?
        _return
        _then .3

        _nip
        mov     ebx, f_value
        next
endcode

; ### int64-equal?
code int64_equal?, 'int64-equal?'       ; x y -- ?
        _ check_int64
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
        _untag_fixnum
        _eq?
        _return

.2:
        ; int64
        _ int64_raw_value
        _eq?
        _return

.3:
        ; float
        _swap
        _ raw_int64_to_float
        _ float_equal?

        next
endcode

%ifdef FELINE_FEATURE_BIGNUMS
; ### bignum-bignum-equal?
code bignum_bignum_equal?, 'bignum-bignum-equal?'       ; x y -- ?
        _ check_bignum
        _swap
        _ check_bignum
        mov     arg0_register, rbx
        poprbx
        mov     arg1_register, rbx
        xcall   c_bignum_bignum_equal
        mov     rbx, rax
        next
endcode

; ### bignum-equal?
code bignum_equal?, 'bignum-equal?'                     ; x y -- ?
        _ verify_bignum

        _over_fixnum?_if .1
        _swap
        _ fixnum_to_bignum
        _ bignum_bignum_equal?
        _return
        _then .1

        _over
        _ bignum?
        _tagged_if .2
        _ bignum_bignum_equal?
        _return
        _then .2

        _over
        _ float?
        _tagged_if .3
        _ bignum_to_float
        _ float_equal?
        _return
        _then .3

        _2drop
        _f
        next
endcode
%endif

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
code fixnum_lt, 'fixnum<'               ; number fixnum -- ?

        ; second arg must be a fixnum
        _verify_fixnum

        ; dispatch on type of first arg
        mov     al, byte [rbp]
        and     al, TAG_MASK
        cmp     al, FIXNUM_TAG
        jne     .1
        _ fixnum_fixnum_lt
        _return

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

%ifdef FELINE_FEATURE_BIGNUMS
; ### float-bignum<
code float_bignum_lt, 'float-bignum<'           ; float bignum -- ?
        _ bignum_to_float
        _ float_float_lt
        next
endcode

; ### fixnum-bignum<
code fixnum_bignum_lt, 'fixnum-bignum<'         ; fixnum bignum -- ?
        _ verify_bignum
        _swap
        _ fixnum_to_bignum
        _swap
        _ bignum_bignum_lt
        next
endcode

; ### bignum<
code bignum_lt, 'bignum<'               ; number bignum -- ?

        ; second arg must be a bignum
        _ verify_bignum

        ; dispatch on type of first arg
        mov     al, byte [rbp]
        and     al, TAG_MASK
        cmp     al, FIXNUM_TAG
        jne     .1
        _ fixnum_bignum_lt
        _return

.1:
        _over
        _ bignum?
        _tagged_if .2
        _ bignum_bignum_lt
        _return
        _then .2

        _over
        _ float?
        _tagged_if .3
        _ float_bignum_lt
        _return
        _then .3

        _drop
        _ error_not_number
        next
endcode
%endif

; ### float-float<
code float_float_lt, 'float-float<'             ; float1 float2 -- ?
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
code fixnum_float_lt, 'fixnum-float<'           ; fixnum float -- ?
        _swap
        _ fixnum_to_float
        _swap
        _ float_float_lt
        next
endcode

%ifdef FELINE_FEATURE_BIGNUMS
; ### bignum-float<
code bignum_float_lt, 'bignum-float<'           ; bignum float -- ?
        _swap
        _ bignum_to_float
        _swap
        _ float_float_lt
        next
endcode
%endif

; ### float<
code float_lt, 'float<'                         ; number float -- ?
        _ verify_float

        _over
        _ float?
        _tagged_if .1
        _ float_float_lt
        _return
        _then .1

        _over_fixnum?_if .2
        _ fixnum_float_lt
        _return
        _then .2

%ifdef FELINE_FEATURE_BIGNUMS
        _over
        _ bignum?
        _tagged_if .3
        _ bignum_float_lt
        _return
        _then .3
%endif

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

%ifdef FELINE_FEATURE_BIGNUMS
; ### bignum-bignum<=
code bignum_bignum_le, 'bignum-bignum<='        ; bignum1 bignum2 -- ?
        _ check_bignum
        _swap
        _ check_bignum
        _swap

        mov     arg1_register, rbx
        poprbx
        mov     arg0_register, rbx
        poprbx

        xcall c_bignum_bignum_le

        pushrbx
        mov     rbx, rax

        next
endcode
%endif

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

%ifdef FELINE_FEATURE_BIGNUMS
; ### fixnum-bignum<=
code fixnum_bignum_le, 'bignum-fixnum<='        ; fixnum bignum -- ?
        _ verify_bignum
        _swap
        _ fixnum_to_bignum
        _swap
        _ bignum_bignum_le
        next
endcode
%endif

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
        and     al, TAG_MASK
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

%ifdef FELINE_FEATURE_BIGNUMS
; ### bignum<=
code bignum_le, 'bignum<='              ; number bignum -- ?

        ; second arg must be a bignum
        _ verify_bignum

        ; dispatch on type of first arg
        mov     al, byte [rbp]
        and     al, TAG_MASK
        cmp     al, FIXNUM_TAG
        jne     .1
        _ fixnum_bignum_le
        _return

.1:
        _over
        _ bignum?
        _tagged_if .2
        _ bignum_bignum_le
        _return
        _then .2

        _drop
        _ error_not_number
        next
endcode
%endif

; ### int64<=
code int64_le, 'int64<='                ; number int64 -- ?

        ; second arg must be int64
        _ verify_int64

        ; dispatch on type of first arg
        _over
        _ fixnum?
        _tagged_if .1
        _ fixnum_int64_le
        _return
        _then .1

        _over
        _ int64?
        _tagged_if .2
        _ int64_int64_le
        _return
        _then .2

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

%ifdef FELINE_FEATURE_BIGNUMS
; ### bignum-float<=
code bignum_float_le, 'bignum-float<='          ; bignum float -- ?
        _swap
        _ bignum_to_float
        _swap
        _ float_float_le
        next
endcode
%endif

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

        mov     eax, t_value
        cmp     [rbp], rbx
        mov     ebx, f_value
        cmovg   ebx, eax
        lea     rbp, [rbp + BYTES_PER_CELL]
        next
endcode

%ifdef FELINE_FEATURE_BIGNUMS
; ### bignum-fixnum>
code bignum_fixnum_gt, 'bignum-fixnum>' ; bignum fixnum -- ?
        _ fixnum_to_bignum
        _ bignum_bignum_gt
        next
endcode
%endif

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
        mov     al, byte [rbp]
        and     al, TAG_MASK
        cmp     al, FIXNUM_TAG
        jne     .1
        _ fixnum_fixnum_gt
        _return

.1:

%ifdef FELINE_FEATURE_BIGNUMS
        _over
        _ bignum?
        _tagged_if .2
        _ bignum_fixnum_gt
        _return
        _then .2
%endif

        _over
        _ float?
        _tagged_if .3
        _ float_fixnum_gt
        _return
        _then .3

        _drop
        _ error_not_number
        next
endcode

%ifdef FELINE_FEATURE_BIGNUMS
; ### bignum-bignum>
code bignum_bignum_gt, 'bignum-bignum>'         ; bignum1 bignum2 -- ?
        _ check_bignum
        _swap
        _ check_bignum
        _swap

        mov     arg1_register, rbx
        poprbx
        mov     arg0_register, rbx
        poprbx

        xcall c_bignum_bignum_gt

        pushrbx
        mov     rbx, rax

        next
endcode

; ### float-bignum>
code float_bignum_gt, 'float-bignum>'         ; float bignum -- ?
        _ bignum_to_float
        _ float_float_gt
        next
endcode

; ### fixnum-bignum>
code fixnum_bignum_gt, 'fixnum-bignum>'         ; fixnum bignum -- ?
        _ verify_bignum
        _swap
        _ fixnum_to_bignum
        _swap
        _ bignum_bignum_gt
        next
endcode

; ### bignum>
code bignum_gt, 'bignum>'                       ; number bignum -- ?

        ; second arg must be a bignum
        _ verify_bignum

        ; dispatch on type of first arg
        mov     al, byte [rbp]
        and     al, TAG_MASK
        cmp     al, FIXNUM_TAG
        jne     .1
        _ fixnum_bignum_gt
        _return

.1:
        _over
        _ bignum?
        _tagged_if .2
        _ bignum_bignum_gt
        _return
        _then .2

        _over
        _ float?
        _tagged_if .3
        _ float_bignum_gt
        _return
        _then .3

        _drop
        _ error_not_number
        next
endcode
%endif

; ### fixnum-float>
code fixnum_float_gt, 'fixnum-float>'           ; fixnum float -- ?
        _swap
        _ fixnum_to_float
        _swap
        _ float_float_gt
        next
endcode

%ifdef FELINE_FEATURE_BIGNUMS
; ### bignum-float>
code bignum_float_gt, 'bignum-float>'           ; bignum float -- ?
        _swap
        _ bignum_to_float
        _swap
        _ float_float_gt
        next
endcode
%endif

; ### float>
code float_gt, 'float>'                         ; number float -- ?
        _ verify_float

        _over
        _ float?
        _tagged_if .1
        _ float_float_gt
        _return
        _then .1

        _over_fixnum?_if .2
        _ fixnum_float_gt
        _return
        _then .2

%ifdef FELINE_FEATURE_BIGNUMS
        _over
        _ bignum?
        _tagged_if .3
        _ bignum_float_gt
        _return
        _then .3
%endif

        _drop
        _ error_not_number
        next
endcode

%ifdef FELINE_FEATURE_BIGNUMS
; ### bignum-bignum>=
code bignum_bignum_ge, 'bignum-bignum>='        ; bignum1 bignum2 -- ?
        _ check_bignum
        _swap
        _ check_bignum
        _swap

        mov     arg1_register, rbx
        poprbx
        mov     arg0_register, rbx
        poprbx

        xcall c_bignum_bignum_ge

        pushrbx
        mov     rbx, rax

        next
endcode

; ### fixnum-bignum>=
code fixnum_bignum_ge, 'fixnum-bignum>='        ; fixnum bignum -- ?
        _ verify_bignum
        _swap
        _ fixnum_to_bignum
        _swap
        _ bignum_bignum_ge
        next
endcode

; ### bignum>=
code bignum_ge, 'bignum>='              ; number bignum -- ?

        ; second arg must be a bignum
        _ verify_bignum

        ; dispatch on type of first arg
        mov     al, byte [rbp]
        and     al, TAG_MASK
        cmp     al, FIXNUM_TAG
        jne     .1
        _ fixnum_bignum_ge
        _return

.1:
        _over
        _ bignum?
        _tagged_if .2
        _ bignum_bignum_ge
        _return
        _then .2

        _over
        _ float?
        _tagged_if .3
        _ float_bignum_ge
        _return
        _then .3

        _drop
        _ error_not_number
        next
endcode
%endif

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

; ### int64>=
code int64_ge, 'int64>='                ; number int64 -- ?

        ; second arg must be int64
        _ verify_int64

        ; dispatch on type of first arg
        _over
        _ fixnum?
        _tagged_if .1
        _ fixnum_int64_ge
        _return
        _then .1

        _over
        _ int64?
        _tagged_if .2
        _ int64_int64_ge
        _return
        _then .2

        _drop
        _ error_not_number

        next
endcode

; ### fixnum-fixnum>=
code fixnum_fixnum_ge, 'fixnum-fixnum>='        ; fixnum1 fixnum2 -- ?
        _check_fixnum
        _swap
        _check_fixnum
        _swap

        mov     eax, t_value
        cmp     [rbp], rbx
        mov     ebx, f_value
        cmovge  ebx, eax
        lea     rbp, [rbp + BYTES_PER_CELL]
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

%ifdef FELINE_FEATURE_BIGNUMS
; ### float-bignum>=
code float_bignum_ge, 'float-bignum>='  ; float bignum -- ?
        _ bignum_to_float
        _ float_float_ge
        next
endcode

; ### bignum-fixnum>=
code bignum_fixnum_ge, 'bignum-fixnum>='        ; bignum fixnum -- ?
        _ fixnum_to_bignum
        _ bignum_bignum_ge
        next
endcode
%endif

; ### float-fixnum>=
code float_fixnum_ge, 'float-fixnum>='          ; bignum fixnum -- ?
        _ fixnum_to_float
        _ float_float_ge
        next
endcode

; ### fixnum>=
code fixnum_ge, 'fixnum>='                      ; number fixnum -- ?

        ; second arg must be a fixnum
        _verify_fixnum

        ; dispatch on type of first arg
        mov     al, byte [rbp]
        and     al, TAG_MASK
        cmp     al, FIXNUM_TAG
        jne     .1
        _ fixnum_fixnum_ge
        _return

.1:

%ifdef FELINE_FEATURE_BIGNUMS
        _over
        _ bignum?
        _tagged_if .2
        _ bignum_fixnum_ge
        _return
        _then .2
%endif

        _over
        _ float?
        _tagged_if .3
        _ float_fixnum_ge
        _return
        _then .3

        _drop
        _ error_not_number
        next
endcode

; ### fixnum-float>=
code fixnum_float_ge, 'fixnum-float>='          ; fixnum float -- ?
        _swap
        _ fixnum_to_float
        _swap
        _ float_float_ge
        next
endcode

%ifdef FELINE_FEATURE_BIGNUMS
; ### bignum-float>=
code bignum_float_ge, 'bignum-float>='          ; bignum float -- ?
        _swap
        _ bignum_to_float
        _swap
        _ float_float_ge
        next
endcode
%endif

; ### float>=
code float_ge, 'float>='                        ; number float -- ?
        _ verify_float

        _over
        _ float?
        _tagged_if .1
        _ float_float_ge
        _return
        _then .1

        _over_fixnum?_if .2
        _ fixnum_float_ge
        _return
        _then .2

%ifdef FELINE_FEATURE_BIGNUMS
        _over
        _ bignum?
        _tagged_if .3
        _ bignum_float_ge
        _return
        _then .3
%endif

        _drop
        _ error_not_number
        next
endcode
