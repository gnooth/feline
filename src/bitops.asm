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

; ### fixnum-bitand
code fixnum_bitand, 'fixnum-bitand'     ; x y -- z
        _untag_2_fixnums
        _and
        _tag_fixnum
        next
endcode

; ### bitand
code bitand, 'bitand'                   ; x y -- z
        _check_fixnum
        _check_fixnum qword [rbp]
        _and
        _tag_fixnum
        next
endcode

; ### integer_to_raw_bits
code integer_to_raw_bits, 'integer_to_raw_bits', SYMBOL_INTERNAL        ; x -- y

        mov     al, bl
        and     al, FIXNUM_TAG_MASK
        cmp     al, FIXNUM_TAG
        jne     .1
        _untag_fixnum
        _return

.1:
        ; not a fixnum
        cmp     rbx, [handle_space_]
        jb      error_not_integer
        cmp     rbx, [handle_space_free_]
        jnb     error_not_integer

        _handle_to_object_unsafe

        test    rbx, rbx
        jz      error_empty_handle

        _object_raw_typecode_eax

        cmp     eax, TYPECODE_INT64
        je      .2
        cmp     eax, TYPECODE_UINT64
        je      .3

        _ error_not_integer
        _return

.2:
        _int64_raw_value
        _return

.3:
        _uint64_raw_value
        next
endcode

; ### bitor
code bitor, 'bitor'                     ; x y -- z
        _check_fixnum
        _check_fixnum qword [rbp]
        _or
        _tag_fixnum
        next
endcode

; ### bitxor
code bitxor, 'bitxor'                   ; x y -- z
        _ integer_to_raw_bits
        _swap
        _ integer_to_raw_bits
        xor     rbx, [rbp]
        lea     rbp, [rbp + BYTES_PER_CELL]
        _ normalize_unsigned
        next
endcode

; ### bitnot
code bitnot, 'bitnot'                   ; x -- y
        _ integer_to_raw_bits
        not     rbx
        _ normalize
        next
endcode

; ### lshift
code lshift, 'lshift'                   ; x n -- y
; shifts fixnum x to the left by n bits
; n must be >= 0
        _check_index
        mov     ecx, ebx
        poprbx
        _ integer_to_raw_bits
        shl     rbx, cl
        _ normalize_unsigned
        next
endcode

; ### lshift-signed
code lshift_signed, 'lshift-signed'     ; x n -- y
; shifts fixnum x to the left by n bits
; n must be >= 0
        _check_index
        _swap
        _ integer_to_raw_bits
        _swap
        mov     ecx, ebx
        poprbx
        shl     rbx, cl
        _ normalize
        next
endcode

; ### rshift
code rshift, 'rshift'                   ; x n -- y
; shifts fixnum x to the right by n bits
; n must be >= 0
        _check_index
        mov     ecx, ebx
        poprbx
        _ integer_to_raw_bits
        shr     rbx, cl
        _ normalize_unsigned
        next
endcode
