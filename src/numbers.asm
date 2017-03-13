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

; ### <
code feline_lt, '<'                     ; x y -- ?
        _ fixnum_lt
        next
endcode
