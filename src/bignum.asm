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

; ### HAVE_BIGNUMS
symbol HAVE_BIGNUMS, 'HAVE_BIGNUMS'

; sizeof(mpz_t) is 16 bytes
%define BIGNUM_DATA_OFFSET      8

; ### bignum?
code bignum?, 'bignum?' ; handle -- ?
        _dup
        _ handle?
        _tagged_if .1
        _handle_to_object_unsafe        ; -- object
        _dup_if .2
        _object_raw_typecode
        _lit TYPECODE_BIGNUM
        _eq?
        _return
        _then .2
        _then .1
        mov     ebx, f_value
        next
endcode

; ### verify-bignum
code verify_bignum, 'verify-bignum'     ; handle -- handle
        _dup
        _ bignum?
        _tagged_if .1
        _return
        _then .1

        _ error_not_bignum
        next
endcode

; ### check-bignum
code check_bignum, 'check-bignum'        ; x -- raw-bignum
        _dup
        _ deref
        test    rbx, rbx
        jz      .error
        movzx   eax, word [rbx]
        cmp     eax, TYPECODE_BIGNUM
        jne     .error
        _nip
        _return
.error:
        _drop                           ; -- x
        jmp     error_not_bignum
        next
endcode

; ### unsigned_to_bignum
subroutine unsigned_to_bignum   ; untagged -- bignum
        _ gc_disable
        mov     arg0_register, rbx
        poprbx
        xcall   c_bignum_from_unsigned
        pushrbx
        mov     rbx, rax
        _ gc_enable
        ret
endsub

; ### signed_to_bignum
subroutine signed_to_bignum     ; untagged -- bignum
        _ gc_disable
        mov     arg0_register, rbx
        poprbx
        xcall   c_bignum_from_signed
        pushrbx
        mov     rbx, rax
        _ gc_enable
        ret
endsub

; ### destroy_bignum_unchecked
subroutine destroy_bignum_unchecked     ; bignum --
        mov     arg0_register, rbx
        add     arg0_register, BIGNUM_DATA_OFFSET
        xcall   c_bignum_free

        _ in_gc?
        _tagged_if_not .1
        _dup
        _ release_handle_for_object
        _then .1

        ; zero out object header
        xor     eax, eax
        mov     [rbx], rax

        _ raw_free

        ret
endsub

; ### fixnum>bignum
code fixnum_to_bignum, 'fixnum>bignum'  ; x -- y
        _check_fixnum
        _ signed_to_bignum
        next
endcode

; ### bignum>base
code bignum_to_base, 'bignum>base'      ; bignum base -- string
        _check_fixnum
        _swap
        _ check_bignum                  ; -- base bignum

        push    this_register

        mov     this_register, rbx
        poprbx                          ; -- base

        mov     arg0_register, this_register
        add     arg0_register, BIGNUM_DATA_OFFSET

        mov     arg1_register, rbx      ; base

        xcall   c_bignum_sizeinbase

        pushrbx
        mov     rbx, rax

        add     rbx, 2
        _ raw_allocate                  ; -- base buffer-address
        _duptor

        mov     arg0_register, rbx      ; buffer address
        poprbx

        mov     arg1_register, rbx      ; base
        poprbx

        mov     arg2_register, this_register
        add     arg2_register, BIGNUM_DATA_OFFSET       ; mpz_t

        xcall   c_bignum_get_str

        pushrbx
        mov     rbx, rax

        _ zcount
        _ copy_to_string

        _rfrom
        _ raw_free

        pop     this_register

        next
endcode

; ### bignum>string
code bignum_to_string, 'bignum>string'  ; bignum -- string
        _lit tagged_fixnum(10)
        _ bignum_to_base
        next
endcode

; ### bignum>hex
code bignum_to_hex, 'bignum>hex'        ; bignum -- string
        _lit tagged_fixnum(16)
        _ bignum_to_base
        next
endcode

; ### bignum-bignum+
code bignum_bignum_plus, 'bignum-bignum+'       ; bignum bignum -- sum
        _ check_bignum
        _swap
        _ check_bignum

        _ gc_disable

        mov     arg0_register, rbx
        poprbx
        mov     arg1_register, rbx
        poprbx

        xcall c_bignum_bignum_plus

        pushrbx
        mov     rbx, rax

        _ gc_enable

        next
endcode

; ### bignum-bignum-
code bignum_bignum_minus, 'bignum-bignum-'      ; bignum1 bignum2 -- difference
        _ check_bignum
        _swap
        _ check_bignum          ; -- raw-bignum2 raw-bignum1

        _ gc_disable

        mov     arg0_register, rbx
        poprbx
        mov     arg1_register, rbx
        poprbx

        xcall c_bignum_bignum_minus

        pushrbx
        mov     rbx, rax

        _ gc_enable

        next
endcode

; ### fixnum-bignum+
code fixnum_bignum_plus, 'fixnum-bignum+'       ; fixnum bignum -- sum

        ; second arg must be bignum
        _ check_bignum

        ; first arg must be a fixnum
        _swap
        _ check_fixnum          ; -- bignum fixnum

        _ gc_disable

        mov     arg1_register, rbx
        poprbx
        mov     arg0_register, rbx
        poprbx

        xcall   c_bignum_fixnum_plus

        ; fixnum or object pointer in rax
        pushrbx
        mov     rbx, rax

        _ gc_enable

        next
endcode

; ### float-bignum+
code float_bignum_plus, 'float-bignum+' ; float bignum -- sum
        _ bignum_to_float
        _ float_float_plus
        next
endcode

