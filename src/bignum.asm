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

; ### check-bignum
code check_bignum, 'check-bignum'       ; handle -- bignum
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
        next
endcode

; ### unsigned_to_bignum
subroutine unsigned_to_bignum   ; untagged -- bignum

        push    this_register

        xcall   bignum_allocate         ; address of allocated object in rax
        mov     this_register, rax

        ; zero all bits of object header
        xor     eax, eax
        mov     [this_register], rax

        _this_object_set_type OBJECT_TYPE_BIGNUM

        mov     arg0_register, this_register
        add     arg0_register, BIGNUM_DATA_OFFSET

        mov     arg1_register, rbx
        poprbx

        xcall   bignum_init_set_ui

        ; return handle
        _this                           ; -- bignum
        _ new_handle                    ; -- handle

        pop     this_register

        ret
endsub

; ### signed_to_bignum
subroutine signed_to_bignum     ; untagged -- bignum

        push    this_register

        xcall   bignum_allocate         ; address of allocated object in rax
        mov     this_register, rax

        ; zero all bits of object header
        xor     eax, eax
        mov     [this_register], rax

        _this_object_set_type OBJECT_TYPE_BIGNUM

        mov     arg0_register, this_register
        add     arg0_register, BIGNUM_DATA_OFFSET

        mov     arg1_register, rbx
        poprbx

        xcall   bignum_init_set_si

        ; return handle
        _this                           ; -- bignum
        _ new_handle                    ; -- handle

        pop     this_register

        ret
endsub

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

; ### bignum>string
code bignum_to_string, 'bignum>string'  ; handle-to-bignum -- string

        _ check_bignum                  ; -- bignum

        push    this_register

        mov     this_register, rbx
        poprbx                          ; --

        mov     arg0_register, this_register
        add     arg0_register, BIGNUM_DATA_OFFSET

        mov     arg1_register, 10       ; base

        xcall   bignum_sizeinbase

        pushrbx
        mov     rbx, rax

        add     rbx, 2
        _ iallocate                     ; -- buffer-address
        _duptor

        mov     arg0_register, rbx      ; buffer address
        poprbx

        mov     arg1_register, 10       ; base

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

; ### bignum=
code bignum_equal, 'bignum='            ; x y -- ?
        ; FIXME
        _error "unimplemented"
        next
endcode
