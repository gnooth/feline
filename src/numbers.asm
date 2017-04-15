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
        _over
        _ bignum?
        _tagged_if .1
        _ fixnum_to_bignum
        _ bignum_equal?
        _else .1
        _2drop
        _f
        _then .1
        next
endcode

; ### bignum-equal?
code bignum_equal?, 'bignum-equal?'     ; x y -- ?
        _dup
        _ bignum?
        _tagged_if .1
        _handle_to_object_unsafe
        _else .1
        _2drop
        _f
        _return
        _then .1

        _over
        _ bignum?
        _tagged_if .2
        mov     arg0_register, rbx
        poprbx
        _handle_to_object_unsafe
        mov     arg1_register, rbx
        poprbx
        xcall   c_bignum_equal
        pushrbx
        mov     rbx, rax
        _return
        _then .2

        _over
        _fixnum?
        _tagged_if .3
        _swap
        _ fixnum_to_bignum
        _ check_bignum
        mov     arg0_register, rbx
        poprbx
        mov     arg1_register, rbx
        poprbx
        xcall   c_bignum_equal
        pushrbx
        mov     rbx, rax
        _return
        _then .3

        _2drop
        _f

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

; ### bignum-fixnum<
code bignum_fixnum_lt, 'bignum-fixnum<' ; bignum fixnum -- ?
        _ fixnum_to_bignum
        _ bignum_bignum_lt
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
        _ bignum?
        _tagged_if .2
        _ bignum_fixnum_lt
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

; ### bignum-bignum<
code bignum_bignum_lt, 'bignum-bignum<'         ; bignum1 bignum2 -- ?
        _ check_bignum
        _swap
        _ check_bignum
        _swap

        mov     arg1_register, rbx
        poprbx
        mov     arg0_register, rbx
        poprbx

        xcall c_bignum_bignum_lt

        pushrbx
        mov     rbx, rax

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

        _drop
        _ error_not_number
        next
endcode

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

; ### bignum-float<
code bignum_float_lt, 'bignum-float<'           ; bignum float -- ?
        _swap
        _ bignum_to_float
        _swap
        _ float_float_lt
        next
endcode

; ### float<
code float_lt, 'float<'                         ; number float -- ?
        _ verify_float

        _over
        _ float?
        _tagged_if .1
        _ float_float_lt
        _return
        _then .1

        _over
        _ fixnum?
        _tagged_if .2
        _ fixnum_float_lt
        _return
        _then .2

        _over
        _ bignum?
        _tagged_if .3
        _ bignum_float_lt
        _return
        _then .3

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

; ### bignum-fixnum<=
code bignum_fixnum_le, 'bignum-fixnum<='        ; bignum fixnum -- ?
        _ fixnum_to_bignum
        _ bignum_bignum_le
        next
endcode

; ### fixnum-bignum<=
code fixnum_bignum_le, 'bignum-fixnum<='        ; fixnum bignum -- ?
        _ verify_bignum
        _swap
        _ fixnum_to_bignum
        _swap
        _ bignum_bignum_le
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
        _ bignum?
        _tagged_if .2
        _ bignum_fixnum_le
        _return
        _then .2

        _drop
        _ error_not_number
        next
endcode

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

; ### bignum-fixnum>
code bignum_fixnum_gt, 'bignum-fixnum>' ; bignum fixnum -- ?
        _ fixnum_to_bignum
        _ bignum_bignum_gt
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
        mov     al, byte [rbp]
        and     al, TAG_MASK
        cmp     al, FIXNUM_TAG
        jne     .1
        _ fixnum_fixnum_gt
        _return

.1:
        _over
        _ bignum?
        _tagged_if .2
        _ bignum_fixnum_gt
        _return
        _then .2

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

        _drop
        _ error_not_number
        next
endcode

; ### fixnum-float>
code fixnum_float_gt, 'fixnum-float>'           ; fixnum float -- ?
        _swap
        _ fixnum_to_float
        _swap
        _ float_float_gt
        next
endcode

; ### bignum-float>
code bignum_float_gt, 'bignum-float>'           ; bignum float -- ?
        _swap
        _ bignum_to_float
        _swap
        _ float_float_gt
        next
endcode

; ### float>
code float_gt, 'float>'                         ; number float -- ?
        _ verify_float

        _over
        _ float?
        _tagged_if .1
        _ float_float_gt
        _return
        _then .1

        _over
        _ fixnum?
        _tagged_if .2
        _ fixnum_float_gt
        _return
        _then .2

        _over
        _ bignum?
        _tagged_if .3
        _ bignum_float_gt
        _return
        _then .3

        _drop
        _ error_not_number
        next
endcode

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
        _over
        _ bignum?
        _tagged_if .2
        _ bignum_fixnum_ge
        _return
        _then .2

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
