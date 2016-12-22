; Copyright (C) 2016 Peter Graves <gnooth@gmail.com>

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

; sizeof(mpz_t) is 16 bytes
%define BIGNUM_DATA_OFFSET      8

; ### bignum?
code bignum?, 'bignum?' ; handle -- ?
        _dup
        _ handle?
        _tagged_if .1
        _handle_to_object_unsafe        ; -- object
        _dup_if .2
        _object_type                    ; -- object-type
        _lit OBJECT_TYPE_BIGNUM
        _eq?
        _return
        _then .2
        _then .1
        mov     ebx, f_value
        next
endcode

; ### error-not-bignum
code error_not_bignum, 'error-not-bignum' ; x --
        ; REVIEW
        _drop
        _error "not a bignum"
        next
endcode

; ### check_bignum
subroutine check_bignum         ; handle -- bignum
        _dup
        _ handle?
        _tagged_if .1
        _handle_to_object_unsafe        ; -- object/0
        _dup_if .2
        _dup
        _object_type                    ; -- object object-type
        _lit OBJECT_TYPE_BIGNUM
        _equal
        _if .3
        _return
        _then .3
        _then .2
        _then .1

        _ error_not_bignum
        ret
endsub

; ### unsigned_to_bignum
subroutine unsigned_to_bignum   ; untagged -- bignum
        _ gc_disable
        mov     arg0_register, rbx
        poprbx
        xcall   bignum_from_unsigned
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
        xcall   bignum_from_signed
        pushrbx
        mov     rbx, rax
        _ gc_enable
        ret
endsub

; ### destroy_bignum_unchecked
subroutine destroy_bignum_unchecked     ; bignum --
        mov     arg0_register, rbx
        add     arg0_register, BIGNUM_DATA_OFFSET
        xcall   bignum_free

        _ in_gc?
        _zeq_if .1
        _dup
        _ release_handle_for_object
        _then .1

        ; zero out object header
        xor     eax, eax
        mov     [rbx], rax

        _ ifree

        ret
endsub

; ### fixnum>bignum
code fixnum_to_bignum, 'fixnum>bignum'  ; x -- y
        _untag_fixnum
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

        xcall   bignum_sizeinbase

        pushrbx
        mov     rbx, rax

        add     rbx, 2
        _ iallocate                     ; -- base buffer-address
        _duptor

        mov     arg0_register, rbx      ; buffer address
        poprbx

        mov     arg1_register, rbx      ; base
        poprbx

        mov     arg2_register, this_register
        add     arg2_register, BIGNUM_DATA_OFFSET       ; mpz_t

        xcall   bignum_get_str

        pushrbx
        mov     rbx, rax

        _ zcount
        _ copy_to_string

        _rfrom
        _ ifree

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
        xcall   bignum_equal
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
        xcall   bignum_equal
        pushrbx
        mov     rbx, rax
        _return
        _then .3

        _2drop
        _f

        next
endcode

; ### bignum-add-fixnum
code bignum_add_fixnum, 'bignum-add-fixnum'     ; fixnum bignum -- sum
        _ check_bignum
        _swap
        _ check_fixnum          ; -- bignum fixnum

        _ gc_disable

        mov     arg1_register, rbx
        poprbx
        mov     arg0_register, rbx
        poprbx

        xcall   bignum_add

        ; fixnum or object pointer in rax
        pushrbx
        mov     rbx, rax

        _ gc_enable
        next
endcode