; ### bignum+
code bignum_plus, 'bignum+'     ; number bignum -- sum

        ; second arg must be a bignum
        _ verify_bignum

        ; dispatch on type of first arg
        _over
        _fixnum?_if .1
        _ fixnum_bignum_plus
        _return
        _then .1

        _over
        _ bignum?
        _tagged_if .2
        _ bignum_bignum_plus
        _return
        _then .2

        _over
        _ float?
        _tagged_if .3
        _ float_bignum_plus
        _return
        _then .3

        _drop
        _ error_not_number

        next
endcode

; ### bignum-
code bignum_minus, 'bignum-'    ; number bignum -- difference

        ; second arg must be a bignum
        _ verify_bignum

        ; dispatch on type of first arg
        _over
        _fixnum?_if .1
        _ bignum_negate
        _ fixnum_bignum_plus
        _return
        _then .1

        _over
        _ bignum?
        _tagged_if .2
        _ bignum_bignum_minus
        _return
        _then .2

        _over
        _ float?
        _tagged_if .3
        _ bignum_to_float
        _ float_float_minus
        _return
        _then .3

        _drop
        _ error_not_number

        next
endcode

; ### bignum-bignum*
code bignum_bignum_multiply, 'bignum-bignum*'       ; bignum bignum -- sum
        _ check_bignum
        _swap
        _ check_bignum

        _ gc_disable

        mov     arg0_register, rbx
        poprbx
        mov     arg1_register, rbx
        poprbx

        xcall c_bignum_bignum_multiply

        pushrbx
        mov     rbx, rax

        _ gc_enable

        next
endcode

; ### fixnum-bignum*
code fixnum_bignum_multiply, 'fixnum-bignum*'   ; x y -- z
        _ verify_bignum
        _swap
        _check_fixnum
        _ signed_to_bignum
        _ bignum_bignum_multiply
        next
endcode

; ### bignum*
code bignum_multiply, 'bignum*'         ; x y -- z

        ; second arg must be a bignum
        _ verify_bignum

        ; dispatch on type of first arg
        _over
        _fixnum?_if .1
        _ fixnum_bignum_multiply
        _return
        _then .1

        _over
        _ bignum?
        _tagged_if .2
        _ bignum_bignum_multiply
        _return
        _then .2

        _over
        _ float?
        _tagged_if .3
        _ bignum_to_float
        _ float_float_multiply
        _return
        _then .3

        _drop
        _ error_not_number

        next
endcode

; ### bignum-bignum/i
code bignum_bignum_divide_truncate, 'bignum-bignum/i'   ; x y -- z
        _ check_bignum
        _swap
        _ check_bignum

        _ gc_disable

        mov     arg0_register, rbx
        poprbx
        mov     arg1_register, rbx
        poprbx

        xcall c_bignum_bignum_divide_truncate

        pushrbx
        mov     rbx, rax

        _ gc_enable

        next
endcode

; ### bignum/i
code bignum_divide_truncate, 'bignum/i' ; x y -- z
        _ verify_bignum

        _over_fixnum?_if .1
        _swap
        _ fixnum_to_bignum
        _swap
        _ bignum_bignum_divide_truncate
        _return
        _then .1

        _over
        _ bignum?
        _tagged_if .2
        _ bignum_bignum_divide_truncate
        _return
        _then .2

        _over
        _ float?
        _tagged_if .3
        _ bignum_to_float
        _ float_float_divide
        _ float_to_integer
        _return
        _then .3

        _drop
        _ error_not_number

        next
endcode

; ### bignum/f
code bignum_divide_float, 'bignum/f'            ; x y -- z
        _ verify_bignum

        _over_fixnum?_if .1
        _swap
        _ fixnum_to_float
        _swap
        _ bignum_to_float
        _ float_float_divide
        _return
        _then .1

        _over
        _ bignum?
        _tagged_if .2
        _swap
        _ bignum_to_float
        _swap
        _ bignum_to_float
        _ float_float_divide
        _return
        _then .2

        _over
        _ float?
        _tagged_if .3
        _ bignum_to_float
        _ float_float_divide
        _ float_to_integer
        _return
        _then .3

        _drop
        _ error_not_number

        next
endcode

; ### bignum-bignum-mod
code bignum_bignum_mod, 'bignum-bignum-mod'     ; x y -- z
        _ check_bignum
        _swap
        _ check_bignum

        _ gc_disable

        mov     arg0_register, rbx
        poprbx
        mov     arg1_register, rbx
        poprbx

        xcall c_bignum_bignum_mod

        pushrbx
        mov     rbx, rax

        _ gc_enable

        next
endcode

; ### fixnum-bignum-mod
code fixnum_bignum_mod, 'fixnum-bignum-mod'     ; x y -- z
        _ verify_bignum
        _swap
        _ fixnum_to_bignum
        _swap
        _ bignum_bignum_mod
        next
endcode

; ### bignum-mod
code bignum_mod, 'bignum-mod'                   ; x y -- z
        _ verify_bignum

        _over_fixnum?_if .1
        _ fixnum_bignum_mod
        _return
        _then .1

        _over
        _ bignum?
        _tagged_if .2
        _ bignum_bignum_mod
        _return
        _then .2

        _drop
        _ error_not_number

        next
endcode

; ### bignum-negate
code bignum_negate, 'bignum-negate'             ; n -- -n
; no type checking
        _handle_to_object_unsafe
        mov     arg0_register, rbx
        poprbx
        _ gc_disable
        xcall   c_bignum_negate
        pushrbx
        mov     rbx, rax
        _ gc_enable
        next
endcode
